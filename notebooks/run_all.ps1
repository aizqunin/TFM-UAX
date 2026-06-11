# run_all.ps1 — Pipeline completo: EDA → Features → Models → Evaluation
# Uso: .\run_all.ps1
# ADVERTENCIA: puede tardar varias horas por los notebooks de Optuna

$ROOT   = $PSScriptRoot
$start  = Get-Date
$failed = @()

$phases = @(
    @{ name = "01_eda";        script = "run_01_eda.ps1" },
    @{ name = "02_features";   script = "run_02_features.ps1" },
    @{ name = "03_models";     script = "run_03_models.ps1" },
    @{ name = "04_evaluation"; script = "run_04_evaluation.ps1" }
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PIPELINE COMPLETO TFM" -ForegroundColor Cyan
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($phase in $phases) {
    Write-Host ">>> Fase: $($phase.name)" -ForegroundColor Yellow
    $script_path = Join-Path $ROOT $phase.script

    & powershell -ExecutionPolicy Bypass -File $script_path

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR en fase $($phase.name) — pipeline interrumpido." -ForegroundColor Red
        $failed += $phase.name
        break   # detener si una fase falla (las siguientes dependen de ella)
    }
    Write-Host ""
}

$total_elapsed = [math]::Round(((Get-Date) - $start).TotalMinutes, 1)
Write-Host "========================================"
Write-Host "  Tiempo total: $total_elapsed min"

if ($failed.Count -eq 0) {
    Write-Host "  Estado: COMPLETADO" -ForegroundColor Green
} else {
    Write-Host "  Fase fallida: $($failed -join ', ')" -ForegroundColor Red
    exit 1
}
Write-Host "========================================"
