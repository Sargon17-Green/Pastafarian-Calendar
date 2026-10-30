-- Slice 6: 432 differential checks in a separate test-only database.
-- 3 date pairs * 4 drop values * 6 stone positions * 6 bowls.
BEGIN;
CREATE TEMP TABLE stage02_round_differential(
    test_name text PRIMARY KEY,
    ok boolean NOT NULL CHECK(ok)
);
WITH cases(label,calculation_day,target_day) AS (VALUES
('same',-15055671::numeric,-15055671::numeric),
('forward',-15055674::numeric,-15055669::numeric),
('remote',-170141183460469231731687303715899161398::numeric,-15055671::numeric)
), drops(drop_label,drop_value) AS (VALUES
('first',1::numeric),('last',720::numeric),('signed',-721::numeric),
('huge',170141183460469231731687303715884105728::numeric)
), indices(stone_index) AS (VALUES (1),(2),(5),(23),(45),(46)),
comparisons AS MATERIALIZED (
    SELECT c.label,d.drop_label,i.stone_index,
      pastafari_sql_tamil.bowl_round(
        pastafari_sql_tamil.initial_bowls(
          pastafari_sql_tamil.work_counts(c.calculation_day,c.target_day)),
        d.drop_value,i.stone_index) AS actual,
      pastafari_sql_tamil_test.bowl_round(
        pastafari_sql_tamil_test.initial_bowls(
          pastafari_sql_tamil_test.work_counts(c.calculation_day,c.target_day)),
        d.drop_value,i.stone_index) AS expected
    FROM cases c CROSS JOIN drops d CROSS JOIN indices i
)
INSERT INTO stage02_round_differential(test_name,ok)
SELECT label||':'||drop_label||':'||stone_index||':'||bowl_id,
       actual[bowl_id]=expected[bowl_id]
FROM comparisons CROSS JOIN generate_series(1,6) AS g(bowl_id);
SELECT count(*) AS differential_assertions FROM stage02_round_differential;
COMMIT;
