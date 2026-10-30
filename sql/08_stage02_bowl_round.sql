-- Stage 2 slice 6: independent production bowl mixing for one of 46 stones.
-- தமிழ்: ஒவ்வொரு கிண்ணச் சுற்றும் துல்லியமான numeric முழு எண்களால் கணக்கிடப்படுகிறது.
-- Requires 03 (exact arithmetic), 04 (stone states), and 07 (permutations).
-- No reference schema, cache, floating point, or global mutable state.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.stir_stone_kind_by_position(p_position integer)
RETURNS integer LANGUAGE SQL IMMUTABLE STRICT AS $$
    SELECT (ARRAY[1,2,3,4,5,1]::integer[])[p_position]
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.bowl_round(
    p_bowls numeric[], p_drop numeric, p_i integer
)
RETURNS numeric[] LANGUAGE SQL STABLE STRICT AS $$
    WITH ordering AS (
        SELECT pastafari_sql_tamil.bowl_order_from_drop(p_drop) AS ord
        WHERE p_i BETWEEN 1 AND 46
          AND p_drop = trunc(p_drop)
          AND p_drop <> 'NaN'::numeric
          AND array_ndims(p_bowls) = 1
          AND array_lower(p_bowls,1) = 1
          AND array_length(p_bowls,1) = 6
          AND array_position(p_bowls,NULL::numeric) IS NULL
    ), positions AS (
        SELECT id,array_position(ord,id) AS pos,ord
        FROM ordering CROSS JOIN generate_series(1,6) AS g(id)
    ), neighbors AS (
        SELECT id,pos,
          ord[CASE WHEN pos=1 THEN 6 ELSE pos-1 END] AS prev_id,
          ord[CASE WHEN pos=6 THEN 1 ELSE pos+1 END] AS next_id
        FROM positions
    ), poured AS (
        SELECT id,pos,prev_id,next_id,
          CASE pos
            WHEN 1 THEN pastafari_sql_tamil.save_value(
                p_drop*p_drop + pastafari_sql_tamil.stone_value(p_i,1)*p_bowls[id]+3*p_i)
            WHEN 2 THEN pastafari_sql_tamil.save_value(
                p_drop*p_drop + pastafari_sql_tamil.stone_value(p_i,2)*p_bowls[id]+5*p_i)
            WHEN 3 THEN pastafari_sql_tamil.save_value(
                p_drop*p_drop + pastafari_sql_tamil.stone_value(p_i,3)*p_bowls[id]+7*p_i)
            ELSE 0::numeric
          END AS pour
        FROM neighbors
    ), mixtures AS (
        SELECT id,pos,prev_id,next_id,
          p_bowls[id] + 2*p_bowls[prev_id] + 3*p_bowls[next_id]
          + pour + p_drop
          + pastafari_sql_tamil.stone_value(
              p_i,pastafari_sql_tamil.stir_stone_kind_by_position(pos)
            ) AS mix
        FROM poured
    )
    SELECT array_agg(
      pastafari_sql_tamil.save_value(
        mix*mix + 5*p_bowls[prev_id]*p_bowls[next_id] + p_i*pos)
      ORDER BY id
    )
    FROM mixtures
$$;
