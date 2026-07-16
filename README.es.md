*Read this in other languages: [English](README.md)*


# Análisis de Riesgo de Mora — LendingClub (P2P Lending)

Análisis de riesgo crediticio sobre **1.23 millones de préstamos** de LendingClub, una plataforma de préstamos *peer-to-peer* (P2P). El proyecto identifica **qué características predicen que un préstamo caiga en mora (default)**, usando PostgreSQL para el análisis y Python para la preparación y visualización de datos.

Está orientado al rubro **fintech de crédito y lending P2P**, donde la evaluación y el monitoreo del riesgo de impago son el corazón del negocio.

---

## Pregunta central

> ¿Qué características predicen que un préstamo caiga en mora?

**Tasa base de default del portafolio: 19.7%** — aproximadamente 1 de cada 5 préstamos terminados cayó en mora. Cada análisis busca identificar **dónde se desvía** ese número base.

---

## Stack técnico

| Herramienta | Uso |
|---|---|
| **Python** (pandas, NumPy) | Limpieza y preparación de datos (2.26M → 1.23M filas) |
| **PostgreSQL** | Análisis SQL avanzado (window functions, CTEs) |
| **Matplotlib / Seaborn** | Visualizaciones |

---

## Estructura del repositorio

```
lending_club_sql_risk/
├── README.md                    # este archivo
├── 01_limpieza_datos.ipynb      # preparación de datos en Python
├── 02_analisis_riesgo.sql       # las 5 queries documentadas
├── data/
│   └── README.md                # cómo obtener el dataset
└── img/
    ├── 01_pareto_grade.png
    ├── 02_cohortes_anual.png
    └── 03_tail_risk.png
```

---

## Preparación de datos

El dataset crudo (2.26M filas) se redujo a **1,230,327 préstamos terminados** mediante:

- **Selección de 15 columnas** relevantes para riesgo crediticio.
- **Tratamiento de nulos con criterio de dominio:** por ejemplo, los nulos en `delinq_2yrs` (morosidades históricas) se rellenaron con `0` tras descubrir que correspondían sistemáticamente a préstamos bajo una política de crédito antigua, no a datos faltantes aleatorios.
- **Corrección de tipos:** `term` y `emp_length` (texto → entero), `issue_d` (texto → fecha).
- **Construcción de la variable objetivo `default`:** binaria (1 = *Charged Off*, 0 = *Fully Paid*), excluyendo los préstamos en curso (*Current*) porque no tienen desenlace conocido y contaminarían el análisis.
- **Tratamiento de outliers** distinguiendo errores de dato (DTI negativo o > 100, ingresos absurdos) de outliers legítimos (ingresos altos pero plausibles).

---

## Análisis y hallazgos

### 1. Concentración de riesgo por grade

El sistema de calificación (`grade`, de A a G) de LendingClub **predice efectivamente la mora**: la tasa de default crece de forma monótona de **5.8% (A) a 49.4% (G)**. El modelo de scoring discrimina riesgo correctamente.

### 2. Concentración de la mora (Pareto)

![Pareto de concentración de mora por grade](img/01_pareto_grade.png)

**Hallazgo clave — la paradoja del riesgo individual vs. agregado:** el grade G es el más peligroso *por préstamo* (49.4%), pero aporta solo el **1.8%** de la mora total por su bajo volumen. En cambio, **tres grades (C, D, B) concentran el 73.8% de toda la mora**, porque tienen volúmenes enormes.

**Insight de negocio:** el monitoreo de riesgo debe priorizar **volumen × tasa**, no solo la tasa. Vigilar los grades C/D/B cubre 3 de cada 4 préstamos morosos.

### 3. Evolución temporal por cohorte anual

![Evolución de la tasa de mora por cohorte anual](img/02_cohortes_anual.png)

La calidad de la cartera **se deterioró a medida que crecía el volumen**. Tras estabilizarse post-crisis (2010–2013), la mora se quiebra al alza en **2014** y alcanza su pico en **2016 (23.7%)**. El patrón sugiere un relajamiento de los criterios de crédito durante la fase de crecimiento acelerado.

> **Nota metodológica:** la aparente "mejora" de 2018 es un **artefacto de cohorte incompleta** — los préstamos a 60 meses emitidos ese año aún no terminaban al momento de capturar los datos, por lo que su tasa de default está artificialmente baja. El gráfico marca este punto explícitamente como dato no confiable.

### 4. Variación año a año (delta)

Aplicando `LAG()` sobre la tasa anual, los deltas localizan con precisión el **punto de quiebre en 2014 (+2.9 pp)** y el deterioro máximo en **2016 (+3.8 pp)**. La caída de -8.2 pp en 2018 es tan abrupta que confirma cuantitativamente el sesgo de cohorte incompleta.

### 5. Tail Risk — combinaciones Grade × Purpose

![Heatmap de tail risk](img/03_tail_risk.png)

Al cruzar `grade` con `purpose` (propósito del préstamo), el **`grade` domina sobre el `purpose`**: los grades F y G son riesgosos con casi cualquier propósito. La combinación más letal es **G + debt_consolidation (50.6%)**.

**Insight de negocio:** los bolsones de riesgo extremo *con volumen significativo* son **F + debt_consolidation** (19,391 préstamos, 46.9%) y **E + debt_consolidation** (56,340 préstamos, 39.4%) — candidatos a encarecimiento o veto. El propósito `debt_consolidation` recurre tanto en las tasas más altas como en los mayores volúmenes.

---

## Técnicas SQL aplicadas

- **Window functions:** `SUM() OVER ()` para Pareto (porcentaje del total y acumulado), `LAG()` para variación año a año.
- **CTEs** (`WITH`): para análisis de agregados sobre agregados (cohortes con delta).
- **Agregación condicional:** `AVG(default_flag)` como tasa de mora, `SUM(default_flag)` como conteo absoluto.
- **Filtrado de grupos:** `HAVING COUNT(*) >= 500` para excluir combinaciones con masa estadística insuficiente.

---

## Próximos pasos

- **Modelo predictivo de default:** con el dataset ya limpio y la variable objetivo construida, el siguiente paso natural es entrenar un modelo de clasificación (regresión logística como baseline, luego árboles/XGBoost) para predecir la probabilidad de mora a nivel de préstamo individual.
- **Análisis de severidad de pérdida:** incorporar el monto recuperado para estimar no solo *si* un préstamo cae en mora, sino *cuánto* se pierde (Loss Given Default).
- **Segmentación de prestatarios:** clustering por perfil de riesgo para informar políticas de pricing diferenciado.
- **Dashboard interactivo:** llevar estos hallazgos a Power BI para monitoreo continuo del riesgo de cartera.

---

## Cómo reproducir

1. Descargar el dataset de LendingClub (ver `data/README.md`).
2. Ejecutar `01_limpieza_datos.ipynb` para generar el CSV limpio.
3. Crear la tabla en PostgreSQL y cargar el CSV.
4. Ejecutar las queries de `02_analisis_riesgo.sql`.

---

*Proyecto de portafolio orientado al análisis de riesgo crediticio en fintech de lending P2P.*
