-- SQL+தமிழ் Stage 2 Slice 19: exact ordered selection without replacement.
-- தமிழ்: 1..17 இலிருந்து வேறுபட்ட பெயர் அடையாளங்களைத் தேர்ந்தெடு.
-- Production-only, immutable, no reference schema, table or cache.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.cutlet_names_unrank(
 p_n integer, p_k integer, p_rank1 numeric
) RETURNS integer[] LANGUAGE plpgsql IMMUTABLE STRICT AS $fn$
DECLARE
 total_count numeric := 1;
 block_count numeric;
 rest_rank numeric := p_rank1;
 candidates integer[];
 result_ids integer[] := ARRAY[]::integer[];
 next_index integer;
 chosen integer;
 j integer;
 pos integer;
BEGIN
 IF p_n < 1 OR p_n > 17 OR p_k < 1 OR p_k > p_n OR
    p_rank1 <> trunc(p_rank1) THEN RETURN NULL; END IF;
 FOR j IN 0..p_k-1 LOOP
   total_count := total_count * (p_n-j);
 END LOOP;
 IF p_rank1 < 1 OR p_rank1 > total_count THEN RETURN NULL; END IF;
 candidates := ARRAY(SELECT generate_series(1,p_n));
 FOR pos IN 1..p_k LOOP
   block_count := 1;
   FOR j IN 1..p_k-pos LOOP
     block_count := block_count * (p_n-pos-j+1);
   END LOOP;
   next_index := div(rest_rank-1,block_count)::integer+1;
   IF next_index < 1 OR next_index > array_length(candidates,1) THEN
     RETURN NULL;
   END IF;
   chosen := candidates[next_index];
   result_ids := array_append(result_ids,chosen);
   candidates := array_remove(candidates,chosen);
   rest_rank := mod(rest_rank-1,block_count)+1;
 END LOOP;
 IF array_length(result_ids,1) <> p_k OR rest_rank <> 1 THEN
   RETURN NULL;
 END IF;
 RETURN result_ids;
END;
$fn$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.choose_cutlet_names(
 p_sauce pastafari_sql_tamil.sauce_result, p_k integer
) RETURNS integer[] LANGUAGE plpgsql IMMUTABLE STRICT AS $fn$
DECLARE
 total_count numeric := 1;
 selected_rank numeric;
 j integer;
BEGIN
 IF p_k < 6 OR p_k > 17 THEN RETURN NULL; END IF;
 FOR j IN 0..p_k-1 LOOP
   total_count := total_count * (17-j);
 END LOOP;
 selected_rank := pastafari_sql_tamil.choose_rank(
     pastafari_sql_tamil.ask_bowl(p_sauce,5,22),total_count);
 IF selected_rank IS NULL OR selected_rank <> trunc(selected_rank) OR
    selected_rank < 1 OR selected_rank > total_count THEN RETURN NULL; END IF;
 RETURN pastafari_sql_tamil.cutlet_names_unrank(17,p_k,selected_rank);
END;
$fn$;
