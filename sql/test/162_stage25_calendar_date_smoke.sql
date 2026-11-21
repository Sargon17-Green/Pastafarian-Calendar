\set ON_ERROR_STOP on
SET statement_timeout = '12min';
-- Native smoke only. This is NOT full Slice25 acceptance.
-- Case anchor_first from immutable, independent preflight JSONL (29 cases).
DO $slice25_smoke$
DECLARE
    v pastafari_sql_tamil.calendar_result_text;
    v_null pastafari_sql_tamil.calendar_result_text;
    v_started timestamptz;
    v_ms numeric;
BEGIN
    v_started := clock_timestamp();
    v := pastafari_sql_tamil.calendar_date(-15055671::numeric,-15057702::numeric);
    v_ms := round(extract(epoch FROM clock_timestamp()-v_started)*1000::numeric,3);
    RAISE NOTICE 'SLICE25_SMOKE_ELAPSED_MS=%',v_ms;
    IF v IS NULL THEN RAISE EXCEPTION 'calendar_date returned NULL for anchor_first'; END IF;
    IF (v).year_number IS DISTINCT FROM 5000::numeric THEN
        RAISE EXCEPTION 'year_number expected 5000 got %',(v).year_number;
    END IF;
    RAISE NOTICE 'SLICE25_SMOKE_FIELD_PASS=year_number';
    IF (v).cutlet_name IS DISTINCT FROM 'அக்காத்'::text THEN
        RAISE EXCEPTION 'cutlet_name mismatch: %',(v).cutlet_name;
    END IF;
    RAISE NOTICE 'SLICE25_SMOKE_FIELD_PASS=cutlet_name';
    IF (v).day_in_cutlet IS DISTINCT FROM 1::numeric THEN
        RAISE EXCEPTION 'day_in_cutlet expected 1 got %',(v).day_in_cutlet;
    END IF;
    RAISE NOTICE 'SLICE25_SMOKE_FIELD_PASS=day_in_cutlet';
    IF (v).month_name IS DISTINCT FROM 'ஒட்டகம்'::text THEN
        RAISE EXCEPTION 'month_name mismatch: %',(v).month_name;
    END IF;
    RAISE NOTICE 'SLICE25_SMOKE_FIELD_PASS=month_name';
    IF (v).day_in_month IS DISTINCT FROM 1::numeric THEN
        RAISE EXCEPTION 'day_in_month expected 1 got %',(v).day_in_month;
    END IF;
    RAISE NOTICE 'SLICE25_SMOKE_FIELD_PASS=day_in_month';

    v_null := pastafari_sql_tamil.calendar_date(NULL::numeric,-15057702::numeric);
    IF v_null IS DISTINCT FROM NULL::pastafari_sql_tamil.calendar_result_text THEN
        RAISE EXCEPTION 'STRICT calculation NULL failed';
    END IF;
    RAISE NOTICE 'SLICE25_SMOKE_INVALID_PASS=null_calculation_day';
    v_null := pastafari_sql_tamil.calendar_date(-15055671::numeric,NULL::numeric);
    IF v_null IS DISTINCT FROM NULL::pastafari_sql_tamil.calendar_result_text THEN
        RAISE EXCEPTION 'STRICT target NULL failed';
    END IF;
    RAISE NOTICE 'SLICE25_SMOKE_INVALID_PASS=null_target_day';
    v_null := pastafari_sql_tamil.calendar_date(-15055671.5::numeric,-15057702::numeric);
    IF v_null IS DISTINCT FROM NULL::pastafari_sql_tamil.calendar_result_text THEN
        RAISE EXCEPTION 'fractional calculation input accepted';
    END IF;
    RAISE NOTICE 'SLICE25_SMOKE_INVALID_PASS=fractional_calculation_day';
    v_null := pastafari_sql_tamil.calendar_date(-15055671::numeric,-15057702.5::numeric);
    IF v_null IS DISTINCT FROM NULL::pastafari_sql_tamil.calendar_result_text THEN
        RAISE EXCEPTION 'fractional target input accepted';
    END IF;
    RAISE NOTICE 'SLICE25_SMOKE_INVALID_PASS=fractional_target_day';
    v_null := pastafari_sql_tamil.calendar_date(-15055671::numeric,-15055671::numeric+60001);
    IF v_null IS DISTINCT FROM NULL::pastafari_sql_tamil.calendar_result_text THEN
        RAISE EXCEPTION 'over-domain target accepted';
    END IF;
    RAISE NOTICE 'SLICE25_SMOKE_INVALID_PASS=over_domain';
    RAISE NOTICE 'SLICE25_SMOKE_GREEN=1';
END;
$slice25_smoke$;
