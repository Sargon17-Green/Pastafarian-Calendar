-- SQL+தமிழ் Slice22: exact array differential. Replace CASE_LABEL only with allowed matrix values.
BEGIN;
WITH chosen AS MATERIALIZED (
  SELECT label,lengths,variant FROM (VALUES
    ('a1',ARRAY[84,84,84]::integer[],1),
    ('a2',ARRAY[84,84,84]::integer[],2),
    ('b1',ARRAY[6,123,123]::integer[],1),
    ('b2',ARRAY[6,123,123]::integer[],2),
    ('c1',ARRAY[80,82,90]::integer[],1),
    ('c2',ARRAY[80,82,90]::integer[],2),
    ('d1',ARRAY[123,100,29]::integer[],1),
    ('d2',ARRAY[123,100,29]::integer[],2)
  ) AS cases(label,lengths,variant)
  WHERE label='__CASE_LABEL__'
), calculated AS MATERIALIZED (
  SELECT c.label,c.lengths,
    pastafari_sql_tamil.choose_month_weaving(
       ROW(ARRAY[10,20,30,40,50,60]::numeric[],
           CASE WHEN c.variant=1 THEN ARRAY[1,2,3,4,5,6]::integer[]
                ELSE ARRAY[6,5,4,3,2,1]::integer[] END
       )::pastafari_sql_tamil.sauce_result,c.lengths) AS actual,
    pastafari_sql_tamil_test.choose_month_weaving(
       ROW(ARRAY[10,20,30,40,50,60]::numeric[],
           CASE WHEN c.variant=1 THEN ARRAY[1,2,3,4,5,6]::integer[]
                ELSE ARRAY[6,5,4,3,2,1]::integer[] END
       )::pastafari_sql_tamil_test.sauce_result,c.lengths) AS expected
  FROM chosen c
), validated AS (
  SELECT label,lengths,actual,expected,
         cardinality(actual) AS actual_length,
         (SELECT sum(x)::integer FROM unnest(lengths) AS u(x)) AS wanted_length,
         (SELECT bool_and(
             (SELECT count(*) FROM unnest(actual) AS u(x) WHERE x=j)=lengths[j]
           ) FROM generate_series(1,cardinality(lengths)) AS s(j)) AS multiplicities,
         (SELECT bool_and(first_pos<lead_first AND last_pos<lead_last) FROM (
              SELECT symbol,
                     min(ord) AS first_pos,
                     max(ord) AS last_pos,
                     lead(min(ord)) OVER (ORDER BY symbol) AS lead_first,
                     lead(max(ord)) OVER (ORDER BY symbol) AS lead_last
              FROM unnest(actual) WITH ORDINALITY AS u(symbol,ord)
              GROUP BY symbol
           ) AS q WHERE lead_first IS NOT NULL) AS ordered_first_and_last
  FROM calculated
)
SELECT label,
       actual IS NOT DISTINCT FROM expected AS exact_array_match,
       actual_length=wanted_length AS length_ok,
       multiplicities,
       ordered_first_and_last
FROM validated;
WITH chosen AS (
  SELECT label,lengths,variant FROM (VALUES
    ('a1',ARRAY[84,84,84]::integer[],1),
    ('a2',ARRAY[84,84,84]::integer[],2),
    ('b1',ARRAY[6,123,123]::integer[],1),
    ('b2',ARRAY[6,123,123]::integer[],2),
    ('c1',ARRAY[80,82,90]::integer[],1),
    ('c2',ARRAY[80,82,90]::integer[],2),
    ('d1',ARRAY[123,100,29]::integer[],1),
    ('d2',ARRAY[123,100,29]::integer[],2)
  ) AS cases(label,lengths,variant)
  WHERE label='__CASE_LABEL__'
), calculated AS (
  SELECT c.lengths,
    pastafari_sql_tamil.choose_month_weaving(
      ROW(ARRAY[10,20,30,40,50,60]::numeric[],
          CASE WHEN c.variant=1 THEN ARRAY[1,2,3,4,5,6]::integer[]
               ELSE ARRAY[6,5,4,3,2,1]::integer[] END
      )::pastafari_sql_tamil.sauce_result,c.lengths) AS actual,
    pastafari_sql_tamil_test.choose_month_weaving(
      ROW(ARRAY[10,20,30,40,50,60]::numeric[],
          CASE WHEN c.variant=1 THEN ARRAY[1,2,3,4,5,6]::integer[]
               ELSE ARRAY[6,5,4,3,2,1]::integer[] END
      )::pastafari_sql_tamil_test.sauce_result,c.lengths) AS expected
  FROM chosen c
)
SELECT 1/((count(*)=1 AND bool_and(
 actual IS NOT DISTINCT FROM expected
 AND cardinality(actual)=(SELECT sum(v) FROM unnest(lengths) AS u(v))
 ))::integer) AS "diff___CASE_LABEL___exact_array"
FROM calculated;
COMMIT;
