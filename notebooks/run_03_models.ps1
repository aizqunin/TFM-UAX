# run_03_models.ps1 — Ejecuta todos los notebooks de 03_models en orden
# Orden: baseline primero, luego Optuna (cada Optuna depende del baseline previo)
# Uso: .\run_03_models.ps1
# ADVERTENCIA: este script puede tardar varias horas (Optuna con n_trials alto)

$JUPYTER  = "C:\Users\cuent\Documents\UAX\TFM\TFM\venv\Scripts\jupyter.exe"
$NB_DIR   = "$PSScriptRoot\03_models"
$TIMEOUT  = 7200  # 2h por notebook (Optuna puede tardar mucho)

$notebooks = @(
    "01_baseline_logreg.ipynb",
    "01b_logreg_optuna.ipynb",
    "02_catboost_model.ipynb",
    "03_catboost_optuna.ipynb",
    "04_lstm_model.ipynb",
    "04b_lstm_optuna.ipynb",
    "05_tabtransformer.ipynb",
    "05b_tabtransformer_optuna.ipynb",
    "06_nam.ipynb",
    "06b_nam_optuna.ipynb"
)

$total  = $notebooks.Count
$failed = @()
$start  = Get-Date

Write-Host "=== Models notebooks ($total) ===" -ForegroundColor Cyan
Write-Host "Directorio: $NB_DIR"
Write-Host "Timeout por notebook: $($TIMEOUT/3600)h"
Write-Host ""

foreach ($nb in $notebooks) {
    $path = Join-Path $NB_DIR $nb
    $i    = [array]::IndexOf($notebooks, $nb) + 1
    Write-Host "[$i/$total] $nb ..." -NoNewline

    $t0 = Get-Date
    & $JUPYTER nbconvert --to notebook --execute --inplace `
        --ExecutePreprocessor.timeout=$TIMEOUT `
        --ExecutePreprocessor.kernel_name=python3 `
        $path 2>&1 | Out-Null

    if ($LASTEXITCODE -eq 0) {
        $elapsed = [math]::Round(((Get-Date) - $t0).TotalMinutes, 1)
        Write-Host " OK ($elapsed min)" -ForegroundColor Green
    } else {
        Write-Host " FAILED" -ForegroundColor Red
        $failed += $nb
        # Continuar con el resto aunque uno falle
    }
}

$total_elapsed = [math]::Round(((Get-Date) - $start).TotalMinutes, 1)
Write-Host ""
Write-Host "=== Completado en $total_elapsed min ===" -ForegroundColor Cyan

if ($failed.Count -gt 0) {
    Write-Host "Notebooks con error:" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
} else {
    Write-Host "Todos los notebooks ejecutados correctamente." -ForegroundColor Green
}
