# SQL+தமிழ் — Slice21 PostgreSQL 17 Native acceptance

**Date:** 2026-11-04  
**PROJECT_ID:** `PC-BRANCH-SQL-TAMIL`  
**Branch:** `SQL+தமிழ்` (branch only; no main/merge/publish)  
**Exact tested source SHA:** `837ec975e81ff96889ade43762f314ba817f94ae`  
**GitHub Actions:** https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41871310680  
**CI:** completed/success, attempt 1, updated 2026-11-04T16:56:19Z. All 10 jobs completed/success; each decoded job log inspected.  
**HEAD before reporting:** the exact tested SHA, checked via the live `SQL+தமிழ்` GitHub branch API. The later report/contract-only commit does **not** establish a new production CI result.

## Acceptance gates

- PostgreSQL Native: **43/43** named assertions returned `ok=t`; `native_43_of_43=1`. Also exactly **50 independent Python-generated SQL golden fixture rows**, with named golden-domain/rank assertions.
- Python independent oracle: `slice21-oracle=PASS exhaustive-tuples=340 full-boundaries=5 fixtures=50`. This local algorithm self-test is distinct from PostgreSQL Native.
- Production-only isolation: **5/5** named assertions `ok=t`, `isolation_5_of_5=1`, without loading the normative test schema.
- Differential: **8/8** separate PostgreSQL jobs (`d2460a`, `d2460b`, `d252a`, `d252b`, `d492a`, `d492b`, `d5778a`, `d5778b`). Each `differential_1_of_1=1`, scalar `ok=t` and `actual={...} expected={...}` integer arrays exactly equal in its original log. Reference SQL loaded only in a separate differential test database.
- Total: **56/56 named PostgreSQL assertions** and 50 generated fixtures. PostgreSQL `17.11 (Debian 17.11-1.pgdg13+2)`; all 10 original `versions.txt` contain the identical exact tested Git SHA.
- Code and workflow source files of Slice21 were already independently read back (6/6 blob SHA) in the implementation checkpoint, and no production source is changed in this acceptance commit.

## Independent original ZIP integrity

All **10/10** original GitHub Actions ZIPs were downloaded (not regenerated). Independently recalculated SHA-256 over each ZIP and matched both GitHub artifact API `digest` and the corresponding `upload-artifact` job-log digest (10/10). All ZIP `testzip()` CRC checks passed (10/10).

| Suffix | Artifact ID | ZIP SHA-256 |
|---|---:|---|
| native | 13345160896 | `86257cf2373fcebe1b4d3cc1d796b9341c479e68cd0a86b731242a1ac73ca2e6` |
| isolation | 13344314206 | `1df315e308918ff5b6169edfe5843e8ee1118961f76354bbd973d4c8f388c251` |
| d2460a | 13344119847 | `1326cd19bf73b0da4626e1fa34beba73f8d20c1158bf00fd27212d7e726f57a5` |
| d2460b | 13343804325 | `8b70241b046a0399298718ad88b6461fcf0f25c9995663d5ac968f1cae4b0574` |
| d252a | 13344886809 | `7b01a7196eee1c08d1c26594dff8f5f9f541ae917bc7befb9b568d2f9092b2ca` |
| d252b | 13345405102 | `cea917b50037f694cd675c5fb52de175059d1742f5cbe9fe6135366be3778644` |
| d492a | 13345515067 | `84633eecffa344e3e1fde03882286774088b2e52669b0c7e9ef6f400df3e156a` |
| d492b | 13344533061 | `627b78d9cdb92ac33edceb26b1e9d2b23c11a73b05f1514cfa738e7090f0bc95` |
| d5778a | 13345510232 | `1fc4c86007e899032547aaa21ace2cfbf88eae78eaead1a44be2270f2d3143a8` |
| d5778b | 13344184045 | `aaff02ed4894bd3019501deb09f0bf8600a67319638c0c24fb293f844b26cacc` |

## Generated SQL file hashes (9/9)

Independently recalculated the SHA-256 of each SQL file **inside** the original ZIP and matched the bundled `*-sha256.txt` (9/9). All differential SQL files represent single named cases.

| Generated file | SHA-256 |
|---|---|
| goldens.sql | `44c7da0312c0c68b75760a8829ffb52c8060f14251df92a304e2746433a1b3d9` |
| d2460a | `ba1bbe8f035b2210b2b0e82e613afc33c376febd68102ae01a60891357d152cd` |
| d2460b | `b8c81474ff303c1966418ca695f87720e5c3fbd4ee2875f24d19760ea0abc176` |
| d252a | `5ba372ea486de62dfc4dbf7c7c39de3a52ed591b724d939d88fc40a37bd13fea` |
| d252b | `90f6ccddd477a75602f5365ca4ee79a1289d9f5de8fd2d1ed72bb94c8eab34ec` |
| d492a | `4895ed8bf5c7bc2f307994f98c90908a74776b8c90d542791d8cbc7185d9232b` |
| d492b | `899e137a6aff028ffb73d9501619baf62ee46829d8352b4676dd9569dce3341d` |
| d5778a | `fbb9b0db9fe995d0a40816f68944c3b5f164289e625588d6012f4a5950146478` |
| d5778b | `e1205a1cfced70a54cd4100315739c33b80a38201347cc27d61ca30b420fda2f` |

## Decision and boundary

**Slice21 ACCEPTED** against the already committed normative contract `artifacts/stage-02/SLICE_21_MONTH_LENGTHS_CONTRACT.md`. Only the production SHA above was tested; acceptance documentation does not imply CI for its new documentation commit. No duplicate workflow dispatch; no user Native execution; no main or merge.

**NEXT:** Stage 2 Slice22 `choose_month_weaving`, with an independent algorithmic contract in `artifacts/stage-02/SLICE_22_MONTH_WEAVING_CONTRACT.md`, before implementation or PostgreSQL acceptance. No Slice22 PASS is claimed.
