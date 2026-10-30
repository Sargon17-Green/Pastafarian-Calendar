-- Slice 8: 3 chain seeds x 6 = 18; 2 full sauces x (6 bowls + 6 permutation)=24;
-- total 42. Reference functions are available only in a separate differential DB.
BEGIN;
CREATE TEMP TABLE stage02_sauce_differential(
    test_name text PRIMARY KEY,
    ok boolean NOT NULL CHECK(ok)
);
WITH RECURSIVE samples(label,initial) AS (VALUES
('ascending',ARRAY[1,2,3,4,5,6]::numeric[]),
('constant',ARRAY[7,7,7,7,7,7]::numeric[]),
('near-modulus',ARRAY[1,170141183460469231731687303715884105727,3,170141183460469231731687303715884105726,5,170141183460469231731687303715884105725]::numeric[])
), reference_steps(label,step,bowls) AS (
    SELECT label,0,initial FROM samples
    UNION ALL
    SELECT label,step+1,pastafari_sql_tamil_test.post_stir_round(bowls,step+1)
    FROM reference_steps WHERE step<12
), results AS MATERIALIZED (
    SELECT r.label,r.bowls AS expected,
           pastafari_sql_tamil.post_stir_chain(s.initial) AS actual
    FROM reference_steps r JOIN samples s USING (label)
    WHERE r.step=12
)
INSERT INTO stage02_sauce_differential(test_name,ok)
SELECT 'stir-chain:'||label||':'||k,actual[k]=expected[k]
FROM results CROSS JOIN generate_series(1,6) AS g(k);

WITH pairs(label,calculation,target) AS (VALUES
('foundation',-15055671::numeric,-15055671::numeric),
('offset',-15055674::numeric,-15055669::numeric)
), results AS MATERIALIZED (
    SELECT label,
           pastafari_sql_tamil.sauce(calculation,target) AS actual,
           pastafari_sql_tamil_test.sauce(calculation,target) AS expected
    FROM pairs
)
INSERT INTO stage02_sauce_differential(test_name,ok)
SELECT 'sauce-bowl:'||label||':'||k,
       ((actual).bowls)[k]=((expected).bowls)[k]
FROM results CROSS JOIN generate_series(1,6) AS g(k)
UNION ALL
SELECT 'sauce-order:'||label||':'||k,
       ((actual).order_at_drop_46)[k]=((expected).order_at_drop_46)[k]
FROM results CROSS JOIN generate_series(1,6) AS g(k);

SELECT count(*) AS differential_assertions FROM stage02_sauce_differential;
COMMIT;
