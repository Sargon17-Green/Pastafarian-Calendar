# Slice25 fixed-year bounded build/cutlet QA contract (2026-11-23)
PROJECT_ID: PC-BRANCH-SQL-TAMIL
Branch: SQL+தமிழ்
Parent HEAD: c2e355c0cd175023535572efe7995ea4452d3e70
Scope QA only; no production/main/merge/release/full 56-case matrix.

Input original PG17 44701320191 year_rec=(4996,-38,-29,-15074038,-15070673). Calculation day=-15055671; target=-15072356. Independent fixture 151 five-field expected=(4996,வெண்கலம்,302,தவளை,50). Archived accepted gate 45133869661 supplies 9 gaps [131,471,251,227,300,839,281,652,213], sum=3365; no repeat Native gate calls.

Exactly five source-native phases with separate 60s statement_timeout: sauce, cutlet count, cutlet partition, cutlet names, unchanged direct build_year_structure. Phases consume prior outputs without repetition except full function (one independent call). Original source Git blob locks 10/19/20/21/26/27, independent fixtures 151/152. Native cutlet ordinal must match the independent oracle using archived gaps (வெண்கலம்,302) before the full function. Five-field comparison only after complete build_year_structure succeeds and agrees with independently timed selectors. Observations include phase entry/exit, durations, PG version, source locks, errors, exit code, original ZIP/SHA/CRC (audit after completed run). A timeout is not an expected PASS and does not assert a defect without logs.

Static lock PASS is not Native PASS; cutlet PASS is not five-field PASS; five-field PASS is not unchanged calendar_date differential, and full Slice25 remains NOT ACCEPTED. No user-execution package or cleanup required absent local results.
