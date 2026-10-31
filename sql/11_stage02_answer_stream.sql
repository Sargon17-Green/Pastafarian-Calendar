-- Stage 2 Slice 9: production answer stream after the sauce.
-- தமிழ்: ஆறு கிண்ணங்களுக்கான கேள்வி மற்றும் பதில் தொடர்.
-- Depends on sql/03..10; no reference/test schema is loaded or invoked.
CREATE TYPE pastafari_sql_tamil.answer_stream AS (
  first_value numeric,
  direction_step integer
);

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.next_bowl_in_drop46_order(
  p_sauce pastafari_sql_tamil.sauce_result,p_queried integer
)
RETURNS integer LANGUAGE SQL IMMUTABLE STRICT AS $$
 WITH candidate AS (
   SELECT (p_sauce).order_at_drop_46 AS ord
 ), valid AS (
   SELECT ord,array_position(ord,p_queried) AS at_pos FROM candidate
   WHERE p_queried BETWEEN 1 AND 6
     AND array_ndims(ord)=1 AND array_lower(ord,1)=1 AND array_length(ord,1)=6
     AND (SELECT array_agg(x ORDER BY x)=ARRAY[1,2,3,4,5,6]::integer[]
          FROM unnest(ord) AS u(x))
 )
 SELECT ord[CASE WHEN at_pos=6 THEN 1 ELSE at_pos+1 END] FROM valid
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.ask_bowl(
  p_sauce pastafari_sql_tamil.sauce_result,p_bowl integer,p_seal integer
)
RETURNS pastafari_sql_tamil.answer_stream LANGUAGE SQL IMMUTABLE STRICT AS $$
 WITH valid AS (
   SELECT (p_sauce).bowls AS b,
     pastafari_sql_tamil.next_bowl_in_drop46_order(p_sauce,p_bowl) AS next_id
   WHERE p_bowl BETWEEN 1 AND 6
     AND array_ndims((p_sauce).bowls)=1
     AND array_lower((p_sauce).bowls,1)=1
     AND array_length((p_sauce).bowls,1)=6
     AND NOT EXISTS (
       SELECT 1 FROM unnest((p_sauce).bowls) AS x(v)
       WHERE v IS NULL OR v<>trunc(v) OR v<1
         OR v>pastafari_sql_tamil.save_modulus()
     )
 ), mix AS (
   SELECT b,next_id,b[p_bowl]+p_seal+181 AS z
   FROM valid WHERE next_id IS NOT NULL
 ), first_step AS (
   SELECT b,pastafari_sql_tamil.save_value(z*z+179*b[next_id]+p_seal) AS first_value
   FROM mix
 ), direction_mix AS (
   SELECT b,first_value,first_value+p_seal+194 AS z FROM first_step
 ), direction_step AS (
   SELECT first_value,
     pastafari_sql_tamil.save_value(z*z+193*first_value+197*b[6]) AS direction_number
   FROM direction_mix
 )
 SELECT ROW(first_value,
   CASE WHEN pastafari_sql_tamil.regular_mod(direction_number,2)=1
        THEN 1 ELSE -1 END
 )::pastafari_sql_tamil.answer_stream FROM direction_step
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.answer_at(
  p_stream pastafari_sql_tamil.answer_stream,p_k numeric
)
RETURNS numeric LANGUAGE SQL IMMUTABLE STRICT AS $$
 SELECT pastafari_sql_tamil.save_value(
   (p_stream).first_value+(p_stream).direction_step*p_k)
 WHERE p_k=trunc(p_k)
   AND (p_stream).first_value=trunc((p_stream).first_value)
   AND (p_stream).first_value BETWEEN 1 AND pastafari_sql_tamil.save_modulus()
   AND (p_stream).direction_step IN (-1,1)
$$;
