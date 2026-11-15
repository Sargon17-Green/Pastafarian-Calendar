-- SQL+தமிழ் Stage 2 Slice24: independent production year-structure composition.
-- Uses only previously accepted production constituent selectors, in dependency order.
CREATE TYPE pastafari_sql_tamil.year_structure AS (
    year_data pastafari_sql_tamil.year_rec,
    cutlet_count integer,
    cutlet_partition integer[],
    cutlet_name_indices integer[],
    month_count integer,
    month_lengths integer[],
    month_weaving integer[],
    month_name_indices integer[]
);

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.build_year_structure(
    p_calculation_day numeric,
    p_year pastafari_sql_tamil.year_rec
) RETURNS pastafari_sql_tamil.year_structure
LANGUAGE plpgsql VOLATILE STRICT AS $fn$
DECLARE
    v_sauce pastafari_sql_tamil.sauce_result;
    v_cutlet_count integer;
    v_cutlet_partition integer[];
    v_cutlet_names integer[];
    v_month_count integer;
    v_month_lengths integer[];
    v_month_weaving integer[];
    v_month_names integer[];
BEGIN
    v_sauce := pastafari_sql_tamil.sauce(
        p_calculation_day, (p_year).open_gate_day + 1
    );
    v_cutlet_count := pastafari_sql_tamil.choose_cutlet_count(v_sauce,p_year);
    v_cutlet_partition := pastafari_sql_tamil.choose_cutlet_partition(
        p_calculation_day,v_sauce,p_year,v_cutlet_count
    );
    v_cutlet_names := pastafari_sql_tamil.choose_cutlet_names(v_sauce,v_cutlet_count);
    v_month_count := pastafari_sql_tamil.choose_month_count(v_sauce,p_year);
    v_month_lengths := pastafari_sql_tamil.choose_month_lengths(
        v_sauce,p_year,v_month_count
    );
    v_month_weaving := pastafari_sql_tamil.choose_month_weaving(v_sauce,v_month_lengths);
    v_month_names := pastafari_sql_tamil.choose_month_names(v_sauce,v_month_count);
    RETURN ROW(
        p_year,v_cutlet_count,v_cutlet_partition,v_cutlet_names,
        v_month_count,v_month_lengths,v_month_weaving,v_month_names
    )::pastafari_sql_tamil.year_structure;
END;
$fn$;
