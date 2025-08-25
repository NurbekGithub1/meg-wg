<#
check-stack.ps1 — расширенная проверка стека (InfluxDB/Redis/GeoServer/MapProxy)
Совместимо с Windows PowerShell 5.1.
Fix: Redis AUTH — добавлен символ '$' перед длиной пароля и расчёт длины в байтах.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Normalize-Url([string]$u) {
    if ([string]::IsNullOrWhiteSpace($u)) { return $null }
    $u = $u.Trim()
    if (-not ($u -match '^(http|https)://')) { throw "URL '$u' без схемы http/https" }
    return $u.TrimEnd('/')
}

function Try-InvokeWebRequest {
    param(
        [Parameter(Mandatory=$true)] [string] $Uri,
        [hashtable] $Headers = $null,
        [string] $Method = 'GET',
        [string] $Body = $null
    )
    try {
        $params = @{
            Uri        = $Uri
            Method     = $Method
            ErrorAction= 'Stop'
        }
        if ($Headers) { $params['Headers'] = $Headers }
        if ($Body)    { $params['Body']    = $Body    }
        return Invoke-WebRequest @params
    } catch {
        throw $_
    }
}

function Diagnose-Influx {
    Write-Host "=== InfluxDB token diagnostics ==="
    if (-not $env:INFLUX_ORG    -and $env:INFLUX_INIT_ORG)    { $env:INFLUX_ORG    = $env:INFLUX_INIT_ORG }
    if (-not $env:INFLUX_BUCKET -and $env:INFLUX_INIT_BUCKET) { $env:INFLUX_BUCKET = $env:INFLUX_INIT_BUCKET }
    if (-not $env:INFLUX_TOKEN  -and $env:INFLUX_INIT_TOKEN)  { $env:INFLUX_TOKEN  = $env:INFLUX_INIT_TOKEN }

    if ($env:INFLUX_TOKEN) { $env:INFLUX_TOKEN = $env:INFLUX_TOKEN.ToString().Trim('"').Trim() }

    if ([string]::IsNullOrWhiteSpace($env:INFLUX_TOKEN)) {
        Write-Warning "INFLUX_TOKEN is EMPTY!"
    } else {
        $tok = $env:INFLUX_TOKEN
        $len = $tok.Length
        Write-Host "INFLUX_TOKEN length: $len"
        if ($len -ge 6) {
            Write-Host ("INFLUX_TOKEN preview: {0}...{1}" -f $tok.Substring(0,3), $tok.Substring($len-3))
        }
    }
    Write-Host ("ORG={0}; BUCKET={1}" -f $env:INFLUX_ORG, $env:INFLUX_BUCKET)
    Write-Host "==================================="
}

