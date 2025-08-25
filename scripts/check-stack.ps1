<#
check-stack.ps1 — расширенная проверка стека (InfluxDB/Redis/GeoServer/MapProxy)
- Нормализация URL'ов
- Явная диагностика токена InfluxDB (длина/превью)
- Поддержка Fallback с INFLUX_INIT_* на INFLUX_*
- Аккуратные сообщения об ошибках
- Проверка Redis AUTH + PING по простому протоколу RESP
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
        [string] $Body = $null,
        [int] $TimeoutSec = 10
    )
    try {
        $params = @{
            Uri = $Uri
            Method = $Method
            TimeoutSec = $TimeoutSec
            ErrorAction = 'Stop'
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
    # Fallback на INIT-переменные, если основные пусты
    if (-not $env:INFLUX_ORG    -and $env:INFLUX_INIT_ORG)    { $env:INFLUX_ORG    = $env:INFLUX_INIT_ORG }
    if (-not $env:INFLUX_BUCKET -and $env:INFLUX_INIT_BUCKET) { $env:INFLUX_BUCKET = $env:INFLUX_INIT_BUCKET }
    if (-not $env:INFLUX_TOKEN  -and $env:INFLUX_INIT_TOKEN)  { $env:INFLUX_TOKEN  = $env:INFLUX_INIT_TOKEN }

    $env:INFLUX_TOKEN = ($env:INFLUX_TOKEN | ForEach-Object { $_ }).ToString().Trim('"').Trim()

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
        $base = Normalize-Url ($env:INFLUX_URL ?? 'http://localhost:8086')
    } catch {
        $result.Errors += "INFLUX_URL: $($_.Exception.Message)"
        return $result
    }

    # /health
    try {
        $r = Try-InvokeWebRequest -Uri "$base/health"
        if ($r.StatusCode -eq 200) { $result.Health = 'OK (200)' } else { $result.Health = "Unexpected ($($r.StatusCode))" }
    } catch {
        $result.Health = "FAIL"
        $result.Errors += "Influx /health: $($_.Exception.Message)"
    }

    # write test
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

    # read test (Flux CSV)
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
    # Поддерживаются переменные: REDIS_HOST/PORT/PASS или REDIS_URL=redis://[:pass@]host:port
    $res = [ordered]@{ AuthPing = $null; Errors = @() }

    # Парсим окружение
    $host = $env:REDIS_HOST
    $port = $env:REDIS_PORT
    $pass = $env:REDIS_PASS

    if (-not $host -and $env:REDIS_URL) {
        try {
            $u = [Uri]$env:REDIS_URL
            if ($u.Scheme -ne 'redis') { throw "REDIS_URL must start with redis://..." }
            $host = $u.Host
            $port = if ($u.Port -gt 0) { $u.Port } else { 6379 }
            if ($u.UserInfo -and $u.UserInfo.Contains(":")) {
                $pass = $u.UserInfo.Split(":")[1]
            }
        } catch {
            $res.Errors += "REDIS_URL parse error: $($_.Exception.Message)"
        }
    }

    if (-not $host) { $host = '127.0.0.1' }
    if (-not $port) { $port = 6379 }

    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $client.ReceiveTimeout = 3000
        $client.SendTimeout = 3000
        $client.Connect($host, [int]$port)

        $stream = $client.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream)
        $writer.NewLine = "`r`n"
        $writer.AutoFlush = $true
        $reader = New-Object System.IO.StreamReader($stream)

        if ($pass) {
            # AUTH <pass>
            $authCmd = "*2`r`n$4`r`nAUTH`r`n$($pass.Length)`r`n$pass`r`n"
            $writer.Write($authCmd)
            $authResp = $reader.ReadLine()
            if (-not $authResp.StartsWith('+OK')) { throw "AUTH failed: $authResp" }
        }

        # PING
        $pingCmd = "*1`r`n$4`r`nPING`r`n"
        $writer.Write($pingCmd)
        $pingResp = $reader.ReadLine()
        if ($pingResp -and $pingResp.StartsWith('+PONG')) { $res.AuthPing = 'OK (200)' } else { throw "PING failed: $pingResp" }

        $reader.Close(); $writer.Close(); $stream.Close(); $client.Close()
    } catch {
        $res.AuthPing = 'FAIL'
        $res.Errors += "Redis: $host:$port — $($_.Exception.Message)"
    }

    return $res
}

function Check-GeoServer {
    $res = [ordered]@{ WebUI = $null; Errors = @() }
    try {
        $base = Normalize-Url ($env:GEOSERVER_URL ?? 'http://localhost:8080/geoserver')
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
        $base = Normalize-Url ($env:MAPPROXY_URL ?? 'http://localhost:8080')
    } catch {
        $res.Demo = 'FAIL'
        $res.Errors += "MAPPROXY_URL: $($_.Exception.Message)"
        return $res
    }

    $candidates = @()
    if ($env:MAPPROXY_DEMO_URL) {
        try {
            # Если задан конкретный URL демо — проверяем его первым
            $demo = Normalize-Url $env:MAPPROXY_DEMO_URL
            $candidates += ($demo + '/')
        } catch {
            $res.Errors += "MAPPROXY_DEMO_URL: $($_.Exception.Message)"
        }
    }
    # Типовые пути
    $candidates += @(
        "$base/demo/",
        "$base/mapproxy/demo/",
        "$base/"
    ) | Select-Object -Unique

    $found = $false
    foreach ($u in $candidates) {
        try {
            $r = Try-InvokeWebRequest -Uri $u -TimeoutSec 6
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
if ($statuses | Where-Object { $_ -and ($_ -notlike 'OK*') } ) {
    Write-Host "=== Summary: FAIL ==="
} else {
    Write-Host "=== Summary: OK ==="
}
