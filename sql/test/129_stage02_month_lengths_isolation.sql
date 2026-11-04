-- Slice21: PostgreSQL production-only isolation (five independent gates).
BEGIN;
CREATE TEMP TABLE slice21_isolation(name text PRIMARY KEY,ok boolean NOT NULL);
WITH fx AS (
 SELECT ROW(ARRAY[10,20,30,40,50,60]::numeric[],ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS s,
        ROW(5000,0,6,0,252)::pastafari_sql_tamil.year_rec AS y
)
INSERT INTO slice21_isolation(name,ok)
SELECT name,coalesce(ok,false) FROM fx CROSS JOIN LATERAL (VALUES
 ('no-reference-schema',to_regnamespace('pastafari_sql_tamil_test') IS NULL),
 ('signature',to_regprocedure('pastafari_sql_tamil.choose_month_lengths(pastafari_sql_tamil.sauce_result,pastafari_sql_tamil.year_rec,integer)') IS NOT NULL),
 ('immutable-helpers',(SELECT count(*)=2 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='pastafari_sql_tamil' AND p.proname IN ('choose_month_lengths','month_lengths_ranked')
   AND p.provolatile='i' AND ((p.proname='choose_month_lengths' AND p.proisstrict)
     OR (p.proname='month_lengths_ranked' AND NOT p.proisstrict)))),
 ('no-reference-or-mutable-table',(SELECT count(*)=0 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='pastafari_sql_tamil' AND p.proname IN ('choose_month_lengths','month_lengths_ranked')
   AND (position('pastafari_sql_tamil_test' IN pg_get_functiondef(p.oid))>0
     OR EXISTS(SELECT 1 FROM pg_depend d WHERE d.classid='pg_proc'::regclass
       AND d.objid=p.oid AND d.refclassid='pg_class'::regclass)))),
 ('valid-without-reference',pastafari_sql_tamil.choose_month_lengths(fx.s,fx.y,3) IS NOT NULL)
) AS t(name,ok);
SELECT name,ok FROM slice21_isolation ORDER BY name;
SELECT 1/((count(*)=5 AND bool_and(ok))::integer) AS isolation_5_of_5 FROM slice21_isolation;
COMMIT;
