# QA29 — Source-plane versus live-memory control semantics around the original 15 candidates

**Stage 1 remains open.** QA29 is divided into two independent finite gates and must not be signed in full until both original GitHub CI receipts and artifacts have been checked.

## Frozen original Native evidence
- Immutable source Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`.
- Accepted QA28 original 15 real predecessor/anchor/successor triples from run `39985923985`; raw JSON SHA-256 `c5a5beaab308df31222652484e5fb18af554bf75e7b492225b107197fb29aa6e`.
- Prior QA20 original source-run shard 0 manifest SHA-256 `782fb868a11a105550ef5af6f8f7cd39e4ba9de77d9565f7549e310549b0073a`, historical run `39761821210`.
- No original QA10–QA28 trace, production byte, `main`, canonical `Befunge+Кыргызча`, or PR #17 is changed.

## QA29A — signed static source-plane interpretation

Original historical QA28 observations partition into:
- **2 witnessed vector resets**: an original `x` preceded the nearest witness; the original `>` executed on `(10,29)` or `(10,38)` with nonunit incoming delta and the real successor moved right by exactly one.
- **2 witnessed 8-cell exits**: original `-` executed on `(112,29)` or `(198,38)` with pre-delta `(1,0)`, followed by `(120,29)` or `(206,38)`. In the immutable *static source*, the seven intervening original characters `x=113..119,y=29` or `x=199..205,y=38` are exactly ASCII 32 spaces, and the destination has original digit `0`.
- **11 unit horizontal exits**: the observed real Native successor is exactly `(x+1,y)` with pre-delta `(1,0)`.

`qa/stage1_qa29a_original_source_plane_control_audit.py` independently pins QA28 JSON and the original Git blob, checks 15 original targets and each transition, verifies both seven-cell static source corridors, and rejects 120 adversarially modified source records. Its CI run is `39999165959` (pending independent acceptance at creation).

This is a valid finite *static source-plane and recorded-STEP* explanation, but it is **not yet proof of the runtime skipped bytes or the internal PyFunge skip algorithm**.

## QA29B — real original PyFunge runtime FungeSpace at both skips

`qa/stage1_qa29b_native_live_blank_corridors.py` replays exactly the original `valid00` input and complete signed QA20 original STEP file, on unmodified production code and actual PyFunge 0.5-rc2. This one original input-driven program contains both nearest witnesses. When the two original `-` instructions are executed, it measures the **seven actual FungeSpace cells before and after** the actual Native instruction, preserving `FungeSpace.put` calls to either original source corridor. It must see seven ASCII 32 bytes at both points in both snapshots, no writes to those cells during the two specific `-` steps, full original STEP parity and exact native seven-field final output. There is no forced IP location, source mutation, or hand-constructed interpreter execution.

`qa/stage1_qa29b_independent_runtime_blank_audit.py` checks the resulting evidence against original QA20 and QA28 hashes, the immutable source, chronological corridor write events and **12 adversarial receipt controls**. Its workflow run is `39999789882` (pending independent acceptance at creation).

A future QA29B PASS would show that the fourteen probed runtime cells were actually blank **at these two witnessed execution instants** under the observed PyFunge memory interface. It would not prove no alternative mutation API, all-input static-byte ownership, what an unsampled instruction could do, global unreachability, code deadness or all Stage 1 spaghetti requirements.

## Gate to follow

QA30 should investigate the actual PyFunge `x`, `j`, `k`, trampoline `#`, vector and stringmode semantics with source-relative state ownership, especially whether input-dependent transitions into any of the original 15 target coordinates are feasible. Do not substitute a large random input corpus or intervention that artificially places the instruction pointer at a desired target.

**Status:** `CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`, `FULL_FUNCTIONAL_QA_PASS=NO`, `GEOMETRIC_SPAGHETTI_QA_PASS=NO`. No Stage 2.
