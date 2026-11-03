-- SQL+தமிழ் Slice19: one bounded full-array reference comparison per job.
BEGIN;
CREATE TEMP TABLE slice19_diff(name text PRIMARY KEY,ok boolean NOT NULL,detail text NOT NULL);
WITH q AS MATERIALIZED (
 SELECT '__CASE_LABEL__'::text AS label,
 substring('__CASE_LABEL__' from '^k([0-9]+)')::integer AS k,
 right('__CASE_LABEL__',1) AS seed
), fx AS MATERIALIZED (
 SELECT label,k,
 ROW(CASE WHEN seed='a' THEN ARRAY[10,20,30,40,50,60]::numeric[]
          ELSE ARRAY[6,33,77,111,148,160]::numeric[] END,
     CASE WHEN seed='a' THEN ARRAY[1,2,3,4,5,6]::integer[]
          ELSE ARRAY[6,5,4,3,2,1]::integer[] END)::pastafari_sql_tamil.sauce_result AS s
 FROM q WHERE k IN (6,7,12,17) AND seed IN ('a','b')
), compared AS MATERIALIZED (
 SELECT label,k,
 pastafari_sql_tamil.choose_cutlet_names(s,k) AS actual,
 pastafari_sql_tamil_test.choose_cutlet_names(
 ROW((s).bowls,(s).order_at_drop_46)::pastafari_sql_tamil_test.sauce_result,k) AS expected
 FROM fx
)
INSERT INTO slice19_diff(name,ok,detail)
SELECT label,coalesce(
 actual IS NOT NULL AND expected IS NOT NULL AND actual IS NOT DISTINCT FROM expected
 AND array_length(actual,1)=k
 AND (SELECT count(DISTINCT x)=k AND min(x)>=1 AND max(x)<=17 FROM unnest(actual) AS t(x)),false),
 format('k=%s actual=%s expected=%s',k,actual,expected)
FROM compared;
SELECT name,ok,detail FROM slice19_diff ORDER BY name;
SELECT 1/((count(*)=1 AND bool_and(ok))::integer) AS differential_1_of_1 FROM slice19_diff;
COMMIT;
