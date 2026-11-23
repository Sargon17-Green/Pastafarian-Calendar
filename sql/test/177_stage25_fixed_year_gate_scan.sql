-- SQL Tamil Slice25 QA ONLY; PG17 historical year_rec (4996,-38,-29,-15074038,-15070673).
-- Calls unchanged negative_gate_gap directly; never calls calendar_date/find_target_year.
\set ON_ERROR_STOP on
CREATE TEMP TABLE qa_fixed_gate(index_value integer PRIMARY KEY,gap_value numeric NOT NULL CHECK(gap_value BETWEEN 42 AND 963),elapsed_ms numeric NOT NULL);
CREATE OR REPLACE FUNCTION pg_temp.qa_fixed_segment(p_low integer,p_high integer)
RETURNS void LANGUAGE plpgsql VOLATILE AS $gate$
DECLARE i integer; g numeric; t timestamptz; start_t timestamptz:=clock_timestamp();
BEGIN
 IF p_low>p_high OR p_low < -38 OR p_high > -30 OR p_high-p_low<>2 THEN
  RAISE EXCEPTION 'invalid bounded segment %..%',p_low,p_high;
 END IF;
 RAISE NOTICE 'S25_SEGMENT_ENTER=%..%',p_low,p_high;
 FOR i IN p_low..p_high LOOP
  t:=clock_timestamp();
  RAISE NOTICE 'S25_GATE_ENTER=index:% offset:%',i,-i;
  g:=pastafari_sql_tamil.negative_gate_gap(-i);
  IF g IS NULL OR g<>trunc(g) OR g NOT BETWEEN 42 AND 963 THEN
   RAISE EXCEPTION 'invalid gap at index % value %',i,g;
  END IF;
  INSERT INTO pg_temp.qa_fixed_gate VALUES (i,g,round(extract(epoch FROM clock_timestamp()-t)*1000,3));
  RAISE NOTICE 'S25_GATE_EXIT=index:% gap:% elapsed_ms:%',i,g,round(extract(epoch FROM clock_timestamp()-t)*1000,3);
 END LOOP;
 RAISE NOTICE 'S25_SEGMENT_EXIT=%..% elapsed_ms:%',p_low,p_high,round(extract(epoch FROM clock_timestamp()-start_t)*1000,3);
END $gate$;
SET statement_timeout='60s';
SELECT pg_temp.qa_fixed_segment(-38,-36);
SET statement_timeout='60s';
SELECT pg_temp.qa_fixed_segment(-35,-33);
SET statement_timeout='60s';
SELECT pg_temp.qa_fixed_segment(-32,-30);
SET statement_timeout='10s';
DO $assert$
DECLARE n integer; total numeric; low_i integer; high_i integer;
BEGIN
 SELECT count(*)::integer,sum(gap_value),min(index_value),max(index_value)
 INTO n,total,low_i,high_i FROM pg_temp.qa_fixed_gate;
 IF n IS DISTINCT FROM 9 OR total IS DISTINCT FROM 3365::numeric
 OR low_i IS DISTINCT FROM -38 OR high_i IS DISTINCT FROM -30 THEN
  RAISE EXCEPTION 'locked year boundary mismatch n=% sum=% first=% last=%',n,total,low_i,high_i;
 END IF;
 RAISE NOTICE 'S25_FIXED_YEAR_GATE_BOUNDARY=PASS count:9 gap_sum:3365';
 RAISE NOTICE 'S25_FIVE_FIELDS=NOT_TESTED';
 RAISE NOTICE 'S25_SOURCE_EQUIVALENCE=NOT_TESTED';
 RAISE NOTICE 'S25_FULL_SLICE=NOT_ACCEPTED';
END $assert$;
SELECT index_value,gap_value,elapsed_ms FROM pg_temp.qa_fixed_gate ORDER BY index_value;
