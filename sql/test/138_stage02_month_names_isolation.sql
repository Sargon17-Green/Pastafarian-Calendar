-- Slice23: isolate production schema in a fresh database.
BEGIN;
CREATE TEMP TABLE slice23_isolation(label text PRIMARY KEY,ok boolean NOT NULL);
WITH f AS (SELECT ROW(ARRAY[10,20,30,40,50,60]::numeric[],
                      ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS s)
INSERT INTO slice23_isolation(label,ok)
SELECT name,coalesce(ok,false) FROM f CROSS JOIN LATERAL (VALUES
 ('reference-absent',to_regnamespace('pastafari_sql_tamil_test') IS NULL),
 ('choose-signature',to_regprocedure('pastafari_sql_tamil.choose_month_names(pastafari_sql_tamil.sauce_result,integer)') IS NOT NULL),
 ('rank-signature',to_regprocedure('pastafari_sql_tamil.month_names_ranked(integer,pastafari_sql_tamil.answer_stream,numeric)') IS NOT NULL),
 ('choose-strict',(SELECT proisstrict FROM pg_proc WHERE oid=to_regprocedure('pastafari_sql_tamil.choose_month_names(pastafari_sql_tamil.sauce_result,integer)'))),
 ('choose-immutable',(SELECT provolatile='i' FROM pg_proc WHERE oid=to_regprocedure('pastafari_sql_tamil.choose_month_names(pastafari_sql_tamil.sauce_result,integer)'))),
 ('no-test-calls',NOT EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace=n.oid
    WHERE n.nspname='pastafari_sql_tamil' AND p.proname IN ('choose_month_names','month_names_ranked')
      AND pg_get_functiondef(p.oid) ILIKE '%pastafari_sql_tamil_test%')),
 ('no-name-cache',NOT EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON c.relnamespace=n.oid
    WHERE n.nspname='pastafari_sql_tamil' AND c.relname IN ('month_names_registry','month_name_cache'))),
 ('rank-first',pastafari_sql_tamil.month_names_ranked(3,NULL::pastafari_sql_tamil.answer_stream,1)=ARRAY[1,2,3]),
 ('rank-invalid',pastafari_sql_tamil.month_names_ranked(3,NULL::pastafari_sql_tamil.answer_stream,0) IS NULL),
 ('choose-k47',cardinality(pastafari_sql_tamil.choose_month_names(f.s,47))=47),
 ('repeat',pastafari_sql_tamil.choose_month_names(f.s,17) IS NOT DISTINCT FROM pastafari_sql_tamil.choose_month_names(f.s,17))
) AS v(name,ok);
SELECT label,ok FROM slice23_isolation ORDER BY label;
SELECT 1/((count(*)=11 AND bool_and(ok))::integer) AS slice23_isolation_all_green FROM slice23_isolation;
COMMIT;
