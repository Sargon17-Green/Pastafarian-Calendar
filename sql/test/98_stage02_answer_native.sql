-- Slice 9: 21 independent-golden + 6 order + 4 bad-next
-- + 5 bad-ask + 5 bad-answer + 3 metadata = 44.
-- Golden values are exact-integer oracle output, not normative SQL output.
BEGIN;
CREATE TEMP TABLE stage02_answer_native(
 test_name text PRIMARY KEY,ok boolean NOT NULL CHECK(ok)
);
WITH fixtures(label,b,ord,q,seal,en,ef,ed,e0,e1,em1,e7) AS (VALUES
('ascending',ARRAY[1,2,3,4,5,6]::numeric[],ARRAY[6,2,4,1,5,3]::integer[],1,1,5,34385,1,34385,34386,34384,34392),
('edge',ARRAY[170141183460469231731687303715884105727,170141183460469231731687303715884105726,170141183460469231731687303715884105725,170141183460469231731687303715884105724,170141183460469231731687303715884105723,170141183460469231731687303715884105722]::numeric[],ARRAY[1,2,3,4,5,6]::integer[],6,0,1,30976,1,30976,30977,30975,30983),
('mixed',ARRAY[7,17,37,77,127,197]::numeric[],ARRAY[3,1,6,2,5,4]::integer[],2,-7,5,59207,-1,59207,59206,59208,59200)
), results AS MATERIALIZED (
 SELECT f.*,
  pastafari_sql_tamil.next_bowl_in_drop46_order(
    ROW(b,ord)::pastafari_sql_tamil.sauce_result,q) AS got_next,
  pastafari_sql_tamil.ask_bowl(
    ROW(b,ord)::pastafari_sql_tamil.sauce_result,q,seal) AS got_stream
 FROM fixtures f
)
INSERT INTO stage02_answer_native(test_name,ok)
SELECT label||':'||v.item,v.ok FROM results
CROSS JOIN LATERAL (VALUES ('next',got_next=en),
 ('first',(got_stream).first_value=ef),
 ('direction',(got_stream).direction_step=ed),
 ('answer0',pastafari_sql_tamil.answer_at(got_stream,0)=e0),
 ('answer1',pastafari_sql_tamil.answer_at(got_stream,1)=e1),
 ('answer-1',pastafari_sql_tamil.answer_at(got_stream,-1)=em1),
 ('answer7',pastafari_sql_tamil.answer_at(got_stream,7)=e7)) AS v(item,ok);

WITH s AS (
 SELECT ROW(ARRAY[1,2,3,4,5,6]::numeric[],
            ARRAY[6,2,4,1,5,3]::integer[])::pastafari_sql_tamil.sauce_result AS sauce
)
INSERT INTO stage02_answer_native(test_name,ok)
SELECT 'order-next:'||k,
 pastafari_sql_tamil.next_bowl_in_drop46_order(sauce,k)=
 (ARRAY[5,4,6,1,3,2]::integer[])[k]
FROM s CROSS JOIN generate_series(1,6) AS g(k);

