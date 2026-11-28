# QA31A — Natural-input differential successor frontier for 15 original source cells

**Submission status: GitHub Actions [40280436139](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40280436139) queued. No QA31A PASS claimed.**

## Isolated scope and frozen historical proof

Use the single production Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`, the accepted QA18 source-role SHA-256 `263a73a40afa17a8a9b1c831a01239be671d9ea0a9c331fd3f725f83cf1cfea7`, and the exact independently accepted QA30A report SHA-256 `7c3ba01dc00a4f67fc30cc52e594b1cd6a2adee597a21939dbe0176ac2be2d4e`. The original archive runs and their accepted exact HEADs are QA20 `39761821210`, QA24 `39841651046`, and QA26 `39945902093`.

QA31A is a **read-only rerun of the forensic audit**, not new Native execution, native source mutation, new test inputs or changed source. It must verify 136/136 genuine input-origin route receipts and all 4,513,423 signed physical STEP records, with exact per-case compressed Native SHA-256.

## New original-input differential question

For executed dynamic-control bytes (`x`, `j`, `k`, `#`, direction selectors and related control operations) outside stringmode, compare:

- **Same observed pre-instruction signature:** physical IP coordinate, pre-execution direction vector, and actually fetched runtime opcode.
- **Recorded actual successor outcome:** physical displacement, next direction vector and next stringmode.
- **Actual input-origin provenance:** original Native run, shard, input label, and adjacent signed STEP pair.

Track sites within Manhattan distance 9 of the 15 original source candidates, retaining the distinct successor outcomes and up to three witnessed inputs for each outcome. A location with no observed nearby control site must remain an explicitly empty observation, not a fabricated route. The 15 candidate coordinates themselves must remain unvisited by the originally accepted Native paths.

A location is marked **observationally differential** only when the same pre-signature is observed with distinct outgoing outcomes in different input-origin runs. The key includes the pre-direction specifically to avoid falsely attributing a different successor solely to a different direction before execution.

Even that differential finding is **not input causality**: the hidden stack, FungeSpace, scheduling or earlier machine state may differ. Nor does matching the current fetched opcode to an immutable static source byte prove that no prior `p` or other memory-write mechanism intervened. No candidate is certified reachable or dead.

## Required evidence and scope

The independent checker must reproduce exact QA20/24/26 program and step totals, retain the original QA30A SHA pin, and reject 60 modified original Native manifest headers plus 10 manipulated consecutive STEP pairs. **70 controls required.** Any RED is retained, not waived, and must be diagnosed before signing.

This is complementary to concurrent QA09C native-mutant calibration. Its files are isolated under `qa/stage1_qa31a_native_control_outcome_variation.py` and `.github/workflows/befunge-stage1-qa31a-native-outcome-variation.yml`; do not change or claim completion of QA09C.

## Governance

`CURRENT_STAGE=1`; `LAST_COMPLETED_STAGE=0`; `FULL_FUNCTIONAL_QA_PASS=NO`; `GEOMETRIC_SPAGHETTI_QA_PASS=NO`. Do not change `main`, canonical `Befunge+Кыргызча`, the signed production source, QA10–QA30 accepted historical artifacts, merge PR #17 or open Stage 2.

## QA30A top-four baseline comparison (not the QA31A result)

A separate read-only local comparison of the already SHA-pinned QA30A aggregate `7c3ba01dc00a4f67fc30cc52e594b1cd6a2adee597a21939dbe0176ac2be2d4e` regrouped its stored four nearest control edges per candidate by `(x,y, pre_dx, pre_dy, fetched_op)`, then compared recorded successor displacement, next vector and next stringmode. Among **48 saved nearest-edge records** for the 12 cells having near-control observations, **zero distinct successor-outcome pairs** under the same pre-signature were found. For the other 3 targets QA30A stored zero near-control edges. This is an independent cross-check of the earlier **capped/nearest** report, not full 136-trace coverage; it cannot establish absence of differential outcomes. QA31A must reexamine every genuine original physical Native control-edge record before any finite result is signed.
