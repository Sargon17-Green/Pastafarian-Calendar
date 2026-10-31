-- 19 boundary/recurrence checks + 4 invalid + 3 metadata = 26.
BEGIN;
CREATE TEMP TABLE stage02_gate_selector_native(test_name text PRIMARY KEY,ok boolean NOT NULL CHECK(ok));
WITH b AS MATERIALIZED (
  SELECT pastafari_sql_tamil.foundation_day() AS f
), g AS MATERIALIZED (
  SELECT b.f,
    pastafari_sql_tamil.gate_day(-1::numeric) AS dn,
    pastafari_sql_tamil.gate_day(0::numeric) AS d0,
    pastafari_sql_tamil.gate_day(1::numeric) AS dp,
    pastafari_sql_tamil.negative_gate_gap(1::numeric) AS gn,
    pastafari_sql_tamil.positive_gate_gap(1::numeric) AS gp
  FROM b
), q AS MATERIALIZED (
  SELECT g.*,
    pastafari_sql_tamil.gate_index_at_or_before(f) AS bf,
    pastafari_sql_tamil.gate_index_at_or_after(f) AS af,
    pastafari_sql_tamil.exact_gate_index(f) AS ef,
    pastafari_sql_tamil.gate_index_at_or_before(f+1) AS br,
    pastafari_sql_tamil.gate_index_at_or_after(f+1) AS ar,
    pastafari_sql_tamil.exact_gate_index(f+1) AS er,
    pastafari_sql_tamil.gate_index_at_or_before(f-1) AS bl,
    pastafari_sql_tamil.gate_index_at_or_after(f-1) AS al,
    pastafari_sql_tamil.exact_gate_index(f-1) AS el,
    pastafari_sql_tamil.gate_index_at_or_before(dp) AS bp,
    pastafari_sql_tamil.gate_index_at_or_after(dp) AS ap,
    pastafari_sql_tamil.exact_gate_index(dp) AS ep,
    pastafari_sql_tamil.gate_index_at_or_before(dn) AS bn,
    pastafari_sql_tamil.gate_index_at_or_after(dn) AS an,
    pastafari_sql_tamil.exact_gate_index(dn) AS en
  FROM g
)
INSERT INTO stage02_gate_selector_native
 SELECT 'foundation',d0=f FROM q
 UNION ALL SELECT 'positive-recurrence',dp=f+gp FROM q
 UNION ALL SELECT 'negative-recurrence',dn=f-gn FROM q
 UNION ALL SELECT 'strict-order',dn<d0 AND d0<dp FROM q
 UNION ALL SELECT 'before:foundation',bf=0 FROM q
 UNION ALL SELECT 'after:foundation',af=0 FROM q
 UNION ALL SELECT 'exact:foundation',ef=0 FROM q
 UNION ALL SELECT 'before:plus-one-day',br=0 FROM q
 UNION ALL SELECT 'after:plus-one-day',ar=1 FROM q
 UNION ALL SELECT 'exact:plus-one-day',er IS NULL FROM q
 UNION ALL SELECT 'before:minus-one-day',bl=-1 FROM q
 UNION ALL SELECT 'after:minus-one-day',al=0 FROM q
 UNION ALL SELECT 'exact:minus-one-day',el IS NULL FROM q
 UNION ALL SELECT 'before:next-gate',bp=1 FROM q
 UNION ALL SELECT 'after:next-gate',ap=1 FROM q
 UNION ALL SELECT 'exact:next-gate',ep=1 FROM q
 UNION ALL SELECT 'before:previous-gate',bn=-1 FROM q
 UNION ALL SELECT 'after:previous-gate',an=-1 FROM q
 UNION ALL SELECT 'exact:previous-gate',en=-1 FROM q;
INSERT INTO stage02_gate_selector_native
 SELECT 'invalid:gate-day',pastafari_sql_tamil.gate_day(1.5) IS NULL
 UNION ALL SELECT 'invalid:before',pastafari_sql_tamil.gate_index_at_or_before(-15055670.5) IS NULL
 UNION ALL SELECT 'invalid:after',pastafari_sql_tamil.gate_index_at_or_after(-15055670.5) IS NULL
 UNION ALL SELECT 'invalid:exact',pastafari_sql_tamil.exact_gate_index(-15055670.5) IS NULL;
INSERT INTO stage02_gate_selector_native
 SELECT 'metadata:sql',(SELECT count(*)=4 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace JOIN pg_language l ON l.oid=p.prolang
 WHERE n.nspname='pastafari_sql_tamil' AND p.proname IN ('gate_day','gate_index_at_or_before','gate_index_at_or_after','exact_gate_index') AND l.lanname='sql')
 UNION ALL SELECT 'metadata:stable',(SELECT count(*)=4 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='pastafari_sql_tamil' AND p.proname IN ('gate_day','gate_index_at_or_before','gate_index_at_or_after','exact_gate_index') AND p.provolatile='s')
 UNION ALL SELECT 'metadata:no-reference',(SELECT count(*)=0 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='pastafari_sql_tamil' AND p.proname IN ('gate_day','gate_index_at_or_before','gate_index_at_or_after','exact_gate_index')
 AND position('pastafari_sql_tamil_test' IN pg_get_functiondef(p.oid))>0);
SELECT count(*) AS native_assertions FROM stage02_gate_selector_native;
COMMIT;
