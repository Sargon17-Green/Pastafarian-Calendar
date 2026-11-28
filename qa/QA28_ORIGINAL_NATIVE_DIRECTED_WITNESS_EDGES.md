# QA28 — Directed Native predecessor/successor triads at the 15 missing source cells

**Discovery scope.** The original-evidence CI run [39985923985](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39985923985) was queued when submitted. **No QA28 CI PASS or overall Stage 1 acceptance is claimed at submission.**

## Why QA28 is distinct from QA27
QA27 reconstructed 136 input-origin actual Native paths (4,513,423 STEP records) and found a minimum Manhattan/L1 distance of 3–9 from the 15 original source cells that still lack observed execution. A distance on a 2D source plane does **not** imply a legally traversable control edge. Original Befunge-98 vectors can be non-unit, and an instruction can change the outgoing direction or the IP's next coordinate.

QA28 deliberately does **not** add random test inputs. It extracts the signed **previous STEP → nearest STEP → next STEP** actual directed transition for each of QA27's 15 globally closest input-origin witnesses. All witnesses happen to be anchored in the accepted QA20 corpus: 13 target witnesses use `valid00` from original shard 0, and 2 use `invalid18` from original shard 1. Each original trace's full monotonic step sequence, gzip SHA-256, original QA20 manifest and QA27 closest-distance receipt must match, independently of the original GitHub CI status.

Original provenance:
- Production Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`.
- QA18 original 21 cells SHA-256 `263a73a40afa17a8a9b1c831a01239be671d9ea0a9c331fd3f725f83cf1cfea7`.
- QA27 original 136-run aggregate raw JSON SHA-256 `20caa24769f882e38c69eb8bb9a31567fdbd7bb52f3f885b95436c1ece2798f3`.
- QA20 original shard-0 manifest SHA-256 `782fb868a11a105550ef5af6f8f7cd39e4ba9de77d9565f7549e310549b0073a`, and original shard-1 manifest SHA-256 `9c5af6212cfd7c1ab58e9603f385767e64b10799c90be416a86c4f09d613bfdd`.

## New physical-edge distinctions to check

The original raw traces show the following specific patterns at the 15 accepted closest witnesses:

- **Two entries via an immediately preceding executed `x`:** `(73,6) → (10,29)` for target `(10,32)`; `(150,29) → (10,38)` for target `(10,35)`. The reached anchor has a non-unit pre-execution delta, but the `>` opcode at that anchor subsequently directs the actual next STEP horizontally.
- **Two exits that differ from adding the anchor's pre-execution delta:** `(112,29) → (120,29)` for target `(113,32)`, and `(198,38) → (206,38)` for target `(199,35)`. The fetched opcode at both anchor coordinates is `-`. The raw STEP pair alone does **not** prove what internal mechanism produced the eight-cell transfer. No hypothetical intermediate instruction executions may be fabricated.
- All 15 nearest-witness successors remain in the same horizontal row as their anchor. The targets themselves remain unvisited in the original 136 Native cases.

Each QA28 signed record retains actual previous, anchor and next tick; coordinates; both deltas; fetched opcodes; stringmode; observed transitions; original target byte; closest L1 distance; and original input label. The auditor must reject **120 adversarially altered triads** (8 controls per original target). The derived report must explicitly flag that extrapolating a *pre-instruction* vector is not the same as observing the successor coordinate.

## Boundaries of any eventual PASS

A successful QA28 receipt establishes exact historical **finite directed transition witnesses for 15 nearest approaches**, not all possible predecessors/successors of these source cells. It cannot prove the absence of reachable but unsampled routes, full static-byte ownership, deterministic global control flow, source deadness, numeric necessity, or Stage 1 completion.

The correct next workstream following finite QA28 confirmation is a bounded analysis of actual `x`, `j`, `k`, trampoline, quote/stringmode and dynamic-write control sites that select entry to or avoidance of the 15 original source cells. Any intervention requires its own admissible Native counterfactual and independent evidence; do not shortcut by forcing IP locations.

Governance: `CURRENT_STAGE=1`; `LAST_COMPLETED_STAGE=0`; `FULL_FUNCTIONAL_QA_PASS=NO`; `GEOMETRIC_SPAGHETTI_QA_PASS=NO`. No edits to original production, `main`, canonical `Befunge+Кыргызча`, historic QA10–QA27 evidence, PR #17 or Stage 2.
