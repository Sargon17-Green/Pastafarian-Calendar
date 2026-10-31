-- Stage 2 Slice 15: bounded adjacent-year navigation.
-- தமிழ்: அடுத்த மற்றும் முந்தைய ஆண்டுகளுக்கான எல்லைக்குட்பட்ட நகர்வு.
-- Each transition starts at the known boundary and walks only one 5,778-day
-- side-window. It stops at the first gate at/over the far boundary plus one
-- sentinel gate. The proven 42..963 gate-gap bounds cap this at 139 steps.
-- Production only: no cache, mutable table, dynamic SQL, or reference schema.

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.next_year(
  p_calculation_day numeric,
  p_known pastafari_sql_tamil.year_rec
) RETURNS pastafari_sql_tamil.year_rec
LANGUAGE SQL STABLE STRICT AS $sql$
WITH RECURSIVE valid AS MATERIALIZED (
  SELECT
    (p_known).year_number AS known_year,
    (p_known).open_gate_index AS known_open_index,
    (p_known).close_gate_index AS known_close_index,
    (p_known).open_gate_day AS known_open_day,
    (p_known).close_gate_day AS known_close_day,
    (p_known).close_gate_day + 5778::numeric AS upper_day
  WHERE p_calculation_day = trunc(p_calculation_day)
    AND (p_known).year_number = trunc((p_known).year_number)
    AND (p_known).open_gate_index = trunc((p_known).open_gate_index)
    AND (p_known).close_gate_index = trunc((p_known).close_gate_index)
    AND (p_known).open_gate_day = trunc((p_known).open_gate_day)
    AND (p_known).close_gate_day = trunc((p_known).close_gate_day)
    AND (p_known).open_gate_index < (p_known).close_gate_index
    AND (p_known).open_gate_day < (p_known).close_gate_day
    AND (p_known).close_gate_index - (p_known).open_gate_index >= 6
    AND (p_known).close_gate_day - (p_known).open_gate_day
          BETWEEN 252 AND 5778
),
walk(gate_index, gate_day, upper_day, step_count, sentinel_done) AS (
  SELECT known_close_index, known_close_day, upper_day, 0, false
  FROM valid
  UNION ALL
  SELECT
    w.gate_index + 1,
    w.gate_day + CASE
      WHEN w.gate_index < 0
        THEN pastafari_sql_tamil.negative_gate_gap(-w.gate_index)
      ELSE pastafari_sql_tamil.positive_gate_gap(w.gate_index + 1)
    END,
    w.upper_day,
    w.step_count + 1,
    w.gate_day >= w.upper_day
  FROM walk AS w
  WHERE NOT w.sentinel_done
    AND w.step_count < 139
),
completed AS MATERIALIZED (
  SELECT coalesce(bool_or(sentinel_done),false) AS sentinel_found
  FROM walk
),
candidates AS MATERIALIZED (
  SELECT
    w.gate_index AS candidate_close_index,
    w.gate_day AS candidate_close_day,
    w.gate_day - v.known_close_day AS candidate_year_days
  FROM walk AS w
  CROSS JOIN valid AS v
  CROSS JOIN completed AS c
  WHERE c.sentinel_found
    AND w.gate_index > v.known_close_index
    AND w.gate_index - v.known_close_index >= 6
    AND w.gate_day - v.known_close_day BETWEEN 252 AND 5778
),
ranked AS MATERIALIZED (
  SELECT
    candidate_close_index,
    candidate_close_day,
    row_number() OVER (
      ORDER BY candidate_year_days, candidate_close_index
    ) AS candidate_rank
  FROM candidates
),
wanted AS MATERIALIZED (
  SELECT CASE WHEN count(*) > 0 THEN
    pastafari_sql_tamil.choose_rank(
      pastafari_sql_tamil.ask_bowl(
        pastafari_sql_tamil.sauce(
          p_calculation_day,max(v.known_close_day)
        ),1,11
      ),
      count(*)::numeric
    )
  END AS selected_rank
  FROM ranked
  CROSS JOIN valid AS v
),
selected AS (
  SELECT ROW(
    v.known_year + 1,
    v.known_close_index,
    r.candidate_close_index,
    v.known_close_day,
    r.candidate_close_day
  )::pastafari_sql_tamil.year_rec AS year_data
  FROM ranked AS r
  CROSS JOIN valid AS v
  CROSS JOIN wanted AS w
  WHERE r.candidate_rank = w.selected_rank
)
SELECT year_data FROM selected
$sql$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.previous_year(
  p_calculation_day numeric,
  p_known pastafari_sql_tamil.year_rec
) RETURNS pastafari_sql_tamil.year_rec
LANGUAGE SQL STABLE STRICT AS $sql$
WITH RECURSIVE valid AS MATERIALIZED (
  SELECT
    (p_known).year_number AS known_year,
    (p_known).open_gate_index AS known_open_index,
    (p_known).close_gate_index AS known_close_index,
    (p_known).open_gate_day AS known_open_day,
    (p_known).close_gate_day AS known_close_day,
    (p_known).open_gate_day - 5778::numeric AS lower_day
  WHERE p_calculation_day = trunc(p_calculation_day)
    AND (p_known).year_number = trunc((p_known).year_number)
    AND (p_known).open_gate_index = trunc((p_known).open_gate_index)
    AND (p_known).close_gate_index = trunc((p_known).close_gate_index)
    AND (p_known).open_gate_day = trunc((p_known).open_gate_day)
    AND (p_known).close_gate_day = trunc((p_known).close_gate_day)
    AND (p_known).open_gate_index < (p_known).close_gate_index
    AND (p_known).open_gate_day < (p_known).close_gate_day
    AND (p_known).close_gate_index - (p_known).open_gate_index >= 6
    AND (p_known).close_gate_day - (p_known).open_gate_day
          BETWEEN 252 AND 5778
),
walk(gate_index, gate_day, lower_day, step_count, sentinel_done) AS (
  SELECT known_open_index, known_open_day, lower_day, 0, false
  FROM valid
  UNION ALL
  SELECT
    w.gate_index - 1,
    w.gate_day - CASE
      WHEN w.gate_index > 0
        THEN pastafari_sql_tamil.positive_gate_gap(w.gate_index)
      ELSE pastafari_sql_tamil.negative_gate_gap(1 - w.gate_index)
    END,
    w.lower_day,
    w.step_count + 1,
    w.gate_day <= w.lower_day
  FROM walk AS w
  WHERE NOT w.sentinel_done
    AND w.step_count < 139
),
completed AS MATERIALIZED (
  SELECT coalesce(bool_or(sentinel_done),false) AS sentinel_found
  FROM walk
),
candidates AS MATERIALIZED (
  SELECT
    w.gate_index AS candidate_open_index,
    w.gate_day AS candidate_open_day,
    v.known_open_day - w.gate_day AS candidate_year_days
  FROM walk AS w
  CROSS JOIN valid AS v
  CROSS JOIN completed AS c
  WHERE c.sentinel_found
    AND w.gate_index < v.known_open_index
    AND v.known_open_index - w.gate_index >= 6
    AND v.known_open_day - w.gate_day BETWEEN 252 AND 5778
),
ranked AS MATERIALIZED (
  SELECT
    candidate_open_index,
    candidate_open_day,
    row_number() OVER (
      ORDER BY candidate_year_days, candidate_open_index DESC
    ) AS candidate_rank
  FROM candidates
),
wanted AS MATERIALIZED (
  SELECT CASE WHEN count(*) > 0 THEN
    pastafari_sql_tamil.choose_rank(
      pastafari_sql_tamil.ask_bowl(
        pastafari_sql_tamil.sauce(
          p_calculation_day,max(v.known_open_day)
        ),1,12
      ),
      count(*)::numeric
    )
  END AS selected_rank
  FROM ranked
  CROSS JOIN valid AS v
),
selected AS (
  SELECT ROW(
    v.known_year - 1,
    r.candidate_open_index,
    v.known_open_index,
    r.candidate_open_day,
    v.known_open_day
  )::pastafari_sql_tamil.year_rec AS year_data
  FROM ranked AS r
  CROSS JOIN valid AS v
  CROSS JOIN wanted AS w
  WHERE r.candidate_rank = w.selected_rank
)
SELECT year_data FROM selected
$sql$;
