# SQL+தமிழ் — Slice24 PG17 preflight timeout triage and bounded repair (2026-11-07)

**PROJECT_ID:** PC-BRANCH-SQL-TAMIL. **Branch:** SQL+தமிழ். **Prior locked SHA:** 92bb203290b227ec913dc7151a1889d0e8fd1c78.
**Scope:** preflight-only repair; production sql/00..25 and all already accepted Slice23 files unchanged. No Slice24 production or Native PASS claim.

## Original run evidence

- GitHub Actions push run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42251804382
- Run completed/cancelled; only job `preflight` (ID 128008555234) completed/cancelled.
- PostgreSQL image `postgres:17` was pulled; original job log and artifact both report PostgreSQL **17.11**.
- Exact SHA and independent Python self-test succeeded: 8/8 synthetic records, 64/64 rejected mutations, 134/134 small compositions. This is NOT a Native goldens check.
- Production SQL 00..25 loaded, and PG catalog printed `slice24_selector_signatures=7/7; year_rec_fields=5/5` and `year_structure_type_preexisting=f`.
- After the catalog notices at **2026-11-06T16:48:14Z**, no navigation/input rows appeared. The run was cancelled at **17:03:16Z** during the same DO block, matching the 15-minute hard cap. The original log does **not** isolate which of `year5000`, `next_year` or `previous_year` was active; asserting a proven algorithm defect would be unjustified.
- The original artifact ID 13523248132 (4 files, 1741 bytes) SHA256 `f32e5797acd4c830d9c38501fb535309bbd2e249928021387c1de11439bbdc5b` matched **GitHub metadata**, **upload-job log**, and **downloaded ZIP bytes**. ZIP CRC test passed; it has no completed ten-input table.
- Consequently, 7/7 PG catalog signatures and 5/5 fields are observed, but **0/10 complete reachable input rows accepted**; run is not success.

## Targeted engineering repair

`sql/test/141_stage02_year_structure_input_preflight.sql` previously began input acquisition with `year5000(foundation_day())`, a prerequisite already accepted at Slice14. The current test now seeds the actual foundation record from the independent Native fixture `sql/test/108_stage02_year5000_native.sql` (5000,-4,4,-15057703,-15053459). These exact five numbers are **not invented** or derived from the tested Slice24 implementation.

The current run verifies this seed against `foundation_day()`, `gate_day(-4)` and `gate_day(4)`, using current PostgreSQL production functions, before it can be counted as a reachable year. The five-field PG catalog gate remains in place. Subsequent four `next_year` and three `previous_year` calls remain genuine production navigation, not mocks; the two boundary-day inputs and original 10/10 and 8/8 checks remain unchanged.

Timestamped `RAISE NOTICE` progress checkpoints after the foundation anchor and after each navigation call make any further 15-minute cancellation precisely diagnosable. This is a performance/observability change to a test, not a fix to a demonstrated production defect. No reference-schema import and no new independent year-structure golden claims.

## Acceptance gate and NEXT

Run source-locked PG17 preflight on this **new branch SHA**, collect original completed logs and artifact ZIP; require 7/7 signature + 5/5 fields + 10/10 reachable inputs + 8/8 navigation + 2/2 boundary days and largest span. Validate each source SHA, original artifact digest vs GitHub/upload log, and ZIP CRC. If cancelled again, use the last progress checkpoint to isolate the expensive navigation call and shard bounded tests rather than declaring PASS. Only then construct >=8 independently sourced actual complete-record goldens, implement production `year_structure/build_year_structure` in ordered sql/26, and supply >=25 Native, >=8 isolation, >=8 full eight-field differential with PG17 original artifacts.

No main, merge, or publication.
