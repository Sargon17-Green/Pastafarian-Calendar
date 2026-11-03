# SQL+தமிழ் — Stage 2 Slice 19: דו"ח קבלת PostgreSQL Native

תאריך: 2026-11-03. **הכרעה: Slice19 ACCEPTED בלבד; אין קבלה של Stage2 כולו ואין טענה לתאריך מלא.**

## זהות מקור והרצה
- Repository: `Sargon17-Green/Pastafarian-Calendar`; branch: `SQL+தமிழ்`.
- Source SHA (also HEAD immediately before this evidence commit): `e216dde0b80c0a85607af97413039ccf2316d811`.
- Workflow: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41618421392; ID `41618421392`, attempt 1, completed/success, created 2026-11-03T10:20:19Z, completed 2026-11-03T10:28:26Z.
- Jobs: **10/10 completed/success**, PostgreSQL **17.11** (Debian 17.11-1.pgdg13+2). Every archive's `versions.txt` independently confirmed the exact source SHA and PG version. No manually dispatched re-run.

## Executed acceptance assertions
- Native `sql/test/120_stage02_cutlet_names_native.sql`: **42/42** true named rows, `native_42_of_42=1`. Python independent fixture selftest output: 28 n/k pairs, **16,064** explicit permutations, **122** golden fixtures.
- Production isolation: **4/4**, `isolation_4_of_4=1`.
- Differential full-array against separate normative schema: **8/8** (`k6a,k6b,k7a,k7b,k12a,k12b,k17a,k17b`). Each `differential_1_of_1=1` and `actual={...} expected={...}` were read from original `differential.txt`, with exact array equality for all eight cases.
- Total: **42+4+8=54/54**. This does not imply universal correctness beyond the tested scope.

## Original action artifacts: independently recomputed hashes and CRC
Each of the **ten original ZIPs** was downloaded using GitHub's artifact endpoint. SHA-256 was computed directly over original archive bytes, matched to GitHub's `digest` and each job's upload log; ZIP CRC was verified using `ZipFile.testzip()`. The extracted text was read and assertion counts checked, not inferred solely from workflow configuration.

| Job | Artifact | ZIP bytes | SHA-256 | Assertions | CRC |
| --- | --- | ---: | --- | --- | --- |
| native | [13223025695](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41618421392/artifacts/13223025695) | 2152 | `c8f441b35a5b5e0c001fb37d5c463af9d8c749ad7d3cddeffb82774f70d3d5b4` | 42/42 | PASS |
| isolation | [13222850627](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41618421392/artifacts/13222850627) | 777 | `876a053064a8d1bc06951947d591e78c1517a36b9e644314f51ff0d2ed724606` | 4/4 | PASS |
| diff/k6a | [13222139146](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41618421392/artifacts/13222139146) | 1835 | `64793ed5047cfe1a991bd54dbaa3ed2201a7b213aba41228337a05e26678fe8d` | 1/1 | PASS |
| diff/k6b | [13223076578](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41618421392/artifacts/13223076578) | 1840 | `c84b0edd139548ac092010df88db1ed45f52153722494919fb81ab689111968c` | 1/1 | PASS |
| diff/k7a | [13222277747](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41618421392/artifacts/13222277747) | 1839 | `b3751a86147d99374e980a6aab74f75f2b2f5f6745a2f688b1df4a7a35590287` | 1/1 | PASS |
| diff/k7b | [13223081641](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41618421392/artifacts/13223081641) | 1847 | `cb6f2ba914fceeb9c02398812c62df7a34a749ef2426b11477e7c32a312bff1f` | 1/1 | PASS |
| diff/k12a | [13222128772](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41618421392/artifacts/13222128772) | 1858 | `77d286bb1a17f75a4427ee3df77b0e211012b7cbe40883870e188f82414682e2` | 1/1 | PASS |
| diff/k12b | [13222592024](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41618421392/artifacts/13222592024) | 1860 | `ba057b444efd69942aa03e8a39b943a576d43285259ba8ebe1c71a0ed375ae59` | 1/1 | PASS |
| diff/k17a | [13222552932](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41618421392/artifacts/13222552932) | 1866 | `e54430453b486d60fb20706b399754263090d1c4c0c7ea77e859c99b2ad74591` | 1/1 | PASS |
| diff/k17b | [13222906447](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41618421392/artifacts/13222906447) | 1867 | `729f936a4a32924b96f866fbe1df543c00f3401c0cf46e440f2e9f0862605f74` | 1/1 | PASS |

## Recomputed generated SQL SHA-256
- Golden fixture SQL `goldens.sql`: `79bba4de74a6388cfe99326fba3ab2a2f2c864694792a90da4685653a312aaec`, equal to `goldens-sha256.txt`; its selftest log reported `pairs=28 permutations=16064 goldens=122`.
- Differential `k6a`: `a47156e281a365848e2172cb95ccf514af6daf3ba6da4c610f4be48f46520e40` (actual `differential-case.sql`, matched corresponding `differential-case-sha256.txt`).
- Differential `k6b`: `7726abfdae2018ac08dca5d1261ee69585a1d471046061c7300f1945bae61010` (actual `differential-case.sql`, matched corresponding `differential-case-sha256.txt`).
- Differential `k7a`: `b5b24210c31ac1d0b6147a322fb6bb01811621e2676eb8e96029c4dd7acc6d13` (actual `differential-case.sql`, matched corresponding `differential-case-sha256.txt`).
- Differential `k7b`: `3b688119ee3e6892b49b0904d063839af83300d66e9419182266d7f15dd3b0a5` (actual `differential-case.sql`, matched corresponding `differential-case-sha256.txt`).
- Differential `k12a`: `1e88170cd550ff0722669fbfbcdf98c1b313aebc94f43e5f067c6160eac98da4` (actual `differential-case.sql`, matched corresponding `differential-case-sha256.txt`).
- Differential `k12b`: `704c84c340eb295b57c2e18927121abd2c082baf68098a58062a26c4c7fb0f93` (actual `differential-case.sql`, matched corresponding `differential-case-sha256.txt`).
- Differential `k17a`: `0dcbbe1596de3ac93cba3de75c70dec5016345e1f984b48f2aff67fce6c1f6be` (actual `differential-case.sql`, matched corresponding `differential-case-sha256.txt`).
- Differential `k17b`: `55d2f6604186557740a31556381bd1498658fb92fbd72d63c9a1ea9991eda6f1` (actual `differential-case.sql`, matched corresponding `differential-case-sha256.txt`).

## Scope and next step
The implementation matches the Slice19 contract `artifacts/stage-02/SLICE_19_CUTLET_NAMES_CONTRACT.md`: exact lexicographic selection of distinct IDs 1..17. Native, isolation, differential, artifact integrity and generated-SQL integrity all passed. **Slice19 ACCEPTED**, not Stage2/full calendar PASS. Next normative source function is `pastafari_sql_tamil_test.choose_month_count`; the independent Slice20 contract is kept next to this report. No `main` mutation, merge, publication or manual duplicate dispatch.
