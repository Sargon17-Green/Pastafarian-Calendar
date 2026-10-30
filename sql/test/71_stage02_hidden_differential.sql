-- Separate native differential database, not a production dependency.
-- Four day-pairs x seven k values. The independent test namespace is
-- loaded only in this separate database.
BEGIN;
CREATE TEMP TABLE stage02_hidden_differential(test_name text PRIMARY KEY, ok boolean NOT NULL CHECK(ok));
WITH pairs AS (
    SELECT * FROM (VALUES
        (1, 0::numeric, 0::numeric),
        (2, -3::numeric, 2::numeric),
        (3, 2::numeric, -3::numeric),
        (4, 0::numeric, pastafari_sql_tamil.save_modulus())
    ) v(pair_id, calc_offset, target_offset)
)
INSERT INTO stage02_hidden_differential(test_name,ok)
SELECT 'pair=' || p.pair_id::text || '/k=' || g.k::text,
    pastafari_sql_tamil.hidden_drop(
        g.k,
        pastafari_sql_tamil.work_counts(
            pastafari_sql_tamil.foundation_day()+p.calc_offset,
            pastafari_sql_tamil.foundation_day()+p.target_offset
        )
    ) =
    pastafari_sql_tamil_test.hidden_drop(
        g.k,
        pastafari_sql_tamil_test.work_counts(
            pastafari_sql_tamil_test.foundation_day()+p.calc_offset,
            pastafari_sql_tamil_test.foundation_day()+p.target_offset
        )
    )
FROM pairs p CROSS JOIN generate_series(1,7) g(k);
SELECT 'மறைந்த துளி ஒப்பீட்டுச் சோதனை' AS status, count(*) AS assertion_count FROM stage02_hidden_differential;
COMMIT;
