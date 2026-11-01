-- SQL+தமிழ் Stage 2 Slice 16: finite target-year traversal.
-- தமிழ்: குறிக்கப்பட்ட நாளுக்கான ஆண்டை எல்லைக்குள் கண்டறி.
-- Supports exact integer days within 60000 days of calculation; outside
-- this domain the explicitly unsupported result is SQL NULL.
-- No reference/test-schema dependencies, cache, dynamic SQL, or state.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.find_target_year(
  p_calculation_day numeric,
  p_target_day numeric
) RETURNS pastafari_sql_tamil.year_rec
LANGUAGE SQL STABLE STRICT AS $sql$
WITH RECURSIVE accepted AS MATERIALIZED (
  SELECT least(
    256::numeric,
    ceil(abs(p_target_day - p_calculation_day) / 252::numeric) + 1
  )::integer AS step_budget
  WHERE p_calculation_day = trunc(p_calculation_day)
    AND p_target_day = trunc(p_target_day)
    AND abs(p_target_day - p_calculation_day) <= 60000
),
seed AS MATERIALIZED (
  SELECT 0 AS step_count, a.step_budget,
         pastafari_sql_tamil.year5000(p_calculation_day) AS yr
  FROM accepted AS a
),
walk(step_count,step_budget,yr) AS (
  SELECT step_count,step_budget,yr
  FROM seed WHERE yr IS NOT NULL
  UNION ALL
  SELECT w.step_count + 1,w.step_budget,
    CASE WHEN p_target_day > (w.yr).close_gate_day
      THEN pastafari_sql_tamil.next_year(p_calculation_day,w.yr)
      ELSE pastafari_sql_tamil.previous_year(p_calculation_day,w.yr)
    END
  FROM walk AS w
  WHERE w.step_count < w.step_budget
    AND w.yr IS NOT NULL
    AND NOT (
      (w.yr).open_gate_day < p_target_day
      AND p_target_day <= (w.yr).close_gate_day
    )
)
SELECT yr
FROM walk
WHERE yr IS NOT NULL
  AND (yr).open_gate_day < p_target_day
  AND p_target_day <= (yr).close_gate_day
ORDER BY step_count
LIMIT 1
$sql$;
