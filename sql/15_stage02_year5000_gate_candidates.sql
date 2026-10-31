-- Stage 2 Slice 13: bounded year-5000 candidate ordering over supplied gate days.
-- தமிழ்: ஆண்டு 5000 வாயில்-இணை வேட்பாளர் வரிசை.
-- Internal intermediate rows only; not the final five calendar components.
-- Gate array is consecutive days from index p_first_index, starting at position 1.
-- Caller must obtain the broad year-5000 gate window separately; no cache or oracle.
-- Validation: integer day/index, 7..320 gate days, adjacent differences 42..963,
-- valid 1-based one-dimensional array. A bad input produces no rows.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.year5000_gate_pairs(
  p_day numeric, p_first_index numeric, p_gate_days numeric[]
) RETURNS TABLE (
  candidate_rank bigint, candidate_count bigint, open_gate_index numeric,
  close_gate_index numeric, open_gate_day numeric, close_gate_day numeric
) LANGUAGE SQL IMMUTABLE STRICT AS $sql$
WITH accepted AS MATERIALIZED (
  SELECT array_length(p_gate_days,1) AS n
  WHERE p_day=trunc(p_day)
    AND p_first_index=trunc(p_first_index)
    AND array_ndims(p_gate_days)=1 AND array_lower(p_gate_days,1)=1
    AND array_length(p_gate_days,1) BETWEEN 7 AND 320
), gates AS MATERIALIZED (
  SELECT g.k, p_gate_days[g.k] AS d
  FROM accepted CROSS JOIN LATERAL generate_subscripts(p_gate_days,1) AS g(k)
), gaps AS MATERIALIZED (
  SELECT k,d,lag(d) OVER (ORDER BY k) AS previous_day FROM gates
), integrity AS MATERIALIZED (
  SELECT coalesce(bool_and(d IS NOT NULL AND d=trunc(d)
           AND (k=1 OR d-previous_day BETWEEN 42 AND 963)),false) AS ok
  FROM gaps
), numbered AS (
  SELECT row_number() OVER (ORDER BY c.d-o.d,o.d) AS candidate_rank,
         count(*) OVER () AS candidate_count,
         p_first_index+o.k-1 AS open_gate_index,
         p_first_index+c.k-1 AS close_gate_index,
         o.d AS open_gate_day, c.d AS close_gate_day
  FROM gates AS o JOIN gates AS c ON c.k>=o.k+6
  CROSS JOIN integrity AS v
  WHERE v.ok AND c.d-o.d BETWEEN 252 AND 5778
    AND o.d<p_day AND p_day<=c.d
)
SELECT candidate_rank,candidate_count,open_gate_index,close_gate_index,
       open_gate_day,close_gate_day
FROM numbered ORDER BY candidate_rank
$sql$;

-- A 1-based rank is supplied explicitly. Generation of that rank from sauce
-- and the complete year-5000 window is an integration step, NOT claimed here.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.year5000_pick_gate_pair(
  p_day numeric, p_first_index numeric, p_gate_days numeric[], p_rank numeric
) RETURNS TABLE (
  candidate_rank bigint, candidate_count bigint, open_gate_index numeric,
  close_gate_index numeric, open_gate_day numeric, close_gate_day numeric
) LANGUAGE SQL IMMUTABLE STRICT AS $sql$
  SELECT x.candidate_rank,x.candidate_count,x.open_gate_index,x.close_gate_index,
         x.open_gate_day,x.close_gate_day
  FROM pastafari_sql_tamil.year5000_gate_pairs(
      p_day,p_first_index,p_gate_days) AS x
  WHERE p_rank=trunc(p_rank) AND p_rank>=1 AND x.candidate_rank=p_rank
$sql$;
