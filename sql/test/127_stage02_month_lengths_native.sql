-- Slice21: named PostgreSQL 17 Native assertions and independent oracle goldens.
BEGIN;
CREATE TEMP TABLE slice21_native(name text PRIMARY KEY,ok boolean NOT NULL);
WITH f AS MATERIALIZED (
 SELECT
 ROW(ARRAY[10,20,30,40,50,60]::numeric[],ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS s,
 ROW(ARRAY[6,33,77,111,148,160]::numeric[],ARRAY[6,5,4,3,2,1]::integer[])::pastafari_sql_tamil.sauce_result AS s2,
 ROW(ARRAY[0,20,30,40,50,60]::numeric[],ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS bad_zero,
 ROW(ARRAY[10,20,30,40,50,60]::numeric[],ARRAY[1,2,3,4,5,5]::integer[])::pastafari_sql_tamil.sauce_result AS bad_dup,
 ROW(ARRAY[10,20,30,40,50,60]::numeric[],ARRAY[1,2,3,4,5]::integer[])::pastafari_sql_tamil.sauce_result AS bad_short,
 ROW(5000,0,6,0,252)::pastafari_sql_tamil.year_rec AS y252,
 ROW(5000,0,6,0,253)::pastafari_sql_tamil.year_rec AS y253,
 ROW(5000,0,6,0,492)::pastafari_sql_tamil.year_rec AS y492,
 ROW(5000,0,6,0,2460)::pastafari_sql_tamil.year_rec AS y2460,
 ROW(5000,0,6,0,5778)::pastafari_sql_tamil.year_rec AS y5778
)
INSERT INTO slice21_native(name,ok)
SELECT name,coalesce(ok,false) FROM f CROSS JOIN LATERAL (VALUES
 ('goldens-50',(SELECT count(*)=50 AND bool_and(pastafari_sql_tamil.month_lengths_ranked(days,slots,NULL::pastafari_sql_tamil.answer_stream,rank1) IS NOT DISTINCT FROM expected) FROM slice21_goldens)),
 ('goldens-domains',(SELECT count(DISTINCT days)>=8 FROM slice21_goldens)),
 ('goldens-lex-mid',(SELECT count(*)>=10 FROM slice21_goldens WHERE rank1>1)),
 ('rank-252-first',pastafari_sql_tamil.month_lengths_ranked(252,3,NULL::pastafari_sql_tamil.answer_stream,1)=ARRAY[6,123,123]::integer[]),
 ('rank-252-last',pastafari_sql_tamil.month_lengths_ranked(252,3,NULL::pastafari_sql_tamil.answer_stream,1) < pastafari_sql_tamil.month_lengths_ranked(252,3,NULL::pastafari_sql_tamil.answer_stream,2) ),
 ('rank-253-first',pastafari_sql_tamil.month_lengths_ranked(253,3,NULL::pastafari_sql_tamil.answer_stream,1)=ARRAY[7,123,123]::integer[]),
 ('rank-253-last',pastafari_sql_tamil.month_lengths_ranked(253,3,NULL::pastafari_sql_tamil.answer_stream,2) > pastafari_sql_tamil.month_lengths_ranked(253,3,NULL::pastafari_sql_tamil.answer_stream,1)),
 ('rank-492-max',pastafari_sql_tamil.month_lengths_ranked(492,4,NULL::pastafari_sql_tamil.answer_stream,1)=ARRAY[123,123,123,123]::integer[]),
 ('rank-2460-max',pastafari_sql_tamil.month_lengths_ranked(2460,20,NULL::pastafari_sql_tamil.answer_stream,1)=array_fill(123,ARRAY[20])),
 ('rank-5778-first',pastafari_sql_tamil.month_lengths_ranked(5778,47,NULL::pastafari_sql_tamil.answer_stream,1)=ARRAY[120]::integer[] || array_fill(123,ARRAY[46])),
 ('rank-5778-last',pastafari_sql_tamil.month_lengths_ranked(5778,47,NULL::pastafari_sql_tamil.answer_stream,18424)=array_fill(123,ARRAY[46]) || ARRAY[120]::integer[]),
 ('rank-5778-middle-shape',(SELECT array_length(a,1)=47 AND (SELECT sum(v) FROM unnest(a) AS u(v))=5778 AND (SELECT bool_and(v BETWEEN 4 AND 123) FROM unnest(a) AS u(v)) FROM (SELECT pastafari_sql_tamil.month_lengths_ranked(5778,47,NULL::pastafari_sql_tamil.answer_stream,9212) AS a) AS q)),
 ('rank-252-middle-shape',(SELECT array_length(a,1)=47 AND (SELECT sum(v) FROM unnest(a) AS u(v))=252 AND (SELECT bool_and(v BETWEEN 4 AND 123) FROM unnest(a) AS u(v)) FROM (SELECT pastafari_sql_tamil.month_lengths_ranked(252,47,NULL::pastafari_sql_tamil.answer_stream,100) AS a) AS q)),
 ('rank-253-first-shape',(SELECT array_length(a,1)=3 AND (SELECT sum(v) FROM unnest(a) AS u(v))=253 AND (SELECT bool_and(v BETWEEN 4 AND 123) FROM unnest(a) AS u(v)) FROM (SELECT pastafari_sql_tamil.month_lengths_ranked(253,3,NULL::pastafari_sql_tamil.answer_stream,1) AS a) AS q)),
 ('rank-492-first-shape',(SELECT array_length(a,1)=4 AND (SELECT sum(v) FROM unnest(a) AS u(v))=492 AND (SELECT bool_and(v BETWEEN 4 AND 123) FROM unnest(a) AS u(v)) FROM (SELECT pastafari_sql_tamil.month_lengths_ranked(492,4,NULL::pastafari_sql_tamil.answer_stream,1) AS a) AS q)),
 ('rank-2460-first-shape',(SELECT array_length(a,1)=20 AND (SELECT sum(v) FROM unnest(a) AS u(v))=2460 AND (SELECT bool_and(v BETWEEN 4 AND 123) FROM unnest(a) AS u(v)) FROM (SELECT pastafari_sql_tamil.month_lengths_ranked(2460,20,NULL::pastafari_sql_tamil.answer_stream,1) AS a) AS q)),
 ('choose-252-shape',(SELECT array_length(a,1)=3 AND (SELECT sum(v) FROM unnest(a) AS u(v))=252 AND (SELECT bool_and(v BETWEEN 4 AND 123) FROM unnest(a) AS u(v)) FROM (SELECT pastafari_sql_tamil.choose_month_lengths(f.s,f.y252,3) AS a) AS q)),
 ('choose-253-shape',(SELECT array_length(a,1)=3 AND (SELECT sum(v) FROM unnest(a) AS u(v))=253 AND (SELECT bool_and(v BETWEEN 4 AND 123) FROM unnest(a) AS u(v)) FROM (SELECT pastafari_sql_tamil.choose_month_lengths(f.s,f.y253,3) AS a) AS q)),
 ('choose-492-shape',(SELECT array_length(a,1)=4 AND (SELECT sum(v) FROM unnest(a) AS u(v))=492 AND (SELECT bool_and(v BETWEEN 4 AND 123) FROM unnest(a) AS u(v)) FROM (SELECT pastafari_sql_tamil.choose_month_lengths(f.s,f.y492,4) AS a) AS q)),
 ('choose-2460-shape',(SELECT array_length(a,1)=20 AND (SELECT sum(v) FROM unnest(a) AS u(v))=2460 AND (SELECT bool_and(v BETWEEN 4 AND 123) FROM unnest(a) AS u(v)) FROM (SELECT pastafari_sql_tamil.choose_month_lengths(f.s,f.y2460,20) AS a) AS q)),
 ('choose-5778-shape',(SELECT array_length(a,1)=47 AND (SELECT sum(v) FROM unnest(a) AS u(v))=5778 AND (SELECT bool_and(v BETWEEN 4 AND 123) FROM unnest(a) AS u(v)) FROM (SELECT pastafari_sql_tamil.choose_month_lengths(f.s,f.y5778,47) AS a) AS q)),
 ('choose-repeat',pastafari_sql_tamil.choose_month_lengths(f.s,f.y253,3) IS NOT DISTINCT FROM pastafari_sql_tamil.choose_month_lengths(f.s,f.y253,3)),
 ('choose-alt-sauce',(SELECT array_length(a,1)=3 AND (SELECT sum(v) FROM unnest(a) AS u(v))=252 AND (SELECT bool_and(v BETWEEN 4 AND 123) FROM unnest(a) AS u(v)) FROM (SELECT pastafari_sql_tamil.choose_month_lengths(f.s2,f.y252,3) AS a) AS q)),
 ('null-sauce',pastafari_sql_tamil.choose_month_lengths(NULL::pastafari_sql_tamil.sauce_result,f.y252,3) IS NULL),
 ('null-year',pastafari_sql_tamil.choose_month_lengths(f.s,NULL::pastafari_sql_tamil.year_rec,3) IS NULL),
 ('null-k',pastafari_sql_tamil.choose_month_lengths(f.s,f.y252,NULL::integer) IS NULL),
 ('bad-bowl-zero',pastafari_sql_tamil.choose_month_lengths(f.bad_zero,f.y252,3) IS NULL),
 ('bad-bowl-order',pastafari_sql_tamil.choose_month_lengths(f.bad_dup,f.y252,3) IS NULL),
 ('bad-bowl-short',pastafari_sql_tamil.choose_month_lengths(f.bad_short,f.y252,3) IS NULL),
 ('bad-year-fraction',pastafari_sql_tamil.choose_month_lengths(f.s,ROW(5000,0,6,0,252.5)::pastafari_sql_tamil.year_rec,3) IS NULL),
 ('bad-year-null-field',pastafari_sql_tamil.choose_month_lengths(f.s,ROW(5000,0,6,NULL,252)::pastafari_sql_tamil.year_rec,3) IS NULL),
 ('bad-year-gate-gap',pastafari_sql_tamil.choose_month_lengths(f.s,ROW(5000,0,5,0,252)::pastafari_sql_tamil.year_rec,3) IS NULL),
 ('bad-year-negative-gap',pastafari_sql_tamil.choose_month_lengths(f.s,ROW(5000,0,6,252,0)::pastafari_sql_tamil.year_rec,3) IS NULL),
 ('bad-year-low',pastafari_sql_tamil.choose_month_lengths(f.s,ROW(5000,0,6,0,251)::pastafari_sql_tamil.year_rec,3) IS NULL),
 ('bad-year-high',pastafari_sql_tamil.choose_month_lengths(f.s,ROW(5000,0,6,0,5779)::pastafari_sql_tamil.year_rec,47) IS NULL),
 ('bad-k-zero',pastafari_sql_tamil.choose_month_lengths(f.s,f.y252,0) IS NULL),
 ('bad-k-negative',pastafari_sql_tamil.choose_month_lengths(f.s,f.y252,-1) IS NULL),
 ('bad-k-high',pastafari_sql_tamil.choose_month_lengths(f.s,f.y252,48) IS NULL),
 ('bad-k-incompatible',pastafari_sql_tamil.choose_month_lengths(f.s,f.y492,3) IS NULL),
 ('bad-rank-zero',pastafari_sql_tamil.month_lengths_ranked(252,3,NULL::pastafari_sql_tamil.answer_stream,0) IS NULL),
 ('bad-rank-fraction',pastafari_sql_tamil.month_lengths_ranked(252,3,NULL::pastafari_sql_tamil.answer_stream,1.5) IS NULL),
 ('bad-rank-over',pastafari_sql_tamil.month_lengths_ranked(5778,47,NULL::pastafari_sql_tamil.answer_stream,18425) IS NULL),
 ('bad-null-stream',pastafari_sql_tamil.month_lengths_ranked(252,3,NULL::pastafari_sql_tamil.answer_stream,NULL::numeric) IS NULL)
) AS t(name,ok);
SELECT name,ok FROM slice21_native ORDER BY name;
SELECT 1/((count(*)=43 AND bool_and(ok))::integer) AS native_43_of_43 FROM slice21_native;
COMMIT;
