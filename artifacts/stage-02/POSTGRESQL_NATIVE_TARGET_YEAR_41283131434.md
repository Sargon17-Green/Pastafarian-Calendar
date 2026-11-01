# SQL+தமிழ் — Slice 16 PostgreSQL 17.11 acceptance evidence

- Project: `PC-BRANCH-SQL-TAMIL`; branch `SQL+தமிழ்`.
- Exact accepted source commit: `d6c0c3e05d371c5d04a8ef300149da8bf06fc07d`.
- GitHub Actions run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41283131434
- Seven jobs each `completed/success`; seven source-stamped artifacts on same SHA. No rerun.
- PostgreSQL: `17.11 (Debian 17.11-1.pgdg13+2)` as recorded in every artifact.
- Acceptance scope is **Slice 16 bounded target-year traversal**, not all Stage 2, all dates, calendar output, merge or publication.

## Runtime acceptance from full job logs and extracted ZIP contents

| Job | Job ID | Observed result | Artifact ID | Independently SHA256-verified ZIP |
|---|---:|---|---:|---|
| target-year-native | 124778945874 | `INSERT 0 18`, 18/18 rows `ok=t`, `native_18_of_18=1` | 13075362468 | `c29f3dca00a57126ca3fb7dadbe136fd15b1249df6c2dabbfa6badae31913f1f` |
| production-isolation | 124778946109 | 4/4, `isolation_4_of_4=1` | 13074314014 | `c49e7cfb028aec23c4993851c769a900d26ef52aefa9e73e5a6f24de3c970df0` |
| differential: cross-zero | 124778945985 | 1/1, actual=expected in all five year fields | 13075660142 | `19a7a3ba1061e40d6363911721cbbfdaf1fff7d3cd808f4c2b8cc8999d5c83d5` |
| differential: previous-year | 124778945993 | 1/1, five fields identical | 13074379965 | `b21d23ed8daee8997ba0b5b0bff57ffe1c6ac2b19ad274fca21a61eff0bbaed3` |
| differential: next-year | 124778946023 | 1/1, five fields identical | 13075346143 | `76c4ee5a37a780f2c36a8499c4cab58ad9afb285b66b24d2904eae7e676c7738` |
| differential: boundary | 124778946055 | 1/1, five fields identical | 13075011691 | `0cb39d86b4dd1361378780db069e4fe9446cd514899b674b90044e7580dd52cc` |
| differential: same-year | 124778946071 | 1/1, five fields identical | 13075090462 | `2dd27e8fc8ceedbd291fbb89d7f0df8e79824362f2592b4695aceec9563b11e4` |

**Total bounded acceptance assertions:** 18 Native + 4 isolation + 5 differential = **27/27**. These are test assertions/groups; each differential comparison checks the five fields separately. Neither ZIP count nor workflow step count is conflated with test count.

Independent archive verification: downloaded all seven artifacts; computed SHA-256 over original ZIP bytes and matched GitHub artifact digest and corresponding job upload log, 7/7. Ran `ZipFile.testzip()`: CRC pass 7/7. Verified all seven embedded version files stamp the exact source SHA. For five generated per-case differential SQL files, computed SHA-256 against embedded `case_sha256.txt`: 5/5. No PostgreSQL execution occurred on the local machine; execution evidence is the hosted GitHub Actions runtime.

## Source identity and algorithm boundaries

Read back four source files from the accepted commit: `sql/18_stage02_target_year_navigation.sql`, `sql/test/112_stage02_target_year_native.sql`, `sql/test/113_stage02_target_year_differential.sql`, and `.github/workflows/sql-tamil-stage02-target-year-native.yml`. All four blobs were returned from commit `d6c0c3e`. The run artifact metadata states branch `SQL+தமிழ்` and exact head SHA.

The function is explicitly limited to integer NUMERIC inputs with day-distance at most 60,000 inclusive. Outside the supported domain, or for fractional inputs or NULL inputs, it returns SQL NULL. The accepted traversal does not prove unrestricted target-year navigation or the five-component final calendar.

## Result

**Slice 16 ACCEPTED** on exact SHA `d6c0c3e05d371c5d04a8ef300149da8bf06fc07d`. Slice 15's earlier PASS was not repeated. Proceed to a separately contracted Stage 2 successor, with new source SHA and fresh runtime evidence. Do not merge `main` or publish.
