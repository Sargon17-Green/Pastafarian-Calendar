-- Slice24 Native: independent, full eight-field assembly of seven accepted selectors.
BEGIN;
CREATE TEMP TABLE slice24_checks(label text PRIMARY KEY,ok boolean NOT NULL);
CREATE TEMP TABLE slice24_full_records(id text,actual jsonb,expected jsonb);
DO $body$
DECLARE
  v_case_label text:='__CASE_LABEL__'; d numeric; y pastafari_sql_tamil.year_rec;
  got pastafari_sql_tamil.year_structure; exp pastafari_sql_tamil.year_structure;
  s pastafari_sql_tamil.sauce_result;
  c integer; cp integer[]; cn integer[]; m integer; ml integer[]; mw integer[]; mn integer[];
  field_types text;
BEGIN
  SELECT x.d INTO STRICT d FROM slice24_cases x WHERE x.id=v_case_label;
  SELECT (x.y).* INTO STRICT y FROM slice24_cases x WHERE x.id=v_case_label;
  got:=pastafari_sql_tamil.build_year_structure(d,y);
  s:=pastafari_sql_tamil.sauce(d,(y).open_gate_day+1);
  c:=pastafari_sql_tamil.choose_cutlet_count(s,y);
  cp:=pastafari_sql_tamil.choose_cutlet_partition(d,s,y,c);
  cn:=pastafari_sql_tamil.choose_cutlet_names(s,c);
  m:=pastafari_sql_tamil.choose_month_count(s,y);
  ml:=pastafari_sql_tamil.choose_month_lengths(s,y,m);
  mw:=pastafari_sql_tamil.choose_month_weaving(s,ml);
  mn:=pastafari_sql_tamil.choose_month_names(s,m);
  exp:=ROW(y,c,cp,cn,m,ml,mw,mn)::pastafari_sql_tamil.year_structure;
  SELECT string_agg(a.attname||':'||a.atttypid::regtype::text,',' ORDER BY a.attnum)
  INTO field_types FROM pg_attribute a
  WHERE a.attrelid='pastafari_sql_tamil.year_structure'::regclass AND a.attnum>0 AND NOT a.attisdropped;
  INSERT INTO slice24_checks(label,ok)
  SELECT k,coalesce(v,false) FROM (VALUES
    ('signature',to_regprocedure('pastafari_sql_tamil.build_year_structure(numeric,pastafari_sql_tamil.year_rec)') IS NOT NULL),
    ('volatility',(SELECT provolatile='v' FROM pg_proc WHERE oid=to_regprocedure('pastafari_sql_tamil.build_year_structure(numeric,pastafari_sql_tamil.year_rec)'))),
    ('strict',(SELECT proisstrict FROM pg_proc WHERE oid=to_regprocedure('pastafari_sql_tamil.build_year_structure(numeric,pastafari_sql_tamil.year_rec)'))),
    ('layout',field_types='year_data:pastafari_sql_tamil.year_rec,cutlet_count:integer,cutlet_partition:integer[],cutlet_name_indices:integer[],month_count:integer,month_lengths:integer[],month_weaving:integer[],month_name_indices:integer[]'),
    ('isolation',to_regnamespace('pastafari_sql_tamil_test') IS NULL),
    ('no-test-calls',NOT EXISTS(SELECT 1 FROM pg_proc p WHERE p.oid=to_regprocedure('pastafari_sql_tamil.build_year_structure(numeric,pastafari_sql_tamil.year_rec)') AND pg_get_functiondef(p.oid) ILIKE '%pastafari_sql_tamil_test%')),
    ('null-day',pastafari_sql_tamil.build_year_structure(NULL::numeric,y) IS NULL),
    ('null-year',pastafari_sql_tamil.build_year_structure(d,NULL::pastafari_sql_tamil.year_rec) IS NULL),
    ('nonnull',got IS NOT NULL),
    ('year',to_jsonb((got).year_data)=to_jsonb(y)),
    ('cutlet-count',(got).cutlet_count IS NOT DISTINCT FROM c),
    ('cutlet-partition',(got).cutlet_partition IS NOT DISTINCT FROM cp),
    ('cutlet-names',(got).cutlet_name_indices IS NOT DISTINCT FROM cn),
    ('month-count',(got).month_count IS NOT DISTINCT FROM m),
    ('month-lengths',(got).month_lengths IS NOT DISTINCT FROM ml),
    ('month-weaving',(got).month_weaving IS NOT DISTINCT FROM mw),
    ('month-names',(got).month_name_indices IS NOT DISTINCT FROM mn),
    ('cutlet-legal',c BETWEEN 6 AND LEAST(17,((y).close_gate_index-(y).open_gate_index)::integer)),
    ('cutlet-length',cardinality(cp)=c),
    ('cutlet-sum',(SELECT sum(v)::numeric=(y).close_gate_index-(y).open_gate_index FROM unnest(cp) AS t(v))),
    ('cutlet-names-unique',(SELECT count(DISTINCT v)=c AND bool_and(v BETWEEN 1 AND 17) FROM unnest(cn) AS t(v))),
    ('month-legal',m BETWEEN ceil(((y).close_gate_day-(y).open_gate_day)/123)::integer AND 47),
    ('month-length',cardinality(ml)=m),
    ('month-sum',(SELECT sum(v)::numeric=(y).close_gate_day-(y).open_gate_day FROM unnest(ml) AS t(v))),
    ('month-range',(SELECT bool_and(v BETWEEN 4 AND 123) FROM unnest(ml) AS t(v))),
    ('weaving-length',cardinality(mw)=((y).close_gate_day-(y).open_gate_day)::integer),
    ('weaving-multiplicity',NOT EXISTS(SELECT 1 FROM generate_series(1,m) q(i) WHERE (SELECT count(*) FROM unnest(mw) AS z(v) WHERE z.v=q.i)<>ml[q.i])),
    ('month-names-unique',(SELECT count(DISTINCT v)=m AND bool_and(v BETWEEN 1 AND 47) FROM unnest(mn) AS t(v))),
    ('full-record',to_jsonb(got)=to_jsonb(exp))
  ) t(k,v);
  INSERT INTO slice24_full_records VALUES(v_case_label,to_jsonb(got),to_jsonb(exp));
END;
$body$;
SELECT label,ok FROM slice24_checks ORDER BY label;
SELECT 'slice24_native_all_green='||(1/((count(*)=29 AND bool_and(ok))::integer))::text FROM slice24_checks;
SELECT 'SLICE24_RECORD_JSON '||jsonb_build_object('id',id,'actual',actual,'expected',expected)::text FROM slice24_full_records;
COMMIT;
