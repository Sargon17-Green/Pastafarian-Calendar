-- SQL+தமிழ் Slice20 bounded Native: 50 independent fixture rows, 36 named tests.
BEGIN;
CREATE TEMP TABLE slice20_native(name text PRIMARY KEY,ok boolean NOT NULL);
WITH f AS MATERIALIZED (
 SELECT
 ROW(ARRAY[10,20,30,40,50,60]::numeric[],ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS s,
 ROW(ARRAY[0,20,30,40,50,60]::numeric[],ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS bad_zero,
 ROW(ARRAY[10,20,30,40,50,60]::numeric[],ARRAY[1,2,3,4,5,5]::integer[])::pastafari_sql_tamil.sauce_result AS bad_dup,
 ROW(ARRAY[10,20,30,40,50,60]::numeric[],ARRAY[1,2,3,4,5]::integer[])::pastafari_sql_tamil.sauce_result AS bad_short,
 ROW(5000,0,6,0,252)::pastafari_sql_tamil.year_rec AS y252,
 ROW(5000,0,6,0,492)::pastafari_sql_tamil.year_rec AS y492,
 ROW(5000,0,6,0,2460)::pastafari_sql_tamil.year_rec AS y2460,
 ROW(5000,0,6,0,5778)::pastafari_sql_tamil.year_rec AS y5778
)
INSERT INTO slice20_native(name,ok)
SELECT name,coalesce(ok,false) FROM f CROSS JOIN LATERAL (VALUES
 ('golden-enumeration-50',(SELECT count(*)=50 AND bool_and(pastafari_sql_tamil.month_count_by_rank(days,rank1)=expected) FROM slice20_goldens)),
 ('helper-252-first',pastafari_sql_tamil.month_count_by_rank(252,1)=3),
 ('helper-252-last',pastafari_sql_tamil.month_count_by_rank(252,45)=47),
 ('helper-252-middle',pastafari_sql_tamil.month_count_by_rank(252,23)=25),
 ('helper-493-first',pastafari_sql_tamil.month_count_by_rank(493,1)=5),
 ('helper-493-last',pastafari_sql_tamil.month_count_by_rank(493,43)=47),
 ('helper-2460-first',pastafari_sql_tamil.month_count_by_rank(2460,1)=20),
 ('helper-2460-middle',pastafari_sql_tamil.month_count_by_rank(2460,14)=33),
 ('helper-2460-last',pastafari_sql_tamil.month_count_by_rank(2460,28)=47),
 ('helper-5778-only',pastafari_sql_tamil.month_count_by_rank(5778,1)=47),
 ('helper-repeat',pastafari_sql_tamil.month_count_by_rank(1230,3) IS NOT DISTINCT FROM pastafari_sql_tamil.month_count_by_rank(1230,3)),
 ('helper-null-days',pastafari_sql_tamil.month_count_by_rank(NULL::numeric,1) IS NULL),
 ('helper-null-rank',pastafari_sql_tamil.month_count_by_rank(252,NULL::numeric) IS NULL),
 ('helper-day-under',pastafari_sql_tamil.month_count_by_rank(251,1) IS NULL),
 ('helper-day-over',pastafari_sql_tamil.month_count_by_rank(5779,1) IS NULL),
 ('helper-day-fraction',pastafari_sql_tamil.month_count_by_rank(252.5,1) IS NULL),
 ('helper-rank-zero',pastafari_sql_tamil.month_count_by_rank(252,0) IS NULL),
 ('helper-rank-negative',pastafari_sql_tamil.month_count_by_rank(252,-1) IS NULL),
 ('helper-rank-fraction',pastafari_sql_tamil.month_count_by_rank(252,1.5) IS NULL),
 ('helper-rank-over',pastafari_sql_tamil.month_count_by_rank(252,46) IS NULL),
 ('helper-rank-over-one',pastafari_sql_tamil.month_count_by_rank(5778,2) IS NULL),
 ('null-sauce',pastafari_sql_tamil.choose_month_count(NULL::pastafari_sql_tamil.sauce_result,f.y252) IS NULL),
 ('null-year',pastafari_sql_tamil.choose_month_count(f.s,NULL::pastafari_sql_tamil.year_rec) IS NULL),
 ('valid-252',pastafari_sql_tamil.choose_month_count(f.s,f.y252) BETWEEN 3 AND 47),
 ('valid-492',pastafari_sql_tamil.choose_month_count(f.s,f.y492) BETWEEN 4 AND 47),
 ('valid-2460',pastafari_sql_tamil.choose_month_count(f.s,f.y2460) BETWEEN 20 AND 47),
 ('valid-5778',pastafari_sql_tamil.choose_month_count(f.s,f.y5778)=47),
 ('choose-deterministic',pastafari_sql_tamil.choose_month_count(f.s,f.y492) IS NOT DISTINCT FROM pastafari_sql_tamil.choose_month_count(f.s,f.y492)),
 ('bad-zero-bowl',pastafari_sql_tamil.choose_month_count(f.bad_zero,f.y252) IS NULL),
 ('bad-duplicate-order',pastafari_sql_tamil.choose_month_count(f.bad_dup,f.y252) IS NULL),
 ('bad-short-order',pastafari_sql_tamil.choose_month_count(f.bad_short,f.y252) IS NULL),
 ('bad-zero-year',pastafari_sql_tamil.choose_month_count(f.s,ROW(5000,0,6,0,0)::pastafari_sql_tamil.year_rec) IS NULL),
 ('bad-long-year',pastafari_sql_tamil.choose_month_count(f.s,ROW(5000,0,6,0,5779)::pastafari_sql_tamil.year_rec) IS NULL),
 ('bad-fractional-year',pastafari_sql_tamil.choose_month_count(f.s,ROW(5000,0,6,0,252.5)::pastafari_sql_tamil.year_rec) IS NULL),
 ('bad-null-day',pastafari_sql_tamil.choose_month_count(f.s,ROW(5000,0,6,NULL,252)::pastafari_sql_tamil.year_rec) IS NULL),
 ('bad-gate-gap',pastafari_sql_tamil.choose_month_count(f.s,ROW(5000,0,5,0,252)::pastafari_sql_tamil.year_rec) IS NULL)
) AS t(name,ok);
SELECT name,ok FROM slice20_native ORDER BY name;
SELECT 1/((count(*)=36 AND bool_and(ok))::integer) AS native_36_of_36 FROM slice20_native;
COMMIT;
