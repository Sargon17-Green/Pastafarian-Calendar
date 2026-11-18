# SQL+தமிழ் Stage2 — Slice24 PostgreSQL 17 Native acceptance
**Project:** PC-BRANCH-SQL-TAMIL  
**Acceptance date:** 2026-11-18  
**Branch:** `SQL+தமிழ்` only. **Source SHA tested:** `4c71d677eb382eea55eeae2d3ac8da99760d2bd5`.  
**Run:** https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44364076198 (natural push, attempt 1, completed/success, source SHA and branch match).  
**Decision: Slice24 ACCEPTED** against the stated Slice24 contract. This decision does not imply Stage2 or entire branch completion.

## Evidence obtained from completed original jobs
- GitHub Actions run metadata: exact event=push, branch=SQL+தமிழ், head_sha=4c71d677eb382eea55eeae2d3ac8da99760d2bd5; 16/16 completed/success matrix jobs. Current branch HEAD at evaluation was the same SHA.
- Read all **16 original job logs**. Each checked out the exact Git SHA; PostgreSQL **17.12**; no error in the test or artifact step. Upload step logged SHA-256 for its ZIP.
- **Native:** 8 distinct real bounded year/day fixtures (anchor, boundary_open, boundary_close, next_1, next_2, next_3, prev_2, prev_3). Each full `results.txt` has **29/29 named `label|t`** and `slice24_native_all_green=1`: **232/232 named Native assertions** across eight isolated jobs. Includes per-job production-only isolation, giving at least 8 isolation checks in fresh `postgres:17` containers.
- Every Native ZIP contains a complete `SLICE24_RECORD_JSON` for its case, where `actual==expected` by parsed JSON deep equality, including complete integer arrays. The standalone Python verifier produced `slice24_actual_full_record=<case> 1/1 PASS` and `slice24_independent_python_structural=<case> 1/1 PASS` for all 8 cases (8 actual-record and 8 independent-structure gates).
- **Differential:** 8 corresponding PostgreSQL jobs; each `results.txt` contains **9/9 named `label|t`**, `slice24_diff_all_green=1`, including per-field comparisons of the eight fields and a ninth full-record `IS NOT DISTINCT FROM` equality: **72/72 differential assertions**.
- **Original artifacts:** downloaded all 16 original ZIP archives. Local SHA-256 of every downloaded ZIP equals **both** GitHub artifact metadata digest and its original job upload log digest, **16/16**. ZIP CRC / testzip: **16/16** clean. All archives report same source manifest; exact `Git SHA` is present in all 16; all generated `test.sql` files recomputed against their included `generated-sha256.txt`, **16/16**.
- Production code untouched by this acceptance report. No manual re-dispatch, no main/merge/publication.

## Locked source manifest (identical in all 16 original archives)
```text
8965f397860d1cc2a8f6442915e76e1e3ee70d5ff21e51c7368a36e3bf953018  sql/26_stage02_year_structure.sql
9db4ab8c87393f2a2b052398b0be7f828c8c6c8c6ea01744eefbedc5e3797f2d  sql/test/142_stage02_year_structure_cases.sql
186ce99d6a78f58ac9677b6b36df923039863fa46dde6fccf1649319b04faef6  sql/test/143_stage02_year_structure_native.sql
6e1f1b5d98aa3211ada0b8e9e6d407c2c741ef8d7bd0bc10033c32cdf2d1f108  sql/test/144_stage02_year_structure_differential.sql
f515133f540fcbaaecc0a2bb635611dda7e78c15b94d77b9f2183df87739519f  sql/test/145_stage02_year_structure_oracle.py
6d0dcc7a5ee6e696461fc2623736c702419591bed9c7e6c21ced21ade6d75220  sql/test/10_normative_reference.sql
```

## Original ZIP archive inventory
| Lane | Case | Original GitHub artifact | ZIP SHA-256 (GitHub metadata = upload log = downloaded bytes) |
|---|---|---|---|
| differential | next_1 | [14458580115](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44364076198/artifacts/14458580115) | `24b796a8c2fa321382d66732f378ef68d5fb231f926059ee45e1d8c4935c628f` |
| differential | boundary_open | [14458070485](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44364076198/artifacts/14458070485) | `9b38fe40b9b1d0108152d714e147f65fb28d65f391937ad2f19672cd80769a10` |
| native | boundary_open | [14457400808](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44364076198/artifacts/14457400808) | `edc193e3602d04de4b21fd1ad64ecba6174a34e082326149dae86ca1201bc6e9` |
| native | anchor | [14457395605](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44364076198/artifacts/14457395605) | `45edc795bb15a16769bb41cee8b2dbc4d18dc2884df3a7c1c75c42936407e6ca` |
| native | boundary_close | [14457360781](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44364076198/artifacts/14457360781) | `357ba1bd2d8f3cf7d539b23d95741eca07235d5d9c037f000239b957098aed1b` |
| native | next_2 | [14457022206](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44364076198/artifacts/14457022206) | `352d3e7861452c982d7c04c187e0367a7cc0505993d440f880b918e3e285f829` |
| differential | prev_3 | [14456976164](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44364076198/artifacts/14456976164) | `89a353161666245f9e63745e73ac76d1f4570443792e19633e47c680e3c4dcf2` |
| differential | boundary_close | [14456559949](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44364076198/artifacts/14456559949) | `721953382fc9b3a507a66088e1a8056337499ef15da7b8ea421d1d226764b1e2` |
| differential | anchor | [14456379511](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44364076198/artifacts/14456379511) | `6906853c3d6329523ddd802153875559702f38e4d12739a8742dab8b0cd9f224` |
| differential | next_2 | [14456279125](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44364076198/artifacts/14456279125) | `ea39ccd4557e8f2942482fe5630295170cfd34c2cb21364f6d792885bc22f30b` |
| native | next_1 | [14456054802](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44364076198/artifacts/14456054802) | `7920d6d748c39447f7614d47298ebb1372ad9760a2e54365e2d6d6917af22aac` |
| differential | next_3 | [14456014560](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44364076198/artifacts/14456014560) | `d1857aa22ee86732fb0c9b098d97d6122c38f5cd1643c8f8ba34aed5d8515d45` |
| native | prev_2 | [14455909867](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44364076198/artifacts/14455909867) | `3ea0cfbdabe6705b267d36b3b1b4631d40a184b3d4232bdd53e7cc80b1ce9c46` |
| native | next_3 | [14455739114](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44364076198/artifacts/14455739114) | `e48dbd3184ad9bf876ce2e4a5a0c7d9c4da5b3ebd9b0ee72a6ce15f3c806b72d` |
| native | prev_3 | [14455664500](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44364076198/artifacts/14455664500) | `e42bb1751004635fb7b3a3e3b923450343c19c19ae4203b8c79d62f0524a8b57` |
| differential | prev_2 | [14454964652](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44364076198/artifacts/14454964652) | `2e863b0403f3486c962f941ebf2a8ca0fbac03bb435762f5791dd63b7f6c5052` |

## Boundary of claim and next
The preceding 16/16 results settle **Slice24**, not next-step `calendar_date`. Run 44364076124 is a **separate Stage1 workflow**; it is not evidence for Slice24. Next: engineering contract `SLICE_25_CALENDAR_DATE_CONTRACT.md`, followed by targeted feasibility, independent ordinal/name oracle, branch-only production and PG17 CI. Source-locked completion must use new SHA and completed logs before Slice25 acceptance.
