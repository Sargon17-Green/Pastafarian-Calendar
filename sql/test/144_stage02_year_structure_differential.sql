-- Exact, full eight-field production-vs-normative differential.
BEGIN;
CREATE TEMP TABLE slice24_diff(label text PRIMARY KEY,ok boolean NOT NULL);
DO $body$
DECLARE
  v_case_label text:='__CASE_LABEL__'; d numeric; y pastafari_sql_tamil.year_rec;
  ref_year pastafari_sql_tamil_test.year_rec;
  a pastafari_sql_tamil.year_structure; b pastafari_sql_tamil_test.year_structure;
BEGIN
  SELECT x.d,x.y INTO STRICT d,y FROM slice24_cases x WHERE x.id=v_case_label;
  ref_year:=ROW((y).year_number,(y).open_gate_index,(y).close_gate_index,
                (y).open_gate_day,(y).close_gate_day)::pastafari_sql_tamil_test.year_rec;
  a:=pastafari_sql_tamil.build_year_structure(d,y);
  b:=pastafari_sql_tamil_test.build_year_structure(d,ref_year);
  INSERT INTO slice24_diff(label,ok) SELECT k,coalesce(v,false) FROM (VALUES
    ('year',to_jsonb((a).year_data) IS NOT DISTINCT FROM to_jsonb((b).year_data)),
    ('cutlet-count',(a).cutlet_count IS NOT DISTINCT FROM (b).cutlet_count),
    ('cutlet-partition',(a).cutlet_partition IS NOT DISTINCT FROM (b).cutlet_partition),
    ('cutlet-names',(a).cutlet_name_indices IS NOT DISTINCT FROM (b).cutlet_name_indices),
    ('month-count',(a).month_count IS NOT DISTINCT FROM (b).month_count),
    ('month-lengths',(a).month_lengths IS NOT DISTINCT FROM (b).month_lengths),
    ('month-weaving',(a).month_weaving IS NOT DISTINCT FROM (b).month_weaving),
    ('month-names',(a).month_name_indices IS NOT DISTINCT FROM (b).month_name_indices),
    ('full-record',to_jsonb(a) IS NOT DISTINCT FROM to_jsonb(b))
  ) t(k,v);
END;
$body$;
SELECT label,ok FROM slice24_diff ORDER BY label;
SELECT 'slice24_diff_all_green='||(1/((count(*)=9 AND bool_and(ok))::integer))::text FROM slice24_diff;
COMMIT;
