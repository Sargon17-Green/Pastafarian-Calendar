DROP SCHEMA IF EXISTS pastafari_sql_tamil_test CASCADE;
CREATE SCHEMA pastafari_sql_tamil_test;

CREATE TYPE pastafari_sql_tamil_test.work_counts AS (
    action numeric,
    target numeric,
    distance numeric,
    connection numeric,
    direction integer
);

CREATE TYPE pastafari_sql_tamil_test.stone5 AS (
    wheat numeric,
    barley numeric,
    salt numeric,
    bitter numeric,
    red numeric
);

CREATE TYPE pastafari_sql_tamil_test.sauce_result AS (
    bowls numeric[],
    order_at_drop_46 integer[]
);

CREATE TYPE pastafari_sql_tamil_test.answer_stream AS (
    first_value numeric,
    direction_step integer
);

CREATE TYPE pastafari_sql_tamil_test.year_rec AS (
    year_number numeric,
    open_gate_index numeric,
    close_gate_index numeric,
    open_gate_day numeric,
    close_gate_day numeric
);

CREATE TYPE pastafari_sql_tamil_test.year_structure AS (
    year_data pastafari_sql_tamil_test.year_rec,
    cutlet_count integer,
    cutlet_partition integer[],
    cutlet_name_indices integer[],
    month_count integer,
    month_lengths integer[],
    month_weaving integer[],
    month_name_indices integer[]
);

CREATE TYPE pastafari_sql_tamil_test.calendar_result_text AS (
    year_number numeric,
    cutlet_name text,
    day_in_cutlet numeric,
    month_name text,
    day_in_month numeric
);


CREATE TABLE pastafari_sql_tamil_test.weave_family_registry (
    family_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    original_lengths integer[] NOT NULL UNIQUE
);

CREATE TABLE pastafari_sql_tamil_test.weave_future_memo (
    family_id bigint NOT NULL REFERENCES pastafari_sql_tamil_test.weave_family_registry(family_id) ON DELETE CASCADE,
    opened_up_to integer NOT NULL,
    tail_length integer NOT NULL,
    factor numeric NOT NULL,
    PRIMARY KEY (family_id, opened_up_to, tail_length)
);
CREATE TABLE IF NOT EXISTS pastafari_sql_tamil_test.gate_cache (
    gate_index numeric PRIMARY KEY,
    gate_day numeric NOT NULL UNIQUE
);

INSERT INTO pastafari_sql_tamil_test.gate_cache(gate_index,gate_day)
VALUES (0::numeric,(-15055671)::numeric)
ON CONFLICT (gate_index) DO NOTHING;

CREATE TABLE pastafari_sql_tamil_test.stone_table (
    stone_index integer PRIMARY KEY,
    wheat numeric NOT NULL,
    barley numeric NOT NULL,
    salt numeric NOT NULL,
    bitter numeric NOT NULL,
    red numeric NOT NULL
);

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.m()
RETURNS numeric
LANGUAGE SQL
IMMUTABLE
AS $$ SELECT 170141183460469231731687303715884105727::numeric $$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.foundation_day()
RETURNS numeric
LANGUAGE SQL
IMMUTABLE
AS $$ SELECT (-15055671)::numeric $$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.floor_div(p_x numeric, p_d numeric)
RETURNS numeric
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    SELECT CASE
      WHEN p_d < 1 THEN NULL::numeric
      WHEN p_x >= 0 THEN div(p_x,p_d)
      ELSE -div(-p_x+p_d-1,p_d)
    END
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.regular_mod(p_x numeric, p_d numeric)
RETURNS numeric
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$ SELECT p_x - pastafari_sql_tamil_test.floor_div(p_x,p_d) * p_d $$;
CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.save_value(p_x numeric)
RETURNS numeric
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    SELECT 1 + pastafari_sql_tamil_test.regular_mod(p_x - 1, pastafari_sql_tamil_test.m())
$$;

