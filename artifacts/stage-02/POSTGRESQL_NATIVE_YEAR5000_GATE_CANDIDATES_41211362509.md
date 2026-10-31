# SQL+தமிழ் — Stage 2 Slice 13: year-5000 gate candidates

- **PROJECT_ID:** `PC-BRANCH-SQL-TAMIL`
- **Branch:** `SQL+தமிழ்`
- **Production SQL:** `sql/15_stage02_year5000_gate_candidates.sql`
- **Native tests:** `sql/test/106_stage02_year5000_gate_candidates_native.sql`
- **Independent differential tests:** `sql/test/107_stage02_year5000_gate_candidates_differential.sql`
- **Source SHA tested:** `95ade2e3cf48bda4026de5148d0d8dc699ad9c31`
- **Workflow:** `.github/workflows/sql-tamil-stage02-year5000-candidates-native.yml`
- **Run:** https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41211362509
- **Job:** `124566872403` (`year5000-candidates-slice13`), completed/success.
- **Runtime:** PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2), isolated Docker PostgreSQL instance on GitHub Actions.

## Verified assertions

| Gate | Captured evidence | Result |
| --- | --- | ---: |
| Native candidate ordering | `INSERT 0 35`, `native_assertions = 35`, `native_35_of_35 = 1` | 35/35 PASS |
| Production-only isolation | `SELECT 4`, `isolation_4_of_4 = 1`; reference schema absent, two production SQL IMMUTABLE functions, synthetic candidate call | 4/4 PASS |
| Independent differential | `INSERT 0 14`, `differential_assertions = 14`, `differential_14_of_14 = 1` | 14/14 PASS |
| **Total** | Completed job and inspected PostgreSQL logs | **53/53 PASS** |

Native tests cover two independently enumerated candidate sets (2 and 6 expected pairs), rank ordering and translation, pick-by-rank, open-exclusive/close-inclusive day boundaries, invalid day/index/gate/rank inputs, malformed gate arrays, and production-function metadata. The differential file compares the fixed numeric expected pairs from a separately enumerated nested-loop oracle; it does not use the production function to generate expected values.

## Diagnosed failure and minimal correction

- Initial run 41203500280 on source SHA `58d649d10b9de393506618808a100d013e5d11a5` completed/failure at the final Native count guard.
- Its artifact showed PostgreSQL inserted 35 Native assertions and reported `native_assertions = 35`, then the guard raised `ERROR: division by zero`.
- Root cause: the workflow's final guard incorrectly required `count(*)=26`, despite the test file defining 35 assertions and the guard alias already being `native_35_of_35`. The assertions themselves had passed; the count literal was stale.
- Corrected only that workflow literal from 26 to 35 in commit `95ade2e3cf48bda4026de5148d0d8dc699ad9c31`. No production SQL or test oracle was changed.
- The corrected run completed all three gates successfully on that exact commit SHA.

## Artifact integrity

- **Artifact ID:** `13046730269`
- **Artifact URL:** https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41211362509/artifacts/13046730269
- **ZIP size:** 1,099 bytes; four entries inspected: `native.txt`, `isolation.txt`, `differential.txt`, `versions.txt`.
- **Independent ZIP SHA-256:** `c8202d4a717cba1a2e6b25a83b14aeb663770ae16df9624f48a7b89d7e9a9c40`, computed from the downloaded ZIP and matching GitHub's artifact metadata and upload log exactly.
- `versions.txt` records PostgreSQL 17.11 and exact source SHA `95ade2e3cf48bda4026de5148d0d8dc699ad9c31`.

## Scope and next engineering unit

This evidence accepts **Slice 13 only**. It does not establish Stage 2 completion, the full calendar calculation, or any main-branch merge. No user-native execution was required.

Next: integrate the year-5000 candidate enumeration over the complete bounded candidate window `[-5778,+5778]` and derive the candidate rank from the existing sauce/answer-stream path. Specify and test a bounded independent oracle, window-edge behavior, rank uniqueness/order, and exact five-component output preservation. Keep production SQL free of the reference schema and avoid copying another branch's implementation. Stage 2 remains open.