function Check-Influx {
    $result = [ordered]@{ Health = $null; Write = $null; Read = $null; Errors = @() }

    try {
        $baseEnv = $env:INFLUX_URL
        if (-not $baseEnv) { $baseEnv = 'http://localhost:8086' }
        $base = Normalize-Url $baseEnv
    } catch {
        $result.Errors += "INFLUX_URL: $($_.Exception.Message)"
        return $result
    }

    try {
        $r = Try-InvokeWebRequest -Uri "$base/health"
        if ($r.StatusCode -eq 200) { $result.Health = 'OK (200)' } else { $result.Health = "Unexpected ($($r.StatusCode))" }
    } catch {
        $result.Health = "FAIL"
        $result.Errors += "Influx /health: $($_.Exception.Message)"
    }

    try {
        $org    = $env:INFLUX_ORG
        $bucket = $env:INFLUX_BUCKET
        if ([string]::IsNullOrWhiteSpace($org))    { throw "INFLUX_ORG is empty" }
        if ([string]::IsNullOrWhiteSpace($bucket)) { throw "INFLUX_BUCKET is empty" }
        if ([string]::IsNullOrWhiteSpace($env:INFLUX_TOKEN)) { throw "INFLUX_TOKEN is empty" }

        $writeUri = "$base/api/v2/write?org=$([uri]::EscapeDataString($org))&bucket=$([uri]::EscapeDataString($bucket))&precision=ns"
        $lp = "awgss_health,host=$($env:COMPUTERNAME) value=1i"
        $hdr = @{ Authorization = "Token $($env:INFLUX_TOKEN)"; "Content-Type"="text/plain" }

        $w = Try-InvokeWebRequest -Uri $writeUri -Method 'POST' -Headers $hdr -Body $lp
        if ($w.StatusCode -in 200,204) { $result.Write = "OK ($($w.StatusCode))" } else { $result.Write = "Unexpected ($($w.StatusCode))" }
    } catch {
        $result.Write = 'FAIL'
        $result.Errors += "Influx write: $($_.Exception.Message)"
    }

    try {
        if ($result.Write -like 'OK*') {
            $q = 'from(bucket:"' + $env:INFLUX_BUCKET + '") |> range(start: -5m) |> filter(fn: (r) => r._measurement == "awgss_health") |> limit(n:1)'
            $qr = Try-InvokeWebRequest -Uri "$base/api/v2/query?org=$([uri]::EscapeDataString($env:INFLUX_ORG))" -Method 'POST' -Headers @{ Authorization = "Token $($env:INFLUX_TOKEN)"; "Accept"="application/csv"; "Content-Type"="application/vnd.flux" } -Body $q
            if ($qr.StatusCode -eq 200) { $result.Read = 'OK (200)' } else { $result.Read = "Unexpected ($($qr.StatusCode))" }
        } else {
            $result.Read = 'SKIPPED (write failed)'
        }
    } catch {
        $result.Read = 'FAIL'
        $result.Errors += "Influx read: $($_.Exception.Message)"
    }

    return $result
}

function Check-Redis {
    $res = [ordered]@{ AuthPing = $null; Errors = @() }

    # Разбор окружения
    $redisHost = $env:REDIS_HOST
    $redisPort = $env:REDIS_PORT
    $redisPass = $env:REDIS_PASS
    if (-not $redisPass -and $env:REDIS_PASSWORD) { $redisPass = $env:REDIS_PASSWORD }  # поддержка REDIS_PASSWORD

    if (-not $redisHost -and $env:REDIS_URL) {
        try {
            $u = [Uri]$env:REDIS_URL
            if ($u.Scheme -ne 'redis') { throw "REDIS_URL must start with redis://..." }
            $redisHost = $u.Host
            if ($u.Port -gt 0) { $redisPort = $u.Port } else { $redisPort = 6379 }
            if ($u.UserInfo -and $u.UserInfo.Contains(":")) {
                $redisPass = $u.UserInfo.Split(":")[1]
            }
        } catch {
            $res.Errors += "REDIS_URL parse error: $($_.Exception.Message)"
        }
    }

    if (-not $redisHost) { $redisHost = '127.0.0.1' }
    if (-not $redisPort) { $redisPort = 6379 }

    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $client.ReceiveTimeout = 3000
        $client.SendTimeout = 3000
        $client.Connect($redisHost, [int]$redisPort)

        $stream = $client.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream)
        $writer.NewLine = "`r`n"
        $writer.AutoFlush = $true
        $reader = New-Object System.IO.StreamReader($stream)

        if ($redisPass) {
            # AUTH <pass> — нужно указать длину пароля в байтах
            $passBytesLen = [System.Text.Encoding]::UTF8.GetByteCount($redisPass)
            # Формируем RESP с корректным '$' перед длиной
            $authCmd = ("*2`r`n`$4`r`nAUTH`r`n`${0}`r`n{1}`r`n" -f $passBytesLen, $redisPass)
            $writer.Write($authCmd)
            $authResp = $reader.ReadLine()
            if (-not $authResp -or -not $authResp.StartsWith('+OK')) { throw "AUTH failed: $authResp" }
        }

        # PING
        $pingCmd = "*1`r`n`$4`r`nPING`r`n"
        $writer.Write($pingCmd)
        $pingResp = $reader.ReadLine()
        if ($pingResp -and $pingResp.StartsWith('+PONG')) { $res.AuthPing = 'OK (200)' } else { throw "PING failed: $pingResp" }

        $reader.Close(); $writer.Close(); $stream.Close(); $client.Close()
    } catch {
        $res.AuthPing = 'FAIL'
        $res.Errors += ("Redis: {0}:{1} - {2}" -f $redisHost, $redisPort, $_.Exception.Message)
    }

    return $res
}

