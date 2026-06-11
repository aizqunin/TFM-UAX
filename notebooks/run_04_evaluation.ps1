# run_04_evaluation.ps1 — Ejecuta todos los notebooks de 04_evaluation en orden
# Prerequisito: 03_models debe haberse ejecutado antes (genera predictions_test.parquet)
# Uso: .\run_04_evaluation.ps1

$JUPYTER  = "C:\Users\cuent\Documents\UAX\TFM\TFM\venv\Scripts\jupyter.exe"
$NB_DIR   = "$PSScriptRoot\04_evaluation"
$TIMEOUT  = 1800  # 30 min por notebook (bootstrap 2000 iter puede tardar)

$notebooks = @(
    "01_metrics.ipynb",
    "02_calibration.ipynb",
    "03_dca.ipynb",
    "04_fairness.ipynb",
    "05_eicu_cohort.ipynb",
    "06_eicu_vitals.ipynb",
    "07_eicu_labels_l3.ipynb",
    "08_eicu_inference.ipynb",
    "09_shap_interpretability.ipynb",
    "10_nam_shape_functions.ipynb",
    "11_calibration_posthoc.ipynb"
)

$total  = $notebooks.Count
$failed = @()
$start  = Get-Date

Write-Host "=== Evaluation notebooks ($total) ===" -ForegroundColor Cyan
Write-Host "Directorio: $NB_DIR"
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
        $elapsed = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)
        Write-Host " OK ($elapsed s)" -ForegroundColor Green
    } else {
        Write-Host " FAILED" -ForegroundColor Red
        $failed += $nb
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
