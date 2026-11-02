-- SQL+தமிழ் Slice18: two full integer-array normative cases per matrix job.
BEGIN;
CREATE TEMP TABLE slice18_diff(name text PRIMARY KEY,ok boolean NOT NULL,detail text NOT NULL);
WITH fx AS MATERIALIZED (
 SELECT '__CASE_LABEL__'::text AS label,
 CASE '__CASE_LABEL__' WHEN 'g6' THEN 6 WHEN 'g7' THEN 7 WHEN 'g8' THEN 8 WHEN 'g9' THEN 9 ELSE NULL END::numeric AS g,
 ROW(ARRAY[10,20,30,40,50,60]::numeric[],ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS s
), prepared AS MATERIALIZED (
 SELECT label,g,s,
 ROW(5000::numeric,0::numeric,g,pastafari_sql_tamil.gate_day(0),pastafari_sql_tamil.gate_day(g))::pastafari_sql_tamil.year_rec AS y,
 ROW((s).bowls,(s).order_at_drop_46)::pastafari_sql_tamil_test.sauce_result AS rs,
 ROW(5000::numeric,0::numeric,g,pastafari_sql_tamil.gate_day(0),pastafari_sql_tamil.gate_day(g))::pastafari_sql_tamil_test.year_rec AS ry
 FROM fx WHERE g IS NOT NULL
), variants AS MATERIALIZED (
 SELECT *,v.r,
 CASE WHEN v.r IS NULL THEN pastafari_sql_tamil.gate_day(0)+1 ELSE pastafari_sql_tamil.gate_day(v.r) END AS day,
 pastafari_sql_tamil.choose_cutlet_count(s,y) AS k
 FROM prepared CROSS JOIN (VALUES(NULL::integer),(2)) AS v(r)
), compared AS MATERIALIZED (
 SELECT label,g,r,k,
 pastafari_sql_tamil.choose_cutlet_partition(day,s,y,k) AS actual,
 pastafari_sql_tamil_test.choose_cutlet_partition(day,rs,ry,k) AS expected
 FROM variants
)
INSERT INTO slice18_diff(name,ok,detail)
SELECT label||CASE WHEN r IS NULL THEN '-non-gate' ELSE '-exact-r2' END,
 coalesce(actual IS NOT NULL AND actual IS NOT DISTINCT FROM expected AND
 array_length(actual,1)=k AND
 (SELECT sum(v)=g AND min(v)>0 FROM unnest(actual) AS t(v)),false),
 format('g=%s;k=%s;r=%s;actual=%s;expected=%s',g,k,coalesce(r::text,'none'),actual,expected)
FROM compared;
SELECT name,ok,detail FROM slice18_diff ORDER BY name;
SELECT 1/((count(*)=2 AND bool_and(ok))::integer) AS differential_2_of_2 FROM slice18_diff;
COMMIT;
