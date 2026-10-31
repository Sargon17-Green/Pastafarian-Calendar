-- Stage 2 Slice 15 differential: production adjacent-year transitions
-- against the independent normative reference in a separate CI database.
-- The workflow substitutes exactly one CASE_LABEL and DIRECTION per job.
CREATE TEMP TABLE stage02_year_navigation_differential (
  test_name text PRIMARY KEY,
  ok boolean NOT NULL,
  detail text NOT NULL
);

WITH base AS MATERIALIZED (
  SELECT pastafari_sql_tamil.foundation_day() AS foundation
),
selected AS MATERIALIZED (
  SELECT
    p.label,
    CASE p.label
      WHEN 'foundation' THEN b.foundation
      ELSE b.foundation + 1
    END AS calculation_day,
    CASE p.label
      WHEN 'foundation' THEN pastafari_sql_tamil.year5000(b.foundation)
      ELSE pastafari_sql_tamil.year5000(b.foundation + 1)
    END AS known_year
  FROM base AS b
  CROSS JOIN (VALUES ('__CASE_LABEL__'::text)) AS p(label)
),
converted AS MATERIALIZED (
  SELECT
    label,calculation_day,known_year,
    ROW(
      (known_year).year_number,
      (known_year).open_gate_index,
      (known_year).close_gate_index,
      (known_year).open_gate_day,
      (known_year).close_gate_day
    )::pastafari_sql_tamil_test.year_rec AS reference_known
  FROM selected
),
compared AS MATERIALIZED (
  SELECT
    label,calculation_day,known_year,
    CASE '__DIRECTION__'
      WHEN 'next' THEN pastafari_sql_tamil.next_year(
        calculation_day,known_year
      )
      WHEN 'previous' THEN pastafari_sql_tamil.previous_year(
        calculation_day,known_year
      )
    END AS actual,
    CASE '__DIRECTION__'
      WHEN 'next' THEN pastafari_sql_tamil_test.next_year(
        calculation_day,reference_known
      )
      WHEN 'previous' THEN pastafari_sql_tamil_test.previous_year(
        calculation_day,reference_known
      )
    END AS expected,
    CASE WHEN label='cross-zero' THEN
      (known_year).open_gate_index < 0
      AND (known_year).close_gate_index > 0
    ELSE true END AS known_year_crosses_zero
  FROM converted
),
evaluated AS (
  SELECT
    label,calculation_day,known_year,actual,expected,
    known_year_crosses_zero
    AND (actual).year_number IS NOT DISTINCT FROM (expected).year_number
    AND (actual).open_gate_index IS NOT DISTINCT FROM (expected).open_gate_index
    AND (actual).close_gate_index IS NOT DISTINCT FROM (expected).close_gate_index
    AND (actual).open_gate_day IS NOT DISTINCT FROM (expected).open_gate_day
    AND (actual).close_gate_day IS NOT DISTINCT FROM (expected).close_gate_day
      AS ok,
    concat_ws(';',
      'known=' || coalesce((known_year).year_number::text,'NULL')
        || ',' || coalesce((known_year).open_gate_index::text,'NULL')
        || ',' || coalesce((known_year).close_gate_index::text,'NULL')
        || ',' || coalesce((known_year).open_gate_day::text,'NULL')
        || ',' || coalesce((known_year).close_gate_day::text,'NULL'),
      'actual=' || coalesce((actual).year_number::text,'NULL')
        || ',' || coalesce((actual).open_gate_index::text,'NULL')
        || ',' || coalesce((actual).close_gate_index::text,'NULL')
        || ',' || coalesce((actual).open_gate_day::text,'NULL')
        || ',' || coalesce((actual).close_gate_day::text,'NULL'),
      'expected=' || coalesce((expected).year_number::text,'NULL')
        || ',' || coalesce((expected).open_gate_index::text,'NULL')
        || ',' || coalesce((expected).close_gate_index::text,'NULL')
        || ',' || coalesce((expected).open_gate_day::text,'NULL')
        || ',' || coalesce((expected).close_gate_day::text,'NULL'),
      'cross_zero=' || known_year_crosses_zero::text
    ) AS detail
  FROM compared
)
INSERT INTO stage02_year_navigation_differential(test_name,ok,detail)
SELECT '__CASE_LABEL__-__DIRECTION__',ok,detail
FROM evaluated;

SELECT test_name,ok,detail FROM stage02_year_navigation_differential;
SELECT 1/((count(*)=1 AND bool_and(ok))::integer)
  AS differential_1_of_1
FROM stage02_year_navigation_differential;
