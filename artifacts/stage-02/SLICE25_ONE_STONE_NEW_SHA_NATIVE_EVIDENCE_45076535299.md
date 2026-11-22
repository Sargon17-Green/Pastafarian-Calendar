# SQL+தமிழ் — Slice25 one-stone candidate: exact-new-SHA PostgreSQL 17.12 evidence audit

PROJECT_ID: PC-BRANCH-SQL-TAMIL
Branch: SQL+தமிழ்
Tested commit: a3120f901eb7d9a65231fed00081ed3eee39786d
Previous parent: 1ae53bd1f70db68aa60cb0c9e3d5c270af8e3c84
Observed source tree before this evidence-only commit: 5fad7653a6a5eb2c0e80fbd6c558e63e93a31c45
Audit date: 2026-11-23
Scope: newly completed *existing* naturally triggered CI runs; no workflow dispatch, production changes, merge, main, release, or 56-job matrix.

## GitHub run/job exact-SHA cross-check
- Candidate run [45076535299](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45076535299), job `137374894718`: completed/success, attempt 1, event push, branch SQL+தமிழ், exact head SHA a3120f901eb7d9a65231fed00081ed3eee39786d; PostgreSQL 17.12. Run's original decoded job log and original artifact audited.
- Stage1 run [45076535266](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45076535266), job `137374894688`: completed/success, same SHA, PostgreSQL 17.12; original log and artifact audited.
- Canonical Names run [45076535329](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45076535329), job `137374894761`: completed/success, same SHA; original log audited, no artifact.
- Before this evidence commit, branch-head REST returned a3120f901eb7d9a65231fed00081ed3eee39786d; exact-SHA run metadata matched the branch.

## Original artifact ZIP verification, not just upload logs
1. Candidate artifact [14775915935](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45076535299/artifacts/14775915935), original 19,882 bytes, 11 ZIP entries. SHA-256 independently recomputed over actual downloaded ZIP bytes: `07304493a77c32c5efd1bf3d8bf72fdd87cbcad99074b29c3e2390363c13c746`. Equal to GitHub artifact digest and original upload-job log. Python zipfile.testzip() returned None: CRC all entries PASS.
2. Stage1 artifact [14774984431](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45076535266/artifacts/14774984431), original 1,389 bytes, 3 ZIP entries. Actual ZIP SHA-256: `9105f0fe3d02ee95cd3fb2f22c074c494d0c921d972ba77528d235e8004f8def`. Equal to GitHub artifact digest and upload-job log. ZIP CRC PASS.
3. Candidate archive `versions.txt`: `PROJECT_ID=PC-BRANCH-SQL-TAMIL`, `SHA=a3120f901eb7d9a65231fed00081ed3eee39786d`, `BRANCH=SQL+தமிழ்`, `postgres (PostgreSQL) 17.12`. `exits.txt`: `SOURCE_LOAD_EXIT=0`, `CANDIDATE_EXIT=0`, `ORACLE_EXIT=0`.
4. Candidate `hashes.txt` records `32cc8835f4fe9b8ac772c845c2cdd12c03b2c321d5c5cc41f06bca55be56c3ab` for `sql/test/175_stage25_one_stone_bowl_qa.sql` and `8dd3712ebe04adda4654692ac7052d7d0cf1a33a3acc7cd61981a37614217b40` for `candidate_oracle.sql`. The latter hash was independently recomputed from actual ZIP member bytes. Independent original generated SQL `independent_stone_bowl.sql` SHA-256 is `c0d5c0dce6746162e936c0928f190fd65d135f411ce25cfcf85b4d0cab243dad`; candidate SQL is exactly the 32-call source function-name substitution on the generated SQL, leaving independently generated expected values in place.
5. `oracle_summary.json` describes generator-stage `native_status=NOT_EXECUTED` (pre-execution metadata). **Do not use that static flag to contradict or replace the later native outcome**: original `oracle.log`, job log, `ORACLE_EXIT=0`, and job conclusion establish actual SQL execution and output.

## PostgreSQL 17.12 original observable results
- Early invalid 2D input regression: `SQL_TAMIL_TWO_DIMENSION_GUARD=PASS`, no PostgreSQL ERROR.
- 46 positions × four drop values × two six-element numeric arrays = **368/368** full-array candidate-versus-production comparisons PASS. This is a complete six-element numeric-array comparison, not a single scalar-field check.
- **12/12 invalid inputs** PASS, including two-dimensional and zero-lower-bound arrays.
- Independent Python integer recurrence and lexicographic-permutation vector generation, with generated SQL executed natively: **230/230 stone fields** and **32/32 bowl cases** PASS.
- Four alternating `EXPLAIN (ANALYZE, TIMING OFF)` blocks on 46 positions: production **3099.040 ms**, candidate **174.850 ms**, candidate **175.389 ms**, production **3110.729 ms**. These are localized measurements, not a guaranteed global speedup or an end-to-end Slice25 throughput gate.
- Stage1 independently recorded **52/52 ordinary**, **7/7 saved-sum**, **3/3 heavy-reference** tests; separate clean database **4/4 production isolation**. Artifact `reference.txt`, `isolation.txt`, `versions.txt` and job log inspected; PostgreSQL 17.12 same source SHA.
- Names canonical hash lock verified by completed/success job, no archive emitted.

## Decision / non-decisions
- Existing branch-only QA patch and focused 2-D guard: **source/code PASS** from prior exact commit plus this branch readback.
- **Focused candidate Native, 368 differential, 12 negatives, independent 230+32, Stage1 and Names: PASS at exact SHA**, with original ZIP SHA+CRC 2/2; focused one-stone verification gate **ACCEPTED**.
- The historically timed-out `prev_3_prev_middle` sauce→bowl-round path and Slice25's broader calendar-date/cutlet gates were *not* rerun or demonstrated by this targeted one-stone test. **Full Slice25: NOT ACCEPTED**. No complete-stage, release, or production optimization approval may be inferred.
- No local-user OS run needed for this exact gate; no new Pending_User_Execution package. No cleanup of unrelated pending files.

## NEXT — authorized narrowly scoped work
1. Develop a bounded, deterministic QA-only diagnosis for the remaining `prev_3_prev_middle` sauce→bowl-round timeout, explicitly separating source/fixture, candidate behavior, gate selection, and elapsed-time accounting. Use existing already-completed evidence; avoid replaying the old failed case unchanged.
2. Define the next measurable contract: inputs = the existing locked Slice25 `prev_3_prev_middle` fixture plus an independent oracle; outputs = exact source SHA, function-phase timings, full comparison fields and exit codes; fail on mismatch, missing markers, SQL errors, or timeout; preserve original zipped logs with byte-level SHA/CRC. Do not assert PASS while queued/in_progress.
3. Any new source change only within branch SQL+தமிழ் and only under fresh expected-HEAD check. No full 56-job matrix, main/merge/release or policy change.
