-- QA-only. Never source into production.
CREATE SCHEMA IF NOT EXISTS pastafari_sql_tamil_qa;
CREATE OR REPLACE FUNCTION pastafari_sql_tamil_qa.bowl_round_one_stone(b numeric[],d numeric,i integer)
RETURNS numeric[] LANGUAGE SQL STABLE STRICT AS $candidate$
WITH ordering AS MATERIALIZED (
 SELECT pastafari_sql_tamil.bowl_order_from_drop(d) AS ord
 WHERE i BETWEEN 1 AND 46 AND d=trunc(d) AND d<>'NaN'::numeric
 AND array_ndims(b)=1 AND array_lower(b,1)=1 AND array_length(b,1)=6
 -- Multidimensional arrays must never reach array_position (WHERE is unordered).
 AND (CASE WHEN array_ndims(b)=1 THEN array_position(b,NULL::numeric) IS NULL ELSE FALSE END)
), st AS MATERIALIZED (
 SELECT pastafari_sql_tamil.stone_state(i) AS stone FROM ordering
), positions AS (
 SELECT g.id,array_position(o.ord,g.id) AS pos,o.ord,st.stone
 FROM ordering o CROSS JOIN st CROSS JOIN generate_series(1,6) g(id)
), neighbors AS (
 SELECT id,pos,stone,
 ord[CASE WHEN pos=1 THEN 6 ELSE pos-1 END] AS prev_id,
 ord[CASE WHEN pos=6 THEN 1 ELSE pos+1 END] AS next_id FROM positions
), poured AS (
 SELECT id,pos,stone,prev_id,next_id,
 CASE pos WHEN 1 THEN pastafari_sql_tamil.save_value(d*d+(stone).wheat*b[id]+3*i)
 WHEN 2 THEN pastafari_sql_tamil.save_value(d*d+(stone).barley*b[id]+5*i)
 WHEN 3 THEN pastafari_sql_tamil.save_value(d*d+(stone).salt*b[id]+7*i)
 ELSE 0::numeric END AS pour FROM neighbors
), mixtures AS (
 SELECT id,pos,prev_id,next_id,
 b[id]+2*b[prev_id]+3*b[next_id]+pour+d+
 CASE pos WHEN 1 THEN (stone).wheat WHEN 2 THEN (stone).barley
 WHEN 3 THEN (stone).salt WHEN 4 THEN (stone).bitter
 WHEN 5 THEN (stone).red ELSE (stone).wheat END AS mix FROM poured
)
SELECT array_agg(pastafari_sql_tamil.save_value(
 mix*mix+5*b[prev_id]*b[next_id]+i*pos) ORDER BY id)
FROM mixtures
$candidate$;
-- Fast regression before 368 expensive comparisons: invalid 2-D input must be NULL, not ERROR.
DO $preflight$
BEGIN
 IF pastafari_sql_tamil_qa.bowl_round_one_stone(
      ARRAY[[1,2,3],[4,5,6]]::numeric[],1::numeric,1) IS NOT NULL THEN
  RAISE EXCEPTION 'SQL_TAMIL_TWO_DIMENSION_GUARD accepted invalid dimensions';
 END IF;
 RAISE NOTICE 'SQL_TAMIL_TWO_DIMENSION_GUARD=PASS';