WITH RECURSIVE s(i,w,b,sa,bi,r) AS (
    SELECT 1,17::numeric,29::numeric,43::numeric,71::numeric,101::numeric
    UNION ALL
    SELECT i+1,
           pastafari_sql_tamil_test.save_value(w*w + 3*b + (i+1)),
           pastafari_sql_tamil_test.save_value(b*b + 5*sa + w),
           pastafari_sql_tamil_test.save_value(sa*sa + 7*bi + b),
           pastafari_sql_tamil_test.save_value(bi*bi + 11*r + sa),
           pastafari_sql_tamil_test.save_value(r*r + 13*w + bi)
    FROM s
    WHERE i<46
)
INSERT INTO pastafari_sql_tamil_test.stone_table(stone_index,wheat,barley,salt,bitter,red)
SELECT i,w,b,sa,bi,r FROM s;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.ceil_div(p_a numeric, p_b numeric)
RETURNS numeric
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$ SELECT div(p_a+p_b-1,p_b) $$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.wrap1(p_position integer, p_size integer)
RETURNS integer
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$ SELECT (pastafari_sql_tamil_test.regular_mod((p_position - 1)::numeric, p_size::numeric) + 1)::integer $$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.day_count(p_day numeric)
RETURNS numeric
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    SELECT CASE
        WHEN p_day = pastafari_sql_tamil_test.foundation_day() THEN 1::numeric
        WHEN p_day > pastafari_sql_tamil_test.foundation_day() THEN 2 * (p_day - pastafari_sql_tamil_test.foundation_day()) + 1
        ELSE 2 * (pastafari_sql_tamil_test.foundation_day() - p_day)
    END
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.work_counts(p_calculation_day numeric, p_target_day numeric)
RETURNS pastafari_sql_tamil_test.work_counts
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    SELECT ROW(
        pastafari_sql_tamil_test.day_count(p_calculation_day),
        pastafari_sql_tamil_test.day_count(p_target_day),
        abs(p_target_day - p_calculation_day) + 1,
        pastafari_sql_tamil_test.day_count(p_calculation_day) + pastafari_sql_tamil_test.day_count(p_target_day),
        CASE WHEN p_target_day < p_calculation_day THEN 1 WHEN p_target_day = p_calculation_day THEN 2 ELSE 3 END
    )::pastafari_sql_tamil_test.work_counts
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.stone_row(p_i integer)
RETURNS pastafari_sql_tamil_test.stone5
LANGUAGE SQL
STABLE
STRICT
AS $$
    SELECT ROW(wheat,barley,salt,bitter,red)::pastafari_sql_tamil_test.stone5
    FROM pastafari_sql_tamil_test.stone_table
    WHERE stone_index=p_i
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.stone_value(p_i integer, p_kind integer)
RETURNS numeric
LANGUAGE SQL
STABLE
STRICT
AS $$
    SELECT CASE p_kind
        WHEN 1 THEN (pastafari_sql_tamil_test.stone_row(p_i)).wheat
        WHEN 2 THEN (pastafari_sql_tamil_test.stone_row(p_i)).barley
        WHEN 3 THEN (pastafari_sql_tamil_test.stone_row(p_i)).salt
        WHEN 4 THEN (pastafari_sql_tamil_test.stone_row(p_i)).bitter
        WHEN 5 THEN (pastafari_sql_tamil_test.stone_row(p_i)).red
    END
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.hidden_drop(p_k integer, p_counts pastafari_sql_tamil_test.work_counts)
RETURNS numeric
LANGUAGE SQL
STABLE
STRICT
AS $$
    WITH RECURSIVE coeff AS (
        SELECT * FROM (VALUES
            (1,3,4,6,8,1),(2,5,7,10,12,2),(3,7,10,14,16,3),(4,9,13,18,20,4),
            (5,11,16,22,24,5),(6,13,19,26,28,1),(7,15,22,30,32,2)
        ) AS v(k,a,b,c,d,first_kind)
        WHERE k = p_k
    ), init AS (
        SELECT pastafari_sql_tamil_test.save_value(
            (p_counts).action
            + a*(p_counts).target
            + b*(p_counts).distance
            + c*(p_counts).connection
            + d*(p_counts).direction
            + pastafari_sql_tamil_test.stone_value(p_k,1)
            + pastafari_sql_tamil_test.stone_value(p_k,2)
            + pastafari_sql_tamil_test.stone_value(p_k,3)
            + pastafari_sql_tamil_test.stone_value(p_k,4)
            + pastafari_sql_tamil_test.stone_value(p_k,5)
        ) AS x
        FROM coeff
    ), g(grind,x) AS (
        SELECT 0, x FROM init
        UNION ALL
        SELECT grind+1,
               pastafari_sql_tamil_test.save_value(
                   x*x + 3*x
                   + pastafari_sql_tamil_test.stone_value(
                       p_k,
                       (ARRAY[1,2,3,4,5,1,2])[grind+1]
                     )
                   + grind + 1
               )
        FROM g
        WHERE grind < 7
    )
    SELECT x FROM g WHERE grind = 7
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.prior_value(p_visible numeric[], p_counts pastafari_sql_tamil_test.work_counts, p_slot integer)
RETURNS numeric
LANGUAGE SQL
STABLE
STRICT
AS $$
    SELECT CASE
        WHEN p_slot >= 1 THEN p_visible[p_slot]
        ELSE pastafari_sql_tamil_test.hidden_drop(1 - p_slot, p_counts)
    END
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.visible_grind_kind(p_g integer)
RETURNS integer
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$ SELECT (ARRAY[1,2,3,4,5,1,2,3,4,5,1])[p_g] $$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.visible_grind_coeff(p_g integer, p_col integer)
RETURNS integer
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    SELECT CASE p_col
      WHEN 1 THEN (ARRAY[3,5,7,11,13,17,19,23,29,31,37])[p_g]
      WHEN 2 THEN (ARRAY[5,7,11,13,17,19,23,29,31,37,41])[p_g]
      WHEN 3 THEN (ARRAY[7,11,13,17,19,23,29,31,37,41,43])[p_g]
      WHEN 4 THEN (ARRAY[11,13,17,19,23,29,31,37,41,43,47])[p_g]
    END
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.one_visible_drop(p_i integer, p_counts pastafari_sql_tamil_test.work_counts, p_visible numeric[])
RETURNS numeric
LANGUAGE SQL
STABLE
STRICT
AS $$
    WITH RECURSIVE p AS (
        SELECT pastafari_sql_tamil_test.prior_value(p_visible,p_counts,p_i-1) AS p1,
               pastafari_sql_tamil_test.prior_value(p_visible,p_counts,p_i-3) AS p3,
               pastafari_sql_tamil_test.prior_value(p_visible,p_counts,p_i-7) AS p7
    ), init AS (
        SELECT pastafari_sql_tamil_test.save_value(
            pastafari_sql_tamil_test.stone_value(p_i,1)*(p_counts).action
            + pastafari_sql_tamil_test.stone_value(p_i,2)*(p_counts).target
            + pastafari_sql_tamil_test.stone_value(p_i,3)*(p_counts).distance
            + pastafari_sql_tamil_test.stone_value(p_i,4)*(p_counts).connection
            + pastafari_sql_tamil_test.stone_value(p_i,5)*(p_counts).direction
            + p1 + 3*p3 + 5*p7 + p_i
        ) AS x, p1, p3, p7
        FROM p
    ), g(grind,x,p1,p3,p7) AS (
        SELECT 0,x,p1,p3,p7 FROM init
        UNION ALL
        SELECT grind+1,
               pastafari_sql_tamil_test.save_value(
                   x*x
                   + pastafari_sql_tamil_test.visible_grind_coeff(grind+1,1)*x
                   + pastafari_sql_tamil_test.visible_grind_coeff(grind+1,2)*p1
                   + pastafari_sql_tamil_test.visible_grind_coeff(grind+1,3)*p3
                   + pastafari_sql_tamil_test.visible_grind_coeff(grind+1,4)*p7
                   + pastafari_sql_tamil_test.stone_value(p_i,pastafari_sql_tamil_test.visible_grind_kind(grind+1))
               ), p1,p3,p7
        FROM g
        WHERE grind < 11
    )
    SELECT x FROM g WHERE grind = 11
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.visible_drops(p_counts pastafari_sql_tamil_test.work_counts)
RETURNS numeric[]
LANGUAGE SQL
STABLE
STRICT
AS $$
    WITH RECURSIVE d(i,arr) AS (
        SELECT 0, ARRAY[]::numeric[]
        UNION ALL
        SELECT i+1, array_append(arr,pastafari_sql_tamil_test.one_visible_drop(i+1,p_counts,arr))
        FROM d
        WHERE i < 46
    )
    SELECT arr FROM d WHERE i = 46
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.factorial_small(p_n integer)
RETURNS integer
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$ SELECT (ARRAY[1,1,2,6,24,120,720])[p_n+1] $$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.bowl_order_from_number(p_rank1 integer)
RETURNS integer[]
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    WITH RECURSIVE u(pos,rank0,remaining,out_arr) AS (
        SELECT 1,p_rank1-1,ARRAY[1,2,3,4,5,6]::integer[],ARRAY[]::integer[]
        UNION ALL
        SELECT pos+1,
               rank0 % pastafari_sql_tamil_test.factorial_small(6-pos),
               array_remove(remaining,remaining[(div(rank0::numeric,pastafari_sql_tamil_test.factorial_small(6-pos)::numeric)::integer)+1]),
               array_append(out_arr,remaining[(div(rank0::numeric,pastafari_sql_tamil_test.factorial_small(6-pos)::numeric)::integer)+1])
        FROM u
        WHERE pos <= 6
    )
    SELECT out_arr FROM u WHERE pos = 7
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.bowl_order_from_drop(p_drop numeric)
RETURNS integer[]
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    SELECT pastafari_sql_tamil_test.bowl_order_from_number((pastafari_sql_tamil_test.regular_mod(p_drop-1,720)+1)::integer)
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.initial_bowls(p_counts pastafari_sql_tamil_test.work_counts)
RETURNS numeric[]
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    WITH q(id,prime) AS (
      VALUES (1,17::numeric),(2,19::numeric),(3,23::numeric),(4,29::numeric),(5,31::numeric),(6,37::numeric)
    ), s AS (
      SELECT id,
             (p_counts).action + (p_counts).target*id + (p_counts).distance
             + (p_counts).connection + (p_counts).direction + prime*prime AS mix
      FROM q
    )
    SELECT array_agg(pastafari_sql_tamil_test.save_value(mix*mix + id) ORDER BY id)
    FROM s
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.stir_stone_kind_by_position(p_pos integer)
RETURNS integer
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$ SELECT (ARRAY[1,2,3,4,5,1])[p_pos] $$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.bowl_round(p_bowls numeric[], p_drop numeric, p_i integer)
RETURNS numeric[]
LANGUAGE SQL
STABLE
STRICT
AS $$
    WITH o AS (
        SELECT pastafari_sql_tamil_test.bowl_order_from_drop(p_drop) AS ord
    ), ids AS (
        SELECT id,array_position(ord,id) AS pos,ord
        FROM o,generate_series(1,6) AS g(id)
    ), calc AS (
        SELECT id,pos,ord,
               ord[pastafari_sql_tamil_test.wrap1(pos-1,6)] AS prev_id,
               ord[pastafari_sql_tamil_test.wrap1(pos+1,6)] AS next_id,
               CASE pos
                 WHEN 1 THEN pastafari_sql_tamil_test.save_value(p_drop*p_drop + pastafari_sql_tamil_test.stone_value(p_i,1)*p_bowls[id] + 3*p_i)
                 WHEN 2 THEN pastafari_sql_tamil_test.save_value(p_drop*p_drop + pastafari_sql_tamil_test.stone_value(p_i,2)*p_bowls[id] + 5*p_i)
                 WHEN 3 THEN pastafari_sql_tamil_test.save_value(p_drop*p_drop + pastafari_sql_tamil_test.stone_value(p_i,3)*p_bowls[id] + 7*p_i)
                 ELSE 0::numeric
               END AS pour
        FROM ids
    ), mixed AS (
        SELECT id,pos,prev_id,next_id,
               p_bowls[id] + 2*p_bowls[prev_id] + 3*p_bowls[next_id] + pour + p_drop
               + pastafari_sql_tamil_test.stone_value(p_i,pastafari_sql_tamil_test.stir_stone_kind_by_position(pos)) AS mix
        FROM calc
    )
    SELECT array_agg(
        pastafari_sql_tamil_test.save_value(mix*mix + 5*p_bowls[prev_id]*p_bowls[next_id] + p_i*pos)
        ORDER BY id
    )
    FROM mixed
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.post_stir_round(p_bowls numeric[], p_stir integer)
RETURNS numeric[]
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    WITH saved AS (
        SELECT pastafari_sql_tamil_test.save_value((SELECT sum(v) FROM unnest(p_bowls) AS x(v)) + 149*p_stir) AS s
    ), o AS (
        SELECT s,pastafari_sql_tamil_test.bowl_order_from_number((pastafari_sql_tamil_test.regular_mod(s-1,720)+1)::integer) AS ord
        FROM saved
    ), ids AS (
        SELECT id,array_position(ord,id) AS pos,ord,s
        FROM o,generate_series(1,6) AS g(id)
    ), calc AS (
        SELECT id,pos,s,
               ord[pastafari_sql_tamil_test.wrap1(pos-1,6)] AS prev_id,
               ord[pastafari_sql_tamil_test.wrap1(pos+1,6)] AS next_id
        FROM ids
    ), mixed AS (
        SELECT id,pos,prev_id,next_id,
               p_bowls[id] + 3*p_bowls[prev_id] + 5*p_bowls[next_id] + s + p_stir + pos*pos AS mix
        FROM calc
    )
    SELECT array_agg(
        pastafari_sql_tamil_test.save_value(mix*mix + 7*p_bowls[prev_id]*p_bowls[next_id])
        ORDER BY id
    )
    FROM mixed
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.sauce(p_calculation_day numeric, p_target_day numeric)
RETURNS pastafari_sql_tamil_test.sauce_result
LANGUAGE SQL
STABLE
STRICT
AS $$
    WITH RECURSIVE c AS (
        SELECT pastafari_sql_tamil_test.work_counts(p_calculation_day,p_target_day) AS counts
    ), v AS (
        SELECT counts,pastafari_sql_tamil_test.visible_drops(counts) AS drops
        FROM c
    ), rounds(i,bowls,drops) AS (
        SELECT 0,pastafari_sql_tamil_test.initial_bowls(counts),drops FROM v
        UNION ALL
        SELECT i+1,pastafari_sql_tamil_test.bowl_round(bowls,drops[i+1],i+1),drops
        FROM rounds
        WHERE i < 46
    ), after_drops AS (
        SELECT bowls,drops FROM rounds WHERE i=46
    ), stirs(n,bowls,drops) AS (
        SELECT 0,bowls,drops FROM after_drops
        UNION ALL
        SELECT n+1,pastafari_sql_tamil_test.post_stir_round(bowls,n+1),drops
        FROM stirs
        WHERE n < 12
    )
    SELECT ROW(bowls,pastafari_sql_tamil_test.bowl_order_from_drop(drops[46]))::pastafari_sql_tamil_test.sauce_result
    FROM stirs
    WHERE n=12
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.next_bowl_in_drop46_order(p_sauce pastafari_sql_tamil_test.sauce_result, p_queried integer)
RETURNS integer
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    SELECT (p_sauce).order_at_drop_46[
        pastafari_sql_tamil_test.wrap1(array_position((p_sauce).order_at_drop_46,p_queried)+1,6)
    ]
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.ask_bowl(p_sauce pastafari_sql_tamil_test.sauce_result, p_bowl integer, p_seal integer)
RETURNS pastafari_sql_tamil_test.answer_stream
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    WITH n AS (
        SELECT pastafari_sql_tamil_test.next_bowl_in_drop46_order(p_sauce,p_bowl) AS next_id
    ), mix1 AS (
        SELECT (p_sauce).bowls[p_bowl] + p_seal + 181 AS z,next_id FROM n
    ), f AS (
        SELECT pastafari_sql_tamil_test.save_value(z*z + 179*(p_sauce).bowls[next_id] + p_seal) AS first_value
        FROM mix1
    ), mix2 AS (
        SELECT first_value,first_value + p_seal + 1 + 193 AS z FROM f
    ), d AS (
        SELECT first_value,
               pastafari_sql_tamil_test.save_value(z*z + 193*first_value + 197*(p_sauce).bowls[6]) AS direction_number
        FROM mix2
    )
    SELECT ROW(first_value,CASE WHEN pastafari_sql_tamil_test.regular_mod(direction_number,2)=1 THEN 1 ELSE -1 END)::pastafari_sql_tamil_test.answer_stream
    FROM d
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.answer_at(p_stream pastafari_sql_tamil_test.answer_stream, p_k numeric)
RETURNS numeric
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    SELECT 1 + pastafari_sql_tamil_test.regular_mod((p_stream).first_value - 1 + (p_stream).direction_step*p_k,pastafari_sql_tamil_test.m())
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.choose_rank_short(p_stream pastafari_sql_tamil_test.answer_stream, p_n numeric)
RETURNS numeric
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    WITH a AS (
        SELECT div(pastafari_sql_tamil_test.m(),p_n)*p_n AS lim,
               pastafari_sql_tamil_test.answer_at(p_stream,0) AS x
    ), accepted AS (
        SELECT CASE WHEN x<=lim THEN x WHEN (p_stream).direction_step=1 THEN 1::numeric ELSE lim END AS y
        FROM a
    )
    SELECT pastafari_sql_tamil_test.regular_mod(y-1,p_n)+1 FROM accepted
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.choose_rank_wide(p_stream pastafari_sql_tamil_test.answer_stream, p_n numeric)
RETURNS numeric
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    WITH RECURSIVE p(k,space) AS (
        SELECT 1,pastafari_sql_tamil_test.m()
        UNION ALL
        SELECT k+1,space*pastafari_sql_tamil_test.m()
        FROM p
        WHERE space < p_n
    ), smallest AS (
        SELECT k,space FROM p WHERE space>=p_n ORDER BY k LIMIT 1
    ), digits(j,k,space,weight,wide) AS (
        SELECT 0,k,space,1::numeric,1::numeric FROM smallest
        UNION ALL
        SELECT j+1,k,space,weight*pastafari_sql_tamil_test.m(),
               wide + (pastafari_sql_tamil_test.answer_at(p_stream,j)-1)*weight
        FROM digits
        WHERE j<k
    ), built AS (
        SELECT space,wide,div(space,p_n)*p_n AS lim
        FROM digits
        WHERE j=k
    ), accepted AS (
        SELECT CASE WHEN wide<=lim THEN wide WHEN (p_stream).direction_step=1 THEN 1::numeric ELSE lim END AS y
        FROM built
    )
    SELECT pastafari_sql_tamil_test.regular_mod(y-1,p_n)+1 FROM accepted
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.choose_rank(p_stream pastafari_sql_tamil_test.answer_stream, p_n numeric)
RETURNS numeric
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    SELECT CASE WHEN p_n<=pastafari_sql_tamil_test.m()
      THEN pastafari_sql_tamil_test.choose_rank_short(p_stream,p_n)
      ELSE pastafari_sql_tamil_test.choose_rank_wide(p_stream,p_n)
    END
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.positive_gate_gap(p_n numeric)
RETURNS numeric
LANGUAGE SQL
VOLATILE
STRICT
AS $$
    SELECT 41 + pastafari_sql_tamil_test.choose_rank(
        pastafari_sql_tamil_test.ask_bowl(
            pastafari_sql_tamil_test.sauce(
                pastafari_sql_tamil_test.foundation_day(),
                pastafari_sql_tamil_test.foundation_day()+p_n
            ),1,1
        ),922
    )
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.negative_gate_gap(p_n numeric)
RETURNS numeric
LANGUAGE SQL
VOLATILE
STRICT
AS $$
    SELECT 41 + pastafari_sql_tamil_test.choose_rank(
        pastafari_sql_tamil_test.ask_bowl(
            pastafari_sql_tamil_test.sauce(
                pastafari_sql_tamil_test.foundation_day(),
                pastafari_sql_tamil_test.foundation_day()-p_n
            ),1,1
        ),922
    )
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.gate_day(p_index numeric)
RETURNS numeric
LANGUAGE SQL
VOLATILE
STRICT
AS $$
    WITH RECURSIVE cached AS (
      SELECT gate_day
      FROM pastafari_sql_tamil_test.gate_cache
      WHERE gate_index=p_index
    ), base AS (
      SELECT c.gate_index,c.gate_day,
             CASE WHEN p_index>c.gate_index THEN 1 WHEN p_index<c.gate_index THEN -1 ELSE 0 END AS step
      FROM pastafari_sql_tamil_test.gate_cache AS c
      WHERE (p_index>=0 AND c.gate_index<=p_index)
         OR (p_index<0 AND c.gate_index>=p_index)
      ORDER BY CASE WHEN p_index>=0 THEN c.gate_index END DESC,
               CASE WHEN p_index<0 THEN c.gate_index END ASC
      LIMIT 1
    ), walk(gate_index,gate_day,step) AS (
      SELECT gate_index,gate_day,step FROM base
      WHERE NOT EXISTS (SELECT 1 FROM cached)
      UNION ALL
      SELECT w.gate_index+w.step,
             w.gate_day + CASE
               WHEN w.step=1 THEN pastafari_sql_tamil_test.positive_gate_gap(w.gate_index+1)
               ELSE -pastafari_sql_tamil_test.negative_gate_gap(abs(w.gate_index-1))
             END,
             w.step
      FROM walk AS w
      WHERE w.gate_index<>p_index
    ), ins AS (
      INSERT INTO pastafari_sql_tamil_test.gate_cache(gate_index,gate_day)
      SELECT gate_index,gate_day FROM walk
      ON CONFLICT (gate_index) DO NOTHING
      RETURNING 1
    ), forced AS (
      SELECT count(*) AS inserted FROM ins
    )
    SELECT gate_day FROM cached
    UNION ALL
    SELECT w.gate_day FROM walk AS w,forced WHERE w.gate_index=p_index
    LIMIT 1
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.gate_index_at_or_before(p_day numeric)
RETURNS numeric
LANGUAGE SQL
VOLATILE
STRICT
AS $$
    WITH RECURSIVE bounds AS (
      SELECT min(gate_index) AS min_i,max(gate_index) AS max_i,
             min(gate_day) AS min_d,max(gate_day) AS max_d
      FROM pastafari_sql_tamil_test.gate_cache
    ), start AS (
      SELECT CASE
               WHEN p_day>max_d THEN max_i
               WHEN p_day<min_d THEN min_i
               ELSE NULL::numeric
             END AS gate_index,
             CASE
               WHEN p_day>max_d THEN max_d
               WHEN p_day<min_d THEN min_d
               ELSE NULL::numeric
             END AS gate_day,
             CASE WHEN p_day>max_d THEN 1 WHEN p_day<min_d THEN -1 ELSE 0 END AS step
      FROM bounds
    ), walk(gate_index,gate_day,step) AS (
      SELECT gate_index,gate_day,step
      FROM start
      WHERE step<>0
      UNION ALL
      SELECT w.gate_index+w.step,
             w.gate_day + CASE
               WHEN w.step=1 THEN pastafari_sql_tamil_test.positive_gate_gap(w.gate_index+1)
               ELSE -pastafari_sql_tamil_test.negative_gate_gap(abs(w.gate_index-1))
             END,
             w.step
      FROM walk AS w
      WHERE (w.step=1 AND w.gate_day<=p_day)
         OR (w.step=-1 AND w.gate_day>p_day)
    ), ins AS (
      INSERT INTO pastafari_sql_tamil_test.gate_cache(gate_index,gate_day)
      SELECT gate_index,gate_day FROM walk
      ON CONFLICT (gate_index) DO NOTHING
      RETURNING 1
    ), forced AS (
      SELECT count(*) AS inserted FROM ins
    ), all_rows AS (
      SELECT gate_index,gate_day FROM pastafari_sql_tamil_test.gate_cache
      UNION ALL
      SELECT gate_index,gate_day FROM walk
    )
    SELECT max(c.gate_index)
    FROM forced,all_rows AS c
    WHERE c.gate_day<=p_day
