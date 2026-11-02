-- SQL+தமிழ் Slice18 Native assertions; generated Python separator fixture loaded first.
BEGIN;
SET LOCAL statement_timeout = '180s';
\echo SLICE18_NATIVE_GROUP=32-golden
CREATE TEMP TABLE slice18_native(name text PRIMARY KEY,ok boolean NOT NULL);
WITH fx AS MATERIALIZED (
 SELECT g,seed,r,
 ROW(ARRAY[(9+seed)::numeric,20,30,40,50,60]::numeric[],ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS s,
 ROW(5000::numeric,0::numeric,g::numeric,pastafari_sql_tamil.gate_day(0),pastafari_sql_tamil.gate_day(g))::pastafari_sql_tamil.year_rec AS y,
 CASE WHEN r IS NULL THEN pastafari_sql_tamil.gate_day(0)+1 ELSE pastafari_sql_tamil.gate_day(r) END AS day
 FROM generate_series(6,9) a(g) CROSS JOIN generate_series(1,4) b(seed)
 CROSS JOIN (VALUES(NULL::integer),(2)) v(r)
), prepared AS MATERIALIZED (
 SELECT *,pastafari_sql_tamil.choose_cutlet_count(s,y) AS k FROM fx
), ranked AS MATERIALIZED (
 SELECT *, (SELECT max(q) FROM stage02_partition_goldens o
 WHERE o.g=prepared.g AND o.k=prepared.k AND o.r IS NOT DISTINCT FROM prepared.r) AS cnt
 FROM prepared
), answers AS MATERIALIZED (
 SELECT *,pastafari_sql_tamil.choose_rank(pastafari_sql_tamil.ask_bowl(s,2,21),cnt) AS q,
 pastafari_sql_tamil.choose_cutlet_partition(day,s,y,k) AS got FROM ranked
)
INSERT INTO slice18_native(name,ok)
SELECT format('g%s-seed%s-r%s',g,seed,coalesce(r::text,'none')),
 coalesce(got IS NOT NULL AND q IS NOT NULL AND got IS NOT DISTINCT FROM
 (SELECT expected FROM stage02_partition_goldens o WHERE o.g=answers.g
 AND o.k=answers.k AND o.r IS NOT DISTINCT FROM answers.r AND o.q=answers.q),false)
FROM answers;
\echo SLICE18_NATIVE_GROUP=21-boundary-negative
WITH fx AS MATERIALIZED (
 SELECT
 ROW(ARRAY[10,20,30,40,50,60]::numeric[],ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS s,
 ROW(ARRAY[0,20,30,40,50,60]::numeric[],ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS bads,
 ROW(ARRAY[10,20,30,40,50,60]::numeric[],ARRAY[1,1,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS bado,
 ROW(5000,0,6,pastafari_sql_tamil.gate_day(0),pastafari_sql_tamil.gate_day(6))::pastafari_sql_tamil.year_rec AS y6,
 ROW(5000,0,7,pastafari_sql_tamil.gate_day(0),pastafari_sql_tamil.gate_day(7))::pastafari_sql_tamil.year_rec AS y7,
 ROW(5000,0,18,pastafari_sql_tamil.gate_day(0),pastafari_sql_tamil.gate_day(18))::pastafari_sql_tamil.year_rec AS y18
) INSERT INTO slice18_native(name,ok)
SELECT name,coalesce(ok,false) FROM fx f CROSS JOIN LATERAL (VALUES
('null-day',pastafari_sql_tamil.choose_cutlet_partition(NULL,f.s,f.y6,6) IS NULL),
('null-sauce',pastafari_sql_tamil.choose_cutlet_partition(pastafari_sql_tamil.gate_day(0),NULL::pastafari_sql_tamil.sauce_result,f.y6,6) IS NULL),
('null-year',pastafari_sql_tamil.choose_cutlet_partition(pastafari_sql_tamil.gate_day(0),f.s,NULL::pastafari_sql_tamil.year_rec,6) IS NULL),
('null-k',pastafari_sql_tamil.choose_cutlet_partition(pastafari_sql_tamil.gate_day(0),f.s,f.y6,NULL::integer) IS NULL),
('fractional-day',pastafari_sql_tamil.choose_cutlet_partition(pastafari_sql_tamil.gate_day(0)+0.5,f.s,f.y6,6) IS NULL),
('gap-five',pastafari_sql_tamil.choose_cutlet_partition(pastafari_sql_tamil.gate_day(0),f.s,ROW(5000,0,5,0,100)::pastafari_sql_tamil.year_rec,6) IS NULL),
('k-five',pastafari_sql_tamil.choose_cutlet_partition(pastafari_sql_tamil.gate_day(0),f.s,f.y6,5) IS NULL),
('k-eighteen',pastafari_sql_tamil.choose_cutlet_partition(pastafari_sql_tamil.gate_day(0),f.s,f.y18,18) IS NULL),
('fractional-open-index',pastafari_sql_tamil.choose_cutlet_partition(pastafari_sql_tamil.gate_day(0),f.s,ROW(5000,0.5,7,0,100)::pastafari_sql_tamil.year_rec,6) IS NULL),
('fractional-close-index',pastafari_sql_tamil.choose_cutlet_partition(pastafari_sql_tamil.gate_day(0),f.s,ROW(5000,0,7.5,0,100)::pastafari_sql_tamil.year_rec,6) IS NULL),
('fractional-year-number',pastafari_sql_tamil.choose_cutlet_partition(pastafari_sql_tamil.gate_day(0),f.s,ROW(5000.5,0,7,0,100)::pastafari_sql_tamil.year_rec,6) IS NULL),
('fractional-year-day',pastafari_sql_tamil.choose_cutlet_partition(pastafari_sql_tamil.gate_day(0),f.s,ROW(5000,0,7,0.5,100)::pastafari_sql_tamil.year_rec,6) IS NULL),
('missing-year-field',pastafari_sql_tamil.choose_cutlet_partition(pastafari_sql_tamil.gate_day(0),f.s,ROW(5000,0,7,NULL,100)::pastafari_sql_tamil.year_rec,6) IS NULL),
('reversed-index',pastafari_sql_tamil.choose_cutlet_partition(pastafari_sql_tamil.gate_day(0),f.s,ROW(5000,7,0,0,100)::pastafari_sql_tamil.year_rec,6) IS NULL),
('reversed-days',pastafari_sql_tamil.choose_cutlet_partition(pastafari_sql_tamil.gate_day(0),f.s,ROW(5000,0,7,100,0)::pastafari_sql_tamil.year_rec,6) IS NULL),
('invalid-bowl',pastafari_sql_tamil.choose_cutlet_partition(pastafari_sql_tamil.gate_day(0),f.bads,f.y6,6) IS NULL),
('invalid-order',pastafari_sql_tamil.choose_cutlet_partition(pastafari_sql_tamil.gate_day(0),f.bado,f.y6,6) IS NULL),
('mismatched-k',pastafari_sql_tamil.choose_cutlet_partition(pastafari_sql_tamil.gate_day(0),f.s,f.y7,CASE WHEN pastafari_sql_tamil.choose_cutlet_count(f.s,f.y7)=6 THEN 7 ELSE 6 END) IS NULL),
('open-endpoint',pastafari_sql_tamil.choose_cutlet_partition(pastafari_sql_tamil.gate_day(0),f.s,f.y6,6) IS NOT DISTINCT FROM pastafari_sql_tamil.choose_cutlet_partition(pastafari_sql_tamil.gate_day(0)+1,f.s,f.y6,6)),
('close-endpoint',pastafari_sql_tamil.choose_cutlet_partition(pastafari_sql_tamil.gate_day(6),f.s,f.y6,6) IS NOT DISTINCT FROM pastafari_sql_tamil.choose_cutlet_partition(pastafari_sql_tamil.gate_day(0)+1,f.s,f.y6,6)),
('g18-structural',(SELECT count(*)=pastafari_sql_tamil.choose_cutlet_count(f.s,f.y18) AND sum(x)=18 AND min(x)>0 FROM unnest(pastafari_sql_tamil.choose_cutlet_partition(pastafari_sql_tamil.gate_day(0)+1,f.s,f.y18,pastafari_sql_tamil.choose_cutlet_count(f.s,f.y18))) a(x)))
) t(name,ok);
SELECT name,ok FROM slice18_native ORDER BY name;
SELECT 1/((count(*)=53 AND bool_and(ok))::integer) AS native_53_of_53 FROM slice18_native;
COMMIT;
