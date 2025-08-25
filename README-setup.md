# AFWGSS — Local Setup & Secrets Workflow (Windows PowerShell 5.1+)

This short guide shows how to keep **secrets out of git** while making setup easy for any developer.

## Files in repo
- `.env.example` — template with all required keys (committed to git).
- `scripts/make-env.ps1` — generates a real `.env` from the template (committed to git).
- `.env` — real file with secrets (NOT committed; ensure it's in `.gitignore`).
- `scripts/check-stack.ps1` — health checks for InfluxDB/Redis/GeoServer/MapProxy.

## One-time machine setup (recommended)
Set secrets in your OS environment (User-level is fine). Open a **new** PowerShell after setting:
```powershell
[Environment]::SetEnvironmentVariable('INFLUX_INIT_PASS','<influx admin pass>','User')
[Environment]::SetEnvironmentVariable('INFLUX_INIT_TOKEN','<influx v2 token>','User')
[Environment]::SetEnvironmentVariable('REDIS_PASSWORD','<redis pass>','User')
[Environment]::SetEnvironmentVariable('GEOSERVER_ADMIN_PASSWORD','<geoserver pass>','User')
```
> Tip: Keep secrets in a password manager and paste them when needed.

## Generate `.env` from template
Preview (no write):
```powershell
powershell -File .\scripts\make-env.ps1 -Check
```
Write `.env` (overwrite existing with `-Force`):
```powershell
powershell -File .\scripts\make-env.ps1 -Force
```

The script:
- Reads `.env.example` (keeps order, comments).
- Replaces placeholders like `__PUT_*__`, `__REPLACE_*__` with values from your environment.
- Understands `REDIS_PASSWORD` alias `REDIS_PASS`.
- Prints a masked preview.
- Verifies variables referenced in `docker-compose.yml` exist in the final `.env` and warns if anything is missing.

## Bring the stack up
```powershell
docker compose up -d
docker ps
```

## Health check
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
.\scripts\check-stack.ps1
```
Expected output (all green):
```
InfluxDB /health : OK (200)
InfluxDB write    : OK (204)
InfluxDB read     : OK (200)
Redis AUTH/PING   : OK (200)
GeoServer Web UI  : OK (200)
MapProxy demo     : OK (200) [http://localhost:8080/]
=== Summary: OK ===
```

## Troubleshooting
- **Influx 401**: token must be a valid v2 token for the *current* data volume; generate via UI or `influx auth create` and export it as `INFLUX_INIT_TOKEN` for init, or `INFLUX_TOKEN` for runtime.
- **Redis -NOAUTH**: set `REDIS_PASSWORD` (or `REDIS_PASS`) in your environment.
- **MapProxy URI errors**: ensure full scheme in URLs, e.g. `http://localhost:8080`.
- **Encoding**: keep scripts in UTF-8 (no BOM).

## CI/CD note
CI should inject the same variables as secrets and run:
```powershell
powershell -File .\scripts\make-env.ps1 -Force
docker compose up -d --pull always
.\scripts\check-stack.ps1
```
