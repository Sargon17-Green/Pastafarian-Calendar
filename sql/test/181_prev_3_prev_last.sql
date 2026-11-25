\set ON_ERROR_STOP on
SET statement_timeout = '720s';
DO $stone_reuse_equivalence$
DECLARE
  v_offset integer;
  v_i integer;
  v_counts pastafari_sql_tamil.work_counts;
  v_initial_bowls numeric[];
  v_old_bowls numeric[];
  v_new_bowls numeric[];
  v_drops_old numeric[];
  v_drops_new numeric[];
  v_round_count integer := 0;
  v_drop_count integer := 0;
  v_started timestamptz := clock_timestamp();
BEGIN
  FOREACH v_offset IN ARRAY ARRAY[1,-1,2,-2,3,-3,4,-4,5,-5,6,-6,7,-7,8,-8,9,-9,10,-10,11,-11,12,-12,13,-13,14,-14,15,-15,16,-16,17,-17,18,-18,19,-19,20,-20,21,-21,22,-22,23,-23,24,-24,25,-25,26,-26,27,-27,28,-28,29,-29,30,-30,31,-31,32,-32,33,-33,34,-34,35,-35,36,-36,37,-37,38,-38,0,-2032,-6158,-9321,-15002,-18366]::integer[] LOOP
    v_counts := pastafari_sql_tamil.work_counts(
      pastafari_sql_tamil.foundation_day(),
      pastafari_sql_tamil.foundation_day() + v_offset);
    v_drops_old := qa_legacy.visible_drops(v_counts);
    v_drops_new := pastafari_sql_tamil.visible_drops(v_counts);
    IF v_drops_old IS DISTINCT FROM v_drops_new THEN
      RAISE EXCEPTION 'legacy/new visible_drops mismatch: case=prev_3_prev_last; offset=%', v_offset;
    END IF;
    IF v_drops_new IS NULL OR array_length(v_drops_new,1) IS DISTINCT FROM 46 THEN
      RAISE EXCEPTION 'invalid visible-drop array for offset %', v_offset; END IF;
    v_drop_count := v_drop_count + array_length(v_drops_new,1);
    v_initial_bowls := pastafari_sql_tamil.initial_bowls(v_counts);
    IF v_initial_bowls IS NULL OR array_length(v_initial_bowls,1) IS DISTINCT FROM 6 THEN
      RAISE EXCEPTION 'invalid initial bowls for offset %', v_offset; END IF;
    v_old_bowls := v_initial_bowls; v_new_bowls := v_initial_bowls;
    FOR v_i IN 1..46 LOOP
      v_old_bowls := qa_legacy.bowl_round(v_old_bowls,v_drops_old[v_i],v_i);
      v_new_bowls := pastafari_sql_tamil.bowl_round(v_new_bowls,v_drops_new[v_i],v_i);
      IF v_old_bowls IS DISTINCT FROM v_new_bowls THEN
        RAISE EXCEPTION 'legacy/new bowl_round mismatch: case=prev_3_prev_last; offset=%; round=%', v_offset, v_i;
      END IF; v_round_count := v_round_count + 1;
    END LOOP;
  END LOOP;
  RAISE NOTICE 'SLICE25_VISIBLE_DROPS_LEGACY_EQUIVALENCE=PASS; CASE=%; OFFSETS=%; DROPS=%',
    'prev_3_prev_last', 82, v_drop_count;
  RAISE NOTICE 'SLICE25_BOWL_ROUND_LEGACY_EQUIVALENCE=PASS; CASE=%; OFFSETS=%; ROUNDS=%; ELAPSED_MS=%',
    'prev_3_prev_last', 82, v_round_count,
    round(extract(epoch FROM clock_timestamp()-v_started)*1000,3);
END;
$stone_reuse_equivalence$;
DO $one_timeout_case$
DECLARE
  v_result pastafari_sql_tamil.calendar_result_text;
  v_started timestamptz := clock_timestamp();
BEGIN
  RAISE NOTICE 'SLICE25_TIMEOUT_CASE_START=prev_3_prev_last';
  v_result := pastafari_sql_tamil.calendar_date(-15055671::numeric,-15070673::numeric);
  IF v_result IS NULL THEN RAISE EXCEPTION 'calendar_date returned NULL: prev_3_prev_last'; END IF;
  IF (v_result).year_number IS DISTINCT FROM 4996::numeric THEN
    RAISE EXCEPTION 'archived oracle mismatch: prev_3_prev_last.year_number'; END IF;
  RAISE NOTICE 'SLICE25_TIMEOUT_CASE_FIELD_PASS=prev_3_prev_last.year_number';
  IF (v_result).cutlet_name IS DISTINCT FROM 'சாம்பல்'::text THEN
    RAISE EXCEPTION 'archived oracle mismatch: prev_3_prev_last.cutlet_name'; END IF;
  RAISE NOTICE 'SLICE25_TIMEOUT_CASE_FIELD_PASS=prev_3_prev_last.cutlet_name';
  IF (v_result).day_in_cutlet IS DISTINCT FROM 213::numeric THEN
    RAISE EXCEPTION 'archived oracle mismatch: prev_3_prev_last.day_in_cutlet'; END IF;
  RAISE NOTICE 'SLICE25_TIMEOUT_CASE_FIELD_PASS=prev_3_prev_last.day_in_cutlet';
  IF (v_result).month_name IS DISTINCT FROM 'மாதுளை'::text THEN
    RAISE EXCEPTION 'archived oracle mismatch: prev_3_prev_last.month_name'; END IF;
  RAISE NOTICE 'SLICE25_TIMEOUT_CASE_FIELD_PASS=prev_3_prev_last.month_name';
  IF (v_result).day_in_month IS DISTINCT FROM 115::numeric THEN
    RAISE EXCEPTION 'archived oracle mismatch: prev_3_prev_last.day_in_month'; END IF;
  RAISE NOTICE 'SLICE25_TIMEOUT_CASE_FIELD_PASS=prev_3_prev_last.day_in_month';
  RAISE NOTICE 'SLICE25_TIMEOUT_CASE_ORACLE=PASS; CASE=prev_3_prev_last; FIELDS=5/5';
  RAISE NOTICE 'SLICE25_TIMEOUT_CASE_ELAPSED_MS=%',
    round(extract(epoch FROM clock_timestamp()-v_started)*1000,3);
  RAISE NOTICE 'SLICE25_FULL_SLICE=NOT_ACCEPTED';
END;
$one_timeout_case$;
