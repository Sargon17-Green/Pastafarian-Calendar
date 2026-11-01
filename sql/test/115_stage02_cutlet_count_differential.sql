-- SQL+தமிழ் Stage 2 Slice 17: independent normative cutlet-count differential.
-- Two case-label placeholders are substituted by CI for each bounded case.
CREATE TEMP TABLE stage02_cutlet_count_differential(
 test_name text PRIMARY KEY,ok boolean NOT NULL,detail text NOT NULL
);
WITH case_data AS MATERIALIZED (
 SELECT '__CASE_LABEL__'::text AS case_name
), fixtures AS MATERIALIZED (
 SELECT case_name,
   CASE case_name WHEN 'g6' THEN 6 WHEN 'g7' THEN 7
                  WHEN 'g17' THEN 17 WHEN 'g18' THEN 18
                  ELSE NULL END::numeric AS gaps,
   ROW(ARRAY[10,20,30,40,50,60]::numeric[],
       ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS s
 FROM case_data
), converted AS MATERIALIZED (
 SELECT case_name,gaps,s,
   ROW(5000::numeric,0::numeric,gaps,0::numeric,100::numeric)::pastafari_sql_tamil.year_rec AS yr,
   ROW((s).bowls,(s).order_at_drop_46)::pastafari_sql_tamil_test.sauce_result AS ref_s,
   ROW(5000::numeric,0::numeric,gaps,0::numeric,100::numeric)::pastafari_sql_tamil_test.year_rec AS ref_yr
 FROM fixtures WHERE gaps IS NOT NULL
), compared AS MATERIALIZED (
 SELECT case_name,gaps,
   pastafari_sql_tamil.choose_cutlet_count(s,yr) AS actual,
   pastafari_sql_tamil_test.choose_cutlet_count(ref_s,ref_yr) AS expected
 FROM converted
)
INSERT INTO stage02_cutlet_count_differential(test_name,ok,detail)
SELECT '__CASE_LABEL__',
   (actual IS NOT NULL AND actual IS NOT DISTINCT FROM expected
      AND actual BETWEEN 6 AND least(17,gaps)),
   'gaps='||gaps||';actual='||coalesce(actual::text,'NULL')||
   ';expected='||coalesce(expected::text,'NULL')
FROM compared;
SELECT test_name,ok,detail FROM stage02_cutlet_count_differential;
SELECT 1/((count(*)=1 AND bool_and(ok))::integer) AS differential_1_of_1
FROM stage02_cutlet_count_differential;
