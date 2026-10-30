-- Isolated test DB only: compare production's 46 results against normative reference.
-- The production schema never imports or invokes this test namespace.
BEGIN;
CREATE TEMP TABLE stage02_visible_differential(
    test_name text PRIMARY KEY,ok boolean NOT NULL CHECK(ok)
);
WITH cases(label,calculation_day,target_day) AS (
  VALUES
   ('same', -15055671::numeric,-15055671::numeric),
   ('forward', -15055674::numeric,-15055669::numeric),
   ('reverse', -15055669::numeric,-15055674::numeric),
   ('large', -15055671::numeric,-15055671::numeric+pastafari_sql_tamil.save_modulus())
), vectors AS MATERIALIZED (
  SELECT label,
     pastafari_sql_tamil.visible_drops(
       pastafari_sql_tamil.work_counts(calculation_day,target_day)) AS actual,
     pastafari_sql_tamil_test.visible_drops(
       pastafari_sql_tamil_test.work_counts(calculation_day,target_day)) AS expected
  FROM cases
)
INSERT INTO stage02_visible_differential(test_name,ok)
SELECT label||':'||i,actual[i]=expected[i]
FROM vectors CROSS JOIN generate_series(1,46) AS g(i);
SELECT 'visible differential assertions' AS status,count(*) AS assertion_count
FROM stage02_visible_differential;
COMMIT;
