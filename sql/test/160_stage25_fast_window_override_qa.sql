\set ON_ERROR_STOP on
-- QA ONLY. Overrides year5000_gate_window solely in the disposable offline PG17 job.
-- The production sql/00..26 files in Git are NOT changed.
-- Exact function from sql/test/158 at e4dccbfa3ab999031f2c1b51bab6e2567712360c; only function name changed.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.year5000_gate_window(p_day numeric)
RETURNS TABLE(first_gate_index numeric, gate_days numeric[])
LANGUAGE SQL STABLE STRICT AS $fast$
WITH RECURSIVE
base AS MATERIALIZED (
  SELECT pastafari_sql_tamil.foundation_day() AS foundation,
         p_day-5778::numeric AS lower_day,
         p_day+5778::numeric AS upper_day
  WHERE p_day=trunc(p_day)
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
