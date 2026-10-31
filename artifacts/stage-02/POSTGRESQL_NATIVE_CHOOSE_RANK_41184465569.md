# SQL+தமிழ் Stage 2 Slice 10 — PostgreSQL Native choose-rank evidence

## Provenance
- Branch: `SQL+தமிழ்`.
- Source/workflow commit: [`7746a3e086bd71e23fd9ea117b2960a37f145998`](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/7746a3e086bd71e23fd9ea117b2960a37f145998); branch HEAD matched before this evidence commit.
- [GitHub Actions run 41184465569](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41184465569): `completed/success`, attempt 1, workflow `SQL Tamil Stage 2 Slice 10 Choose Rank Native`.
- Job `choose-rank-slice10` ID `124488415311`: `completed/success`.
- Runtime from extracted `versions.txt`: PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2), Git SHA exactly `7746a3e086bd71e23fd9ea117b2960a37f145998`.
- [Artifact 13036451250](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41184465569/artifacts/13036451250) (`sql-tamil-slice10-choose-rank`): downloaded 1,161-byte ZIP, opened and verified exactly four files: `native.txt`, `isolation.txt`, `differential.txt`, `versions.txt`.
- Downloaded ZIP SHA-256: `cec47516cbd6b9db910fc583b304afa749c05712d560ec5606a5965e4b324ea4`, exactly equal to both GitHub artifact digest and workflow upload log.

## Native gates verified from ZIP
| Gate | Assertions observed | Final SQL assertion |
| --- | ---: | --- |
| Native choose-rank | 100/100 | `native_100_of_100 = 1` |
| Production-only isolation | 4/4 | `isolation_4_of_4 = 1` |
| Differential in isolated normative-reference database | 62/62 | `differential_62_of_62 = 1` |
| **Total** | **166/166** | All three passed |

The differential log recorded `INSERT 0 56` and `INSERT 0 6`, then `differential_assertions = 62`. The production-only run checked absence of the reference schema, three SQL immutable choose-rank functions, and absence of reference-schema calls. The separate differential database loaded the reference only after the isolated production checks.

## Scope and limitations
This is **Slice 10 Native + isolation + differential PASS**, not proof of the full Stage 2, the complete calendar, or `calendar_date_spaghetti`. The independent JS BigInt-generated 44 golden output vectors were recorded during source implementation; those are not re-counted as PostgreSQL tests.

Source is commit `7746a3e086bd71e23fd9ea117b2960a37f145998`. No merge to `main`.

## NEXT
Implement the next bounded independent production slice in the Stage 2 normative sequence (year-gate/year selection), with a measurable SQL-only contract and isolated Native/differential checks; verify on a new exact source SHA, and preserve run artifacts before accepting that next slice. Do not rerun unchanged Slice 9 or Slice 10 PASS.
