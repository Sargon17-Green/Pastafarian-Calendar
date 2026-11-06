-- Slice23: exact full integer[] comparisons on 4 reachable k x 2 sauces.
BEGIN;
WITH cases(label,k,variant) AS (
 VALUES ('a1',3,1),('a2',3,2),('b1',5,1),('b2',5,2),
        ('c1',17,1),('c2',17,2),('d1',47,1),('d2',47,2)
), selected AS (
 SELECT * FROM cases WHERE label='__CASE_LABEL__'
), sauce AS MATERIALIZED (
 SELECT label,k,
    (CASE WHEN variant=1 THEN ARRAY[10,20,30,40,50,60]::numeric[]
       ELSE ARRAY[6,33,77,111,148,160]::numeric[] END) AS bowls,
    (CASE WHEN variant=1 THEN ARRAY[1,2,3,4,5,6]::integer[]
       ELSE ARRAY[6,5,4,3,2,1]::integer[] END) AS ord
 FROM selected
), match AS MATERIALIZED (
 SELECT label,k,
    pastafari_sql_tamil.choose_month_names(
       ROW(bowls,ord)::pastafari_sql_tamil.sauce_result,k) AS actual,
    pastafari_sql_tamil_test.choose_month_names(
       ROW(bowls,ord)::pastafari_sql_tamil_test.sauce_result,k) AS expected
 FROM sauce
), verified AS MATERIALIZED (
 SELECT label,k,
    actual IS NOT DISTINCT FROM expected AS exact_array_match,
    cardinality(actual)=k AND cardinality(expected)=k AS length_ok,
    (SELECT count(DISTINCT v)=k FROM unnest(actual) AS u(v)) AS uniqueness_ok,
    (SELECT bool_and(v BETWEEN 1 AND 47 AND v IS NOT NULL)
       FROM unnest(actual) AS u(v)) AS range_ok
 FROM match
)
SELECT label,k,exact_array_match,length_ok,uniqueness_ok,range_ok FROM verified;
WITH cases(label,k,variant) AS (
 VALUES ('a1',3,1),('a2',3,2),('b1',5,1),('b2',5,2),
        ('c1',17,1),('c2',17,2),('d1',47,1),('d2',47,2)
), selected AS (
 SELECT * FROM cases WHERE label='__CASE_LABEL__'
), actuals AS MATERIALIZED (
 SELECT k,
   pastafari_sql_tamil.choose_month_names(
     ROW(CASE WHEN variant=1 THEN ARRAY[10,20,30,40,50,60]::numeric[]
              ELSE ARRAY[6,33,77,111,148,160]::numeric[] END,
         CASE WHEN variant=1 THEN ARRAY[1,2,3,4,5,6]::integer[]
              ELSE ARRAY[6,5,4,3,2,1]::integer[] END
     )::pastafari_sql_tamil.sauce_result,k) AS actual,
   pastafari_sql_tamil_test.choose_month_names(
     ROW(CASE WHEN variant=1 THEN ARRAY[10,20,30,40,50,60]::numeric[]
              ELSE ARRAY[6,33,77,111,148,160]::numeric[] END,
         CASE WHEN variant=1 THEN ARRAY[1,2,3,4,5,6]::integer[]
              ELSE ARRAY[6,5,4,3,2,1]::integer[] END
     )::pastafari_sql_tamil_test.sauce_result,k) AS expected
 FROM selected
)
SELECT 1/((count(*)=1 AND bool_and(actual IS NOT DISTINCT FROM expected
      AND cardinality(actual)=k AND cardinality(expected)=k
      AND (SELECT count(DISTINCT v)=k FROM unnest(actual) AS u(v))
      AND (SELECT bool_and(v BETWEEN 1 AND 47 AND v IS NOT NULL)
           FROM unnest(actual) AS u(v))))::integer)
  AS diff___CASE_LABEL___exact_array FROM actuals;
COMMIT;
