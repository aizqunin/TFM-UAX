# TFM — Predicción de Mortalidad y Deterioro Clínico en Urgencias

**Trabajo Fin de Máster · Máster en Inteligencia Artificial · UAX**  
**Autor:** Adrian Izquierdo Niño · **Tutor:** Jesús Ruiz

Sistema de soporte a la decisión clínica basado en aprendizaje automático para la predicción de tres desenlaces en urgencias a partir exclusivamente de datos del triage:

| Label | Descripción | Prevalencia (test) |
|-------|-------------|-------------------|
| **L1** | Ingreso hospitalario | 40,03 % |
| **L2** | Deterioro crítico / mortalidad | 1,51 % |
| **L3** | Intervención crítica (vasopresores / ventilación) | 0,58 % |

Cinco arquitecturas comparadas: **LogReg+LASSO**, **CatBoost**, **LSTM**, **TabTransformer**, **NAM**.

---

## Estructura del repositorio

```
CodigoGit/
├── notebooks/
│   ├── 01_eda/          — Carga de datos, cohorte y etiquetas, split temporal
│   ├── 02_features/     — Construcción de secuencias temporales para LSTM
│   ├── 03_models/       — Entrenamiento y optimización (Optuna) de los 5 modelos
│   └── 04_evaluation/   — Métricas, calibración, DCA, fairness, eICU, SHAP, NAM
├── scripts/
│   └── generate_test_predictions.py  — Genera predicciones de los 5 modelos sobre test
├── data/
│   ├── interim/         — Generado al ejecutar (cohort_with_labels.parquet)
│   ├── processed/       — Generado al ejecutar (train/val/test, predicciones, secuencias LSTM)
│   └── eicu-collaborative-research-database-2.0/  — Datos eICU (no incluidos)
├── models/              — Modelos serializados (se generan al ejecutar los notebooks)
├── reports/
│   ├── figures/         — Figuras generadas (calibración, DCA, fairness, SHAP, NAM)
│   └── tables/          — Tablas CSV de resultados
├── .env.example         — Plantilla de configuración de rutas
├── requirements_no_torch.txt  — Dependencias Python (sin torch; ver instrucciones de instalación)
└── README.md
```

---

## Datos: acceso y configuración

> ⚠️ **Los datos NO están incluidos en este repositorio** por estar sujetos al Data Use Agreement (DUA) de PhysioNet. Para reproducir el trabajo es necesario obtener acceso independiente.

