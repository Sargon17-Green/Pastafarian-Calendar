-- Slice 9 differential gate: 3 vectors x 7 + 1 full sauce x 7 = 28.
-- Reference database is separate from production isolation database.
BEGIN;
CREATE TEMP TABLE stage02_answer_differential(
 test_name text PRIMARY KEY,ok boolean NOT NULL CHECK(ok)
);
WITH cases(label,b,ord,q,seal) AS (VALUES
('ascending',ARRAY[1,2,3,4,5,6]::numeric[],ARRAY[6,2,4,1,5,3]::integer[],1,1),
('edge',ARRAY[170141183460469231731687303715884105727,170141183460469231731687303715884105726,170141183460469231731687303715884105725,170141183460469231731687303715884105724,170141183460469231731687303715884105723,170141183460469231731687303715884105722]::numeric[],ARRAY[1,2,3,4,5,6]::integer[],6,0),
('mixed',ARRAY[7,17,37,77,127,197]::numeric[],ARRAY[3,1,6,2,5,4]::integer[],2,-7)
), calculated AS MATERIALIZED (
 SELECT label,
 pastafari_sql_tamil.next_bowl_in_drop46_order(
 ROW(b,ord)::pastafari_sql_tamil.sauce_result,q) AS actual_next,
 pastafari_sql_tamil_test.next_bowl_in_drop46_order(
 ROW(b,ord)::pastafari_sql_tamil_test.sauce_result,q) AS expected_next,
 pastafari_sql_tamil.ask_bowl(
 ROW(b,ord)::pastafari_sql_tamil.sauce_result,q,seal) AS actual,
 pastafari_sql_tamil_test.ask_bowl(
 ROW(b,ord)::pastafari_sql_tamil_test.sauce_result,q,seal) AS expected
 FROM cases
)
INSERT INTO stage02_answer_differential(test_name,ok)
SELECT label||':'||v.item,v.ok FROM calculated
CROSS JOIN LATERAL (VALUES ('next',actual_next=expected_next),
 ('first',(actual).first_value=(expected).first_value),
 ('direction',(actual).direction_step=(expected).direction_step),
 ('answer-1',pastafari_sql_tamil.answer_at(actual,-1)=pastafari_sql_tamil_test.answer_at(expected,-1)),
 ('answer0',pastafari_sql_tamil.answer_at(actual,0)=pastafari_sql_tamil_test.answer_at(expected,0)),
 ('answer1',pastafari_sql_tamil.answer_at(actual,1)=pastafari_sql_tamil_test.answer_at(expected,1)),
 ('answer7',pastafari_sql_tamil.answer_at(actual,7)=pastafari_sql_tamil_test.answer_at(expected,7))) AS v(item,ok);

WITH full_pair AS (
 SELECT pastafari_sql_tamil.sauce(-15055671,-15055671) AS production,
        pastafari_sql_tamil_test.sauce(-15055671,-15055671) AS reference
), calculated AS MATERIALIZED (
 SELECT pastafari_sql_tamil.next_bowl_in_drop46_order(production,3) AS actual_next,
        pastafari_sql_tamil_test.next_bowl_in_drop46_order(reference,3) AS expected_next,
        pastafari_sql_tamil.ask_bowl(production,3,2) AS actual,
        pastafari_sql_tamil_test.ask_bowl(reference,3,2) AS expected
 FROM full_pair
)
INSERT INTO stage02_answer_differential(test_name,ok)
SELECT 'full-sauce:'||v.item,v.ok FROM calculated
CROSS JOIN LATERAL (VALUES ('next',actual_next=expected_next),
 ('first',(actual).first_value=(expected).first_value),
 ('direction',(actual).direction_step=(expected).direction_step),
 ('answer-1',pastafari_sql_tamil.answer_at(actual,-1)=pastafari_sql_tamil_test.answer_at(expected,-1)),
 ('answer0',pastafari_sql_tamil.answer_at(actual,0)=pastafari_sql_tamil_test.answer_at(expected,0)),
 ('answer1',pastafari_sql_tamil.answer_at(actual,1)=pastafari_sql_tamil_test.answer_at(expected,1)),
 ('answer7',pastafari_sql_tamil.answer_at(actual,7)=pastafari_sql_tamil_test.answer_at(expected,7))) AS v(item,ok);
SELECT count(*) AS differential_assertions FROM stage02_answer_differential;
COMMIT;