$$;
CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.gate_index_at_or_after(p_day numeric)
RETURNS numeric
LANGUAGE SQL
VOLATILE
STRICT
AS $$
    WITH b AS (
      SELECT pastafari_sql_tamil_test.gate_index_at_or_before(p_day) AS i
    )
    SELECT CASE WHEN pastafari_sql_tamil_test.gate_day(i)=p_day THEN i ELSE i+1 END FROM b
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.exact_gate_index(p_day numeric)
RETURNS numeric
LANGUAGE SQL
VOLATILE
STRICT
AS $$
    WITH b AS (SELECT pastafari_sql_tamil_test.gate_index_at_or_before(p_day) AS i)
    SELECT CASE WHEN pastafari_sql_tamil_test.gate_day(i)=p_day THEN i ELSE NULL END FROM b
$$;


CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.falling_factorial(p_n integer,p_k integer)
RETURNS numeric
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    WITH RECURSIVE f(j,r) AS (
      SELECT 0,1::numeric
      UNION ALL
      SELECT j+1,r*(p_n-j)
      FROM f WHERE j<p_k
    )
    SELECT r FROM f WHERE j=p_k
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.unrank_distinct_indices(p_n integer,p_k integer,p_rank1 numeric)
RETURNS integer[]
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    WITH RECURSIVE u(pos,r,remaining,out_arr) AS (
      SELECT 1,p_rank1,ARRAY(SELECT x FROM generate_series(1,p_n) AS g(x)),ARRAY[]::integer[]
      UNION ALL
      SELECT pos+1,
             r-div(r-1,block)*block,
             array_remove(remaining,remaining[(div(r-1,block)+1)::integer]),
             array_append(out_arr,remaining[(div(r-1,block)+1)::integer])
      FROM u
      CROSS JOIN LATERAL (
        SELECT pastafari_sql_tamil_test.falling_factorial(array_length(remaining,1)-1,p_k-pos) AS block
      ) q
      WHERE pos<=p_k
    )
    SELECT out_arr FROM u WHERE pos=p_k+1
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.binomial_exact(p_n integer,p_k integer)
RETURNS numeric
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    WITH RECURSIVE b(i,k_eff,r) AS (
      SELECT 0,least(p_k,p_n-p_k),1::numeric
      WHERE p_n>=0 AND p_k>=0 AND p_k<=p_n
      UNION ALL
      SELECT i+1,k_eff,div(r*(p_n-k_eff+i+1),(i+1)::numeric)
      FROM b
      WHERE i<k_eff
    )
    SELECT COALESCE((SELECT r FROM b WHERE i=k_eff),0::numeric)
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.bounded_count(p_total integer,p_slots integer,p_lo integer,p_hi integer)
RETURNS numeric
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    WITH q AS (
      SELECT p_total-p_slots*p_lo AS rem,p_hi-p_lo AS upper
    )
    SELECT CASE
      WHEN p_slots=0 THEN CASE WHEN p_total=0 THEN 1::numeric ELSE 0::numeric END
      WHEN rem<0 OR rem>p_slots*upper THEN 0::numeric
      ELSE COALESCE((
        SELECT sum(
          CASE WHEN j%2=0 THEN 1::numeric ELSE -1::numeric END
          * pastafari_sql_tamil_test.binomial_exact(p_slots,j)
          * pastafari_sql_tamil_test.binomial_exact(rem-j*(upper+1)+p_slots-1,p_slots-1)
        )
        FROM generate_series(0,least(p_slots,div(rem::numeric,(upper+1)::numeric)::integer)) AS g(j)
      ),0::numeric)
    END
    FROM q
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.unrank_bounded_composition(p_total integer,p_slots integer,p_lo integer,p_hi integer,p_rank1 numeric)
RETURNS integer[]
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    WITH RECURSIVE u(pos,rem,r,out_arr) AS (
      SELECT 1,p_total,p_rank1,ARRAY[]::integer[]
      UNION ALL
      SELECT pos+1,
             rem-chosen,
             r-prev_sum,
             array_append(out_arr,chosen)
      FROM u
      CROSS JOIN LATERAL (
        WITH blocks AS (
          SELECT x,
                 pastafari_sql_tamil_test.bounded_count(rem-x,p_slots-pos,p_lo,p_hi) AS block
          FROM generate_series(p_lo,p_hi) AS g(x)
          WHERE rem-x>=0
        ), sums AS (
          SELECT x,block,
                 COALESCE(sum(block) OVER (ORDER BY x ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING),0::numeric) AS prev_sum,
                 sum(block) OVER (ORDER BY x) AS upto
          FROM blocks
        )
        SELECT x AS chosen,prev_sum
        FROM sums
        WHERE r>prev_sum AND r<=upto
        ORDER BY x LIMIT 1
      ) q
      WHERE pos<=p_slots
    )
    SELECT out_arr FROM u WHERE pos=p_slots+1
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.cutlet_partition_count(
    p_rem integer,p_slots integer,p_cumulative integer,p_required integer,p_hit boolean)
