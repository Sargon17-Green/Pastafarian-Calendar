-- Stage 2 Slice 10: bounded rank selection; SQL production only.
-- தமிழ்: குறுகிய மற்றும் விரிந்த தரவரிசைத் தேர்வு.
-- Preconditions: positive integral n, valid answer stream.
-- Independent layout: validate, pack weighted base-M digits, and select a rank.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.choose_rank_short(
 p_stream pastafari_sql_tamil.answer_stream,p_n numeric
) RETURNS numeric LANGUAGE SQL IMMUTABLE STRICT AS $sql$
 WITH valid AS MATERIALIZED (
   SELECT pastafari_sql_tamil.save_modulus() AS m,p_n AS n,
     pastafari_sql_tamil.answer_at(p_stream,0) AS x,
     (p_stream).direction_step AS direction
   WHERE p_n=trunc(p_n) AND p_n>=1
     AND p_n<=pastafari_sql_tamil.save_modulus()
     AND (p_stream).direction_step IN (-1,1)
     AND (p_stream).first_value=trunc((p_stream).first_value)
     AND (p_stream).first_value BETWEEN 1 AND pastafari_sql_tamil.save_modulus()
 ), bounded AS (
   SELECT n,x,direction,div(m,n)*n AS last_accepted FROM valid
 ), drawn AS (
   SELECT n,CASE WHEN x<=last_accepted THEN x
     WHEN direction=1 THEN 1::numeric ELSE last_accepted END AS chosen
   FROM bounded
 )
 SELECT 1+pastafari_sql_tamil.regular_mod(chosen-1,n) FROM drawn
$sql$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.choose_rank_wide(
 p_stream pastafari_sql_tamil.answer_stream,p_n numeric
) RETURNS numeric LANGUAGE SQL IMMUTABLE STRICT AS $sql$
 WITH RECURSIVE valid AS MATERIALIZED (
   SELECT pastafari_sql_tamil.save_modulus() AS m,p_n AS n,
     (p_stream).direction_step AS direction
   WHERE p_n=trunc(p_n) AND p_n>pastafari_sql_tamil.save_modulus()
     AND (p_stream).direction_step IN (-1,1)
     AND (p_stream).first_value=trunc((p_stream).first_value)
     AND (p_stream).first_value BETWEEN 1 AND pastafari_sql_tamil.save_modulus()
 ), scale(k,space) AS (
   SELECT 1,m FROM valid
   UNION ALL
   SELECT scale.k+1,scale.space*valid.m
   FROM scale CROSS JOIN valid WHERE scale.space<valid.n
 ), span AS (
   SELECT k,space FROM scale
   WHERE space>=(SELECT n FROM valid)
   ORDER BY k LIMIT 1
 ), packed AS (
   SELECT valid.n,valid.direction,span.space,
     1::numeric+sum((pastafari_sql_tamil.answer_at(p_stream,g.j)-1)
        *power(valid.m,g.j::numeric)) AS ticket
   FROM span CROSS JOIN valid
   CROSS JOIN LATERAL generate_series(0,span.k-1) AS g(j)
   GROUP BY valid.n,valid.direction,span.space
 ), picked AS (
   SELECT n,CASE WHEN ticket<=div(space,n)*n THEN ticket
     WHEN direction=1 THEN 1::numeric ELSE div(space,n)*n END AS chosen
   FROM packed
 )
 SELECT 1+pastafari_sql_tamil.regular_mod(chosen-1,n) FROM picked
$sql$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.choose_rank(
 p_stream pastafari_sql_tamil.answer_stream,p_n numeric
) RETURNS numeric LANGUAGE SQL IMMUTABLE STRICT AS $sql$
 SELECT CASE WHEN p_n=trunc(p_n) AND p_n>=1 THEN
   CASE WHEN p_n<=pastafari_sql_tamil.save_modulus()
     THEN pastafari_sql_tamil.choose_rank_short(p_stream,p_n)
     ELSE pastafari_sql_tamil.choose_rank_wide(p_stream,p_n)
   END ELSE NULL::numeric END
$sql$;
