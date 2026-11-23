-- SQL Tamil Slice25: QA ONLY, original PG17 year 4996. No selector replay.
\set ON_ERROR_STOP on
CREATE TEMP TABLE qa_year AS SELECT ROW(4996::numeric,-38::numeric,-29::numeric,-15074038::numeric,-15070673::numeric)::pastafari_sql_tamil.year_rec AS y;
CREATE TEMP TABLE qa_gap(gate_idx,gap_value) AS SELECT * FROM
(VALUES (-38,131),(-37,471),(-36,251),(-35,227),(-34,300),(-33,839),(-32,281),(-31,652),(-30,213)) AS x(i,g);
CREATE TEMP TABLE qa_clock(phase text PRIMARY KEY,begun timestamptz);
DO $pre$
BEGIN
 IF (SELECT count(*) FROM qa_gap)<>9 OR (SELECT sum(gap_value) FROM qa_gap)<>3365 THEN
   RAISE EXCEPTION 'archived PG17 gate vector changed';
 END IF;
 RAISE NOTICE 'S25_SOURCE_YEAR=4996; ARCHIVED_GATES=45133869661; NATIVE_GATE_REPLAY=NO';
END $pre$;
INSERT INTO qa_clock VALUES ('sauce',clock_timestamp());
DO $enter$ BEGIN RAISE NOTICE 'S25_ENTER=sauce'; END $enter$;
SET statement_timeout='60s';
CREATE TEMP TABLE qa_sauce AS SELECT pastafari_sql_tamil.sauce(-15055671::numeric,-15074037::numeric) AS s;
SET statement_timeout='10s';
DO $end$
DECLARE v pastafari_sql_tamil.sauce_result; t timestamptz;
BEGIN
 SELECT (s).* INTO STRICT v FROM qa_sauce;
 SELECT begun INTO STRICT t FROM qa_clock WHERE phase='sauce';
 IF v IS NULL THEN RAISE EXCEPTION 'sauce null'; END IF;
 RAISE NOTICE 'S25_EXIT=sauce elapsed_ms=%',round(extract(epoch from clock_timestamp()-t)*1000,3);
END $end$;
INSERT INTO qa_clock VALUES ('count',clock_timestamp());
DO $enter$ BEGIN RAISE NOTICE 'S25_ENTER=cutlet_count'; END $enter$;
SET statement_timeout='60s';
CREATE TEMP TABLE qa_count AS SELECT pastafari_sql_tamil.choose_cutlet_count(
 (SELECT s FROM qa_sauce),(SELECT y FROM qa_year)) AS k;
SET statement_timeout='10s';
DO $end$
DECLARE k integer; t timestamptz;
BEGIN
 SELECT qa_count.k INTO STRICT k FROM qa_count;
 SELECT begun INTO STRICT t FROM qa_clock WHERE phase='count';
 IF k IS NULL OR k<6 OR k>9 THEN RAISE EXCEPTION 'invalid k=%',k; END IF;
 RAISE NOTICE 'S25_EXIT=cutlet_count k=% elapsed_ms=%',k,round(extract(epoch from clock_timestamp()-t)*1000,3);
END $end$;
INSERT INTO qa_clock VALUES ('partition',clock_timestamp());
DO $enter$ BEGIN RAISE NOTICE 'S25_ENTER=cutlet_partition'; END $enter$;
SET statement_timeout='60s';
CREATE TEMP TABLE qa_parts AS SELECT pastafari_sql_tamil.choose_cutlet_partition(
 -15055671::numeric,(SELECT s FROM qa_sauce),(SELECT y FROM qa_year),(SELECT k FROM qa_count)) AS p;
SET statement_timeout='10s';
DO $end$
DECLARE p integer[]; k integer; t timestamptz;
BEGIN
 SELECT qa_parts.p INTO STRICT p FROM qa_parts;
 SELECT qa_count.k INTO STRICT k FROM qa_count;
 SELECT begun INTO STRICT t FROM qa_clock WHERE phase='partition';
 IF p IS NULL OR cardinality(p) IS DISTINCT FROM k OR
    (SELECT sum(x) FROM unnest(p) AS q(x)) IS DISTINCT FROM 9 OR
    EXISTS(SELECT 1 FROM unnest(p) AS q(x) WHERE x<1 OR x IS NULL) THEN
   RAISE EXCEPTION 'invalid partition %',p;
 END IF;
 RAISE NOTICE 'S25_EXIT=cutlet_partition p=% elapsed_ms=%',p,round(extract(epoch from clock_timestamp()-t)*1000,3);
END $end$;
INSERT INTO qa_clock VALUES ('names',clock_timestamp());
DO $enter$ BEGIN RAISE NOTICE 'S25_ENTER=cutlet_names'; END $enter$;
SET statement_timeout='60s';
CREATE TEMP TABLE qa_names AS SELECT pastafari_sql_tamil.choose_cutlet_names(
 (SELECT s FROM qa_sauce),(SELECT k FROM qa_count)) AS ids;
SET statement_timeout='10s';
CREATE TEMP TABLE qa_cutlet(found_index integer,name text,day_number numeric);
DO $scan$
DECLARE p integer[]; names integer[]; v_gate_idx integer:=-38; day numeric:=-15074038;
 begin_day numeric; g integer; c integer; i integer; hits integer:=0;
 cutlet_name text; ordinal numeric; t timestamptz;
