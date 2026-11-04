-- Slice21: 1 independent full numeric-array comparison per PostgreSQL shard.
BEGIN;
CREATE TEMP TABLE slice21_diff(name text PRIMARY KEY,ok boolean NOT NULL,detail text NOT NULL);
WITH q AS MATERIALIZED (
 SELECT '__CASE_LABEL__'::text AS label,
 substring('__CASE_LABEL__' from '^d([0-9]+)')::numeric AS days,
 right('__CASE_LABEL__',1) AS seed
), fx AS MATERIALIZED (
 SELECT label,days,
 ROW(CASE WHEN seed='a' THEN ARRAY[10,20,30,40,50,60]::numeric[]
          ELSE ARRAY[6,33,77,111,148,160]::numeric[] END,
     CASE WHEN seed='a' THEN ARRAY[1,2,3,4,5,6]::integer[]
          ELSE ARRAY[6,5,4,3,2,1]::integer[] END)::pastafari_sql_tamil.sauce_result AS s,
 ROW(5000::numeric,0::numeric,6::numeric,0::numeric,days)::pastafari_sql_tamil.year_rec AS y
 FROM q WHERE days IN (252,492,2460,5778) AND seed IN ('a','b')
), selected AS MATERIALIZED (
 SELECT label,days,s,y,pastafari_sql_tamil.choose_month_count(s,y) AS k FROM fx
), compared AS MATERIALIZED (
 SELECT label,days,k,
 pastafari_sql_tamil.choose_month_lengths(s,y,k) AS actual,
 pastafari_sql_tamil_test.choose_month_lengths(
   ROW((s).bowls,(s).order_at_drop_46)::pastafari_sql_tamil_test.sauce_result,
   ROW((y).year_number,(y).open_gate_index,(y).close_gate_index,
       (y).open_gate_day,(y).close_gate_day)::pastafari_sql_tamil_test.year_rec,
   k
 ) AS expected FROM selected
), shaped AS MATERIALIZED (
 SELECT *, (SELECT sum(x) FROM unnest(actual) AS u(x)) AS summed,
 (SELECT bool_and(x BETWEEN 4 AND 123) FROM unnest(actual) AS u(x)) AS bounded
 FROM compared
)
INSERT INTO slice21_diff(name,ok,detail)
SELECT label,coalesce(actual IS NOT NULL AND expected IS NOT NULL
 AND actual IS NOT DISTINCT FROM expected
 AND array_length(actual,1)=k AND summed=days AND bounded
 AND actual[1] BETWEEN 4 AND 123 AND actual[k] BETWEEN 4 AND 123,false),
 format('D=%s k=%s actual=%s expected=%s',days,k,actual,expected)
FROM shaped;
SELECT name,ok,detail FROM slice21_diff ORDER BY name;
SELECT 1/((count(*)=1 AND bool_and(ok))::integer) AS differential_1_of_1 FROM slice21_diff;
COMMIT;
