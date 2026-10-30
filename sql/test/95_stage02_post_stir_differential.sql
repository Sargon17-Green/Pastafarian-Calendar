-- Slice 7: 4 x 12 x 6 single-round differential = 288 assertions;
-- 3 x 6 full twelve-stir chain comparisons = 18, total 306.
-- Reference implementation exists only inside this isolated differential DB.
BEGIN;
CREATE TEMP TABLE stage02_stir_differential(
    test_name text PRIMARY KEY,
    ok boolean NOT NULL CHECK(ok)
);
WITH cases(label,bowls) AS (VALUES
('ascending',ARRAY[1,2,3,4,5,6]::numeric[]),
('constant',ARRAY[7,7,7,7,7,7]::numeric[]),
('near-modulus',ARRAY[1,170141183460469231731687303715884105727,3,170141183460469231731687303715884105726,5,170141183460469231731687303715884105725]::numeric[]),
('wide',ARRAY[1298074214633706907132624082305025,1298074214633706907132624082305026,1298074214633706907132624082305027,1298074214633706907132624082305028,1298074214633706907132624082305029,1298074214633706907132624082305030]::numeric[])
), snapshots AS MATERIALIZED (
    SELECT label,stir,
      pastafari_sql_tamil.post_stir_round(bowls,stir) AS actual,
      pastafari_sql_tamil_test.post_stir_round(bowls,stir) AS expected
    FROM cases CROSS JOIN generate_series(1,12) AS g(stir)
)
INSERT INTO stage02_stir_differential(test_name,ok)
SELECT 'round:'||label||':'||stir||':'||id,actual[id]=expected[id]
FROM snapshots CROSS JOIN generate_series(1,6) AS g(id);

WITH RECURSIVE cases(label,bowls) AS (VALUES
('ascending',ARRAY[1,2,3,4,5,6]::numeric[]),
('constant',ARRAY[7,7,7,7,7,7]::numeric[]),
('near-modulus',ARRAY[1,170141183460469231731687303715884105727,3,170141183460469231731687303715884105726,5,170141183460469231731687303715884105725]::numeric[])
), paths(label,step,actual,expected) AS (
    SELECT label,0,bowls,bowls FROM cases
    UNION ALL
    SELECT label,step+1,
      pastafari_sql_tamil.post_stir_round(actual,step+1),
      pastafari_sql_tamil_test.post_stir_round(expected,step+1)
    FROM paths WHERE step<12
)
INSERT INTO stage02_stir_differential(test_name,ok)
SELECT 'chain:'||label||':'||id,actual[id]=expected[id]
FROM paths CROSS JOIN generate_series(1,6) AS g(id)
WHERE step=12;
SELECT count(*) AS differential_assertions FROM stage02_stir_differential;
COMMIT;
