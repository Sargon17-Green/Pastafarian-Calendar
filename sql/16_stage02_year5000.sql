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
-- A single forward walk avoids recomputing gate_day(index) for every element.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.year5000_gate_window(
  p_calculation_day numeric
) RETURNS TABLE (
  first_gate_index numeric,
  gate_days numeric[]
) LANGUAGE SQL STABLE STRICT AS $sql$
WITH RECURSIVE bounds AS MATERIALIZED (
  SELECT
    pastafari_sql_tamil.gate_index_at_or_before(p_calculation_day-5778)-1 AS lo,
    pastafari_sql_tamil.gate_index_at_or_after(p_calculation_day+5778)+1 AS hi
), seed AS MATERIALIZED (
  SELECT lo,hi,pastafari_sql_tamil.gate_day(lo) AS first_day
  FROM bounds
  WHERE lo IS NOT NULL AND hi IS NOT NULL AND lo<=hi
), walk(gate_index,gate_day,last_index) AS (
  SELECT lo,first_day,hi FROM seed
  UNION ALL
  SELECT w.gate_index+1,
         w.gate_day + CASE
           WHEN w.gate_index<0
             THEN pastafari_sql_tamil.negative_gate_gap(-w.gate_index)
           ELSE pastafari_sql_tamil.positive_gate_gap(w.gate_index+1)
         END,
         w.last_index
  FROM walk AS w
  WHERE w.gate_index<w.last_index
)
SELECT min(gate_index),array_agg(gate_day ORDER BY gate_index)
FROM walk
GROUP BY last_index
HAVING count(*) BETWEEN 15 AND 280
$sql$;

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
