# SQL+தமிழ் — Slice25 bounded find_target_year QA baseline

**PROJECT_ID:** PC-BRANCH-SQL-TAMIL
**Date:** 2026-11-20
**Parent HEAD verified:** `ae4412a3bf72963fcc134fb95925e8b76966b462` on `SQL+தமிழ்`.
**Scope:** QA-only contract, locked input, generator, PostgreSQL benchmark workflow; no production, normative, main, merge or release changes.

## Evidence and input provenance

- Accepted Slice24 fixed records: `sql/test/142_stage02_year_structure_cases.sql` (six distinct year records selected from the eight fixture rows).
- Accepted Slice25 structural run `44701320191` (8/8 completed/success, original ZIP hashes and CRC already independently verified): original `SLICE25_YEAR_JSON` log records for year 4996 (job `136170134637`, indices -38..-29, days -15074038..-15070673) and year 5004 (job `136170134738`, indices 29..37, days -15039840..-15034763).
- Read-only `sql/test/151_stage25_calendar_date_locked_goldens_44701320191.jsonl`, blob `21f38cd280498070b08b6c3074780f1742c36957`, contains 29 source-locked ordinal cases. A separate JavaScript construction/check verified 29/29 cases are inside the eight selected years, 8/8 year-first target days and distinct year identities. **These are metadata/fixture checks, not execution of the new Python generator or PostgreSQL selector.**
- `sql/test/152_stage25_selector_locked_years.jsonl` locks eight full `year_rec` five-field expected records, calculation days and selected first days; external provenance is preserved in each record. Neither the function under test nor the normative `calendar_date` generates these expected values.

## Executable QA harness

- `sql/test/153_stage25_selector_input.py` rejects a changed 29-case catalog, missing/duplicate year, noninteger or malformed five-field records, out-of-domain cases and mismatched first dates; emits exactly one source-locked SQL input per selected year.
- `sql/test/154_stage25_selector_benchmark.sql` checks six cheap invalid inputs (both STRICT nulls, fractional calculation/target days, +/-60001 unsupported offsets); calls the real production `find_target_year` **once** for one reachable input, measures elapsed milliseconds with `clock_timestamp()`, and checks all five numeric year-record fields independently.
- `.github/workflows/sql-tamil-stage02-selector-baseline.yml` defines eight independent PG17 jobs (one per year; fail-fast disabled). Each job checks exact `GITHUB_SHA`, generates one input from locked JSONL, records source/file SHA256 and PostgreSQL version, uses `psql -At -X -v ON_ERROR_STOP=1`, caps the SQL statement at **12 minutes** and the entire job at **15 minutes**, and uploads original logs/inputs even after failure. No manual duplicate dispatch is required.
- Result is accepted **per job only** after completed/success, original log, accurate elapsed metric and artifact ZIP SHA256/CRC verification. Prior 6m43s / 9m19s probes are historical observations, not new timings.

## Interpretation and NEXT

This commit makes **no claim** that any selector benchmark passed, any production optimization is correct, or Slice25 calendar_date is implemented. After the natural workflow run, verify original eight jobs and ZIP bytes, compare actual five fields, record per-year durations and any timeout; only then decide whether and how to optimize `find_target_year` while preserving its accepted domain. Next implement `calendar_date(numeric,numeric)` plus ≥40 Native, ≥8 isolation, ≥24 differential assertions and original ZIP/CRC gates under the existing Slice25 contract. Keep main/merge/publication untouched.
