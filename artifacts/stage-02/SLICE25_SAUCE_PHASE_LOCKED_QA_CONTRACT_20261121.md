# PC-BRANCH-SQL-TAMIL / Slice25: source-locked sauce phase instrumentation

Date: 2026-11-21. Authorized branch: SQL+தமிழ். Parent at preparation:
86c2c3c9a80e19afc85a8738b2852fc9d2742d22.

## Original failure / proof boundary

Tested exact source dca2b8e5594c2c80e24d68604d79bf45f140a00a,
run 44910633756, PG 17.12:
* Job 136865491966: anchor_cutlet_boundary completed/success, five locked
  field notices and green marker; original ZIP 14709851794.
* Job 136865492170: prev_3_prev_middle completed/failure with 12-minute
  statement_timeout, no five-field green. Stack: save_value -> stone_state /
  stone_value -> bowl_round -> sauce -> build_year_structure, before
  choose_cutlet_partition. Original ZIP 14710610663, SHA256
  5b972d19d81e14b6e885a0d43d4647159b78ac693780bd7ad100939efac26873.
* Stage1 44910633604 and Names Lock 44910633708 completed/success on that
  tested source. Existing original ZIP SHA256/CRC audit is recorded in
  SLICE25_GUARD_PG17_OUTCOME_AND_SAUCE_PHASE_CONTRACT_44910633756.md.
* Neither the guard pilot nor full Slice25 is accepted.

## New distinct QA code, not a production repair

Script: sql/test/169_stage25_sauce_phase_profile.py.
Workflow: .github/workflows/sql-tamil-stage02-slice25-sauce-phase-profile.yml.

The script explicitly locks Git blobs (not just filenames):

| Source | Exact blob |
|---|---|
| sql/08_stage02_bowl_round.sql | 68a7d99c7cddd1a5b47ef4ef9dc189ab08c53da6 |
| sql/10_stage02_sauce.sql | c5c6be7c02c255382ae7c317bfbf17138a12788c |
| sql/18_stage02_target_year_navigation.sql | c204a314972b22a4a38f06a02c2fe1bd5bde7acf |
| sql/26_stage02_year_structure.sql | faac634a06aee59354de207eb088e4e9996034fa |
| sql/27_stage02_calendar_date.sql | 748d4bc1f7754f003c29a42a1756f26e08c1669b |
| independent locked field generator 164 | 89e28c013e635446c4bf7db2fafe82e095e10f9d |
| independent 29-case / 8-year corpus 151 | 21f38cd280498070b08b6c3074780f1742c36957 |

No production file is edited. The generated SQL declares QA aliases only
(qa_phase_* and qa_trace_*), never CREATE TYPE and never CREATE OR REPLACE
of the existing production calendar_date, sauce, or bowl_round functions.
Original production functions remain available in the same isolated DB.

Trace contract: timestamped entry/exit notices for find_target_year, sauce,
each called bowl_round (1..46), each post-stir round (1..12), order, stone
value, and save_value. A missing EXIT after ENTER is not success. SQL planner
evaluation of subordinate calls may vary; timestamps are observations, not
a proof of dependency ordering, source equivalence, or production speed.
The instrumentation intentionally has substantial overhead.

## Bounded run and independent acceptance barrier

Exactly one previously failed source-locked input:
calculation_day=-15055671, target_day=-15072356,
case prev_3_prev_middle; expected five fields:
4996 / வெண்கலம் / 302 / தவளை / 50.
Do not generate another corpus from the production implementation.

CI loads the original 00..27 scripts in an offline PostgreSQL 17 container,
then QA aliases and a test from the unchanged independent corpus. A query
has SET statement_timeout='12min'. Every job retains versions, project,
branch, SHA, all source hashes, generated SQL hashes, phase notices, errors,
and last reached phase in an artifact even on failure; GitHub job logs carry
the exit code. Exact original failed artifact ID/hash are retained in versions.

A QA phase finish requires five distinct named field notices and green.
Only *after* that new evidence does the same CI job attempt the original
unmodified calendar_date for the same input with the same independent
five-field oracle and its own 12-minute SQL statement timeout. A production
equivalence marker is emitted only if both sets of five fields pass. This
conditional additional comparison is a new-data-dependent experiment,
not a blind re-dispatch. It does not run if the profiled case fails or times out.

## Gate classification

Code proposed for QA branch commit; static source-lock and syntax preflight
are **not** a PostgreSQL execution. Automatic workflow result and source
equivalence are undecided until exact-SHA completed job/log/artifact review.
Full Slice25 remains NOT ACCEPTED; no guard/DP promotion, no full-matrix
re-dispatch, no merge/main/release. If the probe fails before SQL begins,
repair the specific generator/compilation issue using new logs; do not
mislabel it as the original sauce timeout.

NEXT: inspect the natural workflow run on exact new HEAD. Verify job status,
PostgreSQL version, source/checksum manifests, phase entry/exit and source
equivalence if reached, then original artifact digest/CRC. If timeout occurs,
identify last emitted nested phase; keep D=פתוחה/G=READY while the next
authorized targeted diagnosis exists.