RETURNS numeric
LANGUAGE SQL
IMMUTABLE
AS $$
    SELECT CASE
      WHEN p_slots=0 THEN CASE WHEN p_rem=0 AND (p_required IS NULL OR p_hit) THEN 1::numeric ELSE 0::numeric END
      WHEN p_rem<p_slots THEN 0::numeric
      WHEN p_required IS NULL OR p_hit THEN pastafari_sql_tamil_test.binomial_exact(p_rem-1,p_slots-1)
      WHEN p_required-p_cumulative<=0 OR p_required-p_cumulative>=p_rem THEN 0::numeric
      ELSE COALESCE((
        SELECT sum(
          pastafari_sql_tamil_test.binomial_exact((p_required-p_cumulative)-1,q-1)
          * pastafari_sql_tamil_test.binomial_exact((p_rem-(p_required-p_cumulative))-1,p_slots-q-1)
        )
        FROM generate_series(1,p_slots-1) AS g(q)
      ),0::numeric)
    END
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.unrank_cutlet_partition(
    p_total integer,p_slots integer,p_required integer,p_rank1 numeric)
RETURNS integer[]
LANGUAGE SQL
IMMUTABLE
AS $$
    WITH RECURSIVE u(pos,rem,cumulative,hit,r,out_arr) AS (
      SELECT 1,p_total,0,false,p_rank1,ARRAY[]::integer[]
      UNION ALL
      SELECT pos+1,
             rem-chosen,
             cumulative+chosen,
             hit OR (p_required IS NOT NULL AND cumulative+chosen=p_required),
             r-prev_sum,
             array_append(out_arr,chosen)
      FROM u
      CROSS JOIN LATERAL (
        WITH blocks AS (
          SELECT x,
            pastafari_sql_tamil_test.cutlet_partition_count(
              rem-x,p_slots-pos,cumulative+x,p_required,
              hit OR (p_required IS NOT NULL AND cumulative+x=p_required)
            ) AS block
          FROM generate_series(1,rem-(p_slots-pos)) AS g(x)
          WHERE p_required IS NULL OR hit OR cumulative+x<=p_required
        ), sums AS (
          SELECT x,block,
                 COALESCE(sum(block) OVER (ORDER BY x ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING),0::numeric) AS prev_sum,
                 sum(block) OVER (ORDER BY x) AS upto
          FROM blocks
        )
        SELECT x AS chosen,prev_sum
        FROM sums
        WHERE r>prev_sum AND r<=upto
        ORDER BY x LIMIT 1
      ) q
      WHERE pos<=p_slots
    )
    SELECT out_arr FROM u WHERE pos=p_slots+1
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.array_decrement_at(p_arr integer[],p_index integer)
RETURNS integer[]
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    SELECT array_agg(CASE WHEN ord=p_index THEN val-1 ELSE val END ORDER BY ord)
    FROM unnest(p_arr) WITH ORDINALITY AS u(val,ord)
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.weave_last_order_count(
    p_remaining integer[],p_opened integer,p_closed integer)
