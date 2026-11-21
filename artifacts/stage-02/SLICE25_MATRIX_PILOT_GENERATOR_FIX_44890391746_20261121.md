# SQL+தமிழ் Slice25 — source-locked pilot root-cause fix (2026-11-21)

PROJECT_ID: PC-BRANCH-SQL-TAMIL; authorized branch: SQL+தமிழ். Parent source HEAD: 82b5d1a261ce8d0e2b3c94a815e7ff27d15fdb12. Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44890391746. Production SQL and normative oracle were NOT modified. No main, merge or release. Whole Slice25 gate remains NOT ACCEPTED.

## Completed original three-job pilot on the parent commit

- Native anchor_first: job 136804720046 completed/success PostgreSQL 17.12, five independent named field flags; 275796.067 ms. Original ZIP artifact 14702116083 SHA256 4c3e2cd8097895520de66e741f7a7b9b0274ea8ac96a22009a69f53ce64101ab.
- Differential next_2_first: job 136804719998 completed/success PostgreSQL 17.12, five production-golden fields AND five typed normative differential fields; 664077.213 ms. Original ZIP artifact 14701917913 SHA256 8117799cff9b654d545fdf3085c94c59188df24235c0e63acb5ab8b483466ba1.
- Isolation next_1_first: job 136804719829 completed/failure BEFORE PostgreSQL. Original log traceback: sql/test/164_stage25_calendar_date_matrix.py line 90, Python ValueError: unsupported format character at index 49, from trying to apply the Python percent-format operator to an SQL RAISE NOTICE string containing PostgreSQL percent. Independent ordinal selftest 9411/9411 cutlet positions and 22890/22890 month positions, locked corpus 29 cases/8 years/145 fields passed before error. ZIP artifact 14701554143 SHA256 358e4a314023703ccee8bd5d99c9486898f1ee8d331397f63910931382a794e4.
- All three original job logs were inspected. All three original ZIPs independently downloaded; computed raw ZIP SHA256 matched GitHub artifact API digests and upload-job digests; all ZIP entries passed CRC. The isolation artifact contains 4 pre-database files, no PostgreSQL result. All ZIP versions refer to 82b5d1a261ce8d0e2b3c94a815e7ff27d15fdb12.

## Exact fix, measurable regression

In the QA-only SQL generator, replace the malformed Python percent-format expression with an f-string that emits the literal case-specific SQL notice. No calendar function, expected record, workflow or normative source is changed. Expand existing --audit to generate SQL for all 29 locked cases in each of native, isolation and differential modes, and assert exactly 5 native field notices, 5 differential notices only in differential mode, the two isolation notices only in isolation mode and the case-specific green marker. Expected standalone QA: SLICE25_GENERATOR_PREFLIGHT=87/87 PASS. This is a static/generated-SQL preflight, NOT Native or full Slice25 acceptance.

## NEXT / acceptance boundaries

Allow only the natural push-triggered exact-new-SHA three-job pilot to run; no manual duplicate. Verify completed status, exact commit, three original logs, PostgreSQL 17, 29/29 immutable cases, selftest, five-field flags, original ZIP raw+GitHub+upload SHA256 and CRC. The repaired isolation must actually run in a fresh production-only database and emit both isolation notices plus 5 field notices. If pilot passes, design a bounded/sharded full matrix: Native >=40 including >=24 distinct reachable cases and 8 years, >=8 fresh production-only isolation cases and >=24 independent typed five-field differential cases, with measured per-job time limits. No stage-wide PASS before all gates; no main, merge or release.
