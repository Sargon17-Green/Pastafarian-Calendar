-- Stage 2 slice 4: visible 46-drop chain. Production-only PostgreSQL SQL.
-- Dependencies: exact work counts, immutable 46 stone states, seven hidden drops.
-- 11 ordered SAVE grinds per visible drop; no reference/test schema.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.visible_grind_kind(p_step integer)
RETURNS integer LANGUAGE SQL IMMUTABLE STRICT AS $$
    SELECT (ARRAY[1,2,3,4,5,1,2,3,4,5,1])[p_step]
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.visible_grind_coeff(p_step integer, p_column integer)
RETURNS integer LANGUAGE SQL IMMUTABLE STRICT AS $$
    SELECT CASE p_column
      WHEN 1 THEN (ARRAY[3,5,7,11,13,17,19,23,29,31,37])[p_step]
      WHEN 2 THEN (ARRAY[5,7,11,13,17,19,23,29,31,37,41])[p_step]
      WHEN 3 THEN (ARRAY[7,11,13,17,19,23,29,31,37,41,43])[p_step]
      WHEN 4 THEN (ARRAY[11,13,17,19,23,29,31,37,41,43,47])[p_step]
      ELSE NULL::integer
    END
$$;

-- Prefix must contain precisely the i-1 prior visible drops.
-- Positions i-1, i-3 and i-7 <= 0 are resolved through hidden drops.
-- Every stone term in this function uses the same p_i. Materialize that exact
-- stone state once instead of rebuilding its recursive 46-step prefix for each
-- of the five seed terms and eleven grind terms. No persistent cache is used.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.one_visible_drop(
    p_i integer,p_counts pastafari_sql_tamil.work_counts,p_prefix numeric[]
)
RETURNS numeric LANGUAGE SQL IMMUTABLE STRICT AS $$
    WITH RECURSIVE previous AS (
        SELECT
            CASE WHEN p_i-1>=1 THEN p_prefix[p_i-1]
                ELSE pastafari_sql_tamil.hidden_drop(2-p_i,p_counts) END AS p1,
            CASE WHEN p_i-3>=1 THEN p_prefix[p_i-3]
                ELSE pastafari_sql_tamil.hidden_drop(4-p_i,p_counts) END AS p3,
            CASE WHEN p_i-7>=1 THEN p_prefix[p_i-7]
                ELSE pastafari_sql_tamil.hidden_drop(8-p_i,p_counts) END AS p7
        WHERE p_i BETWEEN 1 AND 46
          AND coalesce(array_length(p_prefix,1),0)=p_i-1
    ), stone AS MATERIALIZED (
        SELECT pastafari_sql_tamil.stone_state(p_i) AS stone_data
        FROM previous
    ), seed AS (
        SELECT pastafari_sql_tamil.save_value(
            (stone_data).wheat*(p_counts).action
            + (stone_data).barley*(p_counts).target
            + (stone_data).salt*(p_counts).distance
            + (stone_data).bitter*(p_counts).connection
            + (stone_data).red*(p_counts).direction
            + p1+3*p3+5*p7+p_i
        ) AS x,p1,p3,p7,
          (stone_data).wheat AS wheat,
          (stone_data).barley AS barley,
          (stone_data).salt AS salt,
          (stone_data).bitter AS bitter,
          (stone_data).red AS red
        FROM previous CROSS JOIN stone
    ), chain(step,x,p1,p3,p7,wheat,barley,salt,bitter,red) AS (
        SELECT 0,x,p1,p3,p7,wheat,barley,salt,bitter,red FROM seed
        UNION ALL
        SELECT step+1,pastafari_sql_tamil.save_value(
            x*x
            + pastafari_sql_tamil.visible_grind_coeff(step+1,1)*x
            + pastafari_sql_tamil.visible_grind_coeff(step+1,2)*p1
            + pastafari_sql_tamil.visible_grind_coeff(step+1,3)*p3
            + pastafari_sql_tamil.visible_grind_coeff(step+1,4)*p7
            + CASE pastafari_sql_tamil.visible_grind_kind(step+1)
                WHEN 1 THEN wheat
                WHEN 2 THEN barley
                WHEN 3 THEN salt
                WHEN 4 THEN bitter
                WHEN 5 THEN red
                ELSE NULL::numeric
              END
        ),p1,p3,p7,wheat,barley,salt,bitter,red
        FROM chain WHERE step<11
    )
    SELECT x FROM chain WHERE step=11
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.visible_drops(
    p_counts pastafari_sql_tamil.work_counts
)
RETURNS numeric[] LANGUAGE SQL IMMUTABLE STRICT AS $$
    WITH RECURSIVE drops(i,vals) AS (
        SELECT 0,ARRAY[]::numeric[]
        UNION ALL
        SELECT i+1,array_append(vals,
            pastafari_sql_tamil.one_visible_drop(i+1,p_counts,vals))
        FROM drops WHERE i<46
    )
    SELECT vals FROM drops WHERE i=46
$$;