function Check-GeoServer {
    $res = [ordered]@{ WebUI = $null; Errors = @() }
    try {
        $baseEnv = $env:GEOSERVER_URL
        if (-not $baseEnv) { $baseEnv = 'http://localhost:8080/geoserver' }
        $base = Normalize-Url $baseEnv
        $r = Try-InvokeWebRequest -Uri "$base/web/"
        if ($r.StatusCode -eq 200) { $res.WebUI = 'OK (200)' } else { $res.WebUI = "Unexpected ($($r.StatusCode))" }
    } catch {
        $res.WebUI = 'FAIL'
        $res.Errors += "GeoServer: $($_.Exception.Message)"
    }
    return $res
}

function Check-MapProxy {
    $res = [ordered]@{ Demo = $null; Errors = @() }

    try {
        $baseEnv = $env:MAPPROXY_URL
        if (-not $baseEnv) { $baseEnv = 'http://localhost:8080' }
        $base = Normalize-Url $baseEnv
    } catch {
        $res.Demo = 'FAIL'
        $res.Errors += "MAPPROXY_URL: $($_.Exception.Message)"
        return $res
    }

    $candidates = @()

    if ($env:MAPPROXY_DEMO_URL) {
        try {
            $demo = Normalize-Url $env:MAPPROXY_DEMO_URL
            $candidates += ($demo + '/')
        } catch {
            $res.Errors += "MAPPROXY_DEMO_URL: $($_.Exception.Message)"
        }
    }

    $candidates += @(
        "$base/demo/",
        "$base/mapproxy/demo/",
        "$base/"
    ) | Select-Object -Unique

    $found = $false
    foreach ($u in $candidates) {
        try {
            $r = Try-InvokeWebRequest -Uri $u
            if ($r.StatusCode -eq 200) {
                $res.Demo = "OK (200) [$u]"
                $found = $true
                break
            }
        } catch {
            $res.Errors += "MapProxy candidate '$u': $($_.Exception.Message)"
        }
    }

    if (-not $found) { $res.Demo = 'FAIL' }
    return $res
}

# ------------------------- MAIN -------------------------

Diagnose-Influx

Write-Host "=== Health checks ==="
$inf = Check-Influx
if ($inf.Health) { Write-Host ("InfluxDB /health : {0}" -f $inf.Health) }
if ($inf.Write)  { Write-Host ("InfluxDB write    : {0}" -f $inf.Write); if ($inf.Write -notlike 'OK*') { foreach ($e in $inf.Errors | Where-Object { $_ -like 'Influx write*' }) { Write-Host "  error: $e" } } }
if ($inf.Read)   { Write-Host ("InfluxDB read     : {0}" -f $inf.Read);  if ($inf.Read -notlike 'OK*')  { foreach ($e in $inf.Errors | Where-Object { $_ -like 'Influx read*'  }) { Write-Host "  error: $e" } } }

$red = Check-Redis
Write-Host ("Redis AUTH/PING   : {0}" -f $red.AuthPing)
if ($red.AuthPing -notlike 'OK*') { foreach ($e in $red.Errors) { Write-Host "  error: $e" } }

$geo = Check-GeoServer
Write-Host ("GeoServer Web UI  : {0}" -f $geo.WebUI)
if ($geo.WebUI -notlike 'OK*') { foreach ($e in $geo.Errors) { Write-Host "  error: $e" } }

$mpx = Check-MapProxy
Write-Host ("MapProxy demo     : {0}" -f $mpx.Demo)
if ($mpx.Demo -notlike 'OK*') { foreach ($e in $mpx.Errors) { Write-Host "  error: $e" } }

# Summary
$statuses = @($inf.Health, $inf.Write, $inf.Read, $red.AuthPing, $geo.WebUI, $mpx.Demo)
$hasFail = $false
foreach ($s in $statuses) {
    if ($s -and ($s -notlike 'OK*')) { $hasFail = $true; break }
}
if ($hasFail) { Write-Host "=== Summary: FAIL ===" } else { Write-Host "=== Summary: OK ===" }
