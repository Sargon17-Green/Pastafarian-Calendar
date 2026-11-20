\set ON_ERROR_STOP on
SET statement_timeout = '12min';
-- Slice25 QA ONLY; no production function is modified.
CREATE OR REPLACE FUNCTION pg_temp.slice25_fast_gate_window(p_day numeric)
RETURNS TABLE(first_gate_index numeric, gate_days numeric[])
LANGUAGE SQL STABLE STRICT AS $fast$
WITH RECURSIVE
base AS MATERIALIZED (
  SELECT pastafari_sql_tamil.foundation_day() AS foundation,
         p_day-5778::numeric AS lower_day,
         p_day+5778::numeric AS upper_day
  WHERE p_day=trunc(p_day)
),
starts AS (
  SELECT 1::integer AS dir,0::numeric AS gate_index,
         foundation AS gate_day,upper_day AS limit_day FROM base
  UNION ALL
  SELECT -1::integer,0::numeric,foundation,lower_day FROM base
),
walk(dir,gate_index,gate_day,limit_day,sentinel_done) AS (
  SELECT dir,gate_index,gate_day,limit_day,false FROM starts
  UNION ALL
  SELECT w.dir,w.gate_index+w.dir,
         w.gate_day+CASE
           WHEN w.dir=1 THEN pastafari_sql_tamil.positive_gate_gap(w.gate_index+1)
           ELSE -pastafari_sql_tamil.negative_gate_gap(1-w.gate_index)
         END,
         w.limit_day,
         CASE WHEN w.dir=1 THEN w.gate_day>=w.limit_day
              ELSE w.gate_day<=w.limit_day END
  FROM walk w WHERE NOT w.sentinel_done
),
gates AS MATERIALIZED (
  SELECT DISTINCT ON (gate_index) gate_index,gate_day
  FROM walk ORDER BY gate_index,dir DESC
),
edges AS MATERIALIZED (
  SELECT max(g.gate_index) FILTER (WHERE g.gate_day<=b.lower_day)-1 AS lo,
         min(g.gate_index) FILTER (WHERE g.gate_day>=b.upper_day)+1 AS hi
  FROM gates g CROSS JOIN base b
)
SELECT min(g.gate_index),array_agg(g.gate_day ORDER BY g.gate_index)
FROM gates g CROSS JOIN edges e
WHERE g.gate_index BETWEEN e.lo AND e.hi
HAVING count(*) BETWEEN 15 AND 280
$fast$;
DO $verify_fast$
DECLARE
  v_day numeric; v_year numeric;
  v_expect_open_index numeric; v_expect_close_index numeric;
  v_expect_open_day numeric; v_expect_close_day numeric;
  v_first numeric; v_days numeric[];
  v_count bigint; v_min_count bigint; v_max_count bigint;
  v_rank numeric; v_open_index numeric; v_close_index numeric;
  v_open_day numeric; v_close_day numeric;
  v_started timestamptz; v_elapsed numeric;
BEGIN
  IF (SELECT count(*) FROM slice25_hop_input) <> 1 THEN
    RAISE EXCEPTION 'exactly one source-locked seed is required';
  END IF;
  SELECT calculation_day,(expected_year).year_number,
         (expected_year).open_gate_index,(expected_year).close_gate_index,
         (expected_year).open_gate_day,(expected_year).close_gate_day
    INTO STRICT v_day,v_year,v_expect_open_index,v_expect_close_index,
                v_expect_open_day,v_expect_close_day
  FROM slice25_hop_input WHERE pair_id='seed' AND mode='seed';
  IF v_day IS DISTINCT FROM pastafari_sql_tamil.foundation_day()
     OR v_year IS DISTINCT FROM 5000::numeric THEN
    RAISE EXCEPTION 'seed source lock mismatch';
  END IF;
  v_started := clock_timestamp();
  SELECT first_gate_index,gate_days INTO STRICT v_first,v_days
  FROM pg_temp.slice25_fast_gate_window(v_day);
  v_elapsed := round(extract(epoch FROM clock_timestamp()-v_started)*1000,3);
  RAISE NOTICE 'SLICE25_WINDOW_FAST_MS=%',v_elapsed;
  IF v_first IS NULL OR v_days IS NULL OR cardinality(v_days) NOT BETWEEN 15 AND 280 THEN
    RAISE EXCEPTION 'invalid fast window bounds';
  END IF;
  SELECT count(*),min(candidate_count),max(candidate_count)
    INTO v_count,v_min_count,v_max_count
  FROM pastafari_sql_tamil.year5000_gate_pairs(v_day,v_first,v_days);
  IF v_count <> 43 OR v_min_count <> v_count OR v_max_count <> v_count THEN
    RAISE EXCEPTION 'candidate-count mismatch: %',v_count;
  END IF;
  RAISE NOTICE 'SLICE25_WINDOW_FAST_CANDIDATES=%',v_count;
  SELECT pastafari_sql_tamil.choose_rank(
    pastafari_sql_tamil.ask_bowl(
      pastafari_sql_tamil.sauce(v_day,v_day),1,10
    ),v_count::numeric
  ) INTO STRICT v_rank;
  SELECT open_gate_index,close_gate_index,open_gate_day,close_gate_day
    INTO STRICT v_open_index,v_close_index,v_open_day,v_close_day
  FROM pastafari_sql_tamil.year5000_gate_pairs(v_day,v_first,v_days)
  WHERE candidate_rank=v_rank;
  IF v_open_index IS DISTINCT FROM v_expect_open_index THEN
    RAISE EXCEPTION 'fast open_gate_index mismatch';
  END IF;
  RAISE NOTICE 'SLICE25_FAST_FIELD_PASS=open_gate_index';
  IF v_close_index IS DISTINCT FROM v_expect_close_index THEN
    RAISE EXCEPTION 'fast close_gate_index mismatch';
  END IF;
  RAISE NOTICE 'SLICE25_FAST_FIELD_PASS=close_gate_index';
  IF v_open_day IS DISTINCT FROM v_expect_open_day THEN
    RAISE EXCEPTION 'fast open_gate_day mismatch';
  END IF;
  RAISE NOTICE 'SLICE25_FAST_FIELD_PASS=open_gate_day';
  IF v_close_day IS DISTINCT FROM v_expect_close_day THEN
    RAISE EXCEPTION 'fast close_gate_day mismatch';
  END IF;
  RAISE NOTICE 'SLICE25_FAST_FIELD_PASS=close_gate_day';
  IF v_year IS DISTINCT FROM 5000::numeric THEN
    RAISE EXCEPTION 'fast year_number mismatch';
  END IF;
  RAISE NOTICE 'SLICE25_FAST_FIELD_PASS=year_number';
  RAISE NOTICE 'SLICE25_WINDOW_FAST_SEED_GREEN=1';
END
$verify_fast$;
