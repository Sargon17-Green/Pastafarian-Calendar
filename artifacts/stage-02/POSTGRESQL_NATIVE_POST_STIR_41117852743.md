# PostgreSQL Native evidence — SQL+தமிழ் Stage 2 Slice 7 (post_stir_round)

## Scope and provenance
- Branch: `SQL+தமிழ்`; code/workflow SHA: `3245ab144331d2dd5ab4ae1d38ac261b3241525f`.
- GitHub Actions: [run 41117852743](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41117852743); event `push`; status `completed`; conclusion `success`.
- Job: `post-stir-slice7`, ID `124276623509`; conclusion `success`.
- Runtime from `versions.txt`: PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2).
- Artifact: [13006159519](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41117852743/artifacts/13006159519); name `sql-tamil-slice7-post-stir`; 4 files.
- ZIP SHA-256 independently computed after download: `9c8dd41fe5308fec4df52885a8055a037acce95f99da50cbab7fefe68da3b3b0`, matching GitHub metadata and job log.

## Observed Native results
Results extracted independently from the downloaded ZIP files `native.txt`, `isolation.txt`, and `differential.txt`, not inferred from queued status or workflow declarations:

| Gate | Count in log | Assertion check |
| --- | ---: | ---: |
| Native fixtures / edge cases | 62 | `native_62_of_62 = 1` |
| Production isolation | 4 | `isolation_4_of_4 = 1` |
| Differential vs normative reference | 306 | `differential_306_of_306 = 1` |
| Total | **372 / 372 PASS** | All three successful |

- The differential ran in a separately created `sql_tamil_stir_differential` database.
- Native fixture table includes 36 fixed golden values, 12 bounds, 11 invalid input cases, and 3 production metadata checks.
- Differential set includes 288 single-round checks and 18 twelve-round chain comparisons.
- Production `post_stir_round` is SQL IMMUTABLE and does not reference the test schema, per source inspection and metadata gate.
- Source code blob: `sql/09_stage02_post_stir_round.sql` = `2f2f2e19e8851b3130f3c3d5edafd5dfbc6923f9`.
- Native tests blob: `sql/test/94_stage02_post_stir_native.sql` = `c1c2fba7f80974c2e947c7d2d85a6fdc682d0030`.
- Differential tests blob: `sql/test/95_stage02_post_stir_differential.sql` = `a937d4b40a946cd18eaf1f1e1004121c7cdaca15`.
- Workflow blob: `.github/workflows/sql-tamil-stage02-post-stir-native.yml` = `9fdfd95dc86b076abee818105b6c72c97b66853b`.

## Acceptance boundaries
**Slice 7 Native PASS is confirmed** on the code SHA above. This is **not** a claim that Stage 2, the full Pastafarian calendar, or any later segment is complete; no merge to `main` was made. The report is an evidence commit only and changes no SQL, fixtures, or workflow.

## Next
Review the verified Stage 2 integration contract and identify the next authorized functional slice or end-to-end gate. Verify the actual production composition (not only reference/test functions) before declaring a complete-date or Stage 2 PASS. Do not rerun successful Slice 7 checks on the same code SHA without new cause.
