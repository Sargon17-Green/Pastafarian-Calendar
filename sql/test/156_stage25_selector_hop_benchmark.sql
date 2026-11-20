\set ON_ERROR_STOP on
SET statement_timeout = '12min';

-- QA-only isolated primitive timer. One real production selector call per job.
-- Source and expected year_rec records come from accepted fixed year fixtures,
-- not from this function or normative calendar_date.
DO $slice25_hop_probe$
DECLARE
  v_id text;
  v_mode text;
  v_calc numeric;
  v_source pastafari_sql_tamil.year_rec;
  v_expected pastafari_sql_tamil.year_rec;
  v_actual pastafari_sql_tamil.year_rec;
  v_started timestamptz;
  v_ms numeric;
BEGIN
  IF (SELECT count(*) FROM slice25_hop_input) <> 1 THEN
    RAISE EXCEPTION 'diagnostic requires exactly one source-locked hop input';
  END IF;
  SELECT pair_id,mode,calculation_day INTO STRICT v_id,v_mode,v_calc
  FROM slice25_hop_input;
  SELECT (source_year).* INTO STRICT v_source FROM slice25_hop_input;
  SELECT (expected_year).* INTO STRICT v_expected FROM slice25_hop_input;

  IF v_calc IS NULL OR v_calc <> trunc(v_calc) OR
       v_mode NOT IN ('seed','next','previous') THEN
    RAISE EXCEPTION 'invalid source-locked diagnostic input %',v_id;
  END IF;
  IF v_mode = 'seed' AND (v_expected).year_number <> 5000 THEN
    RAISE EXCEPTION 'seed diagnostic must expect year 5000';
  END IF;
  IF v_mode = 'next' AND NOT (
      (v_source).year_number + 1 = (v_expected).year_number
      AND (v_source).close_gate_index = (v_expected).open_gate_index
      AND (v_source).close_gate_day = (v_expected).open_gate_day) THEN
    RAISE EXCEPTION 'next hop is not adjacent';
  END IF;
  IF v_mode = 'previous' AND NOT (
      (v_source).year_number - 1 = (v_expected).year_number
      AND (v_source).open_gate_index = (v_expected).close_gate_index
      AND (v_source).open_gate_day = (v_expected).close_gate_day) THEN
    RAISE EXCEPTION 'previous hop is not adjacent';
  END IF;

  v_started := clock_timestamp();
  IF v_mode = 'seed' THEN
    v_actual := pastafari_sql_tamil.year5000(v_calc);
  ELSIF v_mode = 'next' THEN
    v_actual := pastafari_sql_tamil.next_year(v_calc,v_source);
  ELSE
    v_actual := pastafari_sql_tamil.previous_year(v_calc,v_source);
  END IF;
  v_ms := round(extract(epoch FROM clock_timestamp()-v_started)*1000::numeric,3);
  RAISE NOTICE 'SLICE25_HOP_ELAPSED_MS pair_id=% mode=% ms=%',v_id,v_mode,v_ms;
  IF v_actual IS NULL THEN
    RAISE EXCEPTION 'source-locked hop returned NULL for %',v_id;
  END IF;
  IF (v_actual).year_number IS DISTINCT FROM (v_expected).year_number THEN
    RAISE EXCEPTION 'year_number mismatch for %',v_id;
  END IF;
  RAISE NOTICE 'SLICE25_HOP_FIELD_PASS=year_number';
  IF (v_actual).open_gate_index IS DISTINCT FROM (v_expected).open_gate_index THEN
    RAISE EXCEPTION 'open_gate_index mismatch for %',v_id;
  END IF;
  RAISE NOTICE 'SLICE25_HOP_FIELD_PASS=open_gate_index';
  IF (v_actual).close_gate_index IS DISTINCT FROM (v_expected).close_gate_index THEN
    RAISE EXCEPTION 'close_gate_index mismatch for %',v_id;
  END IF;
  RAISE NOTICE 'SLICE25_HOP_FIELD_PASS=close_gate_index';
  IF (v_actual).open_gate_day IS DISTINCT FROM (v_expected).open_gate_day THEN
    RAISE EXCEPTION 'open_gate_day mismatch for %',v_id;
  END IF;
  RAISE NOTICE 'SLICE25_HOP_FIELD_PASS=open_gate_day';
  IF (v_actual).close_gate_day IS DISTINCT FROM (v_expected).close_gate_day THEN
    RAISE EXCEPTION 'close_gate_day mismatch for %',v_id;
  END IF;
  RAISE NOTICE 'SLICE25_HOP_FIELD_PASS=close_gate_day';
  RAISE NOTICE 'SLICE25_HOP_GREEN=1 pair_id=%',v_id;
END
$slice25_hop_probe$;
