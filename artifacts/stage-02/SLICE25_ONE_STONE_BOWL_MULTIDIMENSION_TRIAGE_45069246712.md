# SQL+தமிழ் Slice25 — one-stone QA multidimensional-array failure and focused repair

PROJECT_ID: PC-BRANCH-SQL-TAMIL
Branch: SQL+தமிழ்
Observed parent/source SHA: 1ae53bd1f70db68aa60cb0c9e3d5c270af8e3c84
Date: 2026-11-23
Scope: QA-only SQL and this report; no production SQL, main, merge, release, or full 56-job matrix.

## Exact source / completed evidence
- GitHub Actions run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45069246712
- Job 137352274091 completed/failure; PostgreSQL 17.12. Source generation and container startup succeeded; QA step failed. Original decoded job log identifies `sql/test/175_stage25_one_stone_bowl_qa.sql:83` and `SQL function "bowl_round_one_stone" statement 1`, called by invalid-input assignment in the PL/pgSQL DO block, with `ERROR: searching for elements in multidimensional arrays is not supported`.
- Original artifact id 14772608478: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45069246712/artifacts/14772608478 . ZIP SHA256 `867d163772847ac6550aa142fda70832cfb5e2face2df7770a07fc8aec7cf54a` independently computed from original 19,499 bytes and equal to GitHub artifact digest and decoded upload-job log; zipfile.testzip() returned None (CRC OK). 10 original archive entries. `exits.txt`: SOURCE_LOAD_EXIT=0, CANDIDATE_EXIT=3; no ORACLE_EXIT, so independent candidate oracle not executed. `candidate.log` confirms failure; generator static output PASS is *not* PostgreSQL Native PASS.
- Names Lock run 45069246582, job 137352273521 completed/success at source SHA 1ae53bd1f70db68aa60cb0c9e3d5c270af8e3c84; no artifact. Stage1 run 45069246645 success is separately retained by prior exact-SHA evidence, not rerun here.

## Mechanism
PostgreSQL does not guarantee short-circuit left-to-right evaluation of AND conditions in a SQL WHERE predicate; the SQL function called array_position(b,NULL::numeric) without its own dimension guard. The input `ARRAY[[1,2,3],[4,5,6]]::numeric[]` (existing negative test `two_dims`) reaches this one-dimensional-only search, raising ERROR before the 12/12 negative suite can complete. This is a QA candidate input validation defect, not evidence of a numerical mismatch against production.

## Scoped repair and revalidation contract
1. Wrap `array_position` in `CASE WHEN array_ndims(b)=1 THEN ... ELSE FALSE END` so that invalid 2-D arrays cannot invoke it.
2. Add an *early* PG17 preflight for two-dimensional input: must return SQL NULL, never ERROR, and emit `SQL_TAMIL_TWO_DIMENSION_GUARD=PASS` only upon success.
3. Preserve the existing 368/368 full-array differential (46 positions x 4 drops x 2 bowl arrays), all 12 negative inputs, four alternating EXPLAIN ANALYZE timings, and generated independent 230+32 vectors.
4. Exact-new-SHA completed job+log and original artifact ZIP SHA256 (GitHub digest / upload log / raw) + CRC are mandatory before claiming PostgreSQL Native/differential acceptance. A naturally triggered CI run is not accepted while queued/in_progress. No duplicate manual dispatch.

## Gate status at commit creation
Source/QA patch statically checked for unique replacement and preserved count/markers. PostgreSQL Native on the patched SHA: NOT YET VERIFIED. Slice25 as a whole: NOT ACCEPTED. No user-machine execution required.
