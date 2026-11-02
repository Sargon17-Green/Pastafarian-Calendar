-- SQL+தமிழ் Stage 2 Slice 18: exact lexicographic cutlet-partition selector.
-- தமிழ்: தனித்தனி துண்டுகளின் வரிசையை முழு எண் DP மூலம் தேர்வு செய்.
-- Production only; never load test-schema objects or persisted mutable state.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.choose_cutlet_partition(
 p_calculation_day numeric,
 p_sauce pastafari_sql_tamil.sauce_result,
 p_year pastafari_sql_tamil.year_rec,
 p_k integer
) RETURNS integer[]
LANGUAGE plpgsql STABLE STRICT AS $fn$
DECLARE
 g_numeric numeric;
 g integer;
 required_cut integer;
 gate_at_day numeric;
 selected_k integer;
 width integer;
 cells numeric;
 hit_count numeric[];
 pending_count numeric[];
 t integer;
 n integer;
 idx integer;
 limit_n integer;
 total_count numeric;
 wanted numeric;
 remaining integer;
 slots integer;
 prefix_sum integer := 0;
 next_prefix integer;
 new_remaining integer;
 candidate integer;
 chosen integer;
 block_count numeric;
 boundary_hit boolean;
 hit_now boolean;
 parts integer[] := ARRAY[]::integer[];
BEGIN
 -- Validate every composite field before any arithmetic or large allocation.
 IF (p_year).year_number IS NULL OR
    (p_year).open_gate_index IS NULL OR
    (p_year).close_gate_index IS NULL OR
    (p_year).open_gate_day IS NULL OR
    (p_year).close_gate_day IS NULL OR
    (p_year).year_number <> trunc((p_year).year_number) OR
    (p_year).open_gate_index <> trunc((p_year).open_gate_index) OR
    (p_year).close_gate_index <> trunc((p_year).close_gate_index) OR
    (p_year).open_gate_day <> trunc((p_year).open_gate_day) OR
    (p_year).close_gate_day <> trunc((p_year).close_gate_day) OR
    (p_year).close_gate_day <= (p_year).open_gate_day OR
    p_calculation_day <> trunc(p_calculation_day) THEN
   RETURN NULL;
 END IF;
 g_numeric := (p_year).close_gate_index - (p_year).open_gate_index;
 IF g_numeric IS NULL OR g_numeric <> trunc(g_numeric) OR
    g_numeric < 6 OR g_numeric >= 2147483647 OR
    p_k < 6 OR p_k > 17 OR p_k > g_numeric THEN
   RETURN NULL;
 END IF;
 selected_k := pastafari_sql_tamil.choose_cutlet_count(p_sauce,p_year);
 IF selected_k IS NULL OR p_k <> selected_k THEN RETURN NULL; END IF;
 g := g_numeric::integer;
 -- Explicit bounded-memory failure: NUMERIC DP cells, not a random g<=320 rule.
 cells := (p_k::numeric+1)*(g_numeric+1);
 IF cells > 1000000 THEN RETURN NULL; END IF;
 width := g+1;
 gate_at_day := pastafari_sql_tamil.exact_gate_index(p_calculation_day);
 IF gate_at_day IS NOT NULL AND
    gate_at_day > (p_year).open_gate_index AND
    gate_at_day < (p_year).close_gate_index THEN
   required_cut := (gate_at_day-(p_year).open_gate_index)::integer;
 END IF;
 hit_count := array_fill(0::numeric,ARRAY[cells::integer]);
 pending_count := array_fill(0::numeric,ARRAY[cells::integer]);
 -- Row major DP, t parts / n remaining units; index=t*width+n+1.
 -- hit: boundary already met; pending: must still hit exact internal cut.
 hit_count[1] := 1;
 FOR t IN 1..p_k LOOP
   FOR n IN t..g LOOP
     idx := t*width+n+1;
     hit_count[idx] := hit_count[idx-1]+hit_count[(t-1)*width+n];
     IF required_cut IS NOT NULL AND n > g-required_cut THEN
       IF n=g-required_cut+1 THEN
         pending_count[idx] := hit_count[(t-1)*width+(g-required_cut)+1];
       ELSE
         pending_count[idx] := pending_count[idx-1]+
                               pending_count[(t-1)*width+n];
       END IF;
     END IF;
   END LOOP;
 END LOOP;
 IF required_cut IS NULL THEN
   total_count := hit_count[p_k*width+g+1];
 ELSE
   total_count := pending_count[p_k*width+g+1];
 END IF;
 IF total_count IS NULL OR total_count < 1 THEN RETURN NULL; END IF;
 wanted := pastafari_sql_tamil.choose_rank(
   pastafari_sql_tamil.ask_bowl(p_sauce,2,21),total_count);
 IF wanted IS NULL OR wanted <> trunc(wanted) OR wanted < 1
    OR wanted > total_count THEN RETURN NULL; END IF;
 remaining := g;
 slots := p_k;
 boundary_hit := required_cut IS NULL;
 WHILE slots > 0 LOOP
   chosen := NULL;
   limit_n := remaining-slots+1;
   FOR candidate IN 1..limit_n LOOP
     next_prefix := prefix_sum+candidate;
     new_remaining := remaining-candidate;
     hit_now := boundary_hit OR
       (required_cut IS NOT NULL AND next_prefix=required_cut);
     IF required_cut IS NOT NULL AND NOT boundary_hit
        AND next_prefix > required_cut THEN
       block_count := 0;
     ELSIF hit_now THEN
       block_count := hit_count[(slots-1)*width+new_remaining+1];
     ELSE
       block_count := pending_count[(slots-1)*width+new_remaining+1];
     END IF;
     IF wanted > block_count THEN
       wanted := wanted-block_count;
     ELSE
       chosen := candidate;
       prefix_sum := next_prefix;
       boundary_hit := hit_now;
       EXIT;
     END IF;
   END LOOP;
   IF chosen IS NULL THEN RETURN NULL; END IF;
   parts := array_append(parts,chosen);
   remaining := remaining-chosen;
   slots := slots-1;
 END LOOP;
 IF remaining <> 0 OR NOT boundary_hit OR
    array_length(parts,1) <> p_k OR prefix_sum <> g THEN RETURN NULL; END IF;
 RETURN parts;
END;
$fn$;