RETURNS numeric
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    WITH RECURSIVE a(j,total_len,ways) AS (
      SELECT p_closed,0,1::numeric
      UNION ALL
      SELECT j+1,
             total_len+p_remaining[j+1],
             ways * CASE
               WHEN total_len=0 THEN 1::numeric
               ELSE pastafari_sql_tamil_test.binomial_exact(total_len+p_remaining[j+1]-1,p_remaining[j+1]-1)
             END
      FROM a
      WHERE j<p_opened
    )
    SELECT ways FROM a WHERE j=p_opened
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.weave_future_factors(p_lengths integer[])
RETURNS TABLE(opened_up_to integer,tail_length integer,factor numeric)
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    WITH RECURSIVE meta AS (
      SELECT array_length(p_lengths,1) AS month_count,
             (SELECT sum(v)::integer FROM unnest(p_lengths) AS u(v)) AS total_length
      WHERE NOT EXISTS (SELECT 1 FROM unnest(p_lengths) AS u(v) WHERE v<2)
    ), f(opened_up_to,tail_length,factor) AS (
      SELECT month_count,g.r,1::numeric
      FROM meta
      CROSS JOIN LATERAL generate_series(0,total_length-month_count) AS g(r)
      UNION ALL
      SELECT d.opened_up_to-1,
             d.tail_length-p_lengths[d.opened_up_to]+1,
             sum(
               d.factor * pastafari_sql_tamil_test.binomial_exact(
                 d.tail_length-1,
                 p_lengths[d.opened_up_to]-2
               )
             ) OVER (ORDER BY d.tail_length ROWS UNBOUNDED PRECEDING)
      FROM f AS d
      WHERE d.opened_up_to>0
        AND d.tail_length>=p_lengths[d.opened_up_to]-1
    )
    SELECT opened_up_to,tail_length,factor FROM f
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.weave_prepare(p_lengths integer[])
RETURNS bigint
LANGUAGE SQL
VOLATILE
STRICT
AS $$
    INSERT INTO pastafari_sql_tamil_test.weave_family_registry(original_lengths)
    VALUES (p_lengths)
    ON CONFLICT (original_lengths) DO NOTHING;

    INSERT INTO pastafari_sql_tamil_test.weave_future_memo(family_id,opened_up_to,tail_length,factor)
    SELECT f.family_id,x.opened_up_to,x.tail_length,x.factor
    FROM pastafari_sql_tamil_test.weave_family_registry AS f
    CROSS JOIN LATERAL pastafari_sql_tamil_test.weave_future_factors(p_lengths) AS x
    WHERE f.original_lengths=p_lengths
      AND NOT EXISTS (
        SELECT 1 FROM pastafari_sql_tamil_test.weave_future_memo AS m
        WHERE m.family_id=f.family_id
      )
    ON CONFLICT (family_id,opened_up_to,tail_length) DO NOTHING;

    SELECT family_id
    FROM pastafari_sql_tamil_test.weave_family_registry
    WHERE original_lengths=p_lengths
    LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.weave_factor(
    p_family_id bigint,p_opened integer,p_tail integer)
RETURNS numeric
LANGUAGE SQL
VOLATILE
STRICT
AS $$
    SELECT factor
    FROM pastafari_sql_tamil_test.weave_future_memo
    WHERE family_id=p_family_id
      AND opened_up_to=p_opened
      AND tail_length=p_tail
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.weave_count(
    p_original integer[],p_remaining integer[],p_opened integer,p_closed integer)
