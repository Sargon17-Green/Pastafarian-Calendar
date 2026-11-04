# SQL+தமிழ் — Slice20 PostgreSQL 17 Native acceptance

**Date:** 2026-11-04  
**PROJECT_ID:** `PC-BRANCH-SQL-TAMIL`  
**Branch:** `SQL+தமிழ்` (no main/merge)  
**Exact tested source SHA:** `9a65e3ef86f174bb68389420334c6c93858a3fad`  
**GitHub Actions run:** https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41714259445  
**Run status:** `completed/success`, attempt 1, last updated 2026-11-03T20:46:07Z.  
**Branch HEAD before writing this report:** exact tested source SHA. Subsequent report/contract-only commit is not a new production validation run.

## Acceptance

Original 10/10 completed/success job records and decoded job logs independently inspected. Native test output: 36 named assertions, all `t`; `native_36_of_36 = 1`. Native also ran 50 independent Python-generated goldens, with `golden-enumeration-50 = t`. Python oracle self-test reports 5,527 bounded day-length cases and 50 fixtures. Production-only isolation: 4 assertions all `t`, `isolation_4_of_4 = 1`. Differential: 8/8 independent PostgreSQL comparison jobs, each `differential_1_of_1 = 1` and `actual = expected` against reference SQL in a separate database. Total **48/48 named PostgreSQL gates** plus **50 golden fixtures**, all PASS.

**PostgreSQL:** `17.11 (Debian 17.11-1.pgdg13+2)`, confirmed independently from `versions.txt` in all ten original ZIPs; each version file contains the exact tested Git SHA. No local/native run is being claimed in addition to CI. No duplicate workflow dispatch.

## Original ZIP artifact integrity

Downloaded all ten unmodified original artifact ZIPs via GitHub Actions. For each, independently recomputed SHA-256 over the ZIP bytes and matched (1) GitHub's artifact `digest` and (2) the uploaded-artifact SHA-256 recorded in the corresponding job log. Verified ZIP CRC using `ZipFile.testzip()`; all ten PASS. Values below are ZIP SHA-256 (not extracted-file hashes).

| Artifact suffix | GitHub artifact ID | SHA-256 |
|---|---:|---|
| native | 13269382312 | `c7b989bc0d59e940511a25ae0b2a0f2d0a1a19b8121d2536c954147c75f0d00d` |
| isolation | 13269106451 | `786f54bc7846d087b7ae75e29e7f714bcf7535ee1f26a540d2d55d20715dff82` |
| diff-d252a | 13270216768 | `204e08986ccc35afb27e6e8227bb16dd6dc5364ee85b1e1a743b49f5c48519d1` |
| diff-d252b | 13268678821 | `c7e2336f425b693468ff0ca7fd6be746f479132c4313f7acd95b8f93ca3b7844` |
| diff-d492a | 13269182196 | `8a33caaae3f1933bc95f6759b4e9d507641015291ec3f270235547e9bb823a8c` |
| diff-d492b | 13269012942 | `0dc889a19424e01ec193914e1ae0b30ddafcc8114a9d6de7b93fa51696cfec38` |
| diff-d2460a | 13268309434 | `f1413c97773ab76fb408c3817ea97b7e6fe4a4060cf8f006f9c510765f570442` |
| diff-d2460b | 13269512183 | `85fe05bd2f31d1e4cb5ea2cd35f3fc56c51eed325a8574570331454ea07e0416` |
| diff-d5778a | 13268713305 | `386deab5e545c7dd78f54306ffc76cfddd4757f99e7865b21e2d22de5d9e1728` |
| diff-d5778b | 13269401946 | `39a3bba12cd507800a89d1054324e8dce37368abb197ad0137012f74fb61be0d` |

## Generated SQL integrity (9/9)

Recomputed SHA-256 on each SQL file *inside* the corresponding ZIP, compared to its accompanying `*-sha256.txt`. All nine passed:

| File | SHA-256 |
|---|---|
| `goldens.sql` (50 inserts) | `e8a446c82c443e9968a2844521660f7959b4cd191a88803132c06a44d7de46e0` |
| differential `d252a` | `7ae79b180d5b2ef864690525023d870d81b43d5645503b9f565f5b5d86517a99` |
| differential `d252b` | `2b9487512d5b9abf1aa9c78b0339c6a926f6fc8e5d8f159ad205e6e8fdde2802` |
| differential `d492a` | `3968f7452ed717f213756a2c0c4d4fb6cb2ef4f53b107fa1d3b1738bb4eb2733` |
| differential `d492b` | `32f856c4c1b6e6488ba06288e3320926a78a7705d4e2e2f6b183ed0773b507af` |
| differential `d2460a` | `c19ea4b297b8ab4e9634c1a63f922d77b43362dc01c2dae199ec3a14a743b0da` |
| differential `d2460b` | `ccbd96fe49bba56f9b5988d7bffa825f988c3003a62d8e379a9494ca19b8f41d` |
| differential `d5778a` | `9b5baa1402ebcf3975a5ca71d4e615a43b1907d431b4ea998255eda3e4795e15` |
| differential `d5778b` | `dad0066d99b7e558d78eb866404a46a3087238260f7a4eb787f6c3d7986c6a9b` |

Differential scalar detail from each original `differential.txt`: `d252a:23=23`, `d252b:8=8`, `d492a:22=22`, `d492b:4=4`, `d2460a:22=22`, `d2460b:28=28`, `d5778a:47=47`, `d5778b:47=47`.

## Decision

**Slice20 ACCEPTED** under the normative contract at `artifacts/stage-02/SLICE_20_MONTH_COUNT_CONTRACT.md`; no production-source modifications made by this evidence-only acceptance. NEXT: Slice21 `choose_month_lengths` contract and implementation, separately gated by PostgreSQL Native, isolation, differential and artifact integrity. No main merge, external publish, or new test PASS claimed for Slice21.