END $preflight$;
DO $qa$
DECLARE j integer; d numeric; s integer; a numeric[]; before numeric[]; after numeric[];
n integer:=0; bad record; neg integer:=0;
BEGIN
 FOR j IN 1..46 LOOP
  FOREACH d IN ARRAY ARRAY[-1::numeric,1,720,721] LOOP
   FOR s IN 1..2 LOOP
    IF s=1 THEN a:=ARRAY[1,2,3,4,5,6]::numeric[];
    ELSE a:=ARRAY[
     170141183460469231731687303715884105721::numeric,
     170141183460469231731687303715884105722::numeric,
     170141183460469231731687303715884105723::numeric,
     170141183460469231731687303715884105724::numeric,
     170141183460469231731687303715884105725::numeric,
     170141183460469231731687303715884105726::numeric]; END IF;
    before:=pastafari_sql_tamil.bowl_round(a,d,j);
    after:=pastafari_sql_tamil_qa.bowl_round_one_stone(a,d,j);
    IF before IS DISTINCT FROM after THEN
      RAISE EXCEPTION 'mismatch pos=% drop=% shape=%',j,d,s; END IF;
    n:=n+1;
   END LOOP;
  END LOOP;
 END LOOP;
 IF n<>368 THEN RAISE EXCEPTION 'count mismatch %',n; END IF;
 FOR bad IN SELECT * FROM (VALUES
 ('zero',ARRAY[1,2,3,4,5,6]::numeric[],1::numeric,0::integer),
 ('negative',ARRAY[1,2,3,4,5,6]::numeric[],1::numeric,-1::integer),
 ('too_large',ARRAY[1,2,3,4,5,6]::numeric[],1::numeric,47::integer),
 ('null_index',ARRAY[1,2,3,4,5,6]::numeric[],1::numeric,NULL::integer),
 ('fraction',ARRAY[1,2,3,4,5,6]::numeric[],1.5::numeric,1::integer),
 ('nan',ARRAY[1,2,3,4,5,6]::numeric[],'NaN'::numeric,1::integer),
 ('null_drop',ARRAY[1,2,3,4,5,6]::numeric[],NULL::numeric,1::integer),
 ('short',ARRAY[1,2,3]::numeric[],1::numeric,1::integer),
 ('null_item',ARRAY[1,2,NULL,4,5,6]::numeric[],1::numeric,1::integer),
 ('null_array',NULL::numeric[],1::numeric,1::integer),
 ('zero_lower',array_fill(7::numeric,ARRAY[6],ARRAY[0]),1::numeric,1::integer),
 ('two_dims',ARRAY[[1,2,3],[4,5,6]]::numeric[],1::numeric,1::integer)
 ) AS x(label,b,d,i) LOOP
  before:=pastafari_sql_tamil.bowl_round(bad.b,bad.d,bad.i);
  after:=pastafari_sql_tamil_qa.bowl_round_one_stone(bad.b,bad.d,bad.i);
  IF before IS NOT NULL OR after IS NOT NULL THEN
   RAISE EXCEPTION 'invalid input accepted: %',bad.label; END IF;
  neg:=neg+1;
 END LOOP;
 IF neg<>12 THEN RAISE EXCEPTION 'invalid count %',neg; END IF;
 RAISE NOTICE 'SQL_TAMIL_CANDIDATE_DIFFERENTIAL=368/368 PASS';
 RAISE NOTICE 'SQL_TAMIL_CANDIDATE_INVALID=12/12 PASS';
END $qa$;
-- Alternating timings; each query evaluates 46 positions. No speedup claimed a priori.
EXPLAIN (ANALYZE,TIMING OFF,SUMMARY ON)
SELECT sum((pastafari_sql_tamil.bowl_round(ARRAY[1,2,3,4,5,6]::numeric[],721::numeric,g.i))[1]) FROM generate_series(1,46) g(i);
EXPLAIN (ANALYZE,TIMING OFF,SUMMARY ON)
SELECT sum((pastafari_sql_tamil_qa.bowl_round_one_stone(ARRAY[1,2,3,4,5,6]::numeric[],721::numeric,g.i))[1]) FROM generate_series(1,46) g(i);
EXPLAIN (ANALYZE,TIMING OFF,SUMMARY ON)
SELECT sum((pastafari_sql_tamil_qa.bowl_round_one_stone(ARRAY[1,2,3,4,5,6]::numeric[],721::numeric,g.i))[1]) FROM generate_series(1,46) g(i);
EXPLAIN (ANALYZE,TIMING OFF,SUMMARY ON)
SELECT sum((pastafari_sql_tamil.bowl_round(ARRAY[1,2,3,4,5,6]::numeric[],721::numeric,g.i))[1]) FROM generate_series(1,46) g(i);