RETURNS numeric
LANGUAGE SQL
VOLATILE
STRICT
AS $$
    WITH fam AS MATERIALIZED (
      SELECT pastafari_sql_tamil_test.weave_prepare(p_original) AS family_id
    ), b AS (
      SELECT pastafari_sql_tamil_test.weave_last_order_count(p_remaining,p_opened,p_closed) AS active_factor,
             COALESCE((
               SELECT sum(p_remaining[j])::integer
               FROM generate_series(p_closed+1,p_opened) AS g(j)
             ),0) AS active_tail
    )
    SELECT b.active_factor*pastafari_sql_tamil_test.weave_factor(fam.family_id,p_opened,b.active_tail)
    FROM fam,b
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.unrank_weaving(p_lengths integer[],p_rank1 numeric)
RETURNS integer[]
LANGUAGE SQL
VOLATILE
STRICT
AS $$
    WITH RECURSIVE fam AS MATERIALIZED (
      SELECT pastafari_sql_tamil_test.weave_prepare(p_lengths) AS family_id
    ), initial_count AS MATERIALIZED (
      SELECT pastafari_sql_tamil_test.weave_factor(fam.family_id,0,0) AS n,fam.family_id
      FROM fam
    ), valid AS (
      SELECT p_rank1 AS initial_rank,family_id
      FROM initial_count
      WHERE p_rank1>=1 AND p_rank1<=n
    ), u(step,remaining,opened,closed,active_tail,active_factor,r,chosen,family_id) AS (
      SELECT 0,p_lengths,0,0,0,1::numeric,initial_rank,NULL::integer,family_id
      FROM valid
      UNION ALL
      SELECT u.step+1,
             pastafari_sql_tamil_test.array_decrement_at(u.remaining,pick.j),
             CASE WHEN pick.j=u.opened+1 THEN u.opened+1 ELSE u.opened END,
             CASE
               WHEN pick.j<=u.opened AND u.remaining[pick.j]=1 THEN u.closed+1
               ELSE u.closed
             END,
             CASE
               WHEN pick.j=u.opened+1 THEN u.active_tail+u.remaining[pick.j]-1
               ELSE u.active_tail-1
             END,
             pick.next_active_factor,
             u.r-pick.previous_blocks,
             pick.j,
             u.family_id
      FROM u
      CROSS JOIN LATERAL (
        WITH RECURSIVE active AS (
          SELECT g.j,
                 u.remaining[g.j] AS rem,
                 sum(u.remaining[g.j]) OVER (ORDER BY g.j ROWS UNBOUNDED PRECEDING)::numeric AS prefix_total
          FROM generate_series(u.closed+1,u.opened) AS g(j)
        ), suffix(j,product_total,product_minus_one) AS (
          SELECT a.j,a.prefix_total,a.prefix_total-1
          FROM active AS a
          WHERE a.j=u.opened
          UNION ALL
          SELECT a.j,
                 a.prefix_total*s.product_total,
                 (a.prefix_total-1)*s.product_minus_one
          FROM suffix AS s
          JOIN active AS a ON a.j=s.j-1
        ), shared AS MATERIALIZED (
          SELECT
            CASE
              WHEN u.active_tail>0
              THEN pastafari_sql_tamil_test.weave_factor(u.family_id,u.opened,u.active_tail-1)
            END AS active_future,
            CASE
              WHEN u.opened<array_length(p_lengths,1)
              THEN pastafari_sql_tamil_test.weave_factor(
                     u.family_id,
                     u.opened+1,
                     u.active_tail+u.remaining[u.opened+1]-1
                   )
            END AS opening_future
        ), active_candidates AS (
          SELECT a.j,
                 div(
                   u.active_factor
                   * CASE WHEN a.j=u.closed+1 THEN a.rem::numeric ELSE (a.rem-1)::numeric END
                   * COALESCE(s.product_total,1::numeric),
                   u.active_tail::numeric * COALESCE(s.product_minus_one,1::numeric)
                 ) AS next_active_factor
          FROM active AS a
          LEFT JOIN suffix AS s
            ON s.j=CASE WHEN a.j=u.closed+1 THEN a.j+1 ELSE a.j END
          WHERE a.rem>1 OR a.j=u.closed+1
        ), active_blocks AS (
          SELECT a.j,a.next_active_factor,
                 a.next_active_factor*sh.active_future AS block
          FROM active_candidates AS a
          CROSS JOIN shared AS sh
        ), opening_candidate AS (
          SELECT u.opened+1 AS j,
                 u.active_factor
                 * pastafari_sql_tamil_test.binomial_exact(
                     u.active_tail+u.remaining[u.opened+1]-2,
                     u.remaining[u.opened+1]-2
                   ) AS next_active_factor
          WHERE u.opened<array_length(p_lengths,1)
            AND u.remaining[u.opened+1]>=2
        ), opening_block AS (
          SELECT o.j,o.next_active_factor,
                 o.next_active_factor*sh.opening_future AS block
          FROM opening_candidate AS o
          CROSS JOIN shared AS sh
        ), candidates AS (
          SELECT * FROM active_blocks
          UNION ALL
          SELECT * FROM opening_block
        ), ranges AS (
          SELECT j,next_active_factor,block,
                 COALESCE(
                   sum(block) OVER (
                     ORDER BY j ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
                   ),0::numeric
                 ) AS previous_blocks,
                 sum(block) OVER (ORDER BY j ROWS UNBOUNDED PRECEDING) AS through_block
          FROM candidates
        )
        SELECT j,next_active_factor,previous_blocks
        FROM ranges
        WHERE u.r>previous_blocks AND u.r<=through_block
        ORDER BY j
        LIMIT 1
      ) AS pick
      WHERE EXISTS (SELECT 1 FROM unnest(u.remaining) AS x(v) WHERE v<>0)
    )
    SELECT array_agg(chosen ORDER BY step) FILTER (WHERE step>0)
    FROM u
$$;
CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.numeric_series(p_start numeric,p_stop numeric,p_step numeric DEFAULT 1)
RETURNS SETOF numeric
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    WITH RECURSIVE s(v) AS (
      SELECT p_start
      WHERE (p_step>0 AND p_start<=p_stop) OR (p_step<0 AND p_start>=p_stop)
      UNION ALL
      SELECT v+p_step FROM s
      WHERE (p_step>0 AND v+p_step<=p_stop) OR (p_step<0 AND v+p_step>=p_stop)
    )
    SELECT v FROM s
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.year5000(p_calculation_day numeric)
RETURNS pastafari_sql_tamil_test.year_rec
LANGUAGE SQL
VOLATILE
STRICT
AS $$
    WITH bounds AS (
      SELECT pastafari_sql_tamil_test.gate_index_at_or_before(p_calculation_day-5778)-1 AS lo,
             pastafari_sql_tamil_test.gate_index_at_or_after(p_calculation_day+5778)+1 AS hi
    ), candidates AS (
      SELECT i AS oi,j AS ci,
             pastafari_sql_tamil_test.gate_day(i) AS od,
             pastafari_sql_tamil_test.gate_day(j) AS cd
      FROM bounds,
           LATERAL pastafari_sql_tamil_test.numeric_series(lo,hi,1) AS x(i),
           LATERAL pastafari_sql_tamil_test.numeric_series(i+1,hi,1) AS y(j)
      WHERE j-i>=6
    ), valid AS (
      SELECT *,cd-od AS len
      FROM candidates
      WHERE cd-od BETWEEN 252 AND 5778
        AND od<p_calculation_day AND p_calculation_day<=cd
    ), numbered AS (
      SELECT *,row_number() OVER (ORDER BY len,od) AS rn,count(*) OVER () AS cnt
      FROM valid
    ), pick AS (
      SELECT pastafari_sql_tamil_test.choose_rank(
               pastafari_sql_tamil_test.ask_bowl(pastafari_sql_tamil_test.sauce(p_calculation_day,p_calculation_day),1,10),
               max(cnt)::numeric
             ) AS wanted
      FROM numbered
    )
    SELECT ROW(5000,oi,ci,od,cd)::pastafari_sql_tamil_test.year_rec
    FROM numbered,pick
    WHERE rn=wanted
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.next_year(p_calculation_day numeric, p_known pastafari_sql_tamil_test.year_rec)
RETURNS pastafari_sql_tamil_test.year_rec
LANGUAGE SQL
VOLATILE
STRICT
AS $$
    WITH b AS (
      SELECT (p_known).close_gate_index AS oi,(p_known).close_gate_day AS od,
             pastafari_sql_tamil_test.gate_index_at_or_after((p_known).close_gate_day+5778)+1 AS hi
    ), c AS (
      SELECT j AS ci,pastafari_sql_tamil_test.gate_day(j) AS cd,oi,od
      FROM b,LATERAL pastafari_sql_tamil_test.numeric_series(oi+1,hi,1) AS g(j)
    ), v AS (
      SELECT *,cd-od AS len FROM c
      WHERE ci-oi>=6 AND cd-od BETWEEN 252 AND 5778
    ), n AS (
      SELECT *,row_number() OVER (ORDER BY len,ci) AS rn,count(*) OVER () AS cnt FROM v
    ), p AS (
      SELECT pastafari_sql_tamil_test.choose_rank(
        pastafari_sql_tamil_test.ask_bowl(pastafari_sql_tamil_test.sauce(p_calculation_day,(p_known).close_gate_day),1,11),
        max(cnt)::numeric) AS wanted FROM n
    )
    SELECT ROW((p_known).year_number+1,oi,ci,od,cd)::pastafari_sql_tamil_test.year_rec
    FROM n,p WHERE rn=wanted
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.previous_year(p_calculation_day numeric, p_known pastafari_sql_tamil_test.year_rec)
RETURNS pastafari_sql_tamil_test.year_rec
LANGUAGE SQL
VOLATILE
STRICT
AS $$
    WITH b AS (
      SELECT (p_known).open_gate_index AS ci,(p_known).open_gate_day AS cd,
             pastafari_sql_tamil_test.gate_index_at_or_before((p_known).open_gate_day-5778)-1 AS lo
    ), c AS (
      SELECT i AS oi,pastafari_sql_tamil_test.gate_day(i) AS od,ci,cd
      FROM b,LATERAL pastafari_sql_tamil_test.numeric_series(ci-1,lo,-1) AS g(i)
    ), v AS (
      SELECT *,cd-od AS len FROM c
      WHERE ci-oi>=6 AND cd-od BETWEEN 252 AND 5778
    ), n AS (
      SELECT *,row_number() OVER (ORDER BY len,oi DESC) AS rn,count(*) OVER () AS cnt FROM v
    ), p AS (
      SELECT pastafari_sql_tamil_test.choose_rank(
        pastafari_sql_tamil_test.ask_bowl(pastafari_sql_tamil_test.sauce(p_calculation_day,(p_known).open_gate_day),1,12),
        max(cnt)::numeric) AS wanted FROM n
    )
    SELECT ROW((p_known).year_number-1,oi,ci,od,cd)::pastafari_sql_tamil_test.year_rec
    FROM n,p WHERE rn=wanted
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.find_target_year(p_calculation_day numeric, p_target_day numeric)
RETURNS pastafari_sql_tamil_test.year_rec
LANGUAGE SQL
VOLATILE
STRICT
AS $$
    WITH RECURSIVE walk(step,y) AS (
      SELECT 0,pastafari_sql_tamil_test.year5000(p_calculation_day)
      UNION ALL
      SELECT step+1,
             CASE
               WHEN p_target_day>(y).close_gate_day THEN pastafari_sql_tamil_test.next_year(p_calculation_day,y)
               ELSE pastafari_sql_tamil_test.previous_year(p_calculation_day,y)
             END
      FROM walk
      WHERE NOT ((y).open_gate_day<p_target_day AND p_target_day<=(y).close_gate_day)
    )
    SELECT y FROM walk
    WHERE (y).open_gate_day<p_target_day AND p_target_day<=(y).close_gate_day
    ORDER BY step LIMIT 1
