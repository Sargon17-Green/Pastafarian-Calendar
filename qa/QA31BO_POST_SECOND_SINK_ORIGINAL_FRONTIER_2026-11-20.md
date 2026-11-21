# QA31BO — finite signed post-second-sink memory-dependency frontier

**PROJECT_ID:** `PC-BRANCH-BEFUNGE98-KYRGYZ`  
**Branch:** `qa-befunge98-stage1-order-isolation-20261008`  
**Verified base HEAD:** `2851a8ed4729f107de3a30d93e16ab05a422edef`  
**Date:** 2026-11-20  
**Classification:** Finite local source-only QA accepted. **Stage1 OPEN**. No new CI or Native, no main/merge/Stage2.

## Pinned inputs

QA31AI ZIP SHA256 `9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49`; embedded QA31AH/Y ZIPs checked by exact SHA and CRC. Eight QA31V signed-shard CRCs and **200/200 HALT original receipts, 3,628,390 physical STEPs** checked against per-trace SHA and original source blob `560d6aa5807a7f766213a33835cce85eab0fa40c`.

QA31BN ZIP SHA256 `6aaaa08c0edc66f529936d173a2894a7ed9123c523f5b47987498af4fa84ff79`; CRC, 12 manifest files and summary values independently checked. The 410 single-g (-1) and 36 changed boundary predictions are **counterfactual numerical predictions**, not Native measurements.

## Result: finite original-route negative

- 135 original signed traces selected; 446 changed predictions examined: **294** changed original first-sink value at FungeSpace `(103,1715)`, **152** changed second-sink value at `(107,1716)`. Exactly one sink changed per prediction.
- Two independent downstream address scanners (forward live-memory / reverse read-and-overwrite index) agree: **446/446 FINITE_NEGATIVE** after second sink; 0 subsequent `g` reads or instruction fetches of a changed sink cell, 0 unsupported suffix operations.
- Each original suffix is **170 STEPs** long, containing one signed `g` at FungeSpace `(19,1696)`, one signed `p`, and a terminal `@`. The 75,820 suffix inspections double-count the same original STEPs across distinct counterfactual predictions.
- **24/24 genuine no-op** checks, **12/12 hostile derived-record rejections**, **12/12 synthetic read-injections detected** (one per distinct original case). Synthetic injections are NOT signed Native evidence.
- Altered sink cells may remain different at HALT. This result proves neither identical final memory nor counterfactual execution paths. Any changed branch, memory ownership, indirect read or instruction fetch in an actual modified run remains **UNKNOWN**. Global source ownership, full functional and geometric Stage1 gates remain open.

## Permanent reproducibility

Self-contained **QA code, report, machine JSONL, checks and SHA256 manifest** saved in Library:
`/Befunge_QA_Artifacts/QA31BO_BEFUNGE98_KYRGYZ_POST_SECOND_SINK_20261120.zip`.
SHA256 `b95e2c8f9ca4d4c0dc9f2d31fcdf0690e1fad246cfd731ed905e5488638697de`. 9 ZIP members (8 with explicit manifest hashes); CRC and all member SHA digests checked. Original 46 MB signed archive is not duplicated or replaced.

Reproduce with standard Python 3.11+:
`python qa31bo_post_second_sink.py --ai <original-QA31AI.zip> --bn <original-QA31BN.zip> --out <new-empty-directory>`.

**NEXT — QA31BP (QA-only):** cross-index the original downstream `g(19,1696)` last physical writer and its subsequent original stack/output lineage across the pinned 135 cases; separately test whether any pre-first-sink source value can reach that output in the *original* signed route. Independent oracle, original trace SHA checks, >=12 no-op and >=12 hostile controls; modified routes are UNKNOWN, not Native causality. No Stage2, main or merge.
