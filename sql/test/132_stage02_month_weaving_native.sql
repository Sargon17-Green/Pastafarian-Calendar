-- SQL+தமிழ் Slice22: 40 independently generated named goldens + semantic gates.
-- Load sql/test/131_stage02_month_weaving_oracle.py --emit-sql output first.
BEGIN;
CREATE TEMP TABLE slice22_checks(name text PRIMARY KEY,ok boolean NOT NULL);
WITH evaluated AS MATERIALIZED (
    SELECT g.name,g.lengths,g.rank1,g.expected,
           pastafari_sql_tamil.month_weaving_ranked(
             g.lengths,NULL::pastafari_sql_tamil.answer_stream,g.rank1
           ) AS actual
    FROM slice22_goldens AS g
)
INSERT INTO slice22_checks(name,ok)
SELECT 'golden-'||name,coalesce(actual IS NOT DISTINCT FROM expected,false)
FROM evaluated;

WITH fixture AS MATERIALIZED (
    SELECT ROW(
      ARRAY[10,20,30,40,50,60]::numeric[],
      ARRAY[1,2,3,4,5,6]::integer[]
    )::pastafari_sql_tamil.sauce_result AS sauce,
    ROW(
      ARRAY[6,33,77,111,148,160]::numeric[],
      ARRAY[6,5,4,3,2,1]::integer[]
    )::pastafari_sql_tamil.sauce_result AS sauce2,
    ARRAY[84,84,84]::integer[] AS lengths
)
INSERT INTO slice22_checks(name,ok)
SELECT label,coalesce(ok,false)
FROM fixture CROSS JOIN LATERAL (VALUES
  ('golden-exact-count',(SELECT count(*)=40 FROM slice22_goldens)),
  ('golden-vector-diversity',(SELECT count(DISTINCT lengths)>=12 FROM slice22_goldens)),
  ('golden-rank-diversity',(SELECT count(*)>=10 FROM slice22_goldens WHERE rank1>1)),
  ('golden-boundary-present',(SELECT count(*)=1 FROM slice22_goldens
    WHERE name='g40-boundary' AND cardinality(lengths)=47 AND
          (SELECT sum(v) FROM unnest(lengths) AS u(v))=5778)),
  ('rank-zero',pastafari_sql_tamil.month_weaving_ranked(
      fixture.lengths,NULL::pastafari_sql_tamil.answer_stream,0) IS NULL),
  ('rank-minus-one',pastafari_sql_tamil.month_weaving_ranked(
      fixture.lengths,NULL::pastafari_sql_tamil.answer_stream,-1) IS NULL),
  ('rank-fraction',pastafari_sql_tamil.month_weaving_ranked(
      fixture.lengths,NULL::pastafari_sql_tamil.answer_stream,1.25) IS NULL),
  ('rank-over',pastafari_sql_tamil.month_weaving_ranked(
      fixture.lengths,NULL::pastafari_sql_tamil.answer_stream,1e500::numeric) IS NULL),
  ('rank-null-stream',pastafari_sql_tamil.month_weaving_ranked(
      fixture.lengths,NULL::pastafari_sql_tamil.answer_stream,NULL::numeric) IS NULL),
  ('rank-null-lengths',pastafari_sql_tamil.month_weaving_ranked(
      NULL::integer[],NULL::pastafari_sql_tamil.answer_stream,1) IS NULL),
  ('rank-empty-lengths',pastafari_sql_tamil.month_weaving_ranked(
      ARRAY[]::integer[],NULL::pastafari_sql_tamil.answer_stream,1) IS NULL),
  ('rank-null-element',pastafari_sql_tamil.month_weaving_ranked(
      ARRAY[2,NULL,2]::integer[],NULL::pastafari_sql_tamil.answer_stream,1) IS NULL),
  ('rank-under-two',pastafari_sql_tamil.month_weaving_ranked(
      ARRAY[2,1,2]::integer[],NULL::pastafari_sql_tamil.answer_stream,1) IS NULL),
  ('rank-repeatable',pastafari_sql_tamil.month_weaving_ranked(
      fixture.lengths,NULL::pastafari_sql_tamil.answer_stream,2)
      IS NOT DISTINCT FROM pastafari_sql_tamil.month_weaving_ranked(
      fixture.lengths,NULL::pastafari_sql_tamil.answer_stream,2)),
  ('choose-shape',(SELECT cardinality(a)=252 FROM (
       SELECT pastafari_sql_tamil.choose_month_weaving(
         fixture.sauce,fixture.lengths) AS a
     ) AS q)),
  ('choose-alternate-sauce',(SELECT cardinality(a)=252 FROM (
       SELECT pastafari_sql_tamil.choose_month_weaving(
         fixture.sauce2,fixture.lengths) AS a
     ) AS q)),
  ('choose-repeatable',pastafari_sql_tamil.choose_month_weaving(
      fixture.sauce,fixture.lengths)
      IS NOT DISTINCT FROM pastafari_sql_tamil.choose_month_weaving(
      fixture.sauce,fixture.lengths)),
  ('choose-null-sauce',pastafari_sql_tamil.choose_month_weaving(
      NULL::pastafari_sql_tamil.sauce_result,fixture.lengths) IS NULL),
  ('choose-null-lengths',pastafari_sql_tamil.choose_month_weaving(
      fixture.sauce,NULL::integer[]) IS NULL)
) AS t(label,ok);

SELECT name,ok FROM slice22_checks ORDER BY name;
SELECT count(*) AS named_gates, count(*) FILTER (WHERE ok) AS passed
FROM slice22_checks;
SELECT 1/((count(*)>=59 AND bool_and(ok))::integer) AS slice22_native_all_green
FROM slice22_checks;
COMMIT;
