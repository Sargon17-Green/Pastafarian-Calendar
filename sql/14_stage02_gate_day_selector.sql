-- Stage 2 Slice 12: gate-day projection and index selector.
-- தமிழ்: எல்லை நாள் மற்றும் குறியீட்டு தேர்வு.
-- Pure PostgreSQL numeric SQL. No mutable cache, reference schema or dynamic SQL.
-- Domain: integral gate index / integral day. The exhaustive selector is
-- intentionally unbounded; its cost grows with the number of crossed gates.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.gate_day(p_index numeric)
RETURNS numeric LANGUAGE SQL STABLE STRICT AS $sql$
  SELECT pastafari_sql_tamil.foundation_day() +
    CASE
      WHEN p_index>0 THEN
        (SELECT sum(pastafari_sql_tamil.positive_gate_gap(k))
         FROM generate_series(1::numeric,p_index,1::numeric) AS g(k))
      WHEN p_index<0 THEN
        -(SELECT sum(pastafari_sql_tamil.negative_gate_gap(k))
          FROM generate_series(1::numeric,-p_index,1::numeric) AS g(k))
      ELSE 0::numeric
    END
  WHERE p_index=trunc(p_index)
$sql$;

-- A single forward/backward walk from the foundation finds the lower index.
-- The walk stops at the first crossing, without persistent state.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.gate_index_at_or_before(p_day numeric)
RETURNS numeric LANGUAGE SQL STABLE STRICT AS $sql$
 WITH RECURSIVE base AS MATERIALIZED (
   SELECT pastafari_sql_tamil.foundation_day() AS foundation
   WHERE p_day=trunc(p_day)
 ), walk(gate_index,gate_day) AS (
   SELECT 0::numeric,foundation FROM base
   UNION ALL
   SELECT walk.gate_index + CASE WHEN p_day>=base.foundation THEN 1 ELSE -1 END,
          walk.gate_day + CASE
            WHEN p_day>=base.foundation
              THEN pastafari_sql_tamil.positive_gate_gap(walk.gate_index+1)
            ELSE -pastafari_sql_tamil.negative_gate_gap(abs(walk.gate_index-1))
          END
   FROM walk CROSS JOIN base
   WHERE (p_day>=base.foundation AND walk.gate_day<=p_day)
      OR (p_day<base.foundation AND walk.gate_day>p_day)
 )
 SELECT CASE
   WHEN p_day>=base.foundation THEN max(walk.gate_index) FILTER (WHERE walk.gate_day<=p_day)
   ELSE min(walk.gate_index) FILTER (WHERE walk.gate_day<=p_day)
 END
 FROM walk CROSS JOIN base
 GROUP BY base.foundation
$sql$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.gate_index_at_or_after(p_day numeric)
RETURNS numeric LANGUAGE SQL STABLE STRICT AS $sql$
 WITH lower AS MATERIALIZED (
  SELECT pastafari_sql_tamil.gate_index_at_or_before(p_day) AS i
  WHERE p_day=trunc(p_day)
 )
 SELECT i+CASE WHEN pastafari_sql_tamil.gate_day(i)=p_day THEN 0 ELSE 1 END
 FROM lower
$sql$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.exact_gate_index(p_day numeric)
RETURNS numeric LANGUAGE SQL STABLE STRICT AS $sql$
 WITH lower AS MATERIALIZED (
  SELECT pastafari_sql_tamil.gate_index_at_or_before(p_day) AS i
  WHERE p_day=trunc(p_day)
 )
 SELECT i FROM lower WHERE pastafari_sql_tamil.gate_day(i)=p_day
$sql$;
