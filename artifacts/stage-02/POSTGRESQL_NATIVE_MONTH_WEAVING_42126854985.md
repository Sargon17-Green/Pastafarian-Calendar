# SQL+தமிழ் — Stage 2 Slice22 PostgreSQL Native acceptance

**Date (inspection):** 2026-11-06. **Decision:** SLICE22 ACCEPTED, production and QA only; no merge to main or external publication.
**PROJECT_ID:** `PC-BRANCH-SQL-TAMIL`; **branch:** `SQL+தமிழ்`.
**Tested exact source SHA:** `91cb0e9ff837f8c823f7cdaa8a1992f09367f424`; source commit: https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/91cb0e9ff837f8c823f7cdaa8a1992f09367f424 .
**Completed source-locked run:** https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42126854985 .

## Acceptance gates — evidence actually inspected

- 10/10 original GitHub Actions jobs: `completed/success`, eight differential jobs a1,a2,b1,b2,c1,c2,d1,d2 plus `native` and `isolation`.
- Checkout of exact tested SHA and PostgreSQL **17.11** confirmed independently in **all ten original job logs** and all ten original `versions.txt` files.
- Python independent oracle self-test in original Native ZIP: 9 small vectors, 150 brute-force valid words, 660 valid prefixes, 150 rank roundtrips, 40 independently generated realistic goldens; includes boundary D=5778, k=47.
- Original Native `result.txt`: 40 full-array equality golden gates among **59 distinct named native gates**, **59/59** show `ok=t`, `slice22_native_all_green=1`, SQL `INSERT 0 40`, `COMMIT`.
- Original isolation `result.txt`: **8/8** independent live conditions all `ok=t`, `isolation_8_of_8=1`, `COMMIT`; no normative schema dependency in production-only test.
- Eight separate original differential `result.txt` files: for each case, `exact_array_match=t`, `length_ok=t`, `multiplicities=t`, `ordered_first_and_last=t`, `diff_<label>_exact_array=1`, `COMMIT`. These compare actual complete arrays to the separate normative SQL implementation.
- **10/10 original ZIP files** downloaded and locally SHA256 checked against GitHub artifact metadata **and independently against the digest recorded in each original upload-job log**; **10/10 ZIP CRC pass**; **9/9 applicable generated SQL/files recomputed SHA256 checks pass**; all 10 ZIPs carry the expected source SHA and PostgreSQL 17.11.
- Native job began 2026-11-05T23:12:08Z and had uploaded the evidence ZIP by 23:14:28Z: the entire Native gate including D=5778/k=47 completed within **140 seconds**, below the 15-minute job bound. This is a whole-job upper bound, *not* an isolated per-case performance measurement.
- GitHub branch comparison `91cb0e9...SQL+தமிழ்` yielded `identical` before this acceptance report was committed. No new Native rerun was triggered.

## Original artifact SHA256 ledger

Every entry below: SHA256 match with original downloaded ZIP, GitHub digest and the upload-job log; CRC and source-lock pass.

| Case | GitHub artifact ID | Original ZIP SHA256 |
| --- | ---: | --- |
| native | 13461489206 | `263a9b3edb093ee7a63a58e935424d4ff7ecd4027a2fddbf8a19f89735005f42` |
| isolation | 13460493782 | `d998469601dfae5336315fbcc3ecdb60309e1a2b854e1ea6fbfa5c691396ee3d` |
| a1 | 13460463449 | `d87dd2950ef6bda8073a8d65e50831a8f8124e4adae31dcbd652b4652c4491d8` |
| a2 | 13460578343 | `397f17711a84dd7c323c56b389aa416dc87633e59f3f3232bc08f1ba84279702` |
| b1 | 13461597528 | `5fc63a16903500d43b05223901f7dd342403818a7d24d15fa5e90a91040d7bb8` |
| b2 | 13460448080 | `590ed74ce1fb5476ea5c4badc9c410d6b0d4ac936843c1341bcdf9a7489e5add` |
| c1 | 13460739542 | `f80ff87c5dd29c45c9dc7ff170679448c11c569d3373d9b2accd142f5f380922` |
| c2 | 13461488452 | `800b943e06901672368cd1f1a4479bc60ed03655efc28bb1279469311f8bf93d` |
| d1 | 13460834076 | `28a9ad1ef3952169a29a14af4dc245c78a8c0d19fdcc8b6b6a6cc608cdb354c8` |
| d2 | 13461013472 | `37a7e8acac68d54d341714abd971b9a021cc968ed965af3668e0118c9145eeae` |

## Boundaries and follow-up

This is evidence for Slice22 only, on the **tested** SHA above, not a claim of testing the documentation-only acceptance commit. No production code has been altered as part of acceptance. Stage 2 is not yet complete: the next upstream normative function in `sql/test/10_normative_reference.sql` (blob `ce17bf6fd166451b6904411c5e29d1b26d92e278`) is `choose_month_names`, called after `choose_month_weaving` in `build_year_structure`. Prepare Slice23 contract and implement it independently on the same branch, then complete separate source-locked PostgreSQL Native/isolation/differential evidence.
