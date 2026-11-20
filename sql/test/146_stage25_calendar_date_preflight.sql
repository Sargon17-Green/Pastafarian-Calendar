\set ON_ERROR_STOP on
SET statement_timeout = '12min';

-- Slice25 bounded discovery. Six distinct records come from accepted
-- Slice24 fixtures; one adjacent year is derived on either side.
-- This preflight does not implement or claim calendar_date.
CREATE TEMP TABLE slice25_years (
    year_id text PRIMARY KEY,
    calculation_day numeric NOT NULL,
    year_data pastafari_sql_tamil.year_rec NOT NULL
);

INSERT INTO slice25_years(year_id,calculation_day,year_data)
SELECT id,d,y
FROM slice24_cases
WHERE id IN ('anchor','next_1','next_2','next_3','prev_2','prev_3');

INSERT INTO slice25_years(year_id,calculation_day,year_data)
SELECT 'prev_3_prev',d,pastafari_sql_tamil.previous_year(d,y)
FROM slice24_cases
WHERE id='prev_3';

INSERT INTO slice25_years(year_id,calculation_day,year_data)
SELECT 'next_3_next',d,pastafari_sql_tamil.next_year(d,y)
FROM slice24_cases
WHERE id='next_3';

DO $derive_check$
BEGIN
    IF (SELECT count(*) FROM slice25_years) <> 8
       OR (SELECT count(DISTINCT (year_data).year_number) FROM slice25_years) <> 8 THEN
        RAISE EXCEPTION 'expected eight distinct reachable year records';
    END IF;
    IF EXISTS (SELECT 1 FROM slice25_years WHERE year_data IS NULL) THEN
        RAISE EXCEPTION 'adjacent-year derivation returned NULL';
    END IF;
END;
$derive_check$;

CREATE TEMP TABLE slice25_structures (
    year_id text PRIMARY KEY,
    calculation_day numeric NOT NULL,
    year_data pastafari_sql_tamil.year_rec NOT NULL,
    year_structure pastafari_sql_tamil.year_structure NOT NULL
);

CREATE TEMP TABLE slice25_targets (
    case_id text PRIMARY KEY,
    year_id text NOT NULL,
    calculation_day numeric NOT NULL,
    target_day numeric NOT NULL,
    purpose text NOT NULL,
    focus_month_id integer
);

DO $preflight$
DECLARE
    v_year_id text := '__YEAR_CASE__';
    v_calculation_day numeric;
    v_year pastafari_sql_tamil.year_rec;
    v_structure pastafari_sql_tamil.year_structure;
    v_started timestamptz;
    v_elapsed interval;
    v_first numeric;
    v_middle numeric;
    v_last numeric;
    v_boundary numeric;
    v_month_id integer;
    v_first_pos bigint;
    v_second_pos bigint;
    v_count integer;