### MIMIC-IV-ED v2.2 (fuente principal)
1. Crear cuenta en [PhysioNet](https://physionet.org/).
2. Completar la certificación CITI en investigación con sujetos humanos.
3. Firmar el DUA de MIMIC-IV-ED: https://physionet.org/content/mimic-iv-ed/
4. Descargar los siguientes archivos CSV y colocarlos en `data/`:
   - `edstays.csv`
   - `triage.csv`
   - `vitalsign.csv`
   - `diagnosis.csv`
   - `medrecon.csv`
   - `pyxis.csv`
   - `patients.csv`

### eICU Collaborative Research Database v2.0 (validación externa)
1. Firmar el DUA de eICU-CRD: https://physionet.org/content/eicu-crd/
2. Descargar la base de datos completa y colocarla en `data/eicu-collaborative-research-database-2.0/`.

### MIMIC-IV-ED v3.1 (patients)
Para este caso solo descargar el siguiente dataset --> `patients.csv`

### Configurar rutas
```bash
cp .env.example .env
# Editar .env si los datos están en una ruta diferente a data/
```

---

## Instalación del entorno

> ⚠️ **Se requiere Python 3.12 exactamente.** TensorFlow (usado por el LSTM) no es compatible con Python 3.13 ni superior.

### Windows

```powershell
# 1. Crear entorno virtual con Python 3.12
py -3.12 -m venv venv

# 2. Activar
venv\Scripts\activate

# 3. Instalar dependencias base (excluye torch)
pip install -r requirements_no_torch.txt

# 4. Instalar PyTorch con soporte GPU CUDA 12.8 (recomendado)
pip install torch==2.11.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
# Sin GPU:
# pip install torch torchvision torchaudio

# 5. Instalar TensorFlow
pip install tensorflow==2.21.0

# 6. Registrar el entorno como kernel de JupyterLab
python -m ipykernel install --user --name venv --display-name "Python 3.12 (TFM)"

# 7. Lanzar JupyterLab
jupyter lab
```

### macOS / Linux

```bash
# 1. Crear entorno virtual con Python 3.12
python3.12 -m venv venv

# 2. Activar
source venv/bin/activate

# 3. Instalar dependencias base (excluye torch)
pip install -r requirements_no_torch.txt

# 4. Instalar PyTorch
pip install torch torchvision torchaudio   # CPU
# Con CUDA: pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

# 5. Instalar TensorFlow
pip install tensorflow==2.21.0

# 6. Registrar kernel y lanzar
python -m ipykernel install --user --name venv --display-name "Python 3.12 (TFM)"
jupyter lab
```

> Una vez abierto JupyterLab, selecciona el kernel **"Python 3.12 (TFM)"** en cada notebook antes de ejecutarlo.

---

## Orden de ejecución

Los notebooks deben ejecutarse en el orden indicado. Cada fase genera artefactos que la siguiente necesita.

### Fase 1 — Datos (notebooks/01_eda/)
| # | Notebook | Output clave |
|---|----------|-------------|
| 1 | `01_exploratory_analysis.ipynb` | EDA, CSVs limpios |
| 2 | `02_verify_load_mimic_ed.ipynb` | Verificación del loader |
| 3 | `03_verify_build_labels.ipynb` | `data/interim/cohort_with_labels.parquet` |
| 4 | `04_verify_temporal_split.ipynb` | `data/processed/train.parquet`, `val.parquet`, `test.parquet` |
| 5 | `05_eda_train_analysis.ipynb` | Estadísticas descriptivas del train set |

### Fase 2 — Features (notebooks/02_features/)
| # | Notebook | Output clave |
|---|----------|-------------|
| 1 | `01_vitalsign_sequences.ipynb` | `data/processed/lstm_sequences_*.npz` (requerido solo para LSTM) |

### Fase 3 — Modelos (notebooks/03_models/)
| # | Notebook | Output clave |
|---|----------|-------------|
| 1 | `01_baseline_logreg.ipynb` | Modelo LogReg baseline |
| 2 | `01b_logreg_optuna.ipynb` | LogReg optimizado → `models/logreg/` |
| 3 | `02_catboost_model.ipynb` | Modelo CatBoost baseline |
| 4 | `03_catboost_optuna.ipynb` | CatBoost optimizado → `models/catboost_optuna/` |
| 5 | `04_lstm_model.ipynb` | Modelo LSTM baseline |
| 6 | `04b_lstm_optuna.ipynb` | LSTM optimizado → `models/lstm/` |
| 7 | `05_tabtransformer.ipynb` | Modelo TabTransformer baseline |
| 8 | `05b_tabtransformer_optuna.ipynb` | TabTransformer optimizado → `models/tabtransformer/` |
| 9 | `06_nam.ipynb` | Modelo NAM baseline |
| 10 | `06b_nam_optuna.ipynb` | NAM optimizado → `models/nam/` |

> Los notebooks de Optuna realizan 30 trials por target (×3 targets). Tiempo estimado por modelo: 30–120 min en CPU, 10–30 min en GPU.

### Paso previo a la Fase 4 — Generar predicciones sobre test

Antes de ejecutar cualquier notebook de evaluación, ejecutar desde la raíz del repositorio:

```bash
python scripts/generate_test_predictions.py
```

Esto genera `data/processed/predictions_test.parquet` con las probabilidades de los 5 modelos sobre el conjunto de test (59 641 pacientes). Todos los notebooks de evaluación lo leen como entrada.

### Fase 4 — Evaluación (notebooks/04_evaluation/)
| # | Notebook | Output clave |
|---|----------|-------------|
| 1 | `01_metrics.ipynb` | AUROC, AUPRC, Brier con IC bootstrap (n=2000) |
| 2 | `02_calibration.ipynb` | ECE, ICI, curvas de calibración |
| 3 | `03_dca.ipynb` | Decision Curve Analysis |
| 4 | `04_fairness.ipynb` | EOD/EqOdd por género, raza, edad |
| 5 | `05_eicu_cohort.ipynb` | Cohorte eICU (requiere datos eICU) |
| 6 | `06_eicu_vitals.ipynb` | Vitales eICU procesados |
| 7 | `07_eicu_labels_l3.ipynb` | Etiquetas L2/L3 en eICU |
| 8 | `08_eicu_inference.ipynb` | Validación externa sobre eICU |
| 9 | `09_shap_interpretability.ipynb` | SHAP global y local (CatBoost) |
| 10 | `10_nam_shape_functions.ipynb` | Funciones de forma NAM |
| 11 | `11_calibration_posthoc.ipynb` | Calibración post-hoc (Platt scaling) |

> Los notebooks 5–8 de la Fase 4 requieren los datos de eICU-CRD. El resto pueden ejecutarse sin ellos.

---

## Resultados principales (test set MIMIC-IV-ED)

| Modelo | AUROC L1 | AUROC L2 | AUROC L3 |
|--------|----------|----------|----------|
| LogReg+LASSO | 0,816 | 0,869 | 0,881 |
| CatBoost | 0,812 | 0,862 | 0,877 |
| **LSTM** | 0,797 | **0,871** | **0,899** |
| TabTransformer | 0,771 | 0,810 | 0,811 |
| NAM | 0,789 | 0,844 | 0,878 |

Validación externa (eICU-CRD, 89.594 pacientes, 208 hospitales): caída de AUROC de 0,20–0,33 puntos respecto al test interno, atribuible a desplazamiento de dominio (severidad, prevalencia, ausencia de ESI).

---

## Hardware utilizado

- **CPU**: AMD Ryzen 7 5800H (8 cores / 16 threads)
- **GPU (CUDA)**:  NVIDIA GeForce RTX 3050 Ti Laptop GPU (4 GB VRAM)
- **RAM**: 16 GB

---

## Estándar de reporte

Este trabajo sigue las directrices **TRIPOD+AI** (Collins et al., 2024, *BMJ*) para el reporte transparente de modelos de predicción clínica con inteligencia artificial.

---

## Bibliografía

### MIMIC-IV-ED v2.2
@article{PhysioNet-mimic-iv-ed-2.2,
  author = {Johnson, Alistair and Bulgarelli, Lucas and Pollard, Tom and Celi, Leo Anthony and Mark, Roger and Horng, Steven},
  title = {{MIMIC-IV-ED}},
  journal = {{PhysioNet}},
  year = {2023},
  month = jan,
  note = {Version 2.2},
  doi = {10.13026/5ntk-km72},
  url = {https://doi.org/10.13026/5ntk-km72}
}

Goldberger, A., Amaral, L., Glass, L., Hausdorff, J., Ivanov, P. C., Mark, R., ... & Stanley, H. E. (2000). PhysioBank, PhysioToolkit, and PhysioNet: Components of a new research resource for complex physiologic signals. Circulation [Online]. 101 (23), pp. e215–e220. RRID:SCR_007345.

### eICU Collaborative Research Database
@article{PhysioNet-eicu-crd-2.0,
  author = {Pollard, Tom and Johnson, Alistair and Raffa, Jesse and Celi, Leo Anthony and Badawi, Omar and Mark, Roger},
  title = {{eICU Collaborative Research Database}},
  journal = {{PhysioNet}},
  year = {2019},
  month = apr,
  note = {Version 2.0},
  doi = {10.13026/C2WM1R},
  url = {https://doi.org/10.13026/C2WM1R}
}

The eICU Collaborative Research Database, a freely available multi-center database for critical care research. Pollard TJ, Johnson AEW, Raffa JD, Celi LA, Mark RG and Badawi O. Scientific Data (2018). DOI: http://dx.doi.org/10.1038/sdata.2018.178.

Goldberger, A., Amaral, L., Glass, L., Hausdorff, J., Ivanov, P. C., Mark, R., ... & Stanley, H. E. (2000). PhysioBank, PhysioToolkit, and PhysioNet: Components of a new research resource for complex physiologic signals. Circulation [Online]. 101 (23), pp. e215–e220. RRID:SCR_007345.

### MIMIC-IV-ED v3.1
@article{PhysioNet-mimiciv-3.1,
  author = {Johnson, Alistair and Bulgarelli, Lucas and Pollard, Tom and Gow, Brian and Moody, Benjamin and Horng, Steven and Celi, Leo Anthony and Mark, Roger},
  title = {{MIMIC-IV}},
  journal = {{PhysioNet}},
  year = {2024},
  month = oct,
  note = {Version 3.1},
  doi = {10.13026/kpb9-mt58},
  url = {https://doi.org/10.13026/kpb9-mt58}
}

Johnson, A.E.W., Bulgarelli, L., Shen, L. et al. MIMIC-IV, a freely accessible electronic health record dataset. Sci Data 10, 1 (2023). https://doi.org/10.1038/s41597-022-01899-x

Goldberger, A., Amaral, L., Glass, L., Hausdorff, J., Ivanov, P. C., Mark, R., ... & Stanley, H. E. (2000). PhysioBank, PhysioToolkit, and PhysioNet: Components of a new research resource for complex physiologic signals. Circulation [Online]. 101 (23), pp. e215–e220. RRID:SCR_007345.

---
