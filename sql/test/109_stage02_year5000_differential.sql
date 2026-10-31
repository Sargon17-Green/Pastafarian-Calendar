-- Stage 2 Slice 14 differential: production bounded year5000 vs independent cached reference.
-- Five bounded input days exercise both candidate-window edges and nearby interior days.
BEGIN;
CREATE TEMP TABLE stage02_year5000_differential(
  test_name text PRIMARY KEY,
  ok boolean NOT NULL CHECK(ok)
);
WITH base AS MATERIALIZED (
  SELECT pastafari_sql_tamil.foundation_day() AS f
), cases(label,calculation_day) AS MATERIALIZED (
  SELECT 'lower-window-edge',f-5778 FROM base
  UNION ALL SELECT 'one-day-before',f-1 FROM base
  UNION ALL SELECT 'foundation',f FROM base
  UNION ALL SELECT 'one-day-after',f+1 FROM base
  UNION ALL SELECT 'upper-window-edge',f+5778 FROM base
), compared AS MATERIALIZED (
  SELECT label,
    pastafari_sql_tamil.year5000(calculation_day) AS actual,
    pastafari_sql_tamil_test.year5000(calculation_day) AS expected
  FROM cases
)
INSERT INTO stage02_year5000_differential(test_name,ok)
SELECT label||':year-number',
  (actual).year_number=5000
  AND (actual).year_number IS NOT DISTINCT FROM (expected).year_number
FROM compared
UNION ALL SELECT label||':open-index',
  (actual).open_gate_index IS NOT DISTINCT FROM (expected).open_gate_index
FROM compared
UNION ALL SELECT label||':close-index',
  (actual).close_gate_index IS NOT DISTINCT FROM (expected).close_gate_index
FROM compared
UNION ALL SELECT label||':open-day',
  (actual).open_gate_day IS NOT DISTINCT FROM (expected).open_gate_day
FROM compared
UNION ALL SELECT label||':close-day',
  (actual).close_gate_day IS NOT DISTINCT FROM (expected).close_gate_day
FROM compared;

SELECT count(*) AS differential_assertions
FROM stage02_year5000_differential;
COMMIT;
