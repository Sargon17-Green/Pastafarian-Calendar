-- SQL+தமிழ் Stage2 Slice20: exact bounded month-count selection.
-- No reference/test schema, mutable tables or caches.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.month_count_by_rank(
  p_days numeric, p_rank1 numeric
) RETURNS integer LANGUAGE plpgsql IMMUTABLE STRICT AS $fn$
DECLARE
  lo numeric;
  hi numeric;
  n numeric;
BEGIN
  IF p_days <> trunc(p_days) OR p_days < 252 OR p_days > 5778 OR
     p_rank1 <> trunc(p_rank1) THEN RETURN NULL; END IF;
  lo := ceil(p_days / 123::numeric);
  hi := least(47::numeric,floor(p_days / 4::numeric));
  n := hi - lo + 1;
  IF n < 1 OR p_rank1 < 1 OR p_rank1 > n THEN RETURN NULL; END IF;
  RETURN (lo+p_rank1-1)::integer;
END;
$fn$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.choose_month_count(
  p_sauce pastafari_sql_tamil.sauce_result,
  p_year pastafari_sql_tamil.year_rec
) RETURNS integer LANGUAGE plpgsql IMMUTABLE STRICT AS $fn$
DECLARE
  d numeric;
  lo numeric;
  hi numeric;
  selected_rank numeric;
BEGIN
  IF (p_year).year_number IS NULL OR
     (p_year).open_gate_index IS NULL OR
     (p_year).close_gate_index IS NULL OR
     (p_year).open_gate_day IS NULL OR
     (p_year).close_gate_day IS NULL THEN RETURN NULL; END IF;
  IF (p_year).year_number <> trunc((p_year).year_number) OR
     (p_year).open_gate_index <> trunc((p_year).open_gate_index) OR
     (p_year).close_gate_index <> trunc((p_year).close_gate_index) OR
     (p_year).open_gate_day <> trunc((p_year).open_gate_day) OR
     (p_year).close_gate_day <> trunc((p_year).close_gate_day) OR
     (p_year).close_gate_index - (p_year).open_gate_index < 6 THEN RETURN NULL; END IF;
  d := (p_year).close_gate_day - (p_year).open_gate_day;
  IF d < 252 OR d > 5778 THEN RETURN NULL; END IF;
  lo := ceil(d/123::numeric);
  hi := least(47::numeric,floor(d/4::numeric));
  IF hi < lo THEN RETURN NULL; END IF;
  selected_rank := pastafari_sql_tamil.choose_rank(
    pastafari_sql_tamil.ask_bowl(p_sauce,3,30),hi-lo+1);
  RETURN pastafari_sql_tamil.month_count_by_rank(d,selected_rank);
END;
$fn$;
