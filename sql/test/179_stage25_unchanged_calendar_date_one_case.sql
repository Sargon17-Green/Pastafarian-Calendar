-- QA only. Exact archived oracle; no selector substitution, aliases, caches or production edits.
\set ON_ERROR_STOP on
SET statement_timeout = '1500s';
\echo S25_DIRECT_ENTER=calendar_date
\timing on
CREATE TEMP TABLE qa_direct_actual AS
SELECT pastafari_sql_tamil.calendar_date(-15055671::numeric,-15072356::numeric) AS result;
RESET statement_timeout;
\echo S25_DIRECT_EXIT=calendar_date
SELECT (result).* FROM qa_direct_actual;
DO $qa$
DECLARE actual pastafari_sql_tamil.calendar_result_text;
BEGIN
    SELECT (result).* INTO STRICT actual FROM qa_direct_actual;
    IF actual IS DISTINCT FROM ROW(4996::numeric,'வெண்கலம்'::text,302::numeric,'தவளை'::text,50::numeric)::pastafari_sql_tamil.calendar_result_text THEN
        RAISE EXCEPTION 'S25_DIRECT_MISMATCH: actual=%',actual;
    END IF;
    RAISE NOTICE 'S25_DIRECT_DIFFERENTIAL=PASS; CASE=prev_3_prev_middle; FIELDS=5/5';
    RAISE NOTICE 'S25_FULL_SLICE=NOT_ACCEPTED';
END
$qa$;