BEGIN
    SELECT calculation_day
      INTO STRICT v_calculation_day
      FROM slice25_years
     WHERE year_id=v_year_id;

    SELECT (year_data).*
      INTO STRICT v_year
      FROM slice25_years
     WHERE year_id=v_year_id;

    v_started := clock_timestamp();
    v_structure := pastafari_sql_tamil.build_year_structure(v_calculation_day,v_year);
    v_elapsed := clock_timestamp()-v_started;
    IF v_structure IS NULL THEN
        RAISE EXCEPTION 'build_year_structure returned NULL for %',v_year_id;
    END IF;
    RAISE NOTICE 'slice25_build_year_structure year_id=% elapsed=%',v_year_id,v_elapsed;

    INSERT INTO slice25_structures
    VALUES(v_year_id,v_calculation_day,v_year,v_structure);

    v_first := (v_year).open_gate_day+1;
    v_middle := (v_year).open_gate_day+
                floor(((v_year).close_gate_day-(v_year).open_gate_day)/2);
    v_last := (v_year).close_gate_day;

    INSERT INTO slice25_targets
    VALUES
      (v_year_id||'_first',v_year_id,v_calculation_day,v_first,'year_first',NULL),
      (v_year_id||'_middle',v_year_id,v_calculation_day,v_middle,'year_middle',NULL),
      (v_year_id||'_last',v_year_id,v_calculation_day,v_last,'year_last',NULL);

    IF v_year_id='anchor' THEN
        WITH prefixes AS MATERIALIZED (
            SELECT ord,sum(part) OVER(ORDER BY ord)::numeric AS prefix
            FROM unnest((v_structure).cutlet_partition) WITH ORDINALITY AS u(part,ord)
            WHERE ord < (v_structure).cutlet_count
        ), boundaries AS MATERIALIZED (
            SELECT ord,pastafari_sql_tamil.gate_day((v_year).open_gate_index+prefix) AS boundary_day
            FROM prefixes
        )
        SELECT boundary_day
          INTO STRICT v_boundary
          FROM boundaries
         WHERE boundary_day > v_first+1
           AND boundary_day < v_last-1
           AND boundary_day-1 NOT IN (v_first,v_middle,v_last)
           AND boundary_day NOT IN (v_first,v_middle,v_last)
           AND boundary_day+1 NOT IN (v_first,v_middle,v_last)
         ORDER BY abs(boundary_day-v_middle),ord
         LIMIT 1;

        INSERT INTO slice25_targets VALUES
          ('anchor_cutlet_boundary_minus','anchor',v_calculation_day,v_boundary-1,'cutlet_boundary_minus',NULL),
          ('anchor_cutlet_boundary','anchor',v_calculation_day,v_boundary,'cutlet_boundary',NULL),
          ('anchor_cutlet_boundary_plus','anchor',v_calculation_day,v_boundary+1,'cutlet_boundary_plus',NULL);
    END IF;

    IF v_year_id='next_1' THEN
        WITH occurrences AS MATERIALIZED (
            SELECT month_id,pos,
                   row_number() OVER(PARTITION BY month_id ORDER BY pos) AS occurrence
            FROM unnest((v_structure).month_weaving) WITH ORDINALITY AS u(month_id,pos)
        ), pairs AS MATERIALIZED (
            SELECT month_id,
                   max(pos) FILTER(WHERE occurrence=1) AS first_pos,
                   max(pos) FILTER(WHERE occurrence=2) AS second_pos
            FROM occurrences
            GROUP BY month_id
            HAVING count(*)>=2
        )
        SELECT month_id,first_pos,second_pos
          INTO STRICT v_month_id,v_first_pos,v_second_pos
          FROM pairs
         WHERE (v_year).open_gate_day+first_pos NOT IN (v_first,v_middle,v_last)
           AND (v_year).open_gate_day+second_pos NOT IN (v_first,v_middle,v_last)
         ORDER BY month_id
         LIMIT 1;

        INSERT INTO slice25_targets VALUES
          ('next_1_month_first','next_1',v_calculation_day,(v_year).open_gate_day+v_first_pos,'month_first_occurrence',v_month_id),
          ('next_1_month_second','next_1',v_calculation_day,(v_year).open_gate_day+v_second_pos,'month_repeated_occurrence',v_month_id);
    END IF;

    SELECT count(*) INTO v_count
      FROM slice25_targets
     WHERE year_id=v_year_id;

    IF v_count <> (CASE WHEN v_year_id='anchor' THEN 6
                        WHEN v_year_id='next_1' THEN 5 ELSE 3 END) THEN
        RAISE EXCEPTION 'unexpected case count for %: %',v_year_id,v_count;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM slice25_targets
        WHERE year_id=v_year_id
          AND NOT ((v_year).open_gate_day < target_day
                   AND target_day <= (v_year).close_gate_day)
    ) THEN
        RAISE EXCEPTION 'target outside selected year for %',v_year_id;
    END IF;

    IF (SELECT count(DISTINCT target_day) FROM slice25_targets WHERE year_id=v_year_id) <> v_count THEN
        RAISE EXCEPTION 'duplicate target day in %',v_year_id;
    END IF;

    -- Run 44613358925 established that repeated find_target_year calls exceed
    -- the 12-minute statement cap (first probes 6m43s / 9m19s). This job
    -- extracts independent structural fixtures, NOT selector acceptance evidence.
    -- Membership and uniqueness have been checked above for every target;
    -- find_target_year performance/correctness remains a separate open gate.
    RAISE NOTICE 'slice25_selector_deferred year_id=% target_count=% reason=performance',
        v_year_id,v_count;

    RAISE NOTICE 'slice25_reachable_year=% year_number=% targets=%',v_year_id,(v_year).year_number,v_count;
