-- Stage 2 production slice 2: 46 exact, independently computed stone states.
-- No normative/test schema and no mutable cache. All arithmetic is numeric.
CREATE TYPE pastafari_sql_tamil.stone5 AS (
    wheat numeric,
    barley numeric,
    salt numeric,
    bitter numeric,
    red numeric
);

-- Invalid indices have no row; the only defined positions are 1..46.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.stone_state(p_index integer)
RETURNS pastafari_sql_tamil.stone5
LANGUAGE SQL IMMUTABLE STRICT AS $$
    WITH RECURSIVE states(i,wheat,barley,salt,bitter,red) AS (
        SELECT 1,17::numeric,29::numeric,43::numeric,71::numeric,101::numeric
        UNION ALL
        SELECT i+1,
            pastafari_sql_tamil.save_value(wheat*wheat+3*barley+(i+1)),
            pastafari_sql_tamil.save_value(barley*barley+5*salt+wheat),
            pastafari_sql_tamil.save_value(salt*salt+7*bitter+barley),
            pastafari_sql_tamil.save_value(bitter*bitter+11*red+salt),
            pastafari_sql_tamil.save_value(red*red+13*wheat+bitter)
        FROM states
        WHERE i<46 AND i<p_index
    )
    SELECT ROW(wheat,barley,salt,bitter,red)::pastafari_sql_tamil.stone5
    FROM states WHERE i=p_index
$$;

-- Exactly five one-based stone kinds; others resolve to NULL.
CREATE OR REPLACE FUNCTION pastafari_sql_tamil.stone_value(p_index integer,p_kind integer)
RETURNS numeric
LANGUAGE SQL IMMUTABLE STRICT AS $$
    SELECT CASE p_kind
        WHEN 1 THEN (s.stone).wheat
        WHEN 2 THEN (s.stone).barley
        WHEN 3 THEN (s.stone).salt
        WHEN 4 THEN (s.stone).bitter
        WHEN 5 THEN (s.stone).red
        ELSE NULL::numeric
    END
    FROM (SELECT pastafari_sql_tamil.stone_state(p_index) AS stone) AS s
$$;
