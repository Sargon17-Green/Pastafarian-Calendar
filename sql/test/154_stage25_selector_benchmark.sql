\set ON_ERROR_STOP on
SET statement_timeout = '12min';

-- QA only: one source-locked REAL selector call per PostgreSQL job.
-- The expected composite is locked from the accepted Slice24 fixture or
-- an original Slice25 PG17 YEAR_JSON, never from the selector under test.
-- This file is executed after the generated single-row selector_input.sql.

DO $selector_baseline$
DECLARE
  v_id text;
  v_calc numeric;
  v_target numeric;
  v_expected pastafari_sql_tamil.year_rec;
  v_actual pastafari_sql_tamil.year_rec;
  v_invalid pastafari_sql_tamil.year_rec;
  v_started timestamptz;
  v_ms numeric;
BEGIN
  IF (SELECT count(*) FROM slice25_selector_input) <> 1 THEN
    RAISE EXCEPTION 'baseline requires exactly one input';
  END IF;
  SELECT year_id,calculation_day,target_day
    INTO STRICT v_id,v_calc,v_target
    FROM slice25_selector_input;
  SELECT (expected_year_data).*
    INTO STRICT v_expected
    FROM slice25_selector_input;
  IF v_target <> (v_expected).open_gate_day + 1
      OR v_calc <> trunc(v_calc)
      OR abs(v_target - v_calc) > 60000 THEN
    RAISE EXCEPTION 'source-locked selector case is invalid: %',v_id;
  END IF;

  v_invalid := pastafari_sql_tamil.find_target_year(NULL::numeric,v_target);
  IF v_invalid IS DISTINCT FROM NULL::pastafari_sql_tamil.year_rec THEN
    RAISE EXCEPTION 'STRICT calculation_day NULL must yield NULL';
  END IF;
  RAISE NOTICE 'SLICE25_SELECTOR_INVALID_PASS=null_calculation_day';

  v_invalid := pastafari_sql_tamil.find_target_year(v_calc,NULL::numeric);
  IF v_invalid IS DISTINCT FROM NULL::pastafari_sql_tamil.year_rec THEN
    RAISE EXCEPTION 'STRICT target_day NULL must yield NULL';
  END IF;
  RAISE NOTICE 'SLICE25_SELECTOR_INVALID_PASS=null_target_day';

  v_invalid := pastafari_sql_tamil.find_target_year(v_calc+0.5,v_target);
  IF v_invalid IS DISTINCT FROM NULL::pastafari_sql_tamil.year_rec THEN
    RAISE EXCEPTION 'fractional calculation_day must yield NULL';
  END IF;
  RAISE NOTICE 'SLICE25_SELECTOR_INVALID_PASS=fractional_calculation_day';

  v_invalid := pastafari_sql_tamil.find_target_year(v_calc,v_target+0.5);
  IF v_invalid IS DISTINCT FROM NULL::pastafari_sql_tamil.year_rec THEN
    RAISE EXCEPTION 'fractional target_day must yield NULL';
  END IF;
  RAISE NOTICE 'SLICE25_SELECTOR_INVALID_PASS=fractional_target_day';

  v_invalid := pastafari_sql_tamil.find_target_year(v_calc,v_calc+60001);
  IF v_invalid IS DISTINCT FROM NULL::pastafari_sql_tamil.year_rec THEN
    RAISE EXCEPTION 'over-domain +60001 must yield NULL';
  END IF;
  RAISE NOTICE 'SLICE25_SELECTOR_INVALID_PASS=over_domain_positive';

  v_invalid := pastafari_sql_tamil.find_target_year(v_calc,v_calc-60001);
  IF v_invalid IS DISTINCT FROM NULL::pastafari_sql_tamil.year_rec THEN
    RAISE EXCEPTION 'over-domain -60001 must yield NULL';
  END IF;
  RAISE NOTICE 'SLICE25_SELECTOR_INVALID_PASS=over_domain_negative';

  v_started := clock_timestamp();
  v_actual := pastafari_sql_tamil.find_target_year(v_calc,v_target);
  v_ms := round(extract(epoch FROM clock_timestamp()-v_started)*1000::numeric,3);
  RAISE NOTICE 'SLICE25_SELECTOR_ELAPSED_MS year_id=% ms=%',v_id,v_ms;

  IF v_actual IS NULL THEN
    RAISE EXCEPTION 'selector returned NULL for reachable input %',v_id;
  END IF;
  IF (v_actual).year_number IS DISTINCT FROM (v_expected).year_number THEN
    RAISE EXCEPTION 'year_number mismatch on %',v_id;
  END IF;
  RAISE NOTICE 'SLICE25_SELECTOR_FIELD_PASS=year_number';
  IF (v_actual).open_gate_index IS DISTINCT FROM (v_expected).open_gate_index THEN
    RAISE EXCEPTION 'open_gate_index mismatch on %',v_id;
  END IF;
  RAISE NOTICE 'SLICE25_SELECTOR_FIELD_PASS=open_gate_index';
  IF (v_actual).close_gate_index IS DISTINCT FROM (v_expected).close_gate_index THEN
    RAISE EXCEPTION 'close_gate_index mismatch on %',v_id;
  END IF;
  RAISE NOTICE 'SLICE25_SELECTOR_FIELD_PASS=close_gate_index';
  IF (v_actual).open_gate_day IS DISTINCT FROM (v_expected).open_gate_day THEN
    RAISE EXCEPTION 'open_gate_day mismatch on %',v_id;
  END IF;
  RAISE NOTICE 'SLICE25_SELECTOR_FIELD_PASS=open_gate_day';
  IF (v_actual).close_gate_day IS DISTINCT FROM (v_expected).close_gate_day THEN
    RAISE EXCEPTION 'close_gate_day mismatch on %',v_id;
  END IF;
  RAISE NOTICE 'SLICE25_SELECTOR_FIELD_PASS=close_gate_day';

  RAISE NOTICE 'SLICE25_SELECTOR_BASELINE_GREEN=1 year_id=%',v_id;
END
$selector_baseline$;
