# run_01_eda.ps1 — Ejecuta todos los notebooks de 01_eda en orden
# Uso: .\run_01_eda.ps1
# Requiere: venv activo o ajustar $JUPYTER abajo

$JUPYTER  = "C:\Users\cuent\Documents\UAX\TFM\TFM\venv\Scripts\jupyter.exe"
$NB_DIR   = "$PSScriptRoot\01_eda"
$TIMEOUT  = 600   # segundos por notebook

$notebooks = @(
    "01_exploratory_analysis.ipynb",
    "02_verify_load_mimic_ed.ipynb",
    "03_verify_build_labels.ipynb",
    "04_verify_temporal_split.ipynb",
    "05_eda_train_analysis.ipynb"
)

$total   = $notebooks.Count
$failed  = @()
$start   = Get-Date

Write-Host "=== EDA notebooks ($total) ===" -ForegroundColor Cyan
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
