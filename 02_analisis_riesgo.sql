/* ════════════════════════════════════════════════════════════
   ANÁLISIS DE RIESGO DE MORA — LENDINGCLUB (P2P LENDING)
   ════════════════════════════════════════════════════════════
   Autor:    Oscar Araya Diaz
   Dataset:  LendingClub — 1,230,327 préstamos terminados
   Pregunta central: ¿qué características predicen que un
                     préstamo caiga en mora (default)?
   Tasa base de default: 19.7%
   ════════════════════════════════════════════════════════════ */

/* ============================================================
   ANÁLISIS 1: CONCENTRACIÓN DE RIESGO POR GRADE
   ------------------------------------------------------------
  	Pregunta: ¿El sistema de 'grades' de LendingClub predice efectivamente la mora?
	Hipotesis: La tasa de default debería crecer de A hacia G.
	Hallazgo: Confirmado. La proporción crece monótonamente. Pero el grado C genera más
		morosos absolutos que el grado G.
	Insight: El 'grade' es un predictor valido para predecir mora.
   ============================================================ */

SELECT
	grade,
	count(*) as cantidad,
	sum(default_flag) as morosos_absolutos,
	round(avg(default_flag) * 100, 1) as tasa_default_pct
from prestamos
group by grade
order by grade;

/* ============================================================
   ANÁLISIS 2: CONCENTRACIÓN DE LA MORA POR GRADE (PARETO)
   ------------------------------------------------------------
   Pregunta:  ¿qué 'grades' concentran el grueso de la mora total?
   Hipótesis: Los grades del medio (C, D), por volumen, debeiran acumular la mayor parte de
		los morosos. Los G se descartan por la baja cantidad de prestamos.
   Hallazgo: Los 3 mayores 'grades' acumulan el 73,8% del acumulado. En cambio, el grado
		G, que en proporción era el más peligroso, resultó ser el menor aporte de morosos.
   Insight: El monitoreo se debe basar en observar volumen*tasa y no solo tasa. Vigilar
		C/D/B, 'grades' que cubren 3 de cada 4 morosos (73,8%).
   ============================================================ */

select
	grade,
	sum(default_flag) as morosos,
	round(100.0 * sum(default_flag) / sum(sum(default_flag)) over (), 1) as pct_del_total,
-- morosos por grade / morosos totales(sum(sum())) = % total
	round(100.0 * sum(sum(default_flag)) over (order by sum(default_flag) DESC
		rows between unbounded preceding and current row)
		/ sum(sum(default_flag)) over (), 1) as pct_acumulado
from prestamos
group by grade
order by morosos DESC;

/* ============================================================
   ANÁLISIS 3: Cohortes por año de emisión.
   ------------------------------------------------------------
   Pregunta:  ¿La calidad de la cartera de LendingClub mejoró o empeoró con el 
		paso del tiempo?
   Hipótesis: Se espera encontrar una ligera tendencia en U dado que muchos prestamos
		a 60 meses (5 años) se registran como pagados o no pagados luego de 5 años del
		inicio de prestamo.
   Hallazgo: La mora baja post-crisis financiera del 2008 (EEUU). volviendo a subir de
		manera pareja junto a la cantidad de prestamos. Llega a un peak en 2016 (23,7%).
		Se presume relajo de exigencias a medida que la cantidad de prestatarios aumentaba
		en LendingClub.
		El año 2018 se considera incompleto dado que no se proporcionan datos reales
		actuales de los prestamos que fueron sacado a 60 meses. Lo que significa que aún
		no terminaban de pagarse para la fecha de captura de datos de este dataset.
   Insight: Aumentar el numero de prestamos tensiona la calidad crediticia.
   ============================================================ */

select
	extract(year from issue_d) as issue_d_anio,
	count(*) as cantidad,
	round(avg(default_flag) * 100, 1) as tasa_default_pct
from prestamos
group by extract(year from issue_d)
order by issue_d_anio;


/* ============================================================
   ANÁLISIS 4: VARIACIÓN AÑO A AÑO DE LA TASA DE MORA
   ------------------------------------------------------------
   Pregunta: ¿En qué años empeoró o mejoró la calidad crediticia (delta)?
   Hipótesis: deltas positivos en 2014-2016 (años de relajo).
   Hallazgo: Años estables; 2010 - 2013 (deltas sin mucha variación).
		Año peak de deterioro; 2016 (+3.8 puntos porcentuales).
		Ignorar 2018 con su -8.2 pp. Indican falsa mejora. Se confirma el sesgo de
		cohorte incompleta.
   Insight: Los deltas localizan el punto de quiebre (2014) y delatan datos poco
		fiables (2018).
   ============================================================ */

with tasa_anual as (
	select
		extract(year from issue_d) as issue_d_anio,
		count(*) as cantidad,
		round(avg(default_flag) * 100, 1) as tasa_default_pct
	from prestamos
	group by extract(year from issue_d)
)
select
	issue_d_anio,
	cantidad,
	tasa_default_pct,
	lag(tasa_default_pct) over (order by issue_d_anio) as tasa_anio_anterior,
	round(
		tasa_default_pct - lag(tasa_default_pct) over (order by issue_d_anio), 1
		) as variacion_pp
-- variacion por puntos porcentuales. no porcentaje.
from tasa_anual
order by issue_d_anio;


/* ============================================================
   ANÁLISIS 5: RIESGO DE COLA - GRADE X PURPOSE
   ------------------------------------------------------------
   Pregunta:  ¿Qué combinaciones de 'grade' y 'purpose' aumentan de manera más agresiva
		la mora por sobre el 19,7% base?
   Hipótesis: 'grade' bajos, como E, F y G. Y propositos riesgosos deberian llevar la
		delantera.
   Hallazgo: El 'grade' domina sobre el 'purpose'. G y F son cabecillas en casi cualquier
		'purpose'. (top: G + debt_consolidation: 50,6%).
   Insight: La combinación más dañina con volumen por sobre 500 prestamos es: F o E +
		debt_consolidation. (F: 46,9%. E: 39,4%). Estos son candidatos a veto o
		encarecimiento.
   ============================================================ */

select
	grade,
	purpose,
	count(*) as cantidad,
	round(avg(default_flag) * 100, 1) as tasa_default_pct
from prestamos
group by grade, purpose
having count(*) >= 500 --excluimos grupos con masa insuficiente.
order by tasa_defaul_pct DESC
limit 15;
