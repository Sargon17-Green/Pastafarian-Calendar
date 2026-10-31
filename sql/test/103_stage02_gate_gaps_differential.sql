-- 6 full-sauce offset vectors, both signs = 12 differential assertions.
BEGIN;
CREATE TEMP TABLE stage02_gate_gaps_differential(test_name text PRIMARY KEY,ok boolean NOT NULL CHECK(ok));
WITH offsets(n) AS (VALUES (1::numeric),(2::numeric),(3::numeric),(7::numeric),(46::numeric),(123::numeric)),
 p AS MATERIALIZED (
 SELECT n,
 pastafari_sql_tamil.positive_gate_gap(n) AS pos,
 pastafari_sql_tamil_test.positive_gate_gap(n) AS pos_ref,
 pastafari_sql_tamil.negative_gate_gap(n) AS neg,
 pastafari_sql_tamil_test.negative_gate_gap(n) AS neg_ref
 FROM offsets
)
INSERT INTO stage02_gate_gaps_differential(test_name,ok)
 SELECT 'positive:'||n,pos=pos_ref FROM p
 UNION ALL SELECT 'negative:'||n,neg=neg_ref FROM p;
SELECT count(*) AS differential_assertions FROM stage02_gate_gaps_differential;
COMMIT;
