-- SQL+தமிழ் Stage 2 Slice22: exact, stateless month weaving.
-- The mathematical factorization is documented in SLICE_22_MONTH_WEAVING_FEASIBILITY_20261105.md.
-- No reference-schema call, recursive SQL function calls, or persistent/temporary tables.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.month_weaving_ranked(
    p_lengths integer[],
    p_stream pastafari_sql_tamil.answer_stream,
    p_rank_override numeric DEFAULT NULL
) RETURNS integer[] LANGUAGE plpgsql IMMUTABLE AS $fn$
DECLARE
    k integer;
    d integer;
    a integer;
    h integer;
    tmax integer := 0;
    previous_row numeric[];
    new_row numeric[];
    all_rows numeric[];
    row_sizes integer[] := ARRAY[1];
    row_offsets integer[] := ARRAY[]::integer[];
    current_row numeric[];
    next_row numeric[];
    offset_value integer := 1;
    root_count numeric;
    wanted numeric;
    remaining integer[];
    opened integer := 0;
    closed integer := 0;
    tail integer := 0;
    active_factor numeric := 1;
    prefix_sums integer[];
    suffix_num numeric[];
    suffix_den numeric[];
    cumulative integer;
    j integer;
    z integer;
    numerator numeric;
    denominator numeric;
    candidate_factor numeric;
    block_size numeric;
    binomial numeric;
    chosen boolean;
    word integer[] := ARRAY[]::integer[];
