-- Stage 2 Slice 15 Native: exact adjacent-year records, rank boundaries,
-- input validation, bounded duration constraints, and unchanged result shape.
BEGIN;
CREATE TEMP TABLE stage02_year_navigation_native (
  test_name text PRIMARY KEY,
  ok boolean NOT NULL,
  detail text NOT NULL
);

WITH foundation AS MATERIALIZED (
  SELECT f, pastafari_sql_tamil.year5000(f) AS known_year
  FROM (SELECT pastafari_sql_tamil.foundation_day() AS f) AS b
),
forward_limit AS MATERIALIZED (
  SELECT
    f,known_year,
    pastafari_sql_tamil.gate_index_at_or_before(
      (known_year).close_gate_day + 5778
    ) AS last_candidate_index
  FROM foundation
),
forward_count AS MATERIALIZED (
  SELECT *,
    last_candidate_index - (known_year).close_gate_index - 5
      AS candidate_count
  FROM forward_limit
),
forward_rank AS MATERIALIZED (
  SELECT *,
    pastafari_sql_tamil.choose_rank(
      pastafari_sql_tamil.ask_bowl(
        pastafari_sql_tamil.sauce(f,(known_year).close_gate_day),1,11
      ),
      candidate_count
    ) AS selected_rank
  FROM forward_count
),
forward_expected AS MATERIALIZED (
  SELECT *,
    (known_year).close_gate_index + 5 + selected_rank AS selected_index,
    ROW(
      (known_year).year_number + 1,
      (known_year).close_gate_index,
      (known_year).close_gate_index + 5 + selected_rank,
      (known_year).close_gate_day,
      pastafari_sql_tamil.gate_day(
        (known_year).close_gate_index + 5 + selected_rank
      )
    )::pastafari_sql_tamil.year_rec AS expected
  FROM forward_rank
),
forward_actual AS MATERIALIZED (
  SELECT *,pastafari_sql_tamil.next_year(f,known_year) AS actual
  FROM forward_expected
),
backward_limit AS MATERIALIZED (
  SELECT
    f,known_year,
    pastafari_sql_tamil.gate_index_at_or_after(
      (known_year).open_gate_day - 5778
    ) AS first_candidate_index
  FROM foundation
),
backward_count AS MATERIALIZED (
  SELECT *,
    (known_year).open_gate_index - first_candidate_index - 5
      AS candidate_count
  FROM backward_limit
),
backward_rank AS MATERIALIZED (
  SELECT *,
    pastafari_sql_tamil.choose_rank(
      pastafari_sql_tamil.ask_bowl(
        pastafari_sql_tamil.sauce(f,(known_year).open_gate_day),1,12
      ),
      candidate_count
    ) AS selected_rank
  FROM backward_count
),
backward_expected AS MATERIALIZED (
  SELECT *,
    (known_year).open_gate_index - 5 - selected_rank AS selected_index,
    ROW(
      (known_year).year_number - 1,
      (known_year).open_gate_index - 5 - selected_rank,
      (known_year).open_gate_index,
      pastafari_sql_tamil.gate_day(
        (known_year).open_gate_index - 5 - selected_rank
      ),
      (known_year).open_gate_day
    )::pastafari_sql_tamil.year_rec AS expected
  FROM backward_rank
),
backward_actual AS MATERIALIZED (
  SELECT *,pastafari_sql_tamil.previous_year(f,known_year) AS actual
  FROM backward_expected
),
invalid_cases AS MATERIALIZED (
  SELECT * FROM (VALUES
    ('fractional-year',ROW(5000.5,-4,4,-15057703,-15053459)::pastafari_sql_tamil.year_rec),
    ('fractional-open-index',ROW(5000,-4.5,4,-15057703,-15053459)::pastafari_sql_tamil.year_rec),
    ('fractional-close-index',ROW(5000,-4,4.5,-15057703,-15053459)::pastafari_sql_tamil.year_rec),
    ('fractional-open-day',ROW(5000,-4,4,-15057703.5,-15053459)::pastafari_sql_tamil.year_rec),
    ('fractional-close-day',ROW(5000,-4,4,-15057703,-15053459.5)::pastafari_sql_tamil.year_rec),
    ('non-increasing-days',ROW(5000,-4,4,-15053459,-15057703)::pastafari_sql_tamil.year_rec),
    ('index-distance-below-6',ROW(5000,-2,3,-15057703,-15053459)::pastafari_sql_tamil.year_rec),
    ('duration-251',ROW(5000,-4,4,-15057703,-15057452)::pastafari_sql_tamil.year_rec),
    ('duration-5779',ROW(5000,-4,4,-15057703,-15051924)::pastafari_sql_tamil.year_rec),
    ('all-null-fields',ROW(NULL::numeric,NULL::numeric,NULL::numeric,NULL::numeric,NULL::numeric)::pastafari_sql_tamil.year_rec)
  ) AS v(label,bad)
),
tests AS (
  SELECT
    'foundation:fixed-record'::text AS test_name,
    known_year = ROW(
      5000::numeric,-4::numeric,4::numeric,
      -15057703::numeric,-15053459::numeric
    )::pastafari_sql_tamil.year_rec AS ok,
    'known=' || known_year::text AS detail
  FROM foundation
  UNION ALL
  SELECT
    'foundation:crosses-index-zero',
    (known_year).open_gate_index < 0
      AND (known_year).close_gate_index > 0,
    'known=' || known_year::text
  FROM foundation
  UNION ALL
  SELECT
    'forward:exact-five-field-record',
    actual IS NOT DISTINCT FROM expected,
    format('N=%s;rank=%s;expected=%s;actual=%s',
      candidate_count,selected_rank,expected,actual)
  FROM forward_actual
  UNION ALL
  SELECT
    'forward:candidate-count-1-to-139',
    candidate_count BETWEEN 1 AND 139,
    format('N=%s;last_candidate_index=%s',candidate_count,last_candidate_index)
  FROM forward_actual
  UNION ALL
  SELECT
    'forward:rank-in-range',
    selected_rank BETWEEN 1 AND candidate_count,
    format('N=%s;rank=%s',candidate_count,selected_rank)
  FROM forward_actual
  UNION ALL
  SELECT
    'forward:selected-index-in-candidate-range',
    selected_index >= (known_year).close_gate_index + 6
      AND selected_index <= last_candidate_index,
    format('index=%s;range=[%s,%s]',selected_index,
      (known_year).close_gate_index+6,last_candidate_index)
  FROM forward_actual
  UNION ALL
  SELECT
    'forward:duration-252-to-5778',
    (expected).close_gate_day - (known_year).close_gate_day
      BETWEEN 252 AND 5778,
    format('duration=%s',(expected).close_gate_day-(known_year).close_gate_day)
  FROM forward_actual
  UNION ALL
  SELECT
    'forward:year-number-increments',
    (actual).year_number = (known_year).year_number + 1,
    format('known=%s;actual=%s',(known_year).year_number,(actual).year_number)
  FROM forward_actual
  UNION ALL
  SELECT
    'backward:exact-five-field-record',
    actual IS NOT DISTINCT FROM expected,
    format('N=%s;rank=%s;expected=%s;actual=%s',
      candidate_count,selected_rank,expected,actual)
  FROM backward_actual
  UNION ALL
  SELECT
    'backward:candidate-count-1-to-139',
    candidate_count BETWEEN 1 AND 139,
    format('N=%s;first_candidate_index=%s',candidate_count,first_candidate_index)
  FROM backward_actual
  UNION ALL
  SELECT
    'backward:rank-in-range',
    selected_rank BETWEEN 1 AND candidate_count,
    format('N=%s;rank=%s',candidate_count,selected_rank)
  FROM backward_actual
  UNION ALL
  SELECT
    'backward:selected-index-in-candidate-range',
    selected_index >= first_candidate_index
      AND selected_index <= (known_year).open_gate_index - 6,
    format('index=%s;range=[%s,%s]',selected_index,
      first_candidate_index,(known_year).open_gate_index-6)
  FROM backward_actual
  UNION ALL
  SELECT
    'backward:duration-252-to-5778',
    (known_year).open_gate_day - (expected).open_gate_day
      BETWEEN 252 AND 5778,
    format('duration=%s',(known_year).open_gate_day-(expected).open_gate_day)
  FROM backward_actual
  UNION ALL
  SELECT
    'backward:year-number-decrements',
    (actual).year_number = (known_year).year_number - 1,
    format('known=%s;actual=%s',(known_year).year_number,(actual).year_number)
  FROM backward_actual
  UNION ALL
  SELECT
    'invalid:' || label,
    pastafari_sql_tamil.next_year(f,bad) IS NULL
      AND pastafari_sql_tamil.previous_year(f,bad) IS NULL,
    label
  FROM invalid_cases
  CROSS JOIN foundation
  UNION ALL
  SELECT
    'invalid:null-record',
    pastafari_sql_tamil.next_year(f,NULL::pastafari_sql_tamil.year_rec) IS NULL
      AND pastafari_sql_tamil.previous_year(f,NULL::pastafari_sql_tamil.year_rec) IS NULL,
    'NULL year_rec'
  FROM foundation
  UNION ALL
  SELECT
    'invalid:fractional-calculation-day',
    pastafari_sql_tamil.next_year(f+0.5,known_year) IS NULL
      AND pastafari_sql_tamil.previous_year(f+0.5,known_year) IS NULL,
    'fractional p_calculation_day'
  FROM foundation
  UNION ALL
  SELECT
    'invalid:null-calculation-day',
    pastafari_sql_tamil.next_year(NULL::numeric,known_year) IS NULL
      AND pastafari_sql_tamil.previous_year(NULL::numeric,known_year) IS NULL,
    'NULL p_calculation_day'
  FROM foundation
  UNION ALL
  SELECT 'gap:positive-1-in-42-to-963',
    pastafari_sql_tamil.positive_gate_gap(1) BETWEEN 42 AND 963,
    'positive_gate_gap(1)=' || pastafari_sql_tamil.positive_gate_gap(1)::text
  UNION ALL
  SELECT 'gap:negative-1-in-42-to-963',
    pastafari_sql_tamil.negative_gate_gap(1) BETWEEN 42 AND 963,
    'negative_gate_gap(1)=' || pastafari_sql_tamil.negative_gate_gap(1)::text
  UNION ALL
  SELECT 'gap:positive-138-in-42-to-963',
    pastafari_sql_tamil.positive_gate_gap(138) BETWEEN 42 AND 963,
    'positive_gate_gap(138)=' || pastafari_sql_tamil.positive_gate_gap(138)::text
  UNION ALL
  SELECT 'gap:negative-138-in-42-to-963',
    pastafari_sql_tamil.negative_gate_gap(138) BETWEEN 42 AND 963,
    'negative_gate_gap(138)=' || pastafari_sql_tamil.negative_gate_gap(138)::text
  UNION ALL
  SELECT 'metadata:year-rec-five-fields',
    (SELECT count(*)=5
     FROM pg_type t
     JOIN pg_namespace n ON n.oid=t.typnamespace
     JOIN pg_class c ON c.oid=t.typrelid
     JOIN pg_attribute a ON a.attrelid=c.oid
     WHERE n.nspname='pastafari_sql_tamil'
       AND t.typname='year_rec'
       AND a.attnum>0 AND NOT a.attisdropped),
    'year_rec catalog attributes'
  UNION ALL
  SELECT 'metadata:calendar-result-five-fields',
    (SELECT count(*)=5
     FROM pg_type t
     JOIN pg_namespace n ON n.oid=t.typnamespace
     JOIN pg_class c ON c.oid=t.typrelid
     JOIN pg_attribute a ON a.attrelid=c.oid
     WHERE n.nspname='pastafari_sql_tamil'
       AND t.typname='calendar_result'
       AND a.attnum>0 AND NOT a.attisdropped),
    'calendar_result catalog attributes'
  UNION ALL
  SELECT 'metadata:two-sql-stable-functions',
    (SELECT count(*)=2
     FROM pg_proc p
     JOIN pg_namespace n ON n.oid=p.pronamespace
     JOIN pg_language l ON l.oid=p.prolang
     WHERE n.nspname='pastafari_sql_tamil'
       AND p.proname IN ('next_year','previous_year')
       AND l.lanname='sql' AND p.provolatile='s'),
    'next_year and previous_year are SQL STABLE'
  UNION ALL
  SELECT 'metadata:two-year-rec-returns',
    (SELECT count(*)=2
     FROM pg_proc p
     JOIN pg_namespace n ON n.oid=p.pronamespace
     WHERE n.nspname='pastafari_sql_tamil'
       AND p.proname IN ('next_year','previous_year')
       AND p.prorettype='pastafari_sql_tamil.year_rec'::regtype),
    'both return year_rec'
  UNION ALL
  SELECT 'output:all-ten-fields-integral',
    (actual).year_number=trunc((actual).year_number)
      AND (actual).open_gate_index=trunc((actual).open_gate_index)
      AND (actual).close_gate_index=trunc((actual).close_gate_index)
      AND (actual).open_gate_day=trunc((actual).open_gate_day)
      AND (actual).close_gate_day=trunc((actual).close_gate_day)
      AND (backward_actual.actual).year_number=trunc((backward_actual.actual).year_number)
      AND (backward_actual.actual).open_gate_index=trunc((backward_actual.actual).open_gate_index)
      AND (backward_actual.actual).close_gate_index=trunc((backward_actual.actual).close_gate_index)
      AND (backward_actual.actual).open_gate_day=trunc((backward_actual.actual).open_gate_day)
      AND (backward_actual.actual).close_gate_day=trunc((backward_actual.actual).close_gate_day),
    'forward=' || actual::text || ';backward=' || backward_actual.actual::text
  FROM forward_actual
  CROSS JOIN backward_actual
)
INSERT INTO stage02_year_navigation_native(test_name,ok,detail)
SELECT test_name,ok,detail FROM tests;

SELECT count(*) AS native_assertions FROM stage02_year_navigation_native;
SELECT 1/((count(*)=36 AND bool_and(ok))::integer)
  AS native_36_of_36
FROM stage02_year_navigation_native;
COMMIT;
