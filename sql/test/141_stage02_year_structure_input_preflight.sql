-- SQL+தமிழ் Slice24: bounded source-locked PostgreSQL 17 input feasibility.
-- Requires ordered production sql/00..25 only. No normative test schema.
-- Emits actual reachable year records, not independent 8-field golden results.
-- The anchor is the independently proven Slice14 foundation golden from
-- sql/test/108_stage02_year5000_native.sql; do not recompute year5000 here.
-- This avoids repeating a costly, previously accepted prerequisite in preflight.
\set ON_ERROR_STOP on
CREATE TEMP TABLE slice24_inputs (
  case_id text PRIMARY KEY,
  calculation_day numeric NOT NULL,
  year_data pastafari_sql_tamil.year_rec NOT NULL,
  origin text NOT NULL
);

DO $preflight$
DECLARE
    initial_day numeric := pastafari_sql_tamil.foundation_day();
    baseline pastafari_sql_tamil.year_rec;
    current_year pastafari_sql_tamil.year_rec;
    k integer;
    signatures text[] := ARRAY[
      'pastafari_sql_tamil.choose_cutlet_count(pastafari_sql_tamil.sauce_result,pastafari_sql_tamil.year_rec)',
      'pastafari_sql_tamil.choose_cutlet_partition(numeric,pastafari_sql_tamil.sauce_result,pastafari_sql_tamil.year_rec,integer)',
      'pastafari_sql_tamil.choose_cutlet_names(pastafari_sql_tamil.sauce_result,integer)',
      'pastafari_sql_tamil.choose_month_count(pastafari_sql_tamil.sauce_result,pastafari_sql_tamil.year_rec)',
      'pastafari_sql_tamil.choose_month_lengths(pastafari_sql_tamil.sauce_result,pastafari_sql_tamil.year_rec,integer)',
      'pastafari_sql_tamil.choose_month_weaving(pastafari_sql_tamil.sauce_result,integer[])',
      'pastafari_sql_tamil.choose_month_names(pastafari_sql_tamil.sauce_result,integer)'
    ];
    signature text;
    got_year_fields text;
    probe_started_at timestamptz := clock_timestamp();
BEGIN
    FOREACH signature IN ARRAY signatures LOOP
        IF to_regprocedure(signature) IS NULL THEN
            RAISE EXCEPTION 'missing selector signature: %', signature;
        END IF;
    END LOOP;
    SELECT string_agg(a.attname || ':' || a.atttypid::regtype::text, ',' ORDER BY a.attnum)
      INTO got_year_fields
      FROM pg_attribute AS a
     WHERE a.attrelid = 'pastafari_sql_tamil.year_rec'::regclass
       AND a.attnum > 0 AND NOT a.attisdropped;
    IF got_year_fields <> 'year_number:numeric,open_gate_index:numeric,close_gate_index:numeric,open_gate_day:numeric,close_gate_day:numeric' THEN
        RAISE EXCEPTION 'year_rec layout changed: %', got_year_fields;
    END IF;
    RAISE NOTICE 'slice24_selector_signatures=7/7; year_rec_fields=5/5';
    RAISE NOTICE 'year_structure_type_preexisting=%', to_regtype('pastafari_sql_tamil.year_structure') IS NOT NULL;
    -- Slice14 accepted golden; current production year_rec schema checked above.
    -- Verify its endpoints against the current production primitive and ensure
    -- the current foundation day is contained in this actual year.
    baseline := ROW(5000::numeric,-4::numeric,4::numeric,
                    -15057703::numeric,-15053459::numeric)::pastafari_sql_tamil.year_rec;
    IF (baseline).open_gate_day IS DISTINCT FROM pastafari_sql_tamil.gate_day(-4)
       OR (baseline).close_gate_day IS DISTINCT FROM pastafari_sql_tamil.gate_day(4)
       OR NOT ((baseline).open_gate_day < initial_day
               AND initial_day <= (baseline).close_gate_day) THEN
        RAISE EXCEPTION 'Slice14 accepted foundation anchor failed current source checks';
    END IF;
    RAISE NOTICE 'slice24_reachable_progress=foundation_anchor_verified; elapsed=%',
                 clock_timestamp()-probe_started_at;
    INSERT INTO slice24_inputs VALUES ('anchor',initial_day,baseline,'year5000');
    current_year := baseline;
    FOR k IN 1..4 LOOP
        current_year := pastafari_sql_tamil.next_year(initial_day,current_year);
        IF current_year IS NULL THEN RAISE EXCEPTION 'next_year % returned NULL',k; END IF;
        INSERT INTO slice24_inputs VALUES ('next_'||k,initial_day,current_year,'next_year');
        RAISE NOTICE 'slice24_reachable_progress=next_% ; elapsed=%',
                     k,clock_timestamp()-probe_started_at;
    END LOOP;
    current_year := baseline;
    FOR k IN 1..3 LOOP
        current_year := pastafari_sql_tamil.previous_year(initial_day,current_year);
        IF current_year IS NULL THEN RAISE EXCEPTION 'previous_year % returned NULL',k; END IF;
        INSERT INTO slice24_inputs VALUES ('prev_'||k,initial_day,current_year,'previous_year');
        RAISE NOTICE 'slice24_reachable_progress=prev_% ; elapsed=%',
                     k,clock_timestamp()-probe_started_at;
    END LOOP;
    -- Two legitimate day/year pairs exercise exact year boundary days.
    INSERT INTO slice24_inputs VALUES
      ('boundary_open',(baseline).open_gate_day,baseline,'year_open_gate'),
      ('boundary_close',(baseline).close_gate_day,baseline,'year_close_gate');
    IF (SELECT count(*) FROM slice24_inputs) <> 10 THEN
        RAISE EXCEPTION 'expected 10 feasible input rows';
    END IF;
    IF EXISTS (
       SELECT 1 FROM slice24_inputs AS i
       WHERE (i.year_data).close_gate_index-(i.year_data).open_gate_index < 6
         OR (i.year_data).close_gate_day-(i.year_data).open_gate_day NOT BETWEEN 252 AND 5778
         OR (i.year_data).open_gate_day >= (i.year_data).close_gate_day
    ) THEN RAISE EXCEPTION 'at least one input violates year span bounds'; END IF;
    RAISE NOTICE 'slice24_reachable_inputs=10/10; navigation=8/8; boundary_days=2/2';
END;
$preflight$;

-- Actual (source-locked) year/day tuples for subsequent full-record fixtures.
-- The selected maximum year span is the stress candidate for future CI;
-- no claim that it attains the global maximum D=5778 or month_count=47.
SELECT case_id, origin, calculation_day,
       (year_data).year_number AS year_number,
       (year_data).open_gate_index AS open_gate_index,
       (year_data).close_gate_index AS close_gate_index,
       (year_data).open_gate_day AS open_gate_day,
       (year_data).close_gate_day AS close_gate_day,
       (year_data).close_gate_day-(year_data).open_gate_day AS year_days,
       (year_data).close_gate_index-(year_data).open_gate_index AS gate_count,
       ceil(((year_data).close_gate_day-(year_data).open_gate_day)/123::numeric) AS month_count_lower,
       least(47::numeric,floor(((year_data).close_gate_day-(year_data).open_gate_day)/4::numeric)) AS month_count_upper
FROM slice24_inputs
ORDER BY case_id;
SELECT case_id AS slice24_largest_span_case,
       (year_data).close_gate_day-(year_data).open_gate_day AS largest_reachable_span
FROM slice24_inputs ORDER BY largest_reachable_span DESC,case_id LIMIT 1;