$$;
CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.choose_cutlet_count(p_sauce pastafari_sql_tamil_test.sauce_result,p_year pastafari_sql_tamil_test.year_rec)
RETURNS integer
LANGUAGE SQL
VOLATILE
STRICT
AS $$
    WITH c AS (
      SELECT greatest(0,least(17,((p_year).close_gate_index-(p_year).open_gate_index)::integer)-5) AS n
    ), r AS (
      SELECT pastafari_sql_tamil_test.choose_rank(pastafari_sql_tamil_test.ask_bowl(p_sauce,2,20),n::numeric)::integer AS rank1
      FROM c
    )
    SELECT 5+rank1 FROM r
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.choose_cutlet_partition(
    p_calculation_day numeric,p_sauce pastafari_sql_tamil_test.sauce_result,p_year pastafari_sql_tamil_test.year_rec,p_k integer)
RETURNS integer[]
LANGUAGE SQL
VOLATILE
STRICT
AS $$
    WITH x AS (
      SELECT ((p_year).close_gate_index-(p_year).open_gate_index)::integer AS gaps,
             pastafari_sql_tamil_test.exact_gate_index(p_calculation_day) AS g
    ), q AS (
      SELECT gaps,
             CASE WHEN g IS NOT NULL AND (p_year).open_gate_index<g AND g<(p_year).close_gate_index
                  THEN (g-(p_year).open_gate_index)::integer ELSE NULL END AS required
      FROM x
    ), c AS (
      SELECT gaps,required,
             pastafari_sql_tamil_test.cutlet_partition_count(gaps,p_k,0,required,false) AS cnt
      FROM q
    ), r AS (
      SELECT gaps,required,
             pastafari_sql_tamil_test.choose_rank(pastafari_sql_tamil_test.ask_bowl(p_sauce,2,21),cnt) AS rank1
      FROM c
    )
    SELECT pastafari_sql_tamil_test.unrank_cutlet_partition(gaps,p_k,required,rank1) FROM r
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.choose_cutlet_names(p_sauce pastafari_sql_tamil_test.sauce_result,p_k integer)
RETURNS integer[]
LANGUAGE SQL
VOLATILE
STRICT
AS $$
    WITH n AS (SELECT pastafari_sql_tamil_test.falling_factorial(17,p_k) AS cnt),
    r AS (SELECT pastafari_sql_tamil_test.choose_rank(pastafari_sql_tamil_test.ask_bowl(p_sauce,5,22),cnt) AS rank1 FROM n)
    SELECT pastafari_sql_tamil_test.unrank_distinct_indices(17,p_k,rank1) FROM r
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.choose_month_count(p_sauce pastafari_sql_tamil_test.sauce_result,p_year pastafari_sql_tamil_test.year_rec)
RETURNS integer
LANGUAGE SQL
VOLATILE
STRICT
AS $$
    WITH b AS (
      SELECT pastafari_sql_tamil_test.ceil_div((p_year).close_gate_day-(p_year).open_gate_day,123)::integer AS lo,
             least(47,div((p_year).close_gate_day-(p_year).open_gate_day,4)::integer) AS hi
    ), r AS (
      SELECT lo,pastafari_sql_tamil_test.choose_rank(pastafari_sql_tamil_test.ask_bowl(p_sauce,3,30),(hi-lo+1)::numeric)::integer AS rank1
      FROM b
    )
    SELECT lo+rank1-1 FROM r
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.choose_month_lengths(p_sauce pastafari_sql_tamil_test.sauce_result,p_year pastafari_sql_tamil_test.year_rec,p_k integer)
RETURNS integer[]
LANGUAGE SQL
VOLATILE
STRICT
AS $$
    WITH q AS (
      SELECT ((p_year).close_gate_day-(p_year).open_gate_day)::integer AS total
    ), c AS (
      SELECT total,pastafari_sql_tamil_test.bounded_count(total,p_k,4,123) AS cnt FROM q
    ), r AS (
      SELECT total,pastafari_sql_tamil_test.choose_rank(pastafari_sql_tamil_test.ask_bowl(p_sauce,3,31),cnt) AS rank1 FROM c
    )
    SELECT pastafari_sql_tamil_test.unrank_bounded_composition(total,p_k,4,123,rank1) FROM r
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.choose_month_weaving(
    p_sauce pastafari_sql_tamil_test.sauce_result,p_lengths integer[])
