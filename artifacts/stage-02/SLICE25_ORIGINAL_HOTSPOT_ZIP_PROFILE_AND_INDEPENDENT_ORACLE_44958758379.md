# SQL+தமிழ் — one-sauce hotspot verified ZIP; independent oracle gate

Project: PC-BRANCH-SQL-TAMIL. Branch: SQL+தமிழ். No production edits.
Analyzed existing run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44958758379 (attempt 1, exact SHA 52b86a1387192c3552e6947b017e9494f7abebed, completed/success).
Job: 137012636739, PostgreSQL 17.12. Original GitHub artifact: 14730021560, 9,955 bytes. SHA-256 of original downloaded ZIP = 515b84b563aeb633e3391a377fcce1b46a5a0f033b00b22dfbe77d40ce7ac218 (identical to GitHub metadata and upload log). CRC 11/11.
All four exit codes are zero: SOURCE_LOAD_EXIT, SCHEMA_CHECK_EXIT, QA_ALIAS_LOAD_EXIT and PROBE_EXIT. Two logged equivalences PASS 1/1 for stone and sauce; bowl_round ENTER 46, EXIT 46. Source locks/reversible QA clones 3/3. This is a one-case *same-implementation clone equivalence*, not an independent mathematical oracle for sauce and not Slice25 acceptance.
The earlier run 44954222980 completed/failure before native probe because production SQL 00–27 had not been loaded. Fixed in 0ddc7c5 and 52b86a1; no identical run was dispatched.

## Original ZIP trace, non-overlapping nesting
Trace: signed_negative_offset_1, calculation_day -15055671, target_day -15055672. Unit: milliseconds.
- sauce: 1 call, 6432.946 ms.
- bowl_round: 46 calls, sum 2263.586 ms (nested within sauce).
- stone_value: 415 calls, sum 1977.599 ms, including one independent 46/1 probe before sauce; 414 stone calls inside bowl_round, 9 per round.
- stone_state: 415 calls, sum 1956.305 ms (nested in stone_value).
- post_stir_chain: 1 call, 312.526 ms (nested within sauce).
- sauce remainder after excluding bowl_round and post_stir_chain: 3856.834 ms; this includes upstream count/drop computation and other overhead; NOT measured as a single function.
- Approximate stone_value portion within bowl rounds: 1966.532/2263.586 = 86.87% (subtracting one 11.067 ms standalone call). This is a profiling observation, not a projected speedup or proof of exclusive timing.
Timing markers are PostgreSQL NOTICE durations; add only sibling calls, never nested parent and child times. Measurements are one warm/cold-mixed case, not a benchmark distribution.

## QA-only independent mathematical oracle
New file sql/test/174_stage25_stone_independent_oracle.py, generated SQL never copied from other branches.
- Exact modular arithmetic M=170141183460469231731687303715884105727 with mapping 1 + ((x-1) mod M).
- Separate Python iterative integer recurrence evaluates all 46 five-field stone states: 230 exact comparisons to PostgreSQL production.
- Independent six-item lexicographic permutation enumeration (not SQL factoradic decoder) plus Python integer bowl mixing: 4 indexes (1,2,23,46) × 4 drops (-1,1,720,721) × 2 bowl vectors (small and high-range) = 32 additional full-array comparisons.
- Source Git blob locks for 03,04,07,08; mutate a locked source -> stop before PostgreSQL. Output SQL SHA-256, source blob manifest, exact branch/commit/version, exit codes, raw logs and ZIP. PG17.12 must execute 262 comparisons with zero exits and explicit 230/230+32/32 markers. Each comparison uses IS DISTINCT FROM.
- Local pure Python self-test completed successfully: 46 states, first/second fixed sentinels, permutation endpoints, exact modulo boundaries, 32 reference bowls, deterministic generated SQL. This is static MODEL PASS only; the 262 PostgreSQL tests require a completed exact-SHA run.
- Workflow is scoped to two QA-only paths and does not trigger the 56-job matrix. It must not be conflated with full Slice25, production optimization or differential acceptance.

## NEXT and production gate
After independent PostgreSQL oracle and original ZIP/CRC verification, build a *QA-only* candidate computing stone_state(p_i) once per bowl round and reusing its five fields instead of nine independent stone_value calls. Compare candidate against the independently generated 32 bowls, all 46 index positions, invalid inputs, and original production results. Count calls and measure several controlled repetitions; forbid global caches, floats, semantics changes. Only consider a production change after independent correctness, differential/year regression and bounded performance evidence. Do not merge/main/release. D=פתוחה, G=READY.
