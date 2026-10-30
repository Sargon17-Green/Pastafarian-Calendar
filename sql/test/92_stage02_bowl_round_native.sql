-- Slice 6: independently calculated fixed expected vectors + bounds + isolation.
-- 6 vectors * 6 = 36; 46 stone positions; 8 invalid cases; 3 metadata = 93.
BEGIN;
CREATE TEMP TABLE stage02_round_assertions(
    test_name text PRIMARY KEY,
    ok boolean NOT NULL CHECK(ok)
);
WITH fixtures(label,calculation_day,target_day,drop_value,stone_index,expected) AS (VALUES
('same-first',-15055671::numeric,-15055671::numeric,1::numeric,1,
 ARRAY[34937859503507,26428324895998,230945518023999,18486552409863,72755910885384,16894363718067]::numeric[]),
('same-last',-15055671::numeric,-15055671::numeric,720::numeric,46,
 ARRAY[88427070904599930234955945703506739181,163068553084570960829742532555136303401,1626113461219765038448298726487337288,54134967664772210651774678091070073588,67115384796640921746383476284893805997,94457426842187927457238344939547311158]::numeric[]),
('forward',-15055674::numeric,-15055669::numeric,-721::numeric,2,
 ARRAY[1780802109019,42693331630536,5291909897749,3507820366951215637,1225186474498614919,598328307486147881]::numeric[]),
('reverse',-15055669::numeric,-15055674::numeric,721::numeric,45,
 ARRAY[167119942840202347161971699613176194874,130221333751299948301386943048148860150,33138442638245471708002160940156479834,135162455969359995571321886359750049402,73715299868814589740726036695388110695,163883558167040955342842841772792920425]::numeric[]),
('large',-15055671::numeric,170141183460469231731687303715869050056::numeric,170141183460469231731687303715884105728::numeric,23,
 ARRAY[93589421168253784142045643740425757138,125181396292731256933713364937793698371,38008061137989247275046201280007042622,106274584669632545642243193574923064020,34650584241824637870392500060169932391,12323641579813988284875262184439952379]::numeric[]),
('remote',-170141183460469231731687303715899161398::numeric,-15055671::numeric,-170141183460469231731687303715884105728::numeric,46,
 ARRAY[17477881695540411085495274235064761313,96745787894036353804739068935458300012,107128188844360202264163268235193672745,93546312041656207798445730721034848127,121057956441717642135636552966603649982,143790705712778009038742783804665539084]::numeric[])
), computed AS MATERIALIZED (
    SELECT label,expected,pastafari_sql_tamil.bowl_round(
      pastafari_sql_tamil.initial_bowls(
        pastafari_sql_tamil.work_counts(calculation_day,target_day)),
      drop_value,stone_index) AS actual
    FROM fixtures
)
INSERT INTO stage02_round_assertions(test_name,ok)
SELECT 'fixture:'||label||':'||k, actual[k]=expected[k]
FROM computed CROSS JOIN generate_series(1,6) AS s(k);

WITH base AS MATERIALIZED (
    SELECT pastafari_sql_tamil.initial_bowls(
      pastafari_sql_tamil.work_counts(-15055671::numeric,-15055671::numeric)) AS bowls
), rounds AS MATERIALIZED (
    SELECT i,pastafari_sql_tamil.bowl_round(bowls,(i-24)::numeric,i) AS result
    FROM base CROSS JOIN generate_series(1,46) AS s(i)
)
INSERT INTO stage02_round_assertions(test_name,ok)
SELECT 'bounds:'||i,
  coalesce(array_length(result,1),0)=6
  AND NOT EXISTS(SELECT 1 FROM unnest(result) AS u(v)
                 WHERE v IS NULL OR v<1 OR v>pastafari_sql_tamil.save_modulus())
FROM rounds;

WITH base AS (
    SELECT ARRAY[1,2,3,4,5,6]::numeric[] AS v
)
INSERT INTO stage02_round_assertions(test_name,ok)
SELECT 'invalid-stone-0',pastafari_sql_tamil.bowl_round(v,1,0) IS NULL FROM base
UNION ALL SELECT 'invalid-stone-47',pastafari_sql_tamil.bowl_round(v,1,47) IS NULL FROM base
UNION ALL SELECT 'fractional-drop',pastafari_sql_tamil.bowl_round(v,1.5,1) IS NULL FROM base
UNION ALL SELECT 'short-bowls',pastafari_sql_tamil.bowl_round(ARRAY[1,2]::numeric[],1,1) IS NULL FROM base
UNION ALL SELECT 'null-member',pastafari_sql_tamil.bowl_round(ARRAY[1,NULL,3,4,5,6]::numeric[],1,1) IS NULL FROM base
UNION ALL SELECT 'null-bowls',pastafari_sql_tamil.bowl_round(NULL::numeric[],1,1) IS NULL FROM base
UNION ALL SELECT 'null-drop',pastafari_sql_tamil.bowl_round(v,NULL::numeric,1) IS NULL FROM base
UNION ALL SELECT 'null-stone',pastafari_sql_tamil.bowl_round(v,1,NULL::integer) IS NULL FROM base;

INSERT INTO stage02_round_assertions(test_name,ok)
SELECT 'pure-production',
  (SELECT count(*)=0 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='pastafari_sql_tamil'
     AND p.proname IN ('stir_stone_kind_by_position','bowl_round')
     AND position('pastafari_sql_tamil_test' IN pg_get_functiondef(p.oid))>0)
UNION ALL SELECT 'functions-sql',
  (SELECT count(*)=2 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   JOIN pg_language l ON l.oid=p.prolang
   WHERE n.nspname='pastafari_sql_tamil'
     AND p.proname IN ('stir_stone_kind_by_position','bowl_round') AND l.lanname='sql')
UNION ALL SELECT 'functions-not-volatile',
  (SELECT count(*)=2 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='pastafari_sql_tamil'
     AND p.proname IN ('stir_stone_kind_by_position','bowl_round')
     AND p.provolatile IN ('s','i'));

SELECT count(*) AS native_assertions FROM stage02_round_assertions;
COMMIT;
