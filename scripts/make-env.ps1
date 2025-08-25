<#
make-env.ps1 — generate .env from .env.example
Compatible with PowerShell 5.1+
#>

[CmdletBinding()]
param(
  [switch]$Force,
  [switch]$Check
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir
$EnvExamplePath = Join-Path $RepoRoot '.env.example'
$EnvOutPath     = Join-Path $RepoRoot '.env'

if (-not (Test-Path $EnvExamplePath)) { throw ".env.example not found" }

$lines = Get-Content -LiteralPath $EnvExamplePath -Raw -Encoding UTF8 -ErrorAction Stop
$lines = $lines -split "(`r`n|`n)"

function Get-EnvValue([string]$key, [string]$val) {
  if ($val -notmatch '__PUT_|__REPLACE') { return $val }

  # Try environment variables
  $v = [System.Environment]::GetEnvironmentVariable($key, 'Process')
  if (-not $v) { $v = [System.Environment]::GetEnvironmentVariable($key, 'User') }
  if (-not $v) { $v = [System.Environment]::GetEnvironmentVariable($key, 'Machine') }

  # Special alias for Redis
  if (-not $v -and $key -eq 'REDIS_PASSWORD') {
    $v = [System.Environment]::GetEnvironmentVariable('REDIS_PASS','Process')
    if (-not $v) { $v = [System.Environment]::GetEnvironmentVariable('REDIS_PASS','User') }
    if (-not $v) { $v = [System.Environment]::GetEnvironmentVariable('REDIS_PASS','Machine') }
  }

  return $v
}

$outLines = @()
$report   = @()

foreach ($ln in $lines) {
  if ($ln -match '^\s*#' -or $ln.Trim().Length -eq 0) { $outLines += $ln; continue }
  if ($ln -notmatch '^\s*([A-Z0-9_]+)\s*=(.*)$') { $outLines += $ln; continue }

  $key = $Matches[1]
  $val = $Matches[2].Trim()
  $newVal = Get-EnvValue $key $val

  if ($newVal) {
    $outLines += "$key=$newVal"
    $report   += "$key <- ENV"
  } else {
    $outLines += "$key=$val"
    $report   += "$key left as example"
  }
}

Write-Host "=== Preview ==="
$report | ForEach-Object { Write-Host $_ }

if ($Check) {
  Write-Host "Check-only mode: no .env written"
  exit 0
}

if ((Test-Path $EnvOutPath) -and -not $Force) {
  Write-Host ".env already exists. Use -Force to overwrite." -ForegroundColor Yellow
  exit 1
}

$out = [string]::Join("`n", $outLines)
[System.IO.File]::WriteAllText($EnvOutPath, $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ".env written to $EnvOutPath" -ForegroundColor Green
