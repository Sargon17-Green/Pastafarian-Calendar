-- SQL+தமிழ் Stage 2 Slice 17: 20 bounded, independently named Native assertions.
-- Production-only; controlled structurally valid year records are not full dates.
BEGIN;
CREATE TEMP TABLE stage02_cutlet_count_native(
 test_name text PRIMARY KEY, ok boolean NOT NULL, detail text NOT NULL
);
WITH fx AS MATERIALIZED (
 SELECT
   ROW(ARRAY[10,20,30,40,50,60]::numeric[],ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS s,
   ROW(5000,0,6,0,100)::pastafari_sql_tamil.year_rec AS y6,
   ROW(5000,0,7,0,100)::pastafari_sql_tamil.year_rec AS y7,
   ROW(5000,0,17,0,100)::pastafari_sql_tamil.year_rec AS y17,
   ROW(5000,0,18,0,100)::pastafari_sql_tamil.year_rec AS y18,
   ROW(5000,-4,4,-100,100)::pastafari_sql_tamil.year_rec AS yzero,
   ROW(5000,0,5,0,100)::pastafari_sql_tamil.year_rec AS y5,
   ROW(5000,10,2,0,100)::pastafari_sql_tamil.year_rec AS yreverse,
   ROW(5000,0.5,7,0,100)::pastafari_sql_tamil.year_rec AS yfractionalopen,
   ROW(5000,0,7.5,0,100)::pastafari_sql_tamil.year_rec AS yfractionalclose,
   ROW(5000,0,7,0.25,100)::pastafari_sql_tamil.year_rec AS yfractionalday,
   ROW(5000,0,7,110,100)::pastafari_sql_tamil.year_rec AS ybackwardday,
   ROW(5000,0,7,NULL,100)::pastafari_sql_tamil.year_rec AS ynullday,
   ROW(ARRAY[0,20,30,40,50,60]::numeric[],ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS sbadbowl,
   ROW(ARRAY[10,20,30,40,50,60]::numeric[],ARRAY[1,1,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS sbadorder
)
INSERT INTO stage02_cutlet_count_native(test_name,ok,detail)
SELECT test_name,coalesce(ok,false),detail
FROM fx AS f
CROSS JOIN LATERAL (VALUES
 ('g6-exact-six',pastafari_sql_tamil.choose_cutlet_count(f.s,f.y6)=6,'n=1 rank=1'),
 ('g7-rank-oracle',pastafari_sql_tamil.choose_cutlet_count(f.s,f.y7)=5+pastafari_sql_tamil.choose_rank(pastafari_sql_tamil.ask_bowl(f.s,2,20),2),'n=2'),
 ('g17-rank-oracle',pastafari_sql_tamil.choose_cutlet_count(f.s,f.y17)=5+pastafari_sql_tamil.choose_rank(pastafari_sql_tamil.ask_bowl(f.s,2,20),12),'n=12'),
 ('g18-rank-oracle',pastafari_sql_tamil.choose_cutlet_count(f.s,f.y18)=5+pastafari_sql_tamil.choose_rank(pastafari_sql_tamil.ask_bowl(f.s,2,20),12),'saturated n=12'),
 ('saturation-g17-g18',pastafari_sql_tamil.choose_cutlet_count(f.s,f.y18)=pastafari_sql_tamil.choose_cutlet_count(f.s,f.y17),'cap at 17'),
 ('cross-zero-indices',pastafari_sql_tamil.choose_cutlet_count(f.s,f.yzero) BETWEEN 6 AND 8,'gap=8'),
 ('g7-output-bound',pastafari_sql_tamil.choose_cutlet_count(f.s,f.y7) BETWEEN 6 AND 7,'6..7'),
 ('g17-output-bound',pastafari_sql_tamil.choose_cutlet_count(f.s,f.y17) BETWEEN 6 AND 17,'6..17'),
 ('deterministic-repeat',pastafari_sql_tamil.choose_cutlet_count(f.s,f.y7)=pastafari_sql_tamil.choose_cutlet_count(f.s,f.y7),'pure'),
 ('strict-null-sauce',pastafari_sql_tamil.choose_cutlet_count(NULL::pastafari_sql_tamil.sauce_result,f.y7) IS NULL,'STRICT'),
 ('strict-null-year',pastafari_sql_tamil.choose_cutlet_count(f.s,NULL::pastafari_sql_tamil.year_rec) IS NULL,'STRICT'),
 ('fractional-open',pastafari_sql_tamil.choose_cutlet_count(f.s,f.yfractionalopen) IS NULL,'invalid numeric'),
 ('fractional-close',pastafari_sql_tamil.choose_cutlet_count(f.s,f.yfractionalclose) IS NULL,'invalid numeric'),
 ('gap-five-rejected',pastafari_sql_tamil.choose_cutlet_count(f.s,f.y5) IS NULL,'rank n=0 invalid'),
 ('reversed-gates',pastafari_sql_tamil.choose_cutlet_count(f.s,f.yreverse) IS NULL,'negative gaps'),
 ('fractional-gate-day',pastafari_sql_tamil.choose_cutlet_count(f.s,f.yfractionalday) IS NULL,'invalid day'),
 ('inverted-gate-days',pastafari_sql_tamil.choose_cutlet_count(f.s,f.ybackwardday) IS NULL,'invalid year interval'),
 ('null-year-field',pastafari_sql_tamil.choose_cutlet_count(f.s,f.ynullday) IS NULL,'no missing fields'),
 ('invalid-bowl',pastafari_sql_tamil.choose_cutlet_count(f.sbadbowl,f.y7) IS NULL,'invalid SAVE range'),
 ('invalid-bowl-order',pastafari_sql_tamil.choose_cutlet_count(f.sbadorder,f.y7) IS NULL,'not a permutation')
) AS check_case(test_name,ok,detail);
SELECT test_name,ok,detail FROM stage02_cutlet_count_native ORDER BY test_name;
SELECT count(*) AS native_assertions FROM stage02_cutlet_count_native;
SELECT 1/((count(*)=20 AND bool_and(ok))::integer) AS native_20_of_20
FROM stage02_cutlet_count_native;
COMMIT;
