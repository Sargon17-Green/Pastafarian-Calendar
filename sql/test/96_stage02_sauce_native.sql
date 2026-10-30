-- Slice 8: 18 independent golden elements + 3 bounds + 8 invalid inputs
-- + 2 full-sauce structural assertions + 3 production metadata = 34.
-- Golden final vectors from independent Python exact-integer/factoradic oracle.
-- Its single-round calculation was cross-checked against 24 existing golden elements.
BEGIN;
CREATE TEMP TABLE stage02_sauce_native(
    test_name text PRIMARY KEY,
    ok boolean NOT NULL CHECK(ok)
);
WITH fixtures(label,seed,expected) AS (VALUES
('ascending',ARRAY[1,2,3,4,5,6]::numeric[],
 ARRAY[141132694112953656784802743599690311793,136632892414948082655633411464102794505,134404201440819867177248219965286133396,114290835991731114228285355792902410488,133747246005993698450862842763676230984,38641804819033612619357638081595297714]::numeric[]),
('constant',ARRAY[7,7,7,7,7,7]::numeric[],
 ARRAY[154573848616075136477110758234963293432,114534837961322552047755997447456740984,100298628481775788394994419476662246226,80809932347016051023828469592920527688,134331834096982297212410669010249026165,55772548373052095576255538056090349489]::numeric[]),
('near-modulus',ARRAY[1,170141183460469231731687303715884105727,3,170141183460469231731687303715884105726,5,170141183460469231731687303715884105725]::numeric[],
 ARRAY[24393238261597906318692648526153802875,108081687144628913231402351569662477773,103038254233818336590244139192610940218,145687083894327543179045617712201565335,169185838453739004782007606354384488874,35935966788152364605052650739647098633]::numeric[])
), results AS MATERIALIZED (
    SELECT label,expected,pastafari_sql_tamil.post_stir_chain(seed) AS actual
    FROM fixtures
)
INSERT INTO stage02_sauce_native(test_name,ok)
SELECT 'golden:'||label||':'||b,actual[b]=expected[b]
FROM results CROSS JOIN generate_series(1,6) AS s(b);

WITH fixtures(label,seed) AS (VALUES
('ascending',ARRAY[1,2,3,4,5,6]::numeric[]),
('constant',ARRAY[7,7,7,7,7,7]::numeric[]),
('near-modulus',ARRAY[1,170141183460469231731687303715884105727,3,170141183460469231731687303715884105726,5,170141183460469231731687303715884105725]::numeric[])
), computed AS MATERIALIZED (
    SELECT label,pastafari_sql_tamil.post_stir_chain(seed) AS result FROM fixtures
)
INSERT INTO stage02_sauce_native(test_name,ok)
SELECT 'bounds:'||label,
       array_length(result,1)=6
       AND NOT EXISTS (SELECT 1 FROM unnest(result) AS x(v)
                       WHERE v IS NULL OR v < 1 OR v > pastafari_sql_tamil.save_modulus())
FROM computed;

INSERT INTO stage02_sauce_native(test_name,ok)
SELECT 'invalid:null',pastafari_sql_tamil.post_stir_chain(NULL::numeric[]) IS NULL
UNION ALL SELECT 'invalid:short',pastafari_sql_tamil.post_stir_chain(ARRAY[1,2]::numeric[]) IS NULL
UNION ALL SELECT 'invalid:empty',pastafari_sql_tamil.post_stir_chain(ARRAY[]::numeric[]) IS NULL
UNION ALL SELECT 'invalid:null-element',pastafari_sql_tamil.post_stir_chain(ARRAY[1,2,NULL,4,5,6]::numeric[]) IS NULL
UNION ALL SELECT 'invalid:zero',pastafari_sql_tamil.post_stir_chain(ARRAY[0,2,3,4,5,6]::numeric[]) IS NULL
UNION ALL SELECT 'invalid:fraction',pastafari_sql_tamil.post_stir_chain(ARRAY[1.5,2,3,4,5,6]::numeric[]) IS NULL
UNION ALL SELECT 'invalid:above-modulus',pastafari_sql_tamil.post_stir_chain(ARRAY[170141183460469231731687303715884105728,2,3,4,5,6]::numeric[]) IS NULL
UNION ALL SELECT 'invalid:zero-based',pastafari_sql_tamil.post_stir_chain('[0:5]={1,2,3,4,5,6}'::numeric[]) IS NULL;

WITH pairs(label,c,t) AS (VALUES
('foundation',-15055671::numeric,-15055671::numeric),
('offset',-15055674::numeric,-15055669::numeric)
), results AS MATERIALIZED (
    SELECT label,pastafari_sql_tamil.sauce(c,t) AS computed FROM pairs
)
INSERT INTO stage02_sauce_native(test_name,ok)
SELECT 'sauce:shape:'||label,
       array_length((computed).bowls,1)=6
       AND (SELECT count(*)=6 AND bool_and(v>=1 AND v<=pastafari_sql_tamil.save_modulus())
            FROM unnest((computed).bowls) AS x(v))
       AND (SELECT array_agg(v ORDER BY v)=ARRAY[1,2,3,4,5,6]::integer[]
            FROM unnest((computed).order_at_drop_46) AS x(v))
FROM results;

INSERT INTO stage02_sauce_native(test_name,ok)
SELECT 'metadata:production-only',
    (SELECT count(*)=0 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
     WHERE n.nspname='pastafari_sql_tamil'
       AND p.proname IN ('post_stir_chain','sauce')
       AND position('pastafari_sql_tamil_test' IN pg_get_functiondef(p.oid))>0)
UNION ALL SELECT 'metadata:sql-only',
    (SELECT count(*)=2 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
     JOIN pg_language l ON l.oid=p.prolang
     WHERE n.nspname='pastafari_sql_tamil'
       AND p.proname IN ('post_stir_chain','sauce') AND l.lanname='sql')
UNION ALL SELECT 'metadata:nonvolatile',
    (SELECT count(*)=2 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
     WHERE n.nspname='pastafari_sql_tamil'
       AND p.proname IN ('post_stir_chain','sauce')
       AND p.provolatile IN ('i','s'));

SELECT count(*) AS native_assertions FROM stage02_sauce_native;
COMMIT;
