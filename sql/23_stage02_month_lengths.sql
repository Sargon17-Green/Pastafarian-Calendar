-- SQL+தமிழ் Stage 2 Slice21: bounded month-length composition.
-- Production-only exact integer/numeric arithmetic; no reference schema or mutable cache.
-- The DP table is populated exactly once per invocation.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.month_lengths_ranked(
  p_total integer,
  p_slots integer,
  p_stream pastafari_sql_tamil.answer_stream,
  p_rank_override numeric DEFAULT NULL
) RETURNS integer[] LANGUAGE plpgsql IMMUTABLE AS $fn$
DECLARE
  width integer;
  counts numeric[];
  n integer;
  t integer;
  window_count numeric;
  total_count numeric;
  wanted numeric;
  remaining integer;
  slots_left integer;
  x integer;
  rest integer;
  block_count numeric;
  found boolean;
  result_lengths integer[] := ARRAY[]::integer[];
BEGIN
  IF p_total IS NULL OR p_slots IS NULL OR
     p_total < 252 OR p_total > 5778 OR
     p_slots < 1 OR p_slots > 47 OR
     4*p_slots > p_total OR 123*p_slots < p_total THEN
    RETURN NULL;
  END IF;
  width := p_total + 1;
  counts := array_fill(0::numeric, ARRAY[(p_slots+1)*width]);
  -- Flattened row-major C[n,t]: counts[n*width+t+1].
  counts[1] := 1;
  FOR n IN 1..p_slots LOOP
    window_count := 0;
    FOR t IN 0..p_total LOOP
      IF t >= 4 THEN
        window_count := window_count +
          counts[(n-1)*width+t-4+1];
      END IF;
      IF t >= 124 THEN
        window_count := window_count -
          counts[(n-1)*width+t-124+1];
      END IF;
      counts[n*width+t+1] := window_count;
    END LOOP;
  END LOOP;
  total_count := counts[p_slots*width+p_total+1];
  IF total_count IS NULL OR total_count < 1 THEN RETURN NULL; END IF;
  IF p_rank_override IS NULL THEN
    IF p_stream IS NULL THEN RETURN NULL; END IF;
    wanted := pastafari_sql_tamil.choose_rank(p_stream,total_count);
  ELSE
    wanted := p_rank_override;
  END IF;
  IF wanted IS NULL OR wanted <> trunc(wanted) OR
     wanted < 1 OR wanted > total_count THEN RETURN NULL; END IF;
  remaining := p_total;
  slots_left := p_slots;
  FOR n IN 1..p_slots LOOP
    found := false;
    FOR x IN 4..123 LOOP
      rest := remaining-x;
      IF rest < 0 THEN EXIT; END IF;
      IF rest < 4*(slots_left-1) OR rest > 123*(slots_left-1) THEN
        CONTINUE;
      END IF;
      block_count := counts[(slots_left-1)*width+rest+1];
      IF wanted > block_count THEN
        wanted := wanted-block_count;
      ELSE
        result_lengths := array_append(result_lengths,x);
        remaining := rest;
        slots_left := slots_left-1;
        found := true;
        EXIT;
      END IF;
    END LOOP;
    IF NOT found THEN RETURN NULL; END IF;
  END LOOP;
  IF remaining <> 0 OR slots_left <> 0 OR wanted <> 1 OR
     array_length(result_lengths,1) <> p_slots THEN RETURN NULL; END IF;
  RETURN result_lengths;
END;
$fn$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.choose_month_lengths(
  p_sauce pastafari_sql_tamil.sauce_result,
  p_year pastafari_sql_tamil.year_rec,
  p_k integer
) RETURNS integer[] LANGUAGE plpgsql IMMUTABLE STRICT AS $fn$
DECLARE
  d numeric;
  stream pastafari_sql_tamil.answer_stream;
BEGIN
  IF p_k IS NULL OR p_k < 1 OR p_k > 47 OR
     (p_year).year_number IS NULL OR
     (p_year).open_gate_index IS NULL OR
     (p_year).close_gate_index IS NULL OR
     (p_year).open_gate_day IS NULL OR
     (p_year).close_gate_day IS NULL THEN RETURN NULL; END IF;
  IF (p_year).year_number <> trunc((p_year).year_number) OR
     (p_year).open_gate_index <> trunc((p_year).open_gate_index) OR
     (p_year).close_gate_index <> trunc((p_year).close_gate_index) OR
     (p_year).open_gate_day <> trunc((p_year).open_gate_day) OR
     (p_year).close_gate_day <> trunc((p_year).close_gate_day) OR
     (p_year).close_gate_index-(p_year).open_gate_index < 6 THEN
    RETURN NULL;
  END IF;
  d := (p_year).close_gate_day-(p_year).open_gate_day;
  IF d IS NULL OR d <> trunc(d) OR d < 252 OR d > 5778 OR
     4*p_k > d OR 123*p_k < d THEN RETURN NULL; END IF;
  stream := pastafari_sql_tamil.ask_bowl(p_sauce,3,31);
  IF stream IS NULL THEN RETURN NULL; END IF;
  RETURN pastafari_sql_tamil.month_lengths_ranked(d::integer,p_k,stream,NULL);
END;
$fn$;