BEGIN
 SELECT qa_parts.p INTO STRICT p FROM qa_parts;
 SELECT qa_names.ids INTO STRICT names FROM qa_names;
 SELECT begun INTO STRICT t FROM qa_clock WHERE phase='names';
 IF cardinality(names) IS DISTINCT FROM cardinality(p) THEN RAISE EXCEPTION 'invalid names'; END IF;
 RAISE NOTICE 'S25_EXIT=cutlet_names elapsed_ms=%',round(extract(epoch from clock_timestamp()-t)*1000,3);
 FOR c IN 1..cardinality(p) LOOP
   begin_day:=day;
   FOR i IN 1..p[c] LOOP
     SELECT gap_value INTO STRICT g FROM qa_gap WHERE qa_gap.gate_idx=v_gate_idx;
     day:=day+g; v_gate_idx:=v_gate_idx+1;
   END LOOP;
   IF begin_day < -15072356 AND -15072356 <= day THEN
     hits:=hits+1;
     ordinal:=-15072356-begin_day;
     cutlet_name:=pastafari_sql_tamil.source_name('CUTLET',names[c]);
     INSERT INTO qa_cutlet VALUES(c,cutlet_name,ordinal);
   END IF;
 END LOOP;
 IF hits<>1 OR day<>-15070673 OR v_gate_idx<>-29 OR
    cutlet_name IS DISTINCT FROM 'வெண்கலம்' OR ordinal IS DISTINCT FROM 302 THEN
   RAISE EXCEPTION 'cutlet oracle mismatch: hits=% gate=% day=% name=% ordinal=%',
      hits,v_gate_idx,day,cutlet_name,ordinal;
 END IF;
 RAISE NOTICE 'S25_CUTLET_TWO_FIELDS=PASS; NAME=%; ORDINAL=%',cutlet_name,ordinal;
END $scan$;
INSERT INTO qa_clock VALUES ('build',clock_timestamp());
DO $enter$ BEGIN RAISE NOTICE 'S25_ENTER=build_year_structure'; END $enter$;
SET statement_timeout='60s';
CREATE TEMP TABLE qa_full AS SELECT pastafari_sql_tamil.build_year_structure(
 -15055671::numeric,(SELECT y FROM qa_year)) AS structure;
SET statement_timeout='10s';
DO $oracle$
DECLARE v pastafari_sql_tamil.year_structure; t timestamptz;
 weaving integer[]; month_ids integer[]; lengths integer[];
 mid integer; month_day integer; month_name text; cutlet_name text; cutlet_day numeric;
BEGIN
 SELECT (structure).* INTO STRICT v FROM qa_full;
 SELECT begun INTO STRICT t FROM qa_clock WHERE phase='build';
 IF v IS NULL OR (v).year_data IS DISTINCT FROM (SELECT y FROM qa_year) OR
    (v).cutlet_count IS DISTINCT FROM (SELECT k FROM qa_count) OR
    (v).cutlet_partition IS DISTINCT FROM (SELECT p FROM qa_parts) OR
    (v).cutlet_name_indices IS DISTINCT FROM (SELECT ids FROM qa_names) OR
    cardinality((v).month_weaving) IS DISTINCT FROM 3365 THEN
   RAISE EXCEPTION 'full year structure / phased result mismatch';
 END IF;
 RAISE NOTICE 'S25_EXIT=build_year_structure elapsed_ms=%',
   round(extract(epoch from clock_timestamp()-t)*1000,3);
 SELECT name,day_number INTO STRICT cutlet_name,cutlet_day FROM qa_cutlet;
 weaving:=(v).month_weaving; month_ids:=(v).month_name_indices; lengths:=(v).month_lengths;
 mid:=weaving[1682];
 IF mid IS NULL OR mid<1 OR mid>(v).month_count OR
    cardinality(month_ids) IS DISTINCT FROM (v).month_count OR
    cardinality(lengths) IS DISTINCT FROM (v).month_count THEN
   RAISE EXCEPTION 'invalid month structure';
 END IF;
 SELECT count(*) INTO month_day FROM unnest(weaving[1:1682]) AS x(m) WHERE x.m=mid;
 IF month_day<1 OR month_day>lengths[mid] THEN RAISE EXCEPTION 'invalid month ordinal'; END IF;
 month_name:=pastafari_sql_tamil.source_name('MONTH',month_ids[mid]);
 IF ((v).year_data).year_number IS DISTINCT FROM 4996 OR
    cutlet_name IS DISTINCT FROM 'வெண்கலம்' OR cutlet_day IS DISTINCT FROM 302 OR
    month_name IS DISTINCT FROM 'தவளை' OR month_day IS DISTINCT FROM 50 THEN
   RAISE EXCEPTION 'five-field oracle failed: cutlet=% d=% month=% d=%',
      cutlet_name,cutlet_day,month_name,month_day;
 END IF;
 RAISE NOTICE 'S25_FIVE_FIELDS=PASS; EXPECTED=(4996,வெண்கலம்,302,தவளை,50)';
 RAISE NOTICE 'S25_CALENDAR_DATE_EQUIVALENCE=NOT_TESTED; S25_FULL_SLICE=NOT_ACCEPTED';
END $oracle$;
