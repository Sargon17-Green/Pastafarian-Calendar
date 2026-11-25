CREATE SCHEMA qa_legacy;
CREATE OR REPLACE FUNCTION qa_legacy.one_visible_drop(
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
    ), seed AS (
        SELECT pastafari_sql_tamil.save_value(
            pastafari_sql_tamil.stone_value(p_i,1)*(p_counts).action
            + pastafari_sql_tamil.stone_value(p_i,2)*(p_counts).target
            + pastafari_sql_tamil.stone_value(p_i,3)*(p_counts).distance
            + pastafari_sql_tamil.stone_value(p_i,4)*(p_counts).connection
            + pastafari_sql_tamil.stone_value(p_i,5)*(p_counts).direction
            + p1+3*p3+5*p7+p_i
        ) AS x,p1,p3,p7 FROM previous
    ), chain(step,x,p1,p3,p7) AS (
        SELECT 0,x,p1,p3,p7 FROM seed
        UNION ALL
        SELECT step+1,pastafari_sql_tamil.save_value(
            x*x
            + pastafari_sql_tamil.visible_grind_coeff(step+1,1)*x
            + pastafari_sql_tamil.visible_grind_coeff(step+1,2)*p1
            + pastafari_sql_tamil.visible_grind_coeff(step+1,3)*p3
            + pastafari_sql_tamil.visible_grind_coeff(step+1,4)*p7
            + pastafari_sql_tamil.stone_value(
                p_i,pastafari_sql_tamil.visible_grind_kind(step+1)
            )
        ),p1,p3,p7
        FROM chain WHERE step<11
    )
    SELECT x FROM chain WHERE step=11
$$;
CREATE OR REPLACE FUNCTION qa_legacy.visible_drops(
    p_counts pastafari_sql_tamil.work_counts
)
RETURNS numeric[] LANGUAGE SQL IMMUTABLE STRICT AS $$
    WITH RECURSIVE drops(i,vals) AS (
        SELECT 0,ARRAY[]::numeric[]
        UNION ALL
        SELECT i+1,array_append(vals,
            qa_legacy.one_visible_drop(i+1,p_counts,vals))
        FROM drops WHERE i<46
    )
    SELECT vals FROM drops WHERE i=46
$$;
