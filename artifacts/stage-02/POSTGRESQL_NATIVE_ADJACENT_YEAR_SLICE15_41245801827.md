# SQL+தமிழ் — Stage 2 Slice 15: PostgreSQL Native evidence

- Workflow run: [41245801827](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41245801827)
- Workflow run status: `completed / success` (2026-10-31T22:24:39Z; attempt 1).
- Branch: `SQL+தமிழ்`
- Exact tested HEAD: `be0cf1983e8dd4037ba3d35a8e20fc1030ef3722`
- PostgreSQL: 17.11 (Debian 17.11-1.pgdg13+2).
- Scope: Slice15 `next_year` and `previous_year` adjacent-year navigation. Not a Stage2-wide/full-calendar PASS.

## Results from six completed jobs

| Job | GitHub job ID | Verified assertion result |
|---|---:|---|
| year-navigation-native | 124668849942 | 36/36 |
| production-isolation | 124668849940 | 4/4 |
| differential foundation-next | 124668849730 | 1/1, five `year_rec` fields |
| differential foundation-previous | 124668849951 | 1/1, five `year_rec` fields |
| differential cross-zero-next | 124668849968 | 1/1, five `year_rec` fields |
| differential cross-zero-previous | 124668849988 | 1/1, five `year_rec` fields |
| **Total** | **6/6 completed/success** | **44/44 grouped assertions** |

The native artifact contains `INSERT 0 36`, `native_assertions = 36`, and `native_36_of_36 = 1`. Isolation contains `isolation_4_of_4 = 1`. Every differential case contains `differential_1_of_1 = 1`, `actual = expected` for all five year-record fields, and the `cross_zero=true` diagnostic. The oracle is the separate test schema; production-only isolation was executed in a distinct database.

## Artifact integrity verified independently

Each ZIP below was downloaded, SHA-256 recomputed locally, ZIP CRC verified, and file contents examined. All recomputed SHA-256 digests agree with GitHub's artifact metadata and the upload step log. The four embedded generated-case SQL files were independently SHA-256 checked against their respective `case_sha256.txt` records.

| Artifact | ID | ZIP bytes | SHA-256 |
|---|---:|---:|---|
| Native | 13060350612 | 590 | `73e3c4f240cf32af375b028cd524e30318b60fa000dd48c5ad463e4ff745c9a3` |
| Isolation | 13059318176 | 545 | `2857fb9d2ac08b27d8abbd2a5a5ea431454b0777376ef89c25a24812902e6a47` |
| Foundation-next | 13059009925 | 2099 | `0be9f30167e9fde920be4b2d090bfb61c723322547c14be66a8d169dbafebc49` |
| Foundation-previous | 13058748796 | 2106 | `a7cb322d448717d2052c3fe3f375f1f812bb5f30fbb1ca33194ab60e20b98e87` |
| Cross-zero-next | 13058504720 | 2103 | `4205ef4baa834d1ab6cede530287d6e8355da79b601ceab9ff896523ee705526` |
| Cross-zero-previous | 13059665636 | 2103 | `6d969dedef8734600e14225a6bb67a5b78c18a169d518b3243e7d7a21ac81d30` |

All six artifacts are retained at the workflow run's [Artifacts section](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41245801827).

## Acceptance and next contract

**Slice15 accepted (44/44 assertion groups, six independent jobs, six valid ZIPs).** Existing Slice14 acceptance remains intact. Do not rerun prior PASS at the same source SHA.

Next: create and ratify an explicit finite-cost target-year traversal contract for Slice16, including out-of-range and invalid-input behavior, then implement `find_target_year` with independent differential oracle. This report is evidence only; there was no production modification or main merge.