END;
$preflight$;

SELECT 'SLICE25_YEAR_JSON ' || jsonb_build_object(
    'year_id',s.year_id,
    'calculation_day',s.calculation_day,
    'year_data',to_jsonb(s.year_data),
    'year_structure',jsonb_build_object(
        'year_data',to_jsonb((s.year_structure).year_data),
        'cutlet_count',(s.year_structure).cutlet_count,
        'cutlet_partition',(s.year_structure).cutlet_partition,
        'cutlet_name_indices',(s.year_structure).cutlet_name_indices,
        'month_count',(s.year_structure).month_count,
        'month_lengths',(s.year_structure).month_lengths,
        'month_weaving',(s.year_structure).month_weaving,
        'month_name_indices',(s.year_structure).month_name_indices
    ),
    'cutlet_prefix_gates',(
        -- gate_day(index) re-sums every gap from the foundation. Repeating it
        -- at each cutlet boundary is quadratic in the number of gaps.
        -- One forward pass from the source-locked open gate is equivalent:
        -- gate_day(i) - gate_day(i-1) = positive_gate_gap(i) for i>0,
        -- and negative_gate_gap(1-i) for i<=0 (including crossing zero).
        WITH cutlet_prefixes AS MATERIALIZED (
            SELECT 0::bigint AS ordinal,0::numeric AS prefix
            UNION ALL
            SELECT ord,sum(part) OVER(ORDER BY ord)::numeric AS prefix
            FROM unnest((s.year_structure).cutlet_partition)
                 WITH ORDINALITY AS u(part,ord)
        ),
        gap_steps AS MATERIALIZED (
            SELECT step_index,
                   CASE WHEN step_index>0
                        THEN pastafari_sql_tamil.positive_gate_gap(step_index)
                        ELSE pastafari_sql_tamil.negative_gate_gap(1-step_index)
                   END AS gap
            FROM generate_series(
                (s.year_data).open_gate_index+1,
                (s.year_data).close_gate_index,
                1::numeric
            ) AS step(step_index)
        ),
        cumulative_gaps AS MATERIALIZED (
            SELECT step_index,
                   sum(gap) OVER(ORDER BY step_index ROWS UNBOUNDED PRECEDING)
                       AS cumulative_gap
            FROM gap_steps
        )
        SELECT jsonb_agg(
            jsonb_build_object(
                'ordinal',p.ordinal,
                'prefix',p.prefix,
                'gate_index',(s.year_data).open_gate_index+p.prefix,
                'gate_day',CASE WHEN p.ordinal=0
                               THEN (s.year_data).open_gate_day
                               ELSE (s.year_data).open_gate_day+g.cumulative_gap
                          END
            ) ORDER BY p.ordinal
        )
        FROM cutlet_prefixes AS p
        LEFT JOIN cumulative_gaps AS g
          ON g.step_index=(s.year_data).open_gate_index+p.prefix
    )
)::text
FROM slice25_structures AS s;

SELECT 'SLICE25_CASE_JSON ' || jsonb_build_object(
    'case_id',case_id,
    'year_id',year_id,
    'calculation_day',calculation_day,
    'target_day',target_day,
    'purpose',purpose,
    'focus_month_id',focus_month_id
)::text
FROM slice25_targets
ORDER BY case_id;

SELECT 'SLICE25_CATALOG_JSON ' || jsonb_build_object(
    'category',category,
    'canonical_index',canonical_index,
    'source_text_tamil',source_text_tamil
)::text
FROM pastafari_sql_tamil.source_language_catalog
ORDER BY category,canonical_index;

SELECT 'SLICE25_STRUCTURAL_PREFLIGHT_GREEN=1'
WHERE (SELECT count(*) FROM slice25_years)=8
  AND (SELECT count(DISTINCT (year_data).year_number) FROM slice25_years)=8
  AND (SELECT count(*) FROM slice25_structures)=1
  AND (SELECT count(*) FROM slice25_targets)=CASE
      WHEN '__YEAR_CASE__'='anchor' THEN 6
      WHEN '__YEAR_CASE__'='next_1' THEN 5
      ELSE 3 END;
