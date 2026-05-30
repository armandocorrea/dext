# run_metrics_demo.ps1
# Starts Web.MinimalAPIExample, generates HTTP traffic, flushes telemetry to disk.
# Prerequisites: dext-sidecar.exe must be running at http://localhost:3030
#                Web.MinimalAPIExample.exe must already be compiled.

$env:DEXT_SIDECAR_ENABLED = "true"
$ErrorActionPreference = "Stop"

$DextRepo   = "C:\dev\Dext\DextRepository"
$AppExe     = "$DextRepo\Examples\Output\Web.MinimalAPIExample.exe"
$AppUrl     = "http://localhost:5000"
$SidecarUrl = "http://localhost:3030"

# ---- Sidecar health check ----
Write-Host "[Check] Verifying sidecar is running at $SidecarUrl ..." -ForegroundColor Cyan
try {
    $health = Invoke-WebRequest -Uri "$SidecarUrl/health" -UseBasicParsing -TimeoutSec 3
    Write-Host "  Sidecar OK: $($health.Content)" -ForegroundColor Green
} catch {
    Write-Host "  WARN: Sidecar nao esta respondendo. Inicie dext-sidecar.exe antes de executar este script." -ForegroundColor Yellow
}

# ---- Start Web.MinimalAPIExample ----
Write-Host "`n[1/3] Starting Web.MinimalAPIExample..." -ForegroundColor Cyan
Stop-Process -Name "Web.MinimalAPIExample" -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

if (-not (Test-Path $AppExe)) {
    Write-Error "Nao encontrado: $AppExe. Compile o projeto primeiro."
    exit 1
}

$appProc = Start-Process -FilePath $AppExe -PassThru -WindowStyle Normal
Start-Sleep -Seconds 2

# ---- Verify app is up ----
try {
    $r = Invoke-WebRequest -Uri "$AppUrl/health" -UseBasicParsing -TimeoutSec 3
    Write-Host "  App OK: $($r.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "  WARN: App pode ainda estar iniciando..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
}

# ---- Generate HTTP traffic ----
Write-Host "`n[2/3] Generating traffic (30 iterations x 3 endpoints = 90 requests)..." -ForegroundColor Cyan
Write-Host "  Dashboard: $SidecarUrl" -ForegroundColor Magenta

for ($i = 1; $i -le 30; $i++) {
    # Normal requests
    try { Invoke-WebRequest -Uri "$AppUrl/hello?name=DextUser$i" -UseBasicParsing | Out-Null } catch {}
    try { Invoke-WebRequest -Uri "$AppUrl/json"                   -UseBasicParsing | Out-Null } catch {}
    try { Invoke-WebRequest -Uri "$AppUrl/time"                   -UseBasicParsing | Out-Null } catch {}

    # ~1 in 5: error request to generate error metrics
    if ($i % 5 -eq 0) {
        try { Invoke-WebRequest -Uri "$AppUrl/not-found" -UseBasicParsing | Out-Null } catch {}
        Write-Host "  [$i/30] sent (with 404 error)" -ForegroundColor Gray
    }

    Start-Sleep -Milliseconds 100
}

Write-Host "`n  Traffic complete!" -ForegroundColor Green

# ---- Flush telemetry to disk ----
Write-Host "`n[3/3] Flushing telemetry to disk..." -ForegroundColor Cyan
try {
    $flush = Invoke-WebRequest -Uri "$SidecarUrl/api/telemetry/flush" -Method POST -UseBasicParsing -TimeoutSec 5
    Write-Host "  Flush OK: $($flush.Content)" -ForegroundColor Green
} catch {
    Write-Host "  WARN: Flush falhou (sidecar pode nao ter a rota ainda): $($_.Exception.Message)" -ForegroundColor Yellow
}

# ---- Verify persistence ----
$telemetryFile = Join-Path $env:USERPROFILE ".dext\telemetry.json"
Start-Sleep -Milliseconds 500
if (Test-Path $telemetryFile) {
    $content = Get-Content $telemetryFile -Raw
    $items = $content | ConvertFrom-Json
    Write-Host "  Persistencia OK: $($items.Count) items salvos em $telemetryFile" -ForegroundColor Green
} else {
    Write-Host "  WARN: Arquivo de persistencia nao encontrado: $telemetryFile" -ForegroundColor Yellow
}

# ---- History endpoint check ----
try {
    $hist = Invoke-WebRequest -Uri "$SidecarUrl/api/telemetry/history" -UseBasicParsing
    $histItems = $hist.Content | ConvertFrom-Json
    Write-Host "  Historico em memoria: $($histItems.Count) items" -ForegroundColor Cyan
    if ($histItems.Count -gt 0) {
        $first = $histItems[0]
        Write-Host "  Primeiro item - event: $($first.event), app: $($first.data.app)" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Nao foi possivel verificar historico: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Pressione qualquer tecla para encerrar Web.MinimalAPIExample..." -ForegroundColor Yellow
$null = [Console]::ReadKey()

# Cleanup
if ($appProc) {
    Stop-Process -Id $appProc.Id -Force -ErrorAction SilentlyContinue
    Write-Host "Web.MinimalAPIExample encerrado." -ForegroundColor Yellow
}
