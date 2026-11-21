-- SQL+தமிழ் Stage2 Slice25: production calendar-date resolution.
-- Uses only accepted production primitives (Slices 1..24); no test-schema calls,
-- mutable caches, persistent writes, dynamic SQL, or normative function reuse.
-- The type is intentionally distinct from legacy calendar_result (numeric IDs).
CREATE TYPE pastafari_sql_tamil.calendar_result_text AS (
    year_number numeric,
    cutlet_name text,
    day_in_cutlet numeric,
    month_name text,
    day_in_month numeric
);

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.calendar_date(
    p_calculation_day numeric,
    p_target_day numeric
) RETURNS pastafari_sql_tamil.calendar_result_text
LANGUAGE plpgsql VOLATILE STRICT AS $calendar$
DECLARE
    v_year pastafari_sql_tamil.year_rec;
    v_structure pastafari_sql_tamil.year_structure;
    v_cutlet_parts integer[];
    v_cutlet_names integer[];
    v_month_lengths integer[];
    v_month_weaving integer[];
    v_month_names integer[];
    v_cutlet_count integer;
    v_month_count integer;
    v_cutlet_idx integer;
    v_month_position integer;
    v_month_id integer;
    v_cutlet_name_index integer;
    v_month_name_index integer;
    v_gate_step integer;
    v_index numeric;
    v_day numeric;
    v_start_of_cutlet numeric;
    v_gap numeric;
    v_found boolean := false;
    v_day_in_cutlet numeric;
    v_day_in_month numeric := 0;
    v_cutlet_name text;
    v_month_name text;
BEGIN
    -- Keep the accepted selector's integer and 60,000-day input domain.
    IF p_calculation_day <> trunc(p_calculation_day)
       OR p_target_day <> trunc(p_target_day)
       OR abs(p_target_day-p_calculation_day)>60000 THEN
        RETURN NULL;
    END IF;

    v_year := pastafari_sql_tamil.find_target_year(
        p_calculation_day,p_target_day
    );
    IF v_year IS NULL OR NOT (
        (v_year).open_gate_day < p_target_day
        AND p_target_day <= (v_year).close_gate_day
    ) THEN
        RETURN NULL;
    END IF;

    v_structure := pastafari_sql_tamil.build_year_structure(
        p_calculation_day,v_year
    );
    IF v_structure IS NULL OR (v_structure).year_data IS DISTINCT FROM v_year THEN
        RETURN NULL;
    END IF;

    v_cutlet_count := (v_structure).cutlet_count;
    v_month_count := (v_structure).month_count;
    v_cutlet_parts := (v_structure).cutlet_partition;
    v_cutlet_names := (v_structure).cutlet_name_indices;
    v_month_lengths := (v_structure).month_lengths;
    v_month_weaving := (v_structure).month_weaving;
    v_month_names := (v_structure).month_name_indices;

    IF v_cutlet_count IS NULL OR v_month_count IS NULL
       OR v_cutlet_count < 1 OR v_month_count < 1
       OR cardinality(v_cutlet_parts) IS DISTINCT FROM v_cutlet_count
       OR cardinality(v_cutlet_names) IS DISTINCT FROM v_cutlet_count
       OR cardinality(v_month_lengths) IS DISTINCT FROM v_month_count
       OR cardinality(v_month_names) IS DISTINCT FROM v_month_count
       OR cardinality(v_month_weaving) IS DISTINCT FROM
             (v_year).close_gate_day-(v_year).open_gate_day
       OR EXISTS (SELECT 1 FROM unnest(v_cutlet_parts) AS p(n)
                  WHERE n IS NULL OR n<=0)
       OR EXISTS (SELECT 1 FROM unnest(v_month_lengths) AS p(n)
                  WHERE n IS NULL OR n<=0)
       OR (SELECT sum(n)::numeric FROM unnest(v_cutlet_parts) AS p(n))
             IS DISTINCT FROM (v_year).close_gate_index-(v_year).open_gate_index
       OR (SELECT sum(n)::numeric FROM unnest(v_month_lengths) AS p(n))
             IS DISTINCT FROM cardinality(v_month_weaving) THEN
        RETURN NULL;
    END IF;

    -- A single forward accumulation over gate gaps, starting from the
    -- selected year's known open gate. This is not the reference SQL's
    -- repeated gate_day(prefix) evaluation at every cutlet boundary.
    v_index := (v_year).open_gate_index;
    v_day := (v_year).open_gate_day;
    FOR v_cutlet_idx IN 1..v_cutlet_count LOOP
        v_start_of_cutlet := v_day;
        FOR v_gate_step IN 1..v_cutlet_parts[v_cutlet_idx] LOOP
            v_gap := CASE WHEN v_index>=0
                THEN pastafari_sql_tamil.positive_gate_gap(v_index+1)
                ELSE pastafari_sql_tamil.negative_gate_gap(-v_index)
            END;
            IF v_gap IS NULL OR v_gap<=0 THEN RETURN NULL; END IF;
            v_day := v_day+v_gap;
            v_index := v_index+1;
        END LOOP;
        IF NOT v_found AND v_start_of_cutlet<p_target_day
           AND p_target_day<=v_day THEN
            v_found := true;
            v_day_in_cutlet := p_target_day-v_start_of_cutlet;
            v_cutlet_name_index := v_cutlet_names[v_cutlet_idx];
        END IF;
    END LOOP;
    IF NOT v_found OR v_index IS DISTINCT FROM (v_year).close_gate_index
       OR v_day IS DISTINCT FROM (v_year).close_gate_day THEN
        RETURN NULL;
    END IF;

    -- A second, independent left-to-right ordinal scan over the weaving.
    v_month_position := (p_target_day-(v_year).open_gate_day)::integer;
    IF v_month_position<1 OR v_month_position>cardinality(v_month_weaving) THEN
        RETURN NULL;
    END IF;
    v_month_id := v_month_weaving[v_month_position];
    IF v_month_id IS NULL OR v_month_id<1 OR v_month_id>v_month_count THEN
        RETURN NULL;
    END IF;
    FOR v_gate_step IN 1..v_month_position LOOP
        IF v_month_weaving[v_gate_step]=v_month_id THEN
            v_day_in_month := v_day_in_month+1;
        END IF;
    END LOOP;
    IF v_day_in_month<1 OR v_day_in_month>v_month_lengths[v_month_id] THEN
        RETURN NULL;
    END IF;

    v_month_name_index := v_month_names[v_month_id];
    v_cutlet_name := pastafari_sql_tamil.source_name('CUTLET',v_cutlet_name_index);
    v_month_name := pastafari_sql_tamil.source_name('MONTH',v_month_name_index);
    IF v_cutlet_name IS NULL OR v_month_name IS NULL THEN RETURN NULL; END IF;

    RETURN ROW((v_year).year_number,v_cutlet_name,v_day_in_cutlet,
               v_month_name,v_day_in_month
    )::pastafari_sql_tamil.calendar_result_text;
END;
$calendar$;
