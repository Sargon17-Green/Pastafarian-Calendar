-- Stage 2 Slice 10: 28 vectors x direct/dispatcher = 56,
-- plus 3 full sauce choices x direct/dispatcher = 6; total 62 differential.
BEGIN;
CREATE TEMP TABLE stage02_choose_rank_differential(
 test_name text PRIMARY KEY,ok boolean NOT NULL CHECK(ok)
);
WITH cases(label,x,d,n) AS (VALUES
('s1-n1',1,1,1),
('s1-n2',1,1,7),
('s1-n3',1,1,922),
('s1-n4',1,1,170141183460469231731687303715884105727),
('s1-n5',1,1,170141183460469231731687303715884105728),
('s1-n6',1,1,28948022309329048855892746252171976962977213799489202546401021394546514198528),
('s1-n7',1,1,28948022309329048855892746252171976962977213799489202546401021394546514198530),
('s2-n1',170141183460469231731687303715884105727,-1,1),
('s2-n2',170141183460469231731687303715884105727,-1,7),
('s2-n3',170141183460469231731687303715884105727,-1,922),
('s2-n4',170141183460469231731687303715884105727,-1,170141183460469231731687303715884105727),
('s2-n5',170141183460469231731687303715884105727,-1,170141183460469231731687303715884105728),
('s2-n6',170141183460469231731687303715884105727,-1,28948022309329048855892746252171976962977213799489202546401021394546514198528),
('s2-n7',170141183460469231731687303715884105727,-1,28948022309329048855892746252171976962977213799489202546401021394546514198530),
('s3-n1',42,-1,1),
('s3-n2',42,-1,7),
('s3-n3',42,-1,922),
('s3-n4',42,-1,170141183460469231731687303715884105727),
('s3-n5',42,-1,170141183460469231731687303715884105728),
('s3-n6',42,-1,28948022309329048855892746252171976962977213799489202546401021394546514198528),
('s3-n7',42,-1,28948022309329048855892746252171976962977213799489202546401021394546514198530),
('s4-n1',170141183460469231731687303715884105726,1,1),
('s4-n2',170141183460469231731687303715884105726,1,7),
('s4-n3',170141183460469231731687303715884105726,1,922),
('s4-n4',170141183460469231731687303715884105726,1,170141183460469231731687303715884105727),
('s4-n5',170141183460469231731687303715884105726,1,170141183460469231731687303715884105728),
('s4-n6',170141183460469231731687303715884105726,1,28948022309329048855892746252171976962977213799489202546401021394546514198528),
('s4-n7',170141183460469231731687303715884105726,1,28948022309329048855892746252171976962977213799489202546401021394546514198530)
), compared AS MATERIALIZED (
 SELECT label,n,
 CASE WHEN n<=pastafari_sql_tamil.save_modulus()
 THEN pastafari_sql_tamil.choose_rank_short(
   ROW(x,d::integer)::pastafari_sql_tamil.answer_stream,n)
 ELSE pastafari_sql_tamil.choose_rank_wide(
   ROW(x,d::integer)::pastafari_sql_tamil.answer_stream,n)
 END AS actual_direct,
 CASE WHEN n<=pastafari_sql_tamil_test.m()
 THEN pastafari_sql_tamil_test.choose_rank_short(
   ROW(x,d::integer)::pastafari_sql_tamil_test.answer_stream,n)
 ELSE pastafari_sql_tamil_test.choose_rank_wide(
   ROW(x,d::integer)::pastafari_sql_tamil_test.answer_stream,n)
 END AS expected_direct,
 pastafari_sql_tamil.choose_rank(
   ROW(x,d::integer)::pastafari_sql_tamil.answer_stream,n) AS actual_dispatch,
 pastafari_sql_tamil_test.choose_rank(
   ROW(x,d::integer)::pastafari_sql_tamil_test.answer_stream,n) AS expected_dispatch
 FROM cases
)
INSERT INTO stage02_choose_rank_differential(test_name,ok)
SELECT label||':direct',actual_direct=expected_direct FROM compared
UNION ALL SELECT label||':dispatch',actual_dispatch=expected_dispatch FROM compared;

WITH full_sauce AS MATERIALIZED (
 SELECT pastafari_sql_tamil.ask_bowl(
   pastafari_sql_tamil.sauce(-15055671,-15055671),3,1) AS actual,
 pastafari_sql_tamil_test.ask_bowl(
   pastafari_sql_tamil_test.sauce(-15055671,-15055671),3,1) AS expected
), n_cases(label,n) AS (
 VALUES ('small',922::numeric),
 ('wide1',pastafari_sql_tamil.save_modulus()+1),
 ('wide3',power(pastafari_sql_tamil.save_modulus(),2)+1)
), compared AS MATERIALIZED (
 SELECT label,n,
 CASE WHEN n<=pastafari_sql_tamil.save_modulus()
   THEN pastafari_sql_tamil.choose_rank_short(actual,n)
   ELSE pastafari_sql_tamil.choose_rank_wide(actual,n) END AS direct_value,
 CASE WHEN n<=pastafari_sql_tamil_test.m()
   THEN pastafari_sql_tamil_test.choose_rank_short(expected,n)
   ELSE pastafari_sql_tamil_test.choose_rank_wide(expected,n) END AS direct_reference,
 pastafari_sql_tamil.choose_rank(actual,n) AS actual_rank,
 pastafari_sql_tamil_test.choose_rank(expected,n) AS expected_rank
 FROM full_sauce CROSS JOIN n_cases
)
INSERT INTO stage02_choose_rank_differential(test_name,ok)
SELECT 'full-sauce:'||label||':direct',direct_value=direct_reference FROM compared
UNION ALL SELECT 'full-sauce:'||label||':dispatch',actual_rank=expected_rank FROM compared;

SELECT count(*) AS differential_assertions FROM stage02_choose_rank_differential;
COMMIT;
