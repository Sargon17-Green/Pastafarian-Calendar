-- Stage 2, slice 5: six-bowl permutation and initial values.
-- Standalone production implementation; no reference or test schema dependency.
-- Ranks are one-based, 1..720; all arithmetic is exact integer/numeric.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.bowl_factorial(p_n integer)
RETURNS integer LANGUAGE SQL IMMUTABLE STRICT AS $$
    SELECT (ARRAY[1,1,2,6,24,120,720])[p_n+1]
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.bowl_order_from_number(p_rank1 integer)
RETURNS integer[] LANGUAGE SQL IMMUTABLE STRICT AS $$
    WITH RECURSIVE factoradic(pos,rank0,remaining,ordered) AS (
        SELECT 1,p_rank1-1,ARRAY[1,2,3,4,5,6]::integer[],ARRAY[]::integer[]
        WHERE p_rank1 BETWEEN 1 AND 720
        UNION ALL
        SELECT pos+1,
               rank0 % pastafari_sql_tamil.bowl_factorial(6-pos),
               array_remove(remaining,
                   remaining[(rank0 / pastafari_sql_tamil.bowl_factorial(6-pos))+1]),
               array_append(ordered,
                   remaining[(rank0 / pastafari_sql_tamil.bowl_factorial(6-pos))+1])
        FROM factoradic
        WHERE pos <= 6
    )
    SELECT ordered FROM factoradic WHERE pos=7
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.bowl_order_from_drop(p_drop numeric)
RETURNS integer[] LANGUAGE SQL IMMUTABLE STRICT AS $$
    SELECT pastafari_sql_tamil.bowl_order_from_number(
        (pastafari_sql_tamil.regular_mod(p_drop-1,720::numeric)+1)::integer)
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.initial_bowls(
    p_counts pastafari_sql_tamil.work_counts
)
RETURNS numeric[] LANGUAGE SQL IMMUTABLE STRICT AS $$
    WITH primes(id,prime) AS (
        VALUES (1,17::numeric),(2,19::numeric),(3,23::numeric),
               (4,29::numeric),(5,31::numeric),(6,37::numeric)
    ), ingredients AS (
        SELECT id,
            (p_counts).action + (p_counts).target*id
            + (p_counts).distance + (p_counts).connection
            + (p_counts).direction + prime*prime AS mix
        FROM primes
    )
    SELECT array_agg(pastafari_sql_tamil.save_value(mix*mix+id) ORDER BY id)
    FROM ingredients
$$;
