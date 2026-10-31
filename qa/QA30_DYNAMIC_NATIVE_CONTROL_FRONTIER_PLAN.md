# QA30 — Observed dynamic control-flow and memory-access frontier (Stage 1 only)

**Status at submission:** QA30A GitHub Actions run [40125781530](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40125781530) was queued. No QA30 CI PASS is claimed yet.

## Frozen native evidence and provenance

- Production two-dimensional source is the same signed Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`. Do not change it.
- QA18 original 21 source candidates: original roles file SHA-256 `263a73a40afa17a8a9b1c831a01239be671d9ea0a9c331fd3f725f83cf1cfea7`.
- Original QA20/QA24/QA26 physical STEP archives: runs `39761821210` (48 programs, 1,939,997 steps), `39841651046` (24, 776,706), and `39945902093` (64, 1,796,720).
- In total **136 original Native input-origin programs, 4,513,423 STEP records**. Original QA27 independently accepted the full 136 route archive and the 15 still-unobserved source-cell frontiers.
- QA29 showed finite live blank-corridor evidence at original ticks 9485/9630. This does not establish all-input memory ownership.

## QA30A — what the submitted CI measures

`qa/stage1_qa30a_native_control_frontier.py` reads all 12 historical original shard archives (no new program execution), pins the 2D source and QA18 roles, verifies every original individual compressed trace SHA-256, every original Native STEP number and every original input/output receipt, and reconstructs **actual adjacent physical STEP pairs** for executed runtime control bytes.

It records fetched `x`, `j`, `k`, `#`, directional branches, quote/string-mode and vector controls (where observed), and separately the `g`/`p` runtime memory-access opcodes. Every record distinguishes:
- pre-instruction IP position and delta;
- fetched runtime opcode and stringmode;
- next observed IP position and delta;
- actual displacement versus naïve addition of the pre-instruction delta;
- whether the vector or the physical row changed.

For each of 15 unresolved original source cells, the auditor retains up to four of the nearest **actual control-step successors** within L1=9. A candidate with no nearby observed control is recorded **as zero observations**, not forced to have a fabricated witness.

There are 60 modified original-manifest negative controls (five per shard) and 10 altered actual STEP edge controls. **All 70 must be rejected** before a QA30A acceptance claim. On CI RED, preserve the original failure and repair only the exact cause, without lowering acceptance thresholds.

## Essential inference boundaries

An observed `x` branch may be input-dependent; the recorded successor is merely one particular successful input/state. A previous `p` might have changed an opcode; matching a static source byte is not ownership proof. A `g` may read arbitrary dynamic space. A `k` repeats an instruction in a manner requiring actual interpreter semantics and cannot safely be inferred from a two-row nominal STEP model. Stringmode and `#` affect control flow, but the trace may not by itself attribute the internal interpreter mechanism. Never infer universal reachability or dead code from this bounded corpus.

QA30A is a **read-only observational map**. The next gate (QA30B) should select a finite, explicit set of promising candidate entry edges for *new actual input-origin Native causal/semantic experiments*, with origin-state provenance and independent controls; it may not force target IP coordinates or alter the signed source. If a semantic mechanism cannot be decided, mark it unresolved rather than claim PASS.

## Governance

Stage 1 remains open: `CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`, `FULL_FUNCTIONAL_QA_PASS=NO`, `GEOMETRIC_SPAGHETTI_QA_PASS=NO`. No edits to `main`, canonical `Befunge+Кыргызча`, production source, historical QA10–QA29 artifacts, or PR #17; no Stage 2.
