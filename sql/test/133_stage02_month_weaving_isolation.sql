-- SQL+தமிழ் Slice22 production-only isolation; no normative SQL is loaded.
BEGIN;
CREATE TEMP TABLE slice22_isolation(name text PRIMARY KEY,ok boolean NOT NULL);
WITH f AS MATERIALIZED (
  SELECT ROW(ARRAY[10,20,30,40,50,60]::numeric[],
             ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS sauce,
         ARRAY[84,84,84]::integer[] AS lengths
)
INSERT INTO slice22_isolation(name,ok)
SELECT name,coalesce(ok,false) FROM f CROSS JOIN LATERAL (VALUES
 ('no-normative-schema',to_regnamespace('pastafari_sql_tamil_test') IS NULL),
 ('production-signature',to_regprocedure(
   'pastafari_sql_tamil.choose_month_weaving(pastafari_sql_tamil.sauce_result,integer[])') IS NOT NULL),
 ('strictness',(SELECT proisstrict FROM pg_proc WHERE oid=to_regprocedure(
   'pastafari_sql_tamil.choose_month_weaving(pastafari_sql_tamil.sauce_result,integer[])'))),
 ('immutable',(SELECT provolatile='i' FROM pg_proc WHERE oid=to_regprocedure(
   'pastafari_sql_tamil.choose_month_weaving(pastafari_sql_tamil.sauce_result,integer[])'))),
 ('no-production-memo',NOT EXISTS (
   SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
   WHERE n.nspname='pastafari_sql_tamil'
     AND c.relname IN ('weave_family_registry','weave_future_memo','month_weaving_cache'))),
 ('production-no-reference-dependency',NOT EXISTS (
   SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='pastafari_sql_tamil'
     AND p.proname IN ('choose_month_weaving','month_weaving_ranked')
     AND pg_get_functiondef(p.oid) ILIKE '%pastafari_sql_tamil_test%')),
 ('first-rank-repeatable',
   pastafari_sql_tamil.month_weaving_ranked(
      f.lengths,NULL::pastafari_sql_tamil.answer_stream,1)
   IS NOT DISTINCT FROM
   pastafari_sql_tamil.month_weaving_ranked(
      f.lengths,NULL::pastafari_sql_tamil.answer_stream,1)),
 ('sauce-call-valid',(SELECT cardinality(a)=252 FROM (
   SELECT pastafari_sql_tamil.choose_month_weaving(f.sauce,f.lengths) AS a
 ) AS q))
) AS t(name,ok);
SELECT name,ok FROM slice22_isolation ORDER BY name;
SELECT 1/((count(*)=8 AND bool_and(ok))::integer) AS isolation_8_of_8
FROM slice22_isolation;
COMMIT;
