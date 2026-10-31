-- Independent cached reference vs pure source: 3 days + 3*3 selectors + 2 exact = 14.
BEGIN;
CREATE TEMP TABLE stage02_gate_selector_differential(test_name text PRIMARY KEY,ok boolean NOT NULL CHECK(ok));
WITH b AS MATERIALIZED (
 SELECT pastafari_sql_tamil.foundation_day() AS f
), v AS MATERIALIZED (
 SELECT d
 FROM b CROSS JOIN LATERAL (VALUES (f-1::numeric),(f),(f+1::numeric)) AS q(d)
)
INSERT INTO stage02_gate_selector_differential
 SELECT 'before:'||d,
    pastafari_sql_tamil.gate_index_at_or_before(d)=pastafari_sql_tamil_test.gate_index_at_or_before(d)
 FROM v
 UNION ALL SELECT 'after:'||d,
    pastafari_sql_tamil.gate_index_at_or_after(d)=pastafari_sql_tamil_test.gate_index_at_or_after(d)
 FROM v
 UNION ALL SELECT 'exact:'||d,
    pastafari_sql_tamil.exact_gate_index(d) IS NOT DISTINCT FROM pastafari_sql_tamil_test.exact_gate_index(d)
 FROM v;
INSERT INTO stage02_gate_selector_differential
 SELECT 'gate-day:'||i,
   pastafari_sql_tamil.gate_day(i)=pastafari_sql_tamil_test.gate_day(i)
 FROM (VALUES (-1::numeric),(0::numeric),(1::numeric)) AS q(i);
INSERT INTO stage02_gate_selector_differential
 SELECT 'boundary:gate-minus-one',pastafari_sql_tamil.gate_index_at_or_before(
   pastafari_sql_tamil.gate_day(-1))=pastafari_sql_tamil_test.gate_index_at_or_before(
   pastafari_sql_tamil_test.gate_day(-1))
 UNION ALL SELECT 'boundary:gate-plus-one',pastafari_sql_tamil.gate_index_at_or_after(
   pastafari_sql_tamil.gate_day(1))=pastafari_sql_tamil_test.gate_index_at_or_after(
   pastafari_sql_tamil_test.gate_day(1));
SELECT count(*) AS differential_assertions FROM stage02_gate_selector_differential;
COMMIT;
