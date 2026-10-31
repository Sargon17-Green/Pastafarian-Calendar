-- 6 offsets x 4 properties (24) + 5 invalid + 3 metadata = 32.
BEGIN;
CREATE TEMP TABLE stage02_gate_gaps_native(test_name text PRIMARY KEY,ok boolean NOT NULL CHECK(ok));
WITH offsets(n) AS (VALUES (1::numeric),(2::numeric),(3::numeric),(7::numeric),(46::numeric),(123::numeric)),
 eval AS MATERIALIZED (
 SELECT n,pastafari_sql_tamil.positive_gate_gap(n) AS p,
 pastafari_sql_tamil.negative_gate_gap(n) AS m,
 pastafari_sql_tamil.gate_gap_signed(n) AS sp,
 pastafari_sql_tamil.gate_gap_signed(-n) AS sm FROM offsets
 )
INSERT INTO stage02_gate_gaps_native(test_name,ok)
 SELECT 'positive-bounds:'||n,p BETWEEN 42 AND 963 FROM eval
 UNION ALL SELECT 'negative-bounds:'||n,m BETWEEN 42 AND 963 FROM eval
 UNION ALL SELECT 'signed-positive:'||n,p=sp FROM eval
 UNION ALL SELECT 'signed-negative:'||n,m=sm FROM eval;

INSERT INTO stage02_gate_gaps_native(test_name,ok)
 SELECT 'invalid:signed-zero',pastafari_sql_tamil.gate_gap_signed(0) IS NULL
 UNION ALL SELECT 'invalid:signed-fraction',pastafari_sql_tamil.gate_gap_signed(1.5) IS NULL
 UNION ALL SELECT 'invalid:positive-zero',pastafari_sql_tamil.positive_gate_gap(0) IS NULL
 UNION ALL SELECT 'invalid:negative-zero',pastafari_sql_tamil.negative_gate_gap(0) IS NULL
 UNION ALL SELECT 'invalid:positive-negative',pastafari_sql_tamil.positive_gate_gap(-2) IS NULL;

INSERT INTO stage02_gate_gaps_native(test_name,ok)
 SELECT 'metadata:sql-only',(SELECT count(*)=3 FROM pg_proc p
 JOIN pg_namespace n ON n.oid=p.pronamespace JOIN pg_language l ON l.oid=p.prolang
 WHERE n.nspname='pastafari_sql_tamil'
 AND p.proname IN ('gate_gap_signed','positive_gate_gap','negative_gate_gap') AND l.lanname='sql')
 UNION ALL SELECT 'metadata:no-reference-calls',(SELECT count(*)=0 FROM pg_proc p
 JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='pastafari_sql_tamil'
 AND p.proname IN ('gate_gap_signed','positive_gate_gap','negative_gate_gap')
 AND position('pastafari_sql_tamil_test' IN pg_get_functiondef(p.oid))>0)
 UNION ALL SELECT 'metadata:stable',(SELECT count(*)=3 FROM pg_proc p
 JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='pastafari_sql_tamil'
 AND p.proname IN ('gate_gap_signed','positive_gate_gap','negative_gate_gap') AND p.provolatile='s');
SELECT count(*) AS native_assertions FROM stage02_gate_gaps_native;
COMMIT;
