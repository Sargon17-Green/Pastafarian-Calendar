-- SQL+தமிழ் Slice20: four independent production-only assertions.
BEGIN;
CREATE TEMP TABLE slice20_isolation(name text PRIMARY KEY,ok boolean NOT NULL);
INSERT INTO slice20_isolation(name,ok)
SELECT name,coalesce(ok,false) FROM (VALUES
 ('no-reference-schema',to_regnamespace('pastafari_sql_tamil_test') IS NULL),
 ('signature',to_regprocedure('pastafari_sql_tamil.choose_month_count(pastafari_sql_tamil.sauce_result,pastafari_sql_tamil.year_rec)') IS NOT NULL),
 ('immutable-strict-pair',(SELECT count(*)=2 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='pastafari_sql_tamil' AND p.proname IN ('choose_month_count','month_count_by_rank')
      AND p.provolatile='i' AND p.proisstrict)),
 ('no-reference-or-mutable-table',(SELECT count(*)=0 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='pastafari_sql_tamil' AND p.proname IN ('choose_month_count','month_count_by_rank')
      AND (position('pastafari_sql_tamil_test' IN pg_get_functiondef(p.oid))>0
        OR EXISTS(SELECT 1 FROM pg_depend d WHERE d.classid='pg_proc'::regclass
          AND d.objid=p.oid AND d.refclassid='pg_class'::regclass))))
) AS x(name,ok);
SELECT name,ok FROM slice20_isolation ORDER BY name;
SELECT 1/((count(*)=4 AND bool_and(ok))::integer) AS isolation_4_of_4 FROM slice20_isolation;
COMMIT;
