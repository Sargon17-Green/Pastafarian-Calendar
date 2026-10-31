-- Stage 2 Slice 14 Native: bounded year-5000 window and sauce-derived selection.
-- Fixed foundation golden comes from the independent Stage 1 heavy reference gate.
BEGIN;
CREATE TEMP TABLE stage02_year5000_native(
  test_name text PRIMARY KEY,
  ok boolean NOT NULL CHECK(ok)
);
WITH input AS MATERIALIZED (
  SELECT pastafari_sql_tamil.foundation_day() AS f
), window_data AS MATERIALIZED (
  SELECT i.f,w.first_gate_index,w.gate_days
  FROM input AS i
  CROSS JOIN LATERAL pastafari_sql_tamil.year5000_gate_window(i.f) AS w
), candidates AS MATERIALIZED (
  SELECT w.f,c.*
  FROM window_data AS w
  CROSS JOIN LATERAL pastafari_sql_tamil.year5000_gate_pairs(
    w.f,w.first_gate_index,w.gate_days
  ) AS c
), chosen_rank AS MATERIALIZED (
  SELECT pastafari_sql_tamil.choose_rank(
    pastafari_sql_tamil.ask_bowl(
      pastafari_sql_tamil.sauce(max(f),max(f)),1,10
    ),
    max(candidate_count)::numeric
  ) AS rank1
  FROM candidates
), selected AS MATERIALIZED (
  SELECT c.*
  FROM candidates AS c
  CROSS JOIN chosen_rank AS r
  WHERE c.candidate_rank=r.rank1
), actual AS MATERIALIZED (
  SELECT pastafari_sql_tamil.year5000(f) AS yr
  FROM input
)
INSERT INTO stage02_year5000_native(test_name,ok)
SELECT 'foundation:independent-golden',(
  SELECT yr=ROW(
    5000::numeric,-4::numeric,4::numeric,
    -15057703::numeric,-15053459::numeric
  )::pastafari_sql_tamil.year_rec
  FROM actual
)
UNION ALL SELECT 'window:lower-index',(
  SELECT first_gate_index=
    pastafari_sql_tamil.gate_index_at_or_before(f-5778)-1
  FROM window_data
)
UNION ALL SELECT 'window:upper-index',(
  SELECT first_gate_index+array_length(gate_days,1)-1=
    pastafari_sql_tamil.gate_index_at_or_after(f+5778)+1
  FROM window_data
)
UNION ALL SELECT 'window:lower-sentinel',(
  SELECT gate_days[1]<f-5778 FROM window_data
)
UNION ALL SELECT 'window:upper-sentinel',(
  SELECT gate_days[array_length(gate_days,1)]>f+5778 FROM window_data
)
UNION ALL SELECT 'window:first-day-match',(
  SELECT gate_days[1]=pastafari_sql_tamil.gate_day(first_gate_index)
  FROM window_data
)
UNION ALL SELECT 'window:last-day-match',(
  SELECT gate_days[array_length(gate_days,1)]=
    pastafari_sql_tamil.gate_day(first_gate_index+array_length(gate_days,1)-1)
  FROM window_data
)
UNION ALL SELECT 'window:length-15-to-280',(
  SELECT array_length(gate_days,1) BETWEEN 15 AND 280
  FROM window_data
)
UNION ALL SELECT 'window:all-adjacent-gaps-valid',(
  SELECT NOT EXISTS(
    SELECT 1
    FROM window_data AS w
    CROSS JOIN LATERAL generate_series(
      1,array_length(w.gate_days,1)-1
    ) AS g(k)
    WHERE w.gate_days[g.k+1]-w.gate_days[g.k] NOT BETWEEN 42 AND 963
  )
)
UNION ALL SELECT 'candidates:nonempty',(
  SELECT count(*)>0 FROM candidates
)
UNION ALL SELECT 'candidates:count-consistent',(
  SELECT count(*)=max(candidate_count) FROM candidates
)
UNION ALL SELECT 'candidates:ranks-unique-contiguous',(
  SELECT count(DISTINCT candidate_rank)=count(*)
     AND min(candidate_rank)=1
     AND max(candidate_rank)=count(*)
  FROM candidates
)
UNION ALL SELECT 'candidates:all-contract-constraints',(
  SELECT coalesce(bool_and(
    open_gate_day<f AND f<=close_gate_day
    AND close_gate_index-open_gate_index>=6
    AND close_gate_day-open_gate_day BETWEEN 252 AND 5778
  ),false)
  FROM candidates
)
UNION ALL SELECT 'candidates:rank-order',(
  SELECT coalesce(bool_and(candidate_rank=expected_rank),false)
  FROM (
    SELECT candidate_rank,
      row_number() OVER (
        ORDER BY close_gate_day-open_gate_day,open_gate_day
      ) AS expected_rank
    FROM candidates
  ) AS ranked
)
UNION ALL SELECT 'selection:rank-in-range',(
  SELECT r.rank1 BETWEEN 1 AND max(c.candidate_count)
  FROM chosen_rank AS r CROSS JOIN candidates AS c
  GROUP BY r.rank1
)
UNION ALL SELECT 'selection:matches-sauce-derived-rank',(
  SELECT (a.yr).open_gate_index=s.open_gate_index
     AND (a.yr).close_gate_index=s.close_gate_index
     AND (a.yr).open_gate_day=s.open_gate_day
     AND (a.yr).close_gate_day=s.close_gate_day
  FROM actual AS a CROSS JOIN selected AS s
)
UNION ALL SELECT 'invalid:fractional-year',(
  pastafari_sql_tamil.year5000(
    pastafari_sql_tamil.foundation_day()+0.5
  ) IS NULL
)
UNION ALL SELECT 'invalid:fractional-window',(
  NOT EXISTS(
    SELECT 1 FROM pastafari_sql_tamil.year5000_gate_window(
      pastafari_sql_tamil.foundation_day()+0.5
    )
  )
)
UNION ALL SELECT 'invalid:null-year',(
  pastafari_sql_tamil.year5000(NULL::numeric) IS NULL
)
UNION ALL SELECT 'metadata:year-rec-five-fields',(
  SELECT count(*)=5
  FROM pg_type AS t
  JOIN pg_namespace AS n ON n.oid=t.typnamespace
  JOIN pg_class AS c ON c.oid=t.typrelid
  JOIN pg_attribute AS a ON a.attrelid=c.oid
  WHERE n.nspname='pastafari_sql_tamil'
    AND t.typname='year_rec'
    AND a.attnum>0 AND NOT a.attisdropped
)
UNION ALL SELECT 'metadata:calendar-result-five-fields',(
  SELECT count(*)=5
  FROM pg_type AS t
  JOIN pg_namespace AS n ON n.oid=t.typnamespace
  JOIN pg_class AS c ON c.oid=t.typrelid
  JOIN pg_attribute AS a ON a.attrelid=c.oid
  WHERE n.nspname='pastafari_sql_tamil'
    AND t.typname='calendar_result'
    AND a.attnum>0 AND NOT a.attisdropped
)
UNION ALL SELECT 'metadata:sql-stable-functions',(
  SELECT count(*)=2
  FROM pg_proc AS p
  JOIN pg_namespace AS n ON n.oid=p.pronamespace
  JOIN pg_language AS l ON l.oid=p.prolang
  WHERE n.nspname='pastafari_sql_tamil'
    AND p.proname IN ('year5000_gate_window','year5000')
    AND l.lanname='sql' AND p.provolatile='s'
)
UNION ALL SELECT 'metadata:no-reference-body',(
  SELECT count(*)=0
  FROM pg_proc AS p
  JOIN pg_namespace AS n ON n.oid=p.pronamespace
  WHERE n.nspname='pastafari_sql_tamil'
    AND p.proname IN ('year5000_gate_window','year5000')
    AND position('pastafari_sql_tamil_test' IN pg_get_functiondef(p.oid))>0
);

SELECT count(*) AS native_assertions FROM stage02_year5000_native;
COMMIT;
