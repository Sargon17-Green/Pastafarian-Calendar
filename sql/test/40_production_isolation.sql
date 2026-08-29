BEGIN;

CREATE TEMP TABLE stage01_production_isolation_assertions (
    test_name text PRIMARY KEY,
    ok boolean NOT NULL CHECK (ok)
);

INSERT INTO stage01_production_isolation_assertions VALUES
('சோதனை ஒப்புநிலைத் தரவுத்தளப் பெயர்வெளி முதன்மை மட்டும் ஏற்றிய நிலையில் இல்லை', to_regnamespace('pastafari_sql_tamil_test') IS NULL);

INSERT INTO stage01_production_isolation_assertions
SELECT 'முதன்மைச் செயற்கூறுகள் சோதனை ஒப்புநிலையை அழைக்கவில்லை', count(*)=0
FROM pg_proc p
JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='pastafari_sql_tamil'
  AND p.prokind='f'
  AND position('pastafari_sql_tamil_test' in pg_get_functiondef(p.oid))>0;

INSERT INTO stage01_production_isolation_assertions
SELECT 'முதன்மைச் செயற்கூறுகள் அனைத்தும் SQL மொழியிலேயே உள்ளன', count(*)=0
FROM pg_proc p
JOIN pg_namespace n ON n.oid=p.pronamespace
JOIN pg_language l ON l.oid=p.prolang
WHERE n.nspname='pastafari_sql_tamil'
  AND p.prokind='f'
  AND l.lanname<>'sql';

INSERT INTO stage01_production_isolation_assertions
WITH funcs AS MATERIALIZED (
  SELECT p.oid
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='pastafari_sql_tamil' AND p.prokind='f'
)
SELECT 'முதன்மை SQL பாதையில் மிதவை கணக்கு இல்லை', count(*)=0
FROM funcs
WHERE lower(pg_get_functiondef(oid)) ~ '(float4|float8|double precision|(^|[^a-z_])real([^a-z_]|$)|power[[:space:]]*\(|ln[[:space:]]*\(|log[[:space:]]*\(|exp[[:space:]]*\(|floor[[:space:]]*\()';

SELECT 'முதன்மைத் தனிமைப்படுத்தல் சோதனைகள் அனைத்தும் வெற்றியடைந்தன' AS status,
       count(*) AS assertion_count
FROM stage01_production_isolation_assertions;

COMMIT;