WITH s AS (
 SELECT ROW(ARRAY[1,2,3,4,5,6]::numeric[],
            ARRAY[6,2,4,1,5,3]::integer[])::pastafari_sql_tamil.sauce_result AS good,
        ROW(ARRAY[1,2,3,4,5,6]::numeric[],
            ARRAY[1,1,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS dup,
        ROW(ARRAY[1,2,3,4,5,6]::numeric[],
            '[0:5]={1,2,3,4,5,6}'::integer[])::pastafari_sql_tamil.sauce_result AS zero_based
)
INSERT INTO stage02_answer_native(test_name,ok)
SELECT 'invalid-next:zero',pastafari_sql_tamil.next_bowl_in_drop46_order(good,0) IS NULL FROM s
UNION ALL SELECT 'invalid-next:seven',pastafari_sql_tamil.next_bowl_in_drop46_order(good,7) IS NULL FROM s
UNION ALL SELECT 'invalid-next:duplicate',pastafari_sql_tamil.next_bowl_in_drop46_order(dup,1) IS NULL FROM s
UNION ALL SELECT 'invalid-next:zero-based',pastafari_sql_tamil.next_bowl_in_drop46_order(zero_based,1) IS NULL FROM s;

WITH s AS (
 SELECT ROW(ARRAY[1,2,3,4,5,6]::numeric[],
            ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result AS good
)
INSERT INTO stage02_answer_native(test_name,ok)
SELECT 'invalid-ask:short',pastafari_sql_tamil.ask_bowl(
 ROW(ARRAY[1,2]::numeric[],ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result,1,1) IS NULL
UNION ALL SELECT 'invalid-ask:zero',pastafari_sql_tamil.ask_bowl(
 ROW(ARRAY[0,2,3,4,5,6]::numeric[],ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result,1,1) IS NULL
UNION ALL SELECT 'invalid-ask:fraction',pastafari_sql_tamil.ask_bowl(
 ROW(ARRAY[1.5,2,3,4,5,6]::numeric[],ARRAY[1,2,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result,1,1) IS NULL
UNION ALL SELECT 'invalid-ask:query-zero',pastafari_sql_tamil.ask_bowl(good,0,1) IS NULL FROM s
UNION ALL SELECT 'invalid-ask:bad-order',pastafari_sql_tamil.ask_bowl(
 ROW(ARRAY[1,2,3,4,5,6]::numeric[],ARRAY[1,1,3,4,5,6]::integer[])::pastafari_sql_tamil.sauce_result,1,1) IS NULL;

INSERT INTO stage02_answer_native(test_name,ok)
SELECT 'invalid-answer:fraction-k',pastafari_sql_tamil.answer_at(
 ROW(1::numeric,1)::pastafari_sql_tamil.answer_stream,0.5) IS NULL
UNION ALL SELECT 'invalid-answer:zero-step',pastafari_sql_tamil.answer_at(
 ROW(1::numeric,0)::pastafari_sql_tamil.answer_stream,1) IS NULL
UNION ALL SELECT 'invalid-answer:zero-first',pastafari_sql_tamil.answer_at(
 ROW(0::numeric,1)::pastafari_sql_tamil.answer_stream,1) IS NULL
UNION ALL SELECT 'invalid-answer:over-modulus',pastafari_sql_tamil.answer_at(
 ROW(170141183460469231731687303715884105728::numeric,1)::pastafari_sql_tamil.answer_stream,1) IS NULL
UNION ALL SELECT 'invalid-answer:fraction-first',pastafari_sql_tamil.answer_at(
 ROW(1.5::numeric,1)::pastafari_sql_tamil.answer_stream,1) IS NULL;

INSERT INTO stage02_answer_native(test_name,ok)
SELECT 'metadata:no-reference-call',(
 SELECT count(*)=0 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='pastafari_sql_tamil'
 AND p.proname IN ('next_bowl_in_drop46_order','ask_bowl','answer_at')
 AND position('pastafari_sql_tamil_test' IN pg_get_functiondef(p.oid))>0)
UNION ALL SELECT 'metadata:sql-functions',(
 SELECT count(*)=3 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 JOIN pg_language l ON l.oid=p.prolang
 WHERE n.nspname='pastafari_sql_tamil' AND l.lanname='sql'
 AND p.proname IN ('next_bowl_in_drop46_order','ask_bowl','answer_at'))
UNION ALL SELECT 'metadata:immutable',(
 SELECT count(*)=3 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='pastafari_sql_tamil' AND p.provolatile='i'
 AND p.proname IN ('next_bowl_in_drop46_order','ask_bowl','answer_at'));

SELECT count(*) AS native_assertions FROM stage02_answer_native;
COMMIT;
