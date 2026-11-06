-- SQL+தமிழ் Stage 2 Slice23: select distinct month-name indices.
-- Exact numeric unranking; no reference schema, floating point or persistent state.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.month_names_ranked(
    p_k integer,
    p_stream pastafari_sql_tamil.answer_stream,
    p_rank_override numeric DEFAULT NULL
) RETURNS integer[] LANGUAGE plpgsql IMMUTABLE AS $fn$
DECLARE
    space_count numeric := 1;
    suffix_count numeric;
    wanted numeric;
    unused integer[] := ARRAY(SELECT generate_series(1,47));
    picked integer[] := ARRAY[]::integer[];
    choice_index integer;
    selected integer;
    pos integer;
    j integer;
BEGIN
    IF p_k IS NULL OR p_k < 1 OR p_k > 47 THEN RETURN NULL; END IF;
    -- Initial number of ordered distinct k-tuples: 47*46*...*(48-k).
    FOR j IN 0..p_k-1 LOOP
        space_count := space_count * (47-j);
    END LOOP;

    IF p_rank_override IS NOT NULL THEN
        wanted := p_rank_override;
    ELSE
        IF p_stream IS NULL THEN RETURN NULL; END IF;
        wanted := pastafari_sql_tamil.choose_rank(p_stream, space_count);
    END IF;
    IF wanted IS NULL OR wanted <> trunc(wanted) OR
       wanted < 1 OR wanted > space_count THEN RETURN NULL; END IF;

    FOR pos IN 1..p_k LOOP
        -- The remaining lexicographic rank space is partitioned evenly
        -- among each unused first index. Since space_count is exact,
        -- suffix_count = P(n-1, remaining_slots-1) is integral.
        IF cardinality(unused) < 1 OR
           mod(space_count, cardinality(unused)) <> 0 THEN RETURN NULL; END IF;
        suffix_count := div(space_count, cardinality(unused));
        IF suffix_count < 1 THEN RETURN NULL; END IF;
        choice_index := div(wanted-1, suffix_count)::integer + 1;
        IF choice_index < 1 OR choice_index > cardinality(unused) THEN
            RETURN NULL;
        END IF;
        selected := unused[choice_index];
        picked := array_append(picked, selected);
        unused := array_remove(unused, selected);
        wanted := mod(wanted-1, suffix_count)+1;
        space_count := suffix_count;
    END LOOP;
    IF wanted <> 1 OR space_count <> 1 OR
       cardinality(picked) <> p_k THEN RETURN NULL; END IF;
    RETURN picked;
END;
$fn$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.choose_month_names(
    p_sauce pastafari_sql_tamil.sauce_result,
    p_k integer
) RETURNS integer[] LANGUAGE plpgsql IMMUTABLE STRICT AS $fn$
DECLARE
    stream pastafari_sql_tamil.answer_stream;
BEGIN
    IF p_k < 1 OR p_k > 47 THEN RETURN NULL; END IF;
    stream := pastafari_sql_tamil.ask_bowl(p_sauce,5,33);
    IF stream IS NULL THEN RETURN NULL; END IF;
    RETURN pastafari_sql_tamil.month_names_ranked(p_k, stream, NULL::numeric);
END;
$fn$;
