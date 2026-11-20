\set ON_ERROR_STOP on
SET statement_timeout = '12min';

-- Slice25 QA ONLY: decompose accepted year5000 into the exact production
-- window, candidate enumeration, and sauce-ranked selection. No reference
-- schema, cache, generated oracle, or production function is modified.
DO $slice25_seed_profile$
DECLARE
  v_calc numeric;
  v_expected pastafari_sql_tamil.year_rec;
  v_first numeric;
  v_days numeric[];
  v_started timestamptz;
  v_window_ms numeric;
  v_candidates_ms numeric;
  v_choice_ms numeric;
  v_count bigint;
  v_min_count bigint;
  v_max_count bigint;
  v_rank numeric;
  v_open_index numeric;
  v_close_index numeric;
  v_open_day numeric;
  v_close_day numeric;
BEGIN
  IF (SELECT count(*) FROM slice25_hop_input) <> 1 THEN
    RAISE EXCEPTION 'seed profile requires exactly one locked record';
  END IF;
  IF (SELECT pair_id FROM slice25_hop_input) IS DISTINCT FROM 'seed'
     OR (SELECT mode FROM slice25_hop_input) IS DISTINCT FROM 'seed' THEN
    RAISE EXCEPTION 'seed profile requires the source-locked seed fixture';
  END IF;
  SELECT calculation_day INTO STRICT v_calc FROM slice25_hop_input;
  SELECT (expected_year).* INTO STRICT v_expected FROM slice25_hop_input;
  IF v_calc IS NULL OR v_calc <> trunc(v_calc)
     OR (v_expected).year_number IS DISTINCT FROM 5000::numeric THEN
    RAISE EXCEPTION 'invalid calculation day or expected year';
  END IF;

  v_started := clock_timestamp();
  SELECT first_gate_index,gate_days INTO STRICT v_first,v_days
  FROM pastafari_sql_tamil.year5000_gate_window(v_calc);
  v_window_ms := round(extract(epoch FROM clock_timestamp()-v_started)*1000::numeric,3);
  RAISE NOTICE 'SLICE25_SEED_PHASE_MS phase=window ms=%',v_window_ms;
  IF v_first IS NULL OR v_days IS NULL
     OR cardinality(v_days) NOT BETWEEN 15 AND 280 THEN
    RAISE EXCEPTION 'year5000 gate window violates accepted bounds';
  END IF;

  v_started := clock_timestamp();
  CREATE TEMP TABLE slice25_seed_profile_candidates AS
    SELECT * FROM pastafari_sql_tamil.year5000_gate_pairs(v_calc,v_first,v_days);
  v_candidates_ms := round(extract(epoch FROM clock_timestamp()-v_started)*1000::numeric,3);
  RAISE NOTICE 'SLICE25_SEED_PHASE_MS phase=candidates ms=%',v_candidates_ms;
  SELECT count(*),min(candidate_count),max(candidate_count)
    INTO v_count,v_min_count,v_max_count
    FROM slice25_seed_profile_candidates;
  IF v_count < 1 OR v_min_count <> v_count OR v_max_count <> v_count THEN
    RAISE EXCEPTION 'year5000 candidate count inconsistent';
  END IF;

  v_started := clock_timestamp();
  SELECT pastafari_sql_tamil.choose_rank(
    pastafari_sql_tamil.ask_bowl(
      pastafari_sql_tamil.sauce(v_calc,v_calc),1,10
    ), v_count::numeric
  ) INTO STRICT v_rank;
  v_choice_ms := round(extract(epoch FROM clock_timestamp()-v_started)*1000::numeric,3);
  RAISE NOTICE 'SLICE25_SEED_PHASE_MS phase=choice ms=%',v_choice_ms;
  IF v_rank IS NULL OR v_rank <> trunc(v_rank)
     OR v_rank NOT BETWEEN 1 AND v_count THEN
    RAISE EXCEPTION 'year5000 sauce rank outside candidate count';
  END IF;
  SELECT open_gate_index,close_gate_index,open_gate_day,close_gate_day
    INTO STRICT v_open_index,v_close_index,v_open_day,v_close_day
    FROM slice25_seed_profile_candidates WHERE candidate_rank = v_rank;

  IF (v_expected).year_number IS DISTINCT FROM 5000 THEN
    RAISE EXCEPTION 'year number mismatch';
  END IF;
  RAISE NOTICE 'SLICE25_SEED_FIELD_PASS=year_number';
  IF v_open_index IS DISTINCT FROM (v_expected).open_gate_index THEN
    RAISE EXCEPTION 'open index mismatch';
  END IF;
  RAISE NOTICE 'SLICE25_SEED_FIELD_PASS=open_gate_index';
  IF v_close_index IS DISTINCT FROM (v_expected).close_gate_index THEN
    RAISE EXCEPTION 'close index mismatch';
  END IF;
  RAISE NOTICE 'SLICE25_SEED_FIELD_PASS=close_gate_index';
  IF v_open_day IS DISTINCT FROM (v_expected).open_gate_day THEN
    RAISE EXCEPTION 'open day mismatch';
  END IF;
  RAISE NOTICE 'SLICE25_SEED_FIELD_PASS=open_gate_day';
  IF v_close_day IS DISTINCT FROM (v_expected).close_gate_day THEN
    RAISE EXCEPTION 'close day mismatch';
  END IF;
  RAISE NOTICE 'SLICE25_SEED_FIELD_PASS=close_gate_day';
  RAISE NOTICE 'SLICE25_SEED_PROFILE_GREEN=1 candidate_count=%',v_count;
END
$slice25_seed_profile$;