RETURNS integer[]
LANGUAGE SQL
VOLATILE
STRICT
AS $$
    SELECT pastafari_sql_tamil_test.weave_prepare(p_lengths);

    WITH RECURSIVE fam AS MATERIALIZED (
      SELECT family_id
      FROM pastafari_sql_tamil_test.weave_family_registry
      WHERE original_lengths=p_lengths
      LIMIT 1
    ), root AS MATERIALIZED (
      SELECT m.factor AS cnt,fam.family_id
      FROM fam
      JOIN pastafari_sql_tamil_test.weave_future_memo AS m
        ON m.family_id=fam.family_id AND m.opened_up_to=0 AND m.tail_length=0
    ), ranked AS MATERIALIZED (
      SELECT pastafari_sql_tamil_test.choose_rank(
               pastafari_sql_tamil_test.ask_bowl(p_sauce,4,32),cnt
             ) AS rank1,
             family_id
      FROM root
    ), u(step,remaining,opened,closed,active_tail,active_factor,r,chosen,family_id) AS (
      SELECT 0,p_lengths,0,0,0,1::numeric,rank1,NULL::integer,family_id
      FROM ranked
      UNION ALL
      SELECT u.step+1,
             pastafari_sql_tamil_test.array_decrement_at(u.remaining,pick.j),
             CASE WHEN pick.j=u.opened+1 THEN u.opened+1 ELSE u.opened END,
             CASE WHEN pick.j<=u.opened AND u.remaining[pick.j]=1 THEN u.closed+1 ELSE u.closed END,
             CASE WHEN pick.j=u.opened+1 THEN u.active_tail+u.remaining[pick.j]-1 ELSE u.active_tail-1 END,
             pick.next_active_factor,
             u.r-pick.previous_blocks,
             pick.j,
             u.family_id
      FROM u
      CROSS JOIN LATERAL (
        WITH RECURSIVE active AS (
          SELECT g.j,u.remaining[g.j] AS rem,
                 sum(u.remaining[g.j]) OVER (ORDER BY g.j ROWS UNBOUNDED PRECEDING)::numeric AS prefix_total
          FROM generate_series(u.closed+1,u.opened) AS g(j)
        ), suffix(j,product_total,product_minus_one) AS (
          SELECT a.j,a.prefix_total,a.prefix_total-1 FROM active a WHERE a.j=u.opened
          UNION ALL
          SELECT a.j,a.prefix_total*s.product_total,(a.prefix_total-1)*s.product_minus_one
          FROM suffix s JOIN active a ON a.j=s.j-1
        ), shared AS MATERIALIZED (
          SELECT
            CASE WHEN u.active_tail>0 THEN (
              SELECT m.factor FROM pastafari_sql_tamil_test.weave_future_memo AS m
              WHERE m.family_id=u.family_id AND m.opened_up_to=u.opened AND m.tail_length=u.active_tail-1
            ) END AS active_future,
            CASE WHEN u.opened<array_length(p_lengths,1) THEN (
              SELECT m.factor FROM pastafari_sql_tamil_test.weave_future_memo AS m
              WHERE m.family_id=u.family_id AND m.opened_up_to=u.opened+1
                AND m.tail_length=u.active_tail+u.remaining[u.opened+1]-1
            ) END AS opening_future
        ), active_candidates AS (
          SELECT a.j,
                 div(u.active_factor
                   * CASE WHEN a.j=u.closed+1 THEN a.rem::numeric ELSE (a.rem-1)::numeric END
                   * COALESCE(s.product_total,1::numeric),
                   u.active_tail::numeric*COALESCE(s.product_minus_one,1::numeric)) AS next_active_factor
          FROM active a
          LEFT JOIN suffix s ON s.j=CASE WHEN a.j=u.closed+1 THEN a.j+1 ELSE a.j END
          WHERE a.rem>1 OR a.j=u.closed+1
        ), active_blocks AS (
          SELECT a.j,a.next_active_factor,a.next_active_factor*sh.active_future AS block
          FROM active_candidates a CROSS JOIN shared sh
        ), opening_candidate AS (
          SELECT u.opened+1 AS j,
                 u.active_factor*pastafari_sql_tamil_test.binomial_exact(
                   u.active_tail+u.remaining[u.opened+1]-2,u.remaining[u.opened+1]-2) AS next_active_factor
          WHERE u.opened<array_length(p_lengths,1) AND u.remaining[u.opened+1]>=2
        ), opening_block AS (
          SELECT o.j,o.next_active_factor,o.next_active_factor*sh.opening_future AS block
          FROM opening_candidate o CROSS JOIN shared sh
        ), candidates AS (
          SELECT * FROM active_blocks UNION ALL SELECT * FROM opening_block
        ), ranges AS (
          SELECT j,next_active_factor,block,
                 COALESCE(sum(block) OVER (ORDER BY j ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING),0::numeric) AS previous_blocks,
                 sum(block) OVER (ORDER BY j ROWS UNBOUNDED PRECEDING) AS through_block
          FROM candidates
        )
        SELECT j,next_active_factor,previous_blocks
        FROM ranges
        WHERE u.r>previous_blocks AND u.r<=through_block
        ORDER BY j LIMIT 1
      ) pick
      WHERE EXISTS (SELECT 1 FROM unnest(u.remaining) x(v) WHERE v<>0)
    )
    SELECT array_agg(chosen ORDER BY step) FILTER (WHERE step>0)
    FROM u;
$$;
CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.choose_month_names(p_sauce pastafari_sql_tamil_test.sauce_result,p_k integer)
RETURNS integer[]
LANGUAGE SQL
VOLATILE
STRICT
AS $$
    WITH n AS (SELECT pastafari_sql_tamil_test.falling_factorial(47,p_k) AS cnt),
    r AS (SELECT pastafari_sql_tamil_test.choose_rank(pastafari_sql_tamil_test.ask_bowl(p_sauce,5,33),cnt) AS rank1 FROM n)
    SELECT pastafari_sql_tamil_test.unrank_distinct_indices(47,p_k,rank1) FROM r
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.build_year_structure(p_calculation_day numeric,p_year pastafari_sql_tamil_test.year_rec)
RETURNS pastafari_sql_tamil_test.year_structure
LANGUAGE SQL
VOLATILE
STRICT
AS $$
    WITH r AS MATERIALIZED (
      SELECT pastafari_sql_tamil_test.sauce(p_calculation_day,(p_year).open_gate_day+1) AS sauce_data
    ), k AS MATERIALIZED (
      SELECT sauce_data,pastafari_sql_tamil_test.choose_cutlet_count(sauce_data,p_year) AS cutlet_count FROM r
    ), cp AS MATERIALIZED (
      SELECT sauce_data,cutlet_count,
             pastafari_sql_tamil_test.choose_cutlet_partition(p_calculation_day,sauce_data,p_year,cutlet_count) AS cutlet_partition,
             pastafari_sql_tamil_test.choose_cutlet_names(sauce_data,cutlet_count) AS cutlet_names
      FROM k
    ), mc AS MATERIALIZED (
      SELECT *,pastafari_sql_tamil_test.choose_month_count(sauce_data,p_year) AS month_count FROM cp
    ), ml AS MATERIALIZED (
      SELECT *,pastafari_sql_tamil_test.choose_month_lengths(sauce_data,p_year,month_count) AS month_lengths FROM mc
    ), mw AS MATERIALIZED (
      SELECT *,pastafari_sql_tamil_test.choose_month_weaving(sauce_data,month_lengths) AS month_weaving FROM ml
    ), mn AS MATERIALIZED (
      SELECT *,pastafari_sql_tamil_test.choose_month_names(sauce_data,month_count) AS month_names FROM mw
    )
    SELECT ROW(p_year,cutlet_count,cutlet_partition,cutlet_names,month_count,month_lengths,month_weaving,month_names)::pastafari_sql_tamil_test.year_structure
    FROM mn
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil_test.calendar_date(p_calculation_day numeric,p_target_day numeric)
RETURNS pastafari_sql_tamil_test.calendar_result_text
LANGUAGE SQL
VOLATILE
STRICT
AS $$
    WITH y AS MATERIALIZED (
      SELECT pastafari_sql_tamil_test.find_target_year(p_calculation_day,p_target_day) AS yr
    ), s AS MATERIALIZED (
      SELECT yr,pastafari_sql_tamil_test.build_year_structure(p_calculation_day,yr) AS st FROM y
    ), cutlets AS MATERIALIZED (
      SELECT ord::integer AS cutlet_id,
             COALESCE(sum(part) OVER (ORDER BY ord ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING),0)::numeric AS prev_gaps,
             sum(part) OVER (ORDER BY ord)::numeric AS upto_gaps,
             part,yr,st
      FROM s,unnest((st).cutlet_partition) WITH ORDINALITY AS u(part,ord)
    ), chosen AS MATERIALIZED (
      SELECT cutlet_id,
             pastafari_sql_tamil_test.gate_day((yr).open_gate_index+prev_gaps)+1 AS first_day,
             yr,st
      FROM cutlets
      WHERE pastafari_sql_tamil_test.gate_day((yr).open_gate_index+prev_gaps)+1<=p_target_day
        AND p_target_day<=pastafari_sql_tamil_test.gate_day((yr).open_gate_index+upto_gaps)
      ORDER BY cutlet_id LIMIT 1
    ), month_data AS MATERIALIZED (
      SELECT cutlet_id,first_day,yr,st,
             (p_target_day-((yr).open_gate_day+1))::integer AS offset0
      FROM chosen
    ), final_data AS MATERIALIZED (
      SELECT cutlet_id,first_day,yr,st,offset0,
             (st).month_weaving[offset0+1] AS month_id
      FROM month_data
    )
    SELECT ROW(
      (yr).year_number,
      pastafari_sql_tamil.source_name('CUTLET',(st).cutlet_name_indices[cutlet_id]),
      p_target_day-first_day+1,
      pastafari_sql_tamil.source_name('MONTH',(st).month_name_indices[month_id]),
      (SELECT count(*)::numeric FROM unnest((st).month_weaving[1:offset0+1]) AS q(v) WHERE v=month_id)
    )::pastafari_sql_tamil_test.calendar_result_text
    FROM final_data
$$;
