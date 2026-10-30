-- Stage 2, first production slice. No test/reference schema is loaded or called.
-- All values are exact integers represented by PostgreSQL numeric.
-- The five components of the final calendar are NOT implemented by this slice.
CREATE TYPE pastafari_sql_tamil.work_counts AS (
    action numeric,
    target numeric,
    distance numeric,
    connection numeric,
    direction integer
);

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.save_modulus()
RETURNS numeric LANGUAGE SQL IMMUTABLE AS $$
    SELECT 170141183460469231731687303715884105727::numeric
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.foundation_day()
RETURNS numeric LANGUAGE SQL IMMUTABLE AS $$
    SELECT (-15055671)::numeric
$$;

-- Integer Euclidean quotient, defined only for integer x and positive integer d.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.floor_div(p_x numeric, p_d numeric)
RETURNS numeric LANGUAGE SQL IMMUTABLE STRICT AS $$
    SELECT CASE
        WHEN p_d <= 0 OR p_d <> trunc(p_d) OR p_x <> trunc(p_x)
            THEN NULL::numeric
        WHEN p_x >= 0 THEN div(p_x,p_d)
        ELSE -div(-p_x+p_d-1,p_d)
    END
$$;

-- 0 <= result < d, including for negative integer dividends.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.regular_mod(p_x numeric, p_d numeric)
RETURNS numeric LANGUAGE SQL IMMUTABLE STRICT AS $$
    SELECT p_x-pastafari_sql_tamil.floor_div(p_x,p_d)*p_d
$$;

-- Closed interval [1,M] rather than [0,M-1].
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.save_value(p_x numeric)
RETURNS numeric LANGUAGE SQL IMMUTABLE STRICT AS $$
    SELECT 1+pastafari_sql_tamil.regular_mod(
        p_x-1,pastafari_sql_tamil.save_modulus()
    )
$$;

-- The foundation day has count 1; dates before it take even counts.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.day_count(p_day numeric)
RETURNS numeric LANGUAGE SQL IMMUTABLE STRICT AS $$
    SELECT CASE
        WHEN p_day <> trunc(p_day) THEN NULL::numeric
        WHEN p_day = pastafari_sql_tamil.foundation_day() THEN 1::numeric
        WHEN p_day > pastafari_sql_tamil.foundation_day()
            THEN 2*(p_day-pastafari_sql_tamil.foundation_day())+1
        ELSE 2*(pastafari_sql_tamil.foundation_day()-p_day)
    END
$$;

-- First production computation from the two input day numbers.
-- No normative implementation, persistent cache, or global mutable state.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.work_counts(
    p_calculation_day numeric,p_target_day numeric
)
RETURNS pastafari_sql_tamil.work_counts
LANGUAGE SQL IMMUTABLE STRICT AS $$
    SELECT ROW(
        pastafari_sql_tamil.day_count(p_calculation_day),
        pastafari_sql_tamil.day_count(p_target_day),
        abs(p_target_day-p_calculation_day)+1,
        pastafari_sql_tamil.day_count(p_calculation_day)
          + pastafari_sql_tamil.day_count(p_target_day),
        CASE
          WHEN p_target_day<p_calculation_day THEN 1
          WHEN p_target_day=p_calculation_day THEN 2
          ELSE 3
        END
    )::pastafari_sql_tamil.work_counts
    WHERE p_calculation_day=trunc(p_calculation_day)
      AND p_target_day=trunc(p_target_day)
$$;
