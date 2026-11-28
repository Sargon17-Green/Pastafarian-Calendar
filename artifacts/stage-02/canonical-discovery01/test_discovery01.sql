-- Stage02: நான்கு துல்லியமான உள்ளீடுகள்; எதிர்பார்க்கப்படும் வேறுபாடுகளை அளவிடுதல்.
BEGIN;
CREATE TEMP TABLE discovery01_results (
  case_id text PRIMARY KEY, x numeric NOT NULL, legacy numeric NOT NULL,
  oracle numeric NOT NULL, expected_legacy numeric NOT NULL, expected_match boolean NOT NULL
);
INSERT INTO discovery01_results
SELECT case_id,x,pastafari_sql_tamil.save_value(x),oracle,expected_legacy,expected_match
FROM (VALUES
 ('M',170141183460469231731687303715884105727::numeric,170141183460469231731687303715884105727::numeric,0::numeric,false),
 ('2M',340282366920938463463374607431768211454::numeric,170141183460469231731687303715884105727::numeric,0::numeric,false),
 ('3M',510423550381407695195061911147652317181::numeric,170141183460469231731687303715884105727::numeric,0::numeric,false),
 ('M+1',170141183460469231731687303715884105728::numeric,1::numeric,1::numeric,true)
) AS cases(case_id,x,oracle,expected_legacy,expected_match);
SELECT case_id,x,legacy,oracle,legacy=oracle AS normative_match
FROM discovery01_results ORDER BY x;
SELECT 1/((count(*)=4 AND count(*) FILTER (WHERE legacy<>oracle)=3
 AND count(*) FILTER (WHERE legacy=oracle)=1
 AND bool_and(legacy=expected_legacy AND (legacy=oracle)=expected_match))::integer) AS discovery01_observed_pattern
FROM discovery01_results;
SELECT 1/((to_regnamespace('pastafari_sql_tamil_test') IS NULL
 AND position('pastafari_sql_tamil.old_remainder' in pg_get_functiondef('pastafari_sql_tamil.save_value(numeric)'::regprocedure))>0
 AND (SELECT count(*)=0 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='pastafari_sql_tamil' AND p.proname ~ '(^|_)(old|legacy|patch|detour|ghost|latch)($|_)'
 AND p.proname<>'old_remainder'))::integer) AS candidate_route_and_scope;
SELECT 1/(((SELECT count(*)=0 FROM pastafari_sql_tamil.calendar_date_spaghetti(0,0))
 AND (pastafari_sql_tamil.new_monster_context(11,22)).calculation_day=11
 AND (pastafari_sql_tamil.new_monster_context(11,22)).target_day=22
 AND (pastafari_sql_tamil.base_dispatch(pastafari_sql_tamil.new_monster_context(11,22))).status='READY')::integer) AS bootstrap_compatibility;
COMMIT;
