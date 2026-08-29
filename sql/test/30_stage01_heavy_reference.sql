BEGIN;

CREATE TEMP TABLE stage01_heavy_case ON COMMIT DROP AS
WITH y AS MATERIALIZED (
  SELECT pastafari_sql_tamil_test.year5000(pastafari_sql_tamil_test.foundation_day()) AS yr
), s AS MATERIALIZED (
  SELECT yr,
         pastafari_sql_tamil_test.sauce(
           pastafari_sql_tamil_test.foundation_day(),
           (yr).open_gate_day+1
         ) AS sauce_data
  FROM y
), mc AS MATERIALIZED (
  SELECT yr,sauce_data,
         pastafari_sql_tamil_test.choose_month_count(sauce_data,yr) AS month_count
  FROM s
)
SELECT yr,sauce_data,month_count,
       pastafari_sql_tamil_test.choose_month_lengths(sauce_data,yr,month_count) AS month_lengths
FROM mc;

SELECT 1 / ((
  (yr).year_number=5000
  AND (yr).open_gate_index=-4
  AND (yr).close_gate_index=4
  AND (yr).open_gate_day=-15057703
  AND (yr).close_gate_day=-15053459
  AND (yr).close_gate_day-(yr).open_gate_day=4244
  AND month_count=45
  AND array_length(month_lengths,1)=45
  AND (SELECT sum(v) FROM unnest(month_lengths) AS q(v))=4244
)::integer) AS year_structure_assertion
FROM stage01_heavy_case;

WITH w AS MATERIALIZED (
  SELECT month_lengths,
         pastafari_sql_tamil_test.choose_month_weaving(sauce_data,month_lengths) AS weaving
  FROM stage01_heavy_case
), pos AS MATERIALIZED (
  SELECT g.i AS position,w.weaving[g.i] AS month_id,w.month_lengths
  FROM w,LATERAL generate_series(1,array_length(w.weaving,1)) AS g(i)
), stats AS MATERIALIZED (
  SELECT month_id,count(*) AS n,min(position) AS first_pos,max(position) AS last_pos
  FROM pos
  GROUP BY month_id
), ord AS MATERIALIZED (
  SELECT
    COALESCE(bool_and(first_pos<next_first) FILTER (WHERE next_first IS NOT NULL),true) AS first_order_ok,
    COALESCE(bool_and(last_pos<next_last) FILTER (WHERE next_last IS NOT NULL),true) AS last_order_ok
  FROM (
    SELECT month_id,first_pos,last_pos,
           lead(first_pos) OVER (ORDER BY month_id) AS next_first,
           lead(last_pos) OVER (ORDER BY month_id) AS next_last
    FROM stats
  ) q
), checks AS (
  SELECT
    (SELECT array_length(weaving,1)=(SELECT sum(x) FROM unnest(month_lengths) AS u(x)) FROM w) AS length_ok,
    (SELECT count(*)=(SELECT array_length(month_lengths,1) FROM w)
            AND bool_and(n=(SELECT month_lengths[stats.month_id] FROM w))
     FROM stats) AS multiplicities_ok,
    (SELECT min(month_id)=1
            AND max(month_id)=(SELECT array_length(month_lengths,1) FROM w)
     FROM stats) AS id_range_ok,
    first_order_ok,last_order_ok
  FROM ord
)
SELECT 1 / ((length_ok AND multiplicities_ok AND id_range_ok AND first_order_ok AND last_order_ok)::integer)
       AS month_weaving_assertion
FROM checks;

SELECT 1 / ((
  pastafari_sql_tamil_test.calendar_date(
    pastafari_sql_tamil_test.foundation_day(),
    pastafari_sql_tamil_test.foundation_day()
  ) = ROW(5000,'தேள்',503,'கிணறு',56)::pastafari_sql_tamil_test.calendar_result_text
)::integer) AS full_calendar_assertion;

SELECT 'கனரக நெறிமுறைச் சோதனைகள் அனைத்தும் வெற்றியடைந்தன' AS status,
       3 AS assertion_count;

COMMIT;
