-- SQL+தமிழ் Stage 2 Slice 16: independent normative target-year oracle.
-- The CI workflow substitutes the one case-label token on each marked line.
CREATE TEMP TABLE stage02_target_year_differential (
  test_name text PRIMARY KEY,
  ok boolean NOT NULL,
  detail text NOT NULL
);
WITH base AS MATERIALIZED (
  SELECT pastafari_sql_tamil.foundation_day() AS foundation
),
cases AS MATERIALIZED (
  SELECT '__CASE_LABEL__'::text AS case_name, foundation FROM base
),
chosen AS MATERIALIZED (
  SELECT case_name,
    CASE WHEN case_name='cross-zero' THEN foundation+1 ELSE foundation END AS calculation_day
  FROM cases
),
seed AS MATERIALIZED (
  SELECT case_name,calculation_day,
    pastafari_sql_tamil.year5000(calculation_day) AS yr
  FROM chosen
),
targets AS MATERIALIZED (
  SELECT case_name,calculation_day,yr,
    CASE case_name
      WHEN 'same-year' THEN calculation_day
      WHEN 'next-year' THEN (yr).close_gate_day+1
      WHEN 'previous-year' THEN (yr).open_gate_day
      WHEN 'boundary' THEN (yr).close_gate_day
      WHEN 'cross-zero' THEN (yr).close_gate_day+1
      ELSE NULL::numeric
    END AS target_day
  FROM seed
),
compared AS MATERIALIZED (
  SELECT case_name,calculation_day,target_day,yr,
    pastafari_sql_tamil.find_target_year(calculation_day,target_day) AS actual,
    pastafari_sql_tamil_test.find_target_year(calculation_day,target_day) AS expected
  FROM targets
),
evaluated AS (
  SELECT case_name,calculation_day,target_day,actual,expected,
    (actual).year_number IS NOT DISTINCT FROM (expected).year_number
      AND (actual).open_gate_index IS NOT DISTINCT FROM (expected).open_gate_index
      AND (actual).close_gate_index IS NOT DISTINCT FROM (expected).close_gate_index
      AND (actual).open_gate_day IS NOT DISTINCT FROM (expected).open_gate_day
      AND (actual).close_gate_day IS NOT DISTINCT FROM (expected).close_gate_day
      AND (actual).year_number IS NOT NULL
      AND (case_name<>'cross-zero' OR
        ((yr).open_gate_index<0 AND (yr).close_gate_index>0)) AS ok,
    'target='||target_day||';actual='||actual::text||
      ';expected='||expected::text AS detail
  FROM compared
)
INSERT INTO stage02_target_year_differential(test_name,ok,detail)
SELECT '__CASE_LABEL__',ok,detail FROM evaluated;
SELECT test_name,ok,detail FROM stage02_target_year_differential;
SELECT 1/((count(*)=1 AND bool_and(ok))::integer) AS differential_1_of_1
FROM stage02_target_year_differential;
