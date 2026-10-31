# SQL+தமிழ் — Stage 2 Slice 14: PostgreSQL Native evidence

- Workflow run: [41238928425](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41238928425)
- Workflow: `.github/workflows/sql-tamil-stage02-year5000-native.yml`
- Branch: `SQL+தமிழ்`
- Exact source SHA tested: `9826aa2913c06dd35c222db63398efbc4989fe37`
- PostgreSQL: `17.11 (Debian 17.11-1.pgdg13+2)`
- Run conclusion: `completed / success`
- Jobs: 6/6 completed / success.
- Scope: Slice14 bounded year-5000 gate-window selection only. This is not a Stage2-wide or full-calendar PASS.

## Assertion results

| Job | Assertions | Result |
|---|---:|---|
| year5000-native | 23 | 23/23 |
| production-only isolation | 4 | 4/4 |
| differential: lower-window-edge | 5 | 5/5 |
| differential: one-day-before | 5 | 5/5 |
| differential: foundation | 5 | 5/5 |
| differential: one-day-after | 5 | 5/5 |
| differential: upper-window-edge | 5 | 5/5 |
| **Total** | **52** | **52/52** |

Native log records `INSERT 0 23`, `native_23_of_23 = 1`, and `isolation_4_of_4 = 1`. Each isolated differential job records `INSERT 0 5` and `differential_5_of_5 = 1`; all psql commands used `ON_ERROR_STOP=1`.

The five generated differential SQL files each contain exactly one selector for their intended case label. The SHA-256 recorded inside each artifact matches the downloaded SQL file bytes.

## Independently downloaded artifact verification

All six ZIP archives were downloaded from GitHub, passed ZIP integrity testing, and had their SHA-256 recomputed locally. Every computed digest matches the GitHub artifact digest.

| Artifact | Artifact ID | ZIP bytes | SHA-256 |
|---|---:|---:|---|
| Native + isolation | 13057702316 | 742 | `6e7ec82b302df648f8ea953b2d2a6eda7f8605961bcfff6089adcd36a1db60c1` |
| Differential: one-day-before | 13057081590 | 1,630 | `8b4c432aaa734e0205d1f46f8470364deda007ce01ff905704610a34294807be` |
| Differential: one-day-after | 13057063000 | 1,630 | `3ee44fb92fdfb820344c283a83da9890c10aef04a389aff302748380b5bb17f7` |
| Differential: upper-window-edge | 13056873475 | 1,626 | `80c06332309bb18c20d0840e2144b29ff0a50a6441cb85951e5ad11438b86293` |
| Differential: lower-window-edge | 13056779544 | 1,625 | `2e815ab12b1e11fd4641cb4141a9421e4fedaef52d1a7a9f95bb85bfaced6378` |
| Differential: foundation | 13056554553 | 1,629 | `e26b5fb614b1b20495ad49e50151a30817796c43ab9902e594194ecc59eb0251` |

Artifact URLs:
- [Native + isolation](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41238928425/artifacts/13057702316)
- [One day before](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41238928425/artifacts/13057081590)
- [One day after](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41238928425/artifacts/13057063000)
- [Upper window edge](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41238928425/artifacts/13056873475)
- [Lower window edge](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41238928425/artifacts/13056779544)
- [Foundation](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41238928425/artifacts/13056554553)

## Conclusion and next contract

Slice14 is accepted on the exact source SHA above. The production SQL and normative oracle were not changed by the workflow repair. The workflow-only correction is in commit `9826aa2913c06dd35c222db63398efbc4989fe37`.

Next: implement Stage2 Slice15 according to [SLICE_15_ADJACENT_YEAR_NAVIGATION_CONTRACT.md](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/9826aa2913c06dd35c222db63398efbc4989fe37/artifacts/stage-02/SLICE_15_ADJACENT_YEAR_NAVIGATION_CONTRACT.md): production `next_year` and `previous_year`, bounded one-sided 5,778-day recursive walks, exact five-field `year_rec`, malformed-input rejection, PostgreSQL Native, production-only isolation, and independent Differential tests. Slice16 target-year traversal remains out of scope until its finite budget and out-of-range behavior are specified.
