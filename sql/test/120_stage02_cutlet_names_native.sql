-- SQL+தமிழ் Stage 2 Slice19 Native: named, fail-closed, production-only.
-- CI must load 122 independent Python fixtures before this transaction.
BEGIN;
CREATE TEMP TABLE slice19_native(name text PRIMARY KEY, ok boolean NOT NULL);
WITH f AS MATERIALIZED (
 SELECT
 ROW(ARRAY[10,20,30,40,50,60]::numeric[],ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS s,
 ROW(ARRAY[0,20,30,40,50,60]::numeric[],ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS zero_bowl,
 ROW(ARRAY[10.5,20,30,40,50,60]::numeric[],ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS fractional_bowl,
 ROW(ARRAY[NULL,20,30,40,50,60]::numeric[],ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS null_bowl,
 ROW(ARRAY[10,20,30,40,50,60]::numeric[],ARRAY[1,2,3,4,5,5]::integer[])::pastafari_sql_tamil.sauce_result AS duplicate_order,
 ROW(ARRAY[10,20,30,40,50,60]::numeric[],ARRAY[1,2,3,4,5]::integer[])::pastafari_sql_tamil.sauce_result AS short_order,
 ROW(ARRAY[10,20,30,40,50,60]::numeric[],NULL::integer[])::pastafari_sql_tamil.sauce_result AS null_order
)
INSERT INTO slice19_native(name,ok)
SELECT name,coalesce(ok,false) FROM f CROSS JOIN LATERAL (VALUES
 ('null-sauce', pastafari_sql_tamil.choose_cutlet_names(NULL::pastafari_sql_tamil.sauce_result,6) IS NULL),
 ('null-k', pastafari_sql_tamil.choose_cutlet_names(f.s,NULL::integer) IS NULL),
 ('k-zero', pastafari_sql_tamil.choose_cutlet_names(f.s,0) IS NULL),
 ('k-five', pastafari_sql_tamil.choose_cutlet_names(f.s,5) IS NULL),
 ('k-eighteen', pastafari_sql_tamil.choose_cutlet_names(f.s,18) IS NULL),
 ('k-negative', pastafari_sql_tamil.choose_cutlet_names(f.s,-1) IS NULL),
 ('bad-zero-bowl', pastafari_sql_tamil.choose_cutlet_names(f.zero_bowl,6) IS NULL),
 ('bad-fractional-bowl', pastafari_sql_tamil.choose_cutlet_names(f.fractional_bowl,6) IS NULL),
 ('bad-null-bowl', pastafari_sql_tamil.choose_cutlet_names(f.null_bowl,6) IS NULL),
 ('bad-duplicate-order', pastafari_sql_tamil.choose_cutlet_names(f.duplicate_order,6) IS NULL),
 ('bad-short-order', pastafari_sql_tamil.choose_cutlet_names(f.short_order,6) IS NULL),
 ('bad-null-order', pastafari_sql_tamil.choose_cutlet_names(f.null_order,6) IS NULL),
 ('helper-null-n', pastafari_sql_tamil.cutlet_names_unrank(NULL::integer,6,1) IS NULL),
 ('helper-null-k', pastafari_sql_tamil.cutlet_names_unrank(17,NULL::integer,1) IS NULL),
 ('helper-null-r', pastafari_sql_tamil.cutlet_names_unrank(17,6,NULL::numeric) IS NULL),
 ('helper-n-zero', pastafari_sql_tamil.cutlet_names_unrank(0,1,1) IS NULL),
 ('helper-n-eighteen', pastafari_sql_tamil.cutlet_names_unrank(18,6,1) IS NULL),
 ('helper-k-zero', pastafari_sql_tamil.cutlet_names_unrank(17,0,1) IS NULL),
 ('helper-k-over-n', pastafari_sql_tamil.cutlet_names_unrank(6,7,1) IS NULL),
 ('helper-rank-zero', pastafari_sql_tamil.cutlet_names_unrank(17,6,0) IS NULL),
 ('helper-rank-negative', pastafari_sql_tamil.cutlet_names_unrank(17,6,-1) IS NULL),
 ('helper-rank-fraction', pastafari_sql_tamil.cutlet_names_unrank(17,6,1.5) IS NULL),
 ('helper-rank-over', pastafari_sql_tamil.cutlet_names_unrank(17,6,8910721) IS NULL),
 ('helper-k6-first', pastafari_sql_tamil.cutlet_names_unrank(17,6,1)=ARRAY[1,2,3,4,5,6]::integer[]),
 ('helper-k6-last', pastafari_sql_tamil.cutlet_names_unrank(17,6,8910720)=ARRAY[17,16,15,14,13,12]::integer[]),
 ('helper-k17-first', pastafari_sql_tamil.cutlet_names_unrank(17,17,1)=ARRAY(SELECT generate_series(1,17))),
 ('helper-k17-last', pastafari_sql_tamil.cutlet_names_unrank(17,17,355687428096000)=ARRAY(SELECT generate_series(17,1,-1))),
 ('helper-middle-valid', (SELECT array_length(v,1)=12 AND cardinality(ARRAY(SELECT DISTINCT unnest(v)))=12 FROM (SELECT pastafari_sql_tamil.cutlet_names_unrank(17,12,123456) AS v) a)),
 ('helper-repeat', pastafari_sql_tamil.cutlet_names_unrank(17,7,1234) IS NOT DISTINCT FROM pastafari_sql_tamil.cutlet_names_unrank(17,7,1234)),
 ('oracle-small-122', (SELECT count(*)=122 AND bool_and(pastafari_sql_tamil.cutlet_names_unrank(n,k,rank1) IS NOT DISTINCT FROM expected) FROM slice19_goldens))
) AS t(name,ok);
-- 12 distinct k-specific assertions; each checks length, unique IDs and range.
WITH f AS (SELECT ROW(ARRAY[10,20,30,40,50,60]::numeric[],ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS s),
 checks AS (
 SELECT k,pastafari_sql_tamil.choose_cutlet_names(s,k) AS value
 FROM f CROSS JOIN generate_series(6,17) AS g(k)
)
INSERT INTO slice19_native(name,ok)
SELECT 'k-'||k||'-full-structure', coalesce(
 array_length(value,1)=k AND
 (SELECT count(DISTINCT x)=k AND min(x)>=1 AND max(x)<=17 FROM unnest(value) AS a(x)),false)
FROM checks;
SELECT name,ok FROM slice19_native ORDER BY name;
SELECT 1/((count(*)=42 AND bool_and(ok))::integer) AS native_42_of_42 FROM slice19_native;
COMMIT;
