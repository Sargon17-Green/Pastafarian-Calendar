-- SQL+தமிழ் Stage 2 Slice 16: bounded navigation Native checks.
-- Every production call uses PostgreSQL NUMERIC; no reference schema is loaded.
BEGIN;
CREATE TEMP TABLE stage02_target_year_native (
  test_name text PRIMARY KEY,
  ok boolean NOT NULL,
  detail text NOT NULL
);
WITH base AS MATERIALIZED (
  SELECT pastafari_sql_tamil.foundation_day() AS f
),
seed AS MATERIALIZED (
  SELECT f,pastafari_sql_tamil.year5000(f) AS known
  FROM base
),
adjacent AS MATERIALIZED (
  SELECT f,known,
    pastafari_sql_tamil.next_year(f,known) AS next_rec,
    pastafari_sql_tamil.previous_year(f,known) AS prev_rec
  FROM seed
),
resolved AS MATERIALIZED (
  SELECT f,known,next_rec,prev_rec,
    pastafari_sql_tamil.find_target_year(f,f) AS same_rec,
    pastafari_sql_tamil.find_target_year(f,(known).close_gate_day) AS close_rec,
    pastafari_sql_tamil.find_target_year(f,(known).open_gate_day) AS open_rec,
    pastafari_sql_tamil.find_target_year(f,(known).open_gate_day-1) AS before_rec,
    pastafari_sql_tamil.find_target_year(f,(known).close_gate_day+1) AS after_rec,
    pastafari_sql_tamil.find_target_year(NULL::numeric,f) AS null_calc,
    pastafari_sql_tamil.find_target_year(f,NULL::numeric) AS null_target,
    pastafari_sql_tamil.find_target_year(f+0.5,f) AS fraction_calc,
    pastafari_sql_tamil.find_target_year(f,f+0.5) AS fraction_target,
    pastafari_sql_tamil.find_target_year(f,f+60001) AS too_far_forward,
    pastafari_sql_tamil.find_target_year(f,f-60001) AS too_far_backward
  FROM adjacent
)
INSERT INTO stage02_target_year_native(test_name,ok,detail)
SELECT t.name,t.ok, t.detail
FROM resolved AS r
CROSS JOIN LATERAL (VALUES
 ('seed-at-calculation',r.same_rec IS NOT DISTINCT FROM r.known,'same'),
 ('inclusive-close',r.close_rec IS NOT DISTINCT FROM r.known,'close'),
 ('exclusive-open',r.open_rec IS NOT DISTINCT FROM r.prev_rec,'open'),
 ('one-day-before-open',r.before_rec IS NOT DISTINCT FROM r.prev_rec,'before'),
 ('one-day-after-close',r.after_rec IS NOT DISTINCT FROM r.next_rec,'after'),
 ('backward-link',(r.prev_rec).close_gate_day=(r.known).open_gate_day,'previous boundary'),
 ('forward-link',(r.next_rec).open_gate_day=(r.known).close_gate_day,'next boundary'),
 ('monotonic-years',(r.prev_rec).year_number=(r.known).year_number-1
   AND (r.next_rec).year_number=(r.known).year_number+1,'year order'),
 ('record-integral',(r.after_rec).year_number=trunc((r.after_rec).year_number)
   AND (r.after_rec).open_gate_index=trunc((r.after_rec).open_gate_index)
   AND (r.after_rec).close_gate_index=trunc((r.after_rec).close_gate_index)
   AND (r.after_rec).open_gate_day=trunc((r.after_rec).open_gate_day)
   AND (r.after_rec).close_gate_day=trunc((r.after_rec).close_gate_day),'five fields'),
 ('index-zero-crossing',(r.known).open_gate_index<0
   AND (r.known).close_gate_index>0,'foundation year'),
 ('strict-null-calculation',r.null_calc IS NULL,'null calculation'),
 ('strict-null-target',r.null_target IS NULL,'null target'),
 ('fractional-calculation-rejected',r.fraction_calc IS NULL,'no rounding'),
 ('fractional-target-rejected',r.fraction_target IS NULL,'no rounding'),
 ('positive-out-of-range',r.too_far_forward IS NULL,'delta=60001'),
 ('negative-out-of-range',r.too_far_backward IS NULL,'delta=-60001'),
 ('budget-upper-bound',least(256::numeric,ceil(60000::numeric/252)+1)=240,'B(60000)=240'),
 ('budget-zero',least(256::numeric,ceil(0::numeric/252)+1)=1,'B(0)=1')
) AS t(name,ok,detail);
SELECT test_name,ok,detail FROM stage02_target_year_native ORDER BY test_name;
SELECT count(*) AS native_assertions FROM stage02_target_year_native;
SELECT 1/((count(*)=18 AND bool_and(ok))::integer) AS native_18_of_18
FROM stage02_target_year_native;
COMMIT;
