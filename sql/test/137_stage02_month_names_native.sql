-- Slice23: exact independent 64 full-array goldens + semantic PostgreSQL 17 gates.
BEGIN;
CREATE TEMP TABLE slice23_checks(label text PRIMARY KEY,ok boolean NOT NULL);
INSERT INTO slice23_checks(label,ok)
SELECT 'golden-'||name,
       coalesce(pastafari_sql_tamil.month_names_ranked(k,NULL::pastafari_sql_tamil.answer_stream,rank1)
                IS NOT DISTINCT FROM expected,false)
FROM slice23_goldens;
WITH f AS MATERIALIZED (
 SELECT ROW(ARRAY[10,20,30,40,50,60]::numeric[],
            ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS s,
        ROW(ARRAY[6,33,77,111,148,160]::numeric[],
            ARRAY[6,5,4,3,2,1]::integer[])::pastafari_sql_tamil.sauce_result AS t
)
INSERT INTO slice23_checks(label,ok)
SELECT name,coalesce(ok,false) FROM f CROSS JOIN LATERAL (VALUES
 ('goldens-count',(SELECT count(*)=64 FROM slice23_goldens)),
 ('goldens-8-k',(SELECT count(DISTINCT k)=8 FROM slice23_goldens)),
 ('goldens-k47',(SELECT count(*)=8 FROM slice23_goldens WHERE k=47)),
 ('goldens-k3',(SELECT count(*)=8 FROM slice23_goldens WHERE k=3)),
 ('goldens-k17',(SELECT count(*)=8 FROM slice23_goldens WHERE k=17)),
 ('goldens-boundary-ends',(SELECT count(*)=8 FROM slice23_goldens WHERE name LIKE '%-r8')),
 ('helper-signature',to_regprocedure('pastafari_sql_tamil.month_names_ranked(integer,pastafari_sql_tamil.answer_stream,numeric)') IS NOT NULL),
 ('choose-signature',to_regprocedure('pastafari_sql_tamil.choose_month_names(pastafari_sql_tamil.sauce_result,integer)') IS NOT NULL),
 ('null-k',pastafari_sql_tamil.month_names_ranked(NULL,NULL::pastafari_sql_tamil.answer_stream,1) IS NULL),
 ('k0',pastafari_sql_tamil.month_names_ranked(0,NULL::pastafari_sql_tamil.answer_stream,1) IS NULL),
 ('kminus',pastafari_sql_tamil.month_names_ranked(-1,NULL::pastafari_sql_tamil.answer_stream,1) IS NULL),
 ('k48',pastafari_sql_tamil.month_names_ranked(48,NULL::pastafari_sql_tamil.answer_stream,1) IS NULL),
 ('rank0',pastafari_sql_tamil.month_names_ranked(3,NULL::pastafari_sql_tamil.answer_stream,0) IS NULL),
 ('rankminus',pastafari_sql_tamil.month_names_ranked(3,NULL::pastafari_sql_tamil.answer_stream,-1) IS NULL),
 ('rankfraction',pastafari_sql_tamil.month_names_ranked(3,NULL::pastafari_sql_tamil.answer_stream,1.25) IS NULL),
 ('ranklarge',pastafari_sql_tamil.month_names_ranked(47,NULL::pastafari_sql_tamil.answer_stream,1e100::numeric) IS NULL),
 ('missing-stream',pastafari_sql_tamil.month_names_ranked(3,NULL::pastafari_sql_tamil.answer_stream,NULL::numeric) IS NULL),
 ('first-k47',pastafari_sql_tamil.month_names_ranked(47,NULL::pastafari_sql_tamil.answer_stream,1)=ARRAY(SELECT generate_series(1,47))::integer[]),
 ('last-k47',pastafari_sql_tamil.month_names_ranked(47,NULL::pastafari_sql_tamil.answer_stream,(SELECT rank1 FROM slice23_goldens WHERE name='k47-r8'))=ARRAY(SELECT generate_series(47,1,-1))::integer[]),
 ('first-k3',pastafari_sql_tamil.month_names_ranked(3,NULL::pastafari_sql_tamil.answer_stream,1)=ARRAY[1,2,3]),
 ('null-sauce',pastafari_sql_tamil.choose_month_names(NULL::pastafari_sql_tamil.sauce_result,3) IS NULL),
 ('null-k-wrapper',pastafari_sql_tamil.choose_month_names(f.s,NULL::integer) IS NULL),
 ('choose-k3',cardinality(pastafari_sql_tamil.choose_month_names(f.s,3))=3),
 ('choose-k5',cardinality(pastafari_sql_tamil.choose_month_names(f.s,5))=5),
 ('choose-k17',cardinality(pastafari_sql_tamil.choose_month_names(f.s,17))=17),
 ('choose-k47',cardinality(pastafari_sql_tamil.choose_month_names(f.s,47))=47),
 ('choose-other-sauce',cardinality(pastafari_sql_tamil.choose_month_names(f.t,47))=47),
 ('distinct-k3',(SELECT count(DISTINCT v)=3 FROM unnest(pastafari_sql_tamil.choose_month_names(f.s,3)) AS u(v))),
 ('distinct-k47',(SELECT count(DISTINCT v)=47 FROM unnest(pastafari_sql_tamil.choose_month_names(f.s,47)) AS u(v))),
 ('range-k17',(SELECT bool_and(v BETWEEN 1 AND 47) FROM unnest(pastafari_sql_tamil.choose_month_names(f.t,17)) AS u(v))),
 ('repeatable',pastafari_sql_tamil.choose_month_names(f.s,17) IS NOT DISTINCT FROM pastafari_sql_tamil.choose_month_names(f.s,17)),
 ('rank-repeatable',pastafari_sql_tamil.month_names_ranked(31,NULL::pastafari_sql_tamil.answer_stream,10001)
   IS NOT DISTINCT FROM pastafari_sql_tamil.month_names_ranked(31,NULL::pastafari_sql_tamil.answer_stream,10001))
) AS gates(name,ok);
SELECT label,ok FROM slice23_checks ORDER BY label;
SELECT count(*) AS total,count(*) FILTER (WHERE ok) AS passed FROM slice23_checks;
SELECT 1/((count(*)>=96 AND bool_and(ok))::integer) AS slice23_native_all_green FROM slice23_checks;
COMMIT;
