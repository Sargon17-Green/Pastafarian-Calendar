BEGIN;

CREATE TEMP TABLE saved_sum_discriminator_assertions (
    test_name text PRIMARY KEY,
    ok boolean NOT NULL CHECK (ok)
);

WITH input AS MATERIALIZED (
    SELECT ARRAY[1::numeric,2::numeric,3::numeric,4::numeric,5::numeric,6::numeric] AS old_bowls,
           1::integer AS stir
), raw_terms AS MATERIALIZED (
    SELECT old_bowls,
           stir,
           (SELECT sum(v) FROM unnest(old_bowls) AS q(v)) AS raw_sum
    FROM input
), terms AS MATERIALIZED (
    SELECT old_bowls,
           stir,
           raw_sum,
           pastafari_sql_tamil_test.save_value(raw_sum + 149*stir) AS saved_sum
    FROM raw_terms
), ordered AS MATERIALIZED (
    SELECT old_bowls,
           stir,
           raw_sum,
           saved_sum,
           pastafari_sql_tamil_test.bowl_order_from_number(
               (pastafari_sql_tamil_test.regular_mod(saved_sum-1,720)+1)::integer
           ) AS order_arr
    FROM terms
), neighbors AS MATERIALIZED (
    SELECT old_bowls,
           stir,
           raw_sum,
           saved_sum,
           order_arr,
           id,
           array_position(order_arr,id) AS pos,
           order_arr[pastafari_sql_tamil_test.wrap1(array_position(order_arr,id)-1,6)] AS prev_id,
           order_arr[pastafari_sql_tamil_test.wrap1(array_position(order_arr,id)+1,6)] AS next_id
    FROM ordered
    CROSS JOIN generate_series(1,6) AS g(id)
), calc AS MATERIALIZED (
    SELECT old_bowls,
           stir,
           raw_sum,
           saved_sum,
           order_arr,
           id,
           pos,
           prev_id,
           next_id,
           old_bowls[id]
             + 3*old_bowls[prev_id]
             + 5*old_bowls[next_id]
             + saved_sum
             + stir
             + pos*pos AS u_saved,
           old_bowls[id]
             + 3*old_bowls[prev_id]
             + 5*old_bowls[next_id]
             + raw_sum
             + stir
             + pos*pos AS u_raw
    FROM neighbors
), arrays AS MATERIALIZED (
    SELECT old_bowls,
           stir,
           raw_sum,
           saved_sum,
           order_arr,
           max(u_saved) FILTER (WHERE id=1) AS bowl1_u_saved,
           max(u_raw) FILTER (WHERE id=1) AS bowl1_u_raw,
           array_agg(
               pastafari_sql_tamil_test.save_value(
                   u_saved*u_saved + 7*old_bowls[prev_id]*old_bowls[next_id]
               ) ORDER BY id
           ) AS canonical_bowls,
           array_agg(
               pastafari_sql_tamil_test.save_value(
                   u_raw*u_raw + 7*old_bowls[prev_id]*old_bowls[next_id]
               ) ORDER BY id
           ) AS raw_sum_mutant_bowls
    FROM calc
    GROUP BY old_bowls,stir,raw_sum,saved_sum,order_arr
), observed AS MATERIALIZED (
    SELECT *,
           pastafari_sql_tamil_test.post_stir_round(old_bowls,stir) AS implementation_bowls
    FROM arrays
)
INSERT INTO saved_sum_discriminator_assertions
SELECT 'மூலக் கூட்டுத்தொகையும் SAVE செய்த கூட்டுத்தொகையும் வேறுபடுகின்றன',
       raw_sum=21::numeric AND saved_sum=170::numeric AND raw_sum<>saved_sum
FROM observed
UNION ALL
SELECT 'SAVE செய்த கூட்டுத்தொகை அதே வரிசைமாற்றத்தையும் கணக்கையும் இயக்குகிறது',
       order_arr=ARRAY[2,4,1,3,6,5]::integer[]
FROM observed
UNION ALL
SELECT 'முதல் கிண்ணத்தின் இடைநிலை u இல் saved-sum பயன்படுத்தப்படுகிறது',
       bowl1_u_saved=208::numeric AND bowl1_u_raw=59::numeric AND bowl1_u_saved<>bowl1_u_raw
FROM observed
UNION ALL
SELECT 'சுயாதீன saved-sum எதிர்பார்ப்பு நிலையான சாட்சியுடன் ஒத்துள்ளது',
       canonical_bowls=ARRAY[43348::numeric,43821::numeric,49771::numeric,36114::numeric,57684::numeric,55801::numeric]
FROM observed
UNION ALL
SELECT 'raw-sum mutant நிலையான வேறுபட்ட சாட்சியுடன் ஒத்துள்ளது',
       raw_sum_mutant_bowls=ARRAY[3565::numeric,3740::numeric,5518::numeric,1695::numeric,8365::numeric,7674::numeric]
FROM observed
UNION ALL
SELECT 'உண்மையான post-stir saved-sum எதிர்பார்ப்புடன் ஒத்துள்ளது',
       implementation_bowls=canonical_bowls
FROM observed
UNION ALL
SELECT 'உண்மையான post-stir raw-sum mutant-ஐ நிராகரிக்கிறது',
       implementation_bowls<>raw_sum_mutant_bowls
FROM observed;

SELECT 'saved-sum discriminator தயாராக உள்ளது' AS status,
       count(*) AS assertion_count
FROM saved_sum_discriminator_assertions;

COMMIT;
