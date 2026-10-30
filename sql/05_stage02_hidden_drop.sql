-- Stage 2 slice 3. Production-only seven hidden drops.
-- Canonical arithmetic: coefficient rows and seven ordered grinds, SAVE at
-- initial aggregation and after every grind. No reference or test namespace.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.hidden_drop(
    p_k integer, p_counts pastafari_sql_tamil.work_counts
)
RETURNS numeric LANGUAGE SQL IMMUTABLE STRICT AS $$
    WITH RECURSIVE coeff AS (
        SELECT * FROM (VALUES
            (1,3,4,6,8),(2,5,7,10,12),(3,7,10,14,16),
            (4,9,13,18,20),(5,11,16,22,24),
            (6,13,19,26,28),(7,15,22,30,32)
        ) AS v(k,a,b,c,d)
        WHERE k = p_k
    ), init AS (
        SELECT pastafari_sql_tamil.save_value(
            (p_counts).action
            + a*(p_counts).target
            + b*(p_counts).distance
            + c*(p_counts).connection
            + d*(p_counts).direction
            + pastafari_sql_tamil.stone_value(p_k,1)
            + pastafari_sql_tamil.stone_value(p_k,2)
            + pastafari_sql_tamil.stone_value(p_k,3)
            + pastafari_sql_tamil.stone_value(p_k,4)
            + pastafari_sql_tamil.stone_value(p_k,5)
        ) AS x
        FROM coeff
    ), grind_chain(grind,x) AS (
        SELECT 0, x FROM init
        UNION ALL
        SELECT grind+1,
            pastafari_sql_tamil.save_value(
                x*x + 3*x
                + pastafari_sql_tamil.stone_value(
                    p_k, (ARRAY[1,2,3,4,5,1,2])[grind+1]
                )
                + grind + 1
            )
        FROM grind_chain
        WHERE grind < 7
    )
    SELECT x FROM grind_chain WHERE grind = 7
$$;
