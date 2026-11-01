-- SQL+தமிழ் Stage 2 Slice 17: pure cutlet count selected from year and sauce.
-- தமிழ்: ஆண்டிற்கான கட்லெட் எண்ணிக்கை; முழுத் தேதி அல்ல.
-- Production-only exact NUMERIC arithmetic; no test schema, tables or cache.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.choose_cutlet_count(
  p_sauce pastafari_sql_tamil.sauce_result,
  p_year pastafari_sql_tamil.year_rec
) RETURNS integer LANGUAGE SQL IMMUTABLE STRICT AS $sql$
WITH valid AS MATERIALIZED (
 SELECT (p_year).close_gate_index-(p_year).open_gate_index AS gap_count
 WHERE (p_year).year_number IS NOT NULL
   AND (p_year).year_number=trunc((p_year).year_number)
   AND (p_year).open_gate_index IS NOT NULL
   AND (p_year).close_gate_index IS NOT NULL
   AND (p_year).open_gate_day IS NOT NULL
   AND (p_year).close_gate_day IS NOT NULL
   AND (p_year).open_gate_index=trunc((p_year).open_gate_index)
   AND (p_year).close_gate_index=trunc((p_year).close_gate_index)
   AND (p_year).open_gate_day=trunc((p_year).open_gate_day)
   AND (p_year).close_gate_day=trunc((p_year).close_gate_day)
   AND (p_year).open_gate_day < (p_year).close_gate_day
   AND (p_year).close_gate_index-(p_year).open_gate_index >= 6
), ranked AS MATERIALIZED (
 SELECT least(17::numeric,gap_count)-5 AS rank_space,
        pastafari_sql_tamil.choose_rank(
          pastafari_sql_tamil.ask_bowl(p_sauce,2,20),
          least(17::numeric,gap_count)-5
        ) AS selected_rank
 FROM valid
)
SELECT (5+selected_rank)::integer FROM ranked
WHERE selected_rank IS NOT NULL
  AND selected_rank=trunc(selected_rank)
  AND selected_rank BETWEEN 1 AND rank_space
$sql$;