BEGIN
    IF p_lengths IS NULL OR array_ndims(p_lengths) IS DISTINCT FROM 1 THEN
        RETURN NULL;
    END IF;
    k := coalesce(array_length(p_lengths,1),0);
    IF k=0 OR array_lower(p_lengths,1) <> 1 OR
       EXISTS (SELECT 1 FROM unnest(p_lengths) AS l(v) WHERE v IS NULL OR v<2) THEN
        RETURN NULL;
    END IF;
    SELECT sum(v)::integer INTO d FROM unnest(p_lengths) AS u(v);
    IF d IS NULL OR d<1 THEN RETURN NULL; END IF;
    remaining := p_lengths;

    -- F_k(T)=1; F_(a-1)(T)=SUM_(x=0)^T F_a(x+h-1) C(x+h-2,h-2).
    -- Store each complete row by prepending it once to a flattened vector.
    -- Array appends are per ROW (k times), never per DP cell.
    FOR j IN 1..k LOOP
        tmax := tmax + remaining[j]-1;
        row_sizes := array_append(row_sizes,tmax+1);
    END LOOP;
    previous_row := array_fill(1::numeric,ARRAY[tmax+1]);
    all_rows := previous_row;
    FOR a IN REVERSE k..1 LOOP
        h := remaining[a];
        tmax := tmax-h+1;
        WITH RECURSIVE prefix(t,choose_factor,partial_sum) AS (
            SELECT 0,1::numeric,previous_row[h]
            UNION ALL
            SELECT t+1,
                   div(choose_factor*(t+h-1),t+1),
                   partial_sum + previous_row[t+h+1] *
                     div(choose_factor*(t+h-1),t+1)
            FROM prefix
            WHERE t<tmax
        )
        SELECT array_agg(partial_sum ORDER BY t) INTO new_row FROM prefix;
        IF coalesce(array_length(new_row,1),0) <> tmax+1 THEN
            RETURN NULL;
        END IF;
        all_rows := new_row || all_rows;
        previous_row := new_row;
    END LOOP;
    root_count := previous_row[1];
    IF root_count IS NULL OR root_count<1 THEN RETURN NULL; END IF;

    IF p_rank_override IS NULL THEN
        IF p_stream IS NULL THEN RETURN NULL; END IF;
        wanted := pastafari_sql_tamil.choose_rank(p_stream,root_count);
    ELSE
        wanted := p_rank_override;
    END IF;
    IF wanted IS NULL OR wanted <> trunc(wanted) OR
       wanted<1 OR wanted>root_count THEN
        RETURN NULL;
    END IF;

    -- F_a occupies [row_offsets[a+1], row_offsets[a+1]+row_sizes[a+1]-1].
    FOR a IN 0..k LOOP
        row_offsets := array_append(row_offsets,offset_value);
        offset_value := offset_value+row_sizes[a+1];
    END LOOP;
    IF cardinality(all_rows) <> offset_value-1 THEN RETURN NULL; END IF;
    current_row := all_rows[row_offsets[1]:row_offsets[1]+row_sizes[1]-1];
    next_row := all_rows[row_offsets[2]:row_offsets[2]+row_sizes[2]-1];

    FOR a IN 1..d LOOP
        -- Active symbols are exactly closed+1 ... opened.  S_j is
        -- their inclusive prefix sum; candidate suffix ratios use the
        -- product of S_(i-1)/(S_i-1) for i>j.
        prefix_sums := array_fill(0,ARRAY[k]);
        suffix_num := array_fill(1::numeric,ARRAY[k]);
        suffix_den := array_fill(1::numeric,ARRAY[k]);
        cumulative := 0;
        FOR j IN closed+1..opened LOOP
            cumulative := cumulative+remaining[j];
            prefix_sums[j] := cumulative;
        END LOOP;
        IF cumulative <> tail THEN RETURN NULL; END IF;
        FOR j IN REVERSE opened..closed+2 LOOP
            suffix_num[j-1] := suffix_num[j]*prefix_sums[j-1];
            suffix_den[j-1] := suffix_den[j]*(prefix_sums[j]-1);
        END LOOP;

        chosen := false;
        FOR j IN closed+1..opened LOOP
            -- Only the earliest active symbol may be closed next.
            IF remaining[j]=1 AND j>closed+1 THEN CONTINUE; END IF;
            IF j=closed+1 THEN
                numerator := active_factor*suffix_num[j];
                denominator := suffix_den[j];
            ELSE
                numerator := active_factor*(remaining[j]-1)*suffix_num[j];
                denominator := (prefix_sums[j]-1)*suffix_den[j];
            END IF;
            IF denominator<=0 OR mod(numerator,denominator)<>0 THEN
                RETURN NULL;
            END IF;
            candidate_factor := div(numerator,denominator);
            block_size := candidate_factor*current_row[tail];
            IF block_size<=0 THEN CONTINUE; END IF;
            IF wanted>block_size THEN
                wanted := wanted-block_size;
            ELSE
                active_factor := candidate_factor;
                IF remaining[j]=1 THEN closed := closed+1; END IF;
                remaining[j] := remaining[j]-1;
                tail := tail-1;
                word := array_append(word,j);
                chosen := true;
                EXIT;
            END IF;
        END LOOP;

        IF NOT chosen AND opened<k THEN
            -- The sole admissible new symbol is opened+1. Its first
            -- occurrence leaves h-1 indistinguishable active tokens.
            h := remaining[opened+1];
            binomial := 1;
            FOR z IN 1..h-2 LOOP
                numerator := binomial*(tail+z);
                IF mod(numerator,z)<>0 THEN RETURN NULL; END IF;
                binomial := div(numerator,z);
            END LOOP;
            candidate_factor := active_factor*binomial;
            block_size := candidate_factor*next_row[tail+h];
            IF block_size IS NOT NULL AND block_size>0 AND wanted<=block_size THEN
                opened := opened+1;
                active_factor := candidate_factor;
                tail := tail+h-1;
                remaining[opened] := h-1;
                word := array_append(word,opened);
                current_row := next_row;
                IF opened<k THEN
                    next_row := all_rows[
                        row_offsets[opened+2]:
                        row_offsets[opened+2]+row_sizes[opened+2]-1
                    ];
                END IF;
                chosen := true;
            END IF;
        END IF;
        IF NOT chosen THEN RETURN NULL; END IF;
    END LOOP;
    IF opened<>k OR closed<>k OR tail<>0 OR wanted<>1 OR
       cardinality(word)<>d THEN
        RETURN NULL;
    END IF;
    RETURN word;
END;
$fn$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.choose_month_weaving(
    p_sauce pastafari_sql_tamil.sauce_result,
    p_lengths integer[]
) RETURNS integer[] LANGUAGE plpgsql IMMUTABLE STRICT AS $fn$
DECLARE
    stream pastafari_sql_tamil.answer_stream;
BEGIN
    stream := pastafari_sql_tamil.ask_bowl(p_sauce,4,32);
    IF stream IS NULL THEN RETURN NULL; END IF;
    RETURN pastafari_sql_tamil.month_weaving_ranked(p_lengths,stream,NULL);
END;
$fn$;
