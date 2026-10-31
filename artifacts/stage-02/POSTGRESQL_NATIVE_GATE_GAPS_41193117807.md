# SQL+தமிழ் — Stage 2 Slice 11, gate gaps: PostgreSQL Native evidence

- **PROJECT_ID:** `PC-BRANCH-SQL-TAMIL`
- **Branch:** `SQL+தமிழ்`
- **Production/CI source SHA:** `9ee775d8a1487efb83a7cb383f872de3e99c913d`
- **Workflow:** `.github/workflows/sql-tamil-stage02-gate-gaps-native.yml`
- **Run:** https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41193117807
- **Job:** `124513783895` (`gate-gaps-slice11`)
- **Run state:** `completed`, **conclusion:** `success` (2026-10-31)
- **Native runtime:** PostgreSQL 17.11, isolated Docker container, GitHub Actions Ubuntu runner.

## Verified assertions

| Gate | Evidence from captured logs | Result |
| --- | --- | --- |
| Native | 24 offset properties + 5 invalid inputs + 3 metadata checks; `native_assertions = 32`, `native_32_of_32 = 1` | 32/32 PASS |
| Production isolation | `SELECT 4`; `isolation_4_of_4 = 1` | 4/4 PASS |
| Differential | 6 offset vectors × 2 signs; `differential_assertions = 12`, `differential_12_of_12 = 1` | 12/12 PASS |
| **Total** | Logs and completed job | **48/48 PASS** |

## Artifact integrity

- **Artifact ID:** `13040185816`
- **Artifact URL:** https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41193117807/artifacts/13040185816
- **ZIP SHA-256:** `0ac198a5a266bf7ce53af1f06451c3590e225e18b329223437adde4871f1704a`
- SHA-256 computed independently from downloaded ZIP; identical to GitHub Actions upload log and artifact metadata digest.
- Archive size: 1,157 bytes. Four entries inspected: `native.txt`, `isolation.txt`, `differential.txt`, `versions.txt`.
- `versions.txt` declares the exact source SHA and PostgreSQL version.

## Preceding failure and patch

- Run 41187309384 on parent SHA `9287f9b061b363fb7f4e2676fa0a647ae2d57b4a` failed because CI queries referred to tables `stage02_choose_rank_native` and `stage02_choose_rank_differential`, but the Slice 11 tests created `stage02_gate_gaps_native` and `stage02_gate_gaps_differential`.
- Patch `9ee775d8a1487efb83a7cb383f872de3e99c913d` changed **only** the two CI table references. It did not change production SQL or test vectors.
- Fixed workflow's completed run and 48/48 log evidence are the acceptance basis, **not** the earlier failure.

## Scope limits and NEXT

This proves Slice 11's configured Native, isolation and differential gates only. **Stage 2 overall and `calendar_date_spaghetti` are not accepted.** No main/merge/publishing action has occurred.

Next engineering unit: Stage 2 gate-day/index selector. Ground its specification in existing signed gate-gap and reference semantics, define an independent bounded oracle, test boundary/negative offsets, and keep production independent of `pastafari_sql_tamil_test`. Do not claim Native PASS before a completed matching-SHA run and logs.
