-- Stage 2 Slice 8: production composition of all bowl rounds and all twelve post-stir rounds.
-- தமிழ்: 46 கிண்ணச் சுற்றுகளும் பின்னர் 12 கலக்குச் சுற்றுகளும்.
-- Requires 03..09 in order. Does not load or call the normative/test schema.
CREATE TYPE pastafari_sql_tamil.sauce_result AS (
    bowls numeric[],
    order_at_drop_46 integer[]
);

-- This intentionally validates the externally callable starting state.
-- Do not silently accept an improperly indexed or out-of-SAVE-range array.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.post_stir_chain(p_bowls numeric[])
RETURNS numeric[] LANGUAGE SQL IMMUTABLE STRICT AS $$
    WITH RECURSIVE chain(stir, bowls) AS (
        SELECT 0, p_bowls
        WHERE array_ndims(p_bowls) = 1
          AND array_lower(p_bowls,1) = 1
          AND array_length(p_bowls,1) = 6
          AND NOT EXISTS (
              SELECT 1 FROM unnest(p_bowls) AS b(v)
              WHERE v IS NULL OR v <> trunc(v)
                OR v < 1 OR v > pastafari_sql_tamil.save_modulus()
          )
        UNION ALL
        SELECT stir+1, pastafari_sql_tamil.post_stir_round(bowls,stir+1)
        FROM chain
        WHERE stir < 12
    )
    SELECT bowls FROM chain WHERE stir = 12
$$;

-- The last 46-drop permutation is retained independently of the 12 subsequent
-- stirs.  The bowl vector, however, is the state AFTER all twelve stirs.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.sauce(
    p_calculation_day numeric, p_target_day numeric
)
RETURNS pastafari_sql_tamil.sauce_result
LANGUAGE SQL STABLE STRICT AS $$
    WITH RECURSIVE input_counts AS (
        SELECT pastafari_sql_tamil.work_counts(
            p_calculation_day,p_target_day
        ) AS counts
    ), input_state AS (
        SELECT pastafari_sql_tamil.initial_bowls(counts) AS first_bowls,
               pastafari_sql_tamil.visible_drops(counts) AS drops
        FROM input_counts
        WHERE counts IS NOT NULL
    ), bowl_steps(step,bowls,drops) AS (
        SELECT 0,first_bowls,drops FROM input_state
        UNION ALL
        SELECT step+1,
               pastafari_sql_tamil.bowl_round(bowls,drops[step+1],step+1),
               drops
        FROM bowl_steps
        WHERE step < 46
    )
    SELECT ROW(
        pastafari_sql_tamil.post_stir_chain(bowls),
        pastafari_sql_tamil.bowl_order_from_drop(drops[46])
    )::pastafari_sql_tamil.sauce_result
    FROM bowl_steps
    WHERE step = 46
$$;
