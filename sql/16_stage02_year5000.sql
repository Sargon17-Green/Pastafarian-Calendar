-- Stage 2 Slice 14: bounded year-5000 gate window and sauce-ranked selection.
-- தமிழ்: ஆண்டு 5000 வாயில் சாளரமும் சாஸ் தரவரிசைத் தேர்வும்.
-- Production only: no reference schema, mutable cache, or temporary table.
-- The finite day window is [p_calculation_day-5778, p_calculation_day+5778],
-- expanded by one sentinel gate on either side.
CREATE TYPE pastafari_sql_tamil.year_rec AS (
  year_number numeric,
  open_gate_index numeric,
  close_gate_index numeric,
  open_gate_day numeric,
  close_gate_day numeric
);

-- Return consecutive gate days from the lower sentinel through the upper
-- sentinel. The min/max gap bounds prove the array length is 15..280.
-- Two bounded directional walks from the foundation avoid separate index scans
-- and repeated gate_day(index) recomputation for the lower sentinel.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.year5000_gate_window(p_calculation_day numeric)
RETURNS TABLE(first_gate_index numeric, gate_days numeric[])
LANGUAGE SQL STABLE STRICT AS $fast$
WITH RECURSIVE
base AS MATERIALIZED (
  SELECT pastafari_sql_tamil.foundation_day() AS foundation,
         p_calculation_day-5778::numeric AS lower_day,
         p_calculation_day+5778::numeric AS upper_day
  WHERE p_calculation_day=trunc(p_calculation_day)
),
starts AS (
  SELECT 1::integer AS dir,0::numeric AS gate_index,
         foundation AS gate_day,upper_day AS limit_day FROM base
  UNION ALL
  SELECT -1::integer,0::numeric,foundation,lower_day FROM base
),
walk(dir,gate_index,gate_day,limit_day,sentinel_done) AS (
  SELECT dir,gate_index,gate_day,limit_day,false FROM starts
  UNION ALL
  SELECT w.dir,w.gate_index+w.dir,
         w.gate_day+CASE
           WHEN w.dir=1 THEN pastafari_sql_tamil.positive_gate_gap(w.gate_index+1)
           ELSE -pastafari_sql_tamil.negative_gate_gap(1-w.gate_index)
         END,
         w.limit_day,
         CASE WHEN w.dir=1 THEN w.gate_day>=w.limit_day
              ELSE w.gate_day<=w.limit_day END
  FROM walk w WHERE NOT w.sentinel_done
),
gates AS MATERIALIZED (
  SELECT DISTINCT ON (gate_index) gate_index,gate_day
  FROM walk ORDER BY gate_index,dir DESC
),
edges AS MATERIALIZED (
  SELECT max(g.gate_index) FILTER (WHERE g.gate_day<=b.lower_day)-1 AS lo,
         min(g.gate_index) FILTER (WHERE g.gate_day>=b.upper_day)+1 AS hi
  FROM gates g CROSS JOIN base b
)
SELECT min(g.gate_index),array_agg(g.gate_day ORDER BY g.gate_index)
FROM gates g CROSS JOIN edges e
WHERE g.gate_index BETWEEN e.lo AND e.hi
HAVING count(*) BETWEEN 15 AND 280
$fast$;

-- The selected pair is the candidate whose 1-based rank is drawn from the
-- same-day sauce, bowl 1, seal 10, over the exact candidate count.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.year5000(
  p_calculation_day numeric
) RETURNS pastafari_sql_tamil.year_rec
LANGUAGE SQL STABLE STRICT AS $sql$
WITH window_data AS MATERIALIZED (
  SELECT first_gate_index,gate_days
  FROM pastafari_sql_tamil.year5000_gate_window(p_calculation_day)
), candidates AS MATERIALIZED (
  SELECT c.*
  FROM window_data AS w
  CROSS JOIN LATERAL pastafari_sql_tamil.year5000_gate_pairs(
    p_calculation_day,w.first_gate_index,w.gate_days
  ) AS c
), selected_rank AS MATERIALIZED (
  SELECT CASE WHEN count(*)>0 THEN
    pastafari_sql_tamil.choose_rank(
      pastafari_sql_tamil.ask_bowl(
        pastafari_sql_tamil.sauce(p_calculation_day,p_calculation_day),1,10
      ),
      max(candidate_count)::numeric
    )
  END AS rank1
  FROM candidates
)
SELECT ROW(
  5000::numeric,
  c.open_gate_index,
  c.close_gate_index,
  c.open_gate_day,
  c.close_gate_day
)::pastafari_sql_tamil.year_rec
FROM candidates AS c
CROSS JOIN selected_rank AS r
WHERE c.candidate_rank=r.rank1
$sql$;
