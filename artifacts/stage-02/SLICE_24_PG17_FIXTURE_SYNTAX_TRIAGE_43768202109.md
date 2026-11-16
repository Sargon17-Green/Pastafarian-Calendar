# Slice24 PG17 fixture parsing failure — run 43768202109

Project: PC-BRANCH-SQL-TAMIL (SQL+தமிழ்)
Original tested SHA: `56bef8f3761a24bb99b02a1f7561595e04fd9398`
Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43768202109
Date checked: 2026-11-16

## Evidence

- 16/16 matrix jobs completed/failure: 8 native and 8 differential. The 16 original job logs were inspected.
- All 16 logs report PostgreSQL 17.12, failure in `sql/test/142_stage02_year_structure_cases.sql:11`, `syntax error at or near "("` while parsing the VALUES rows, and process exit code 3.
- In all 16 jobs, source files loaded before the fixture. No native/golden/differential assertion completed; no Stage2 or Slice24 PASS is asserted.
- All 16 job logs include upload-side artifact ZIP SHA-256 digests matching the 16 artifact metadata digests and identify the same tested SHA. Original ZIP bytes and CRC have NOT been independently inspected in this report, so complete artifact acceptance remains pending.

## Root cause and bounded patch

Eight legitimate rows in `INSERT INTO slice24_cases VALUES` were not separated by commas. The first row ended without comma, and PostgreSQL rejected the opening parenthesis of the next row.

Patch ONLY `sql/test/142_stage02_year_structure_cases.sql`: append one comma to each of the first seven row expressions. Keep all eight case identifiers, source-selected year/day values, record fields, type casts, and the final semicolon byte-for-byte unchanged.

## Preflight and limitations

Structural preflight: eight ordered unique labels, eight typed `year_rec` rows, exactly seven added row separators, no non-separator changes. This is a static QA check, NOT a PostgreSQL native PASS.

## NEXT

Inspect automatic push CI at the new commit SHA (do not manually re-dispatch). Require all 16 completed jobs with PG17 native, 8 x 29 named checks, 8 Python actual-structure checks, 8 differential full-eight-field comparisons with 9 checks each, and >=8 isolation checks; verify each original ZIP SHA256 against GitHub metadata and upload logs and against downloaded ZIP bytes/CRC; verify embedded source and generated SQL hashes. Repair only evidence-supported failures. No merge to main or release.
