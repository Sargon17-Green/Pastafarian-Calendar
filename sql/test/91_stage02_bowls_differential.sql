-- Separate isolated database only: production vs normative reference.
-- 720 one-based ranks, 12 signed/large wraps, 30 initial-bowl values = 762.
BEGIN;
CREATE TEMP TABLE stage02_bowl_differential(
    test_name text PRIMARY KEY,
    ok boolean NOT NULL CHECK(ok)
);
INSERT INTO stage02_bowl_differential(test_name,ok)
SELECT 'rank:'||r,
  pastafari_sql_tamil.bowl_order_from_number(r)
    =pastafari_sql_tamil_test.bowl_order_from_number(r)
FROM generate_series(1,720) AS s(r);

WITH drops(label,val) AS (VALUES
('d1',-1441::numeric),
('d2',-721::numeric),
('d3',-720::numeric),
('d4',-1::numeric),
('d5',0::numeric),
('d6',1::numeric),
('d7',719::numeric),
('d8',720::numeric),
('d9',721::numeric),
('d10',1440::numeric),
('d11',170141183460469231731687303715884105728::numeric),
('d12',-170141183460469231731687303715884105728::numeric)
)
INSERT INTO stage02_bowl_differential(test_name,ok)
SELECT 'drop:'||label,
    pastafari_sql_tamil.bowl_order_from_drop(val)
      =pastafari_sql_tamil_test.bowl_order_from_drop(val)
FROM drops;

WITH cases(label,calculation_day,target_day) AS (VALUES
('same',-15055671::numeric,-15055671::numeric),
('forward',-15055674::numeric,-15055669::numeric),
('reverse',-15055669::numeric,-15055674::numeric),
('large',-15055671::numeric,170141183460469231731687303715869050056::numeric),
('remote-past',-170141183460469231731687303715899161398::numeric,-15055671::numeric)
), both AS MATERIALIZED (
  SELECT label,
    pastafari_sql_tamil.initial_bowls(
       pastafari_sql_tamil.work_counts(calculation_day,target_day)) AS actual,
    pastafari_sql_tamil_test.initial_bowls(
       pastafari_sql_tamil_test.work_counts(calculation_day,target_day)) AS expected
  FROM cases
)
INSERT INTO stage02_bowl_differential(test_name,ok)
SELECT 'bowl:'||label||':'||bowl_id,actual[bowl_id]=expected[bowl_id]
FROM both CROSS JOIN generate_series(1,6) AS g(bowl_id);

SELECT 'slice5 bowl differential assertions' AS status,count(*) AS assertion_count
FROM stage02_bowl_differential;
COMMIT;
