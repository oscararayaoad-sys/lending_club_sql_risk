# Datos

El dataset de LendingClub **no está incluido** en este repositorio por su tamaño (varios cientos de MB, por encima del límite de GitHub).

## Cómo obtener el dataset

1. Descargar el dataset **"Lending Club Loan Data"** desde [Kaggle](https://www.kaggle.com/datasets/wordsforthewise/lending-club).
2. Usar el archivo de préstamos aceptados (`accepted_*.csv`).
3. Colocarlo en esta carpeta (`data/`).
4. Ejecutar el notebook `01_limpieza_datos.ipynb` desde la raíz del proyecto para generar el CSV limpio (`lending_club_limpio.csv`).

## Sobre el dataset

- **Crudo:** ~2.26 millones de filas, 100+ columnas (2007–2018).
- **Limpio (este proyecto):** 1,230,327 préstamos terminados, 15 columnas + variable objetivo `default`.

El proceso de limpieza completo, con su justificación, está documentado en `01_limpieza_datos.ipynb`.
