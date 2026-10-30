-- Stage 2 Slice 7: twelve post-stir rounds of six exact numeric bowls.
-- தமிழ்: கலக்கிய பிறகான பன்னிரண்டு சுற்றுகள்; production is reference-independent.
-- Preconditions: six one-based, integral SAVE values and stir index 1..12.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.post_stir_round(
    p_bowls numeric[], p_stir integer
)
RETURNS numeric[] LANGUAGE SQL IMMUTABLE STRICT AS $$
    WITH seed AS (
        SELECT pastafari_sql_tamil.save_value(
            (SELECT sum(v) FROM unnest(p_bowls) AS x(v)) + 149*p_stir
        ) AS s
        WHERE p_stir BETWEEN 1 AND 12
          AND array_ndims(p_bowls) = 1
          AND array_lower(p_bowls,1) = 1
          AND array_length(p_bowls,1) = 6
          AND NOT EXISTS (
              SELECT 1 FROM unnest(p_bowls) AS x(v)
              WHERE v IS NULL OR v <> trunc(v)
                 OR v < 1 OR v > pastafari_sql_tamil.save_modulus()
          )
    ), ordering AS (
        SELECT s, pastafari_sql_tamil.bowl_order_from_number(
            (pastafari_sql_tamil.regular_mod(s-1,720)+1)::integer
        ) AS ord
        FROM seed
    ), positions AS (
        SELECT id, array_position(ord,id) AS pos,ord,s
        FROM ordering CROSS JOIN generate_series(1,6) AS g(id)
    ), neighbors AS (
        SELECT id,pos,s,
            ord[CASE WHEN pos=1 THEN 6 ELSE pos-1 END] AS prev_id,
            ord[CASE WHEN pos=6 THEN 1 ELSE pos+1 END] AS next_id
        FROM positions
    ), mixtures AS (
        SELECT id,
          p_bowls[id] + 3*p_bowls[prev_id] + 5*p_bowls[next_id]
          + s + p_stir + pos*pos AS mix,
          prev_id,next_id
        FROM neighbors
    )
    SELECT array_agg(
        pastafari_sql_tamil.save_value(
            mix*mix + 7*p_bowls[prev_id]*p_bowls[next_id]
        ) ORDER BY id
    )
    FROM mixtures
$$;
