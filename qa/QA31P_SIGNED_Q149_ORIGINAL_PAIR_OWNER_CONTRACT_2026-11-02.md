# QA31P — signed original valid-pair counter ownership at the row38 gate (2026-11-02)

PROJECT_ID: `PC-BRANCH-BEFUNGE98-KYRGYZ`; existing QA branch `qa-befunge98-stage1-order-isolation-20261008`. Stage1 remains OPEN.

## Inputs and identity
- Immutable production source `src/interleaved_work_counts.b98`, exact Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`.
- Existing original QA31D Native run 40709128569, artifact 12825616476, ZIP SHA256 `b8df61e31a3f28bfcc21bbccb4d2ee26b5ccfeca534969e87d95a211fbb40eeb`, CRC PASS, *not rerun*.
- Natural valid stdin cases `b'0 0 0 0\n'` and `b'0 0 0 1\n'`; 17,387 and 19,713 total original STEP records; read only the initial 9,607 physical STEPs per case through `j(114,38)`.

## Method and measured oracle
The new `qa/stage1_qa31p_original_counter_owner.py` replays the minimal Befunge-98 operand stack and FungeSpace writes/reads independently from original signed TSV opcode/IP sequences, while checking each visited opcode against the exact pinned source. On natural input, consume each delivered byte with `~`; at documented EOF tick 9340 perform reflection without pushing. Capture **all `p` writes** to `(1,49)`, not only expected source sites. Require in each original case the five complete owner events `(tick, x, y, value)`: `(146,106,2,0)`, `(2408,248,26,1)`, `(4670,248,26,2)`, `(6932,248,26,3)`, `(9194,248,26,4)`. Require final `g(57,38)` at tick 9557 to read 4 from owner tick 9194, then `j(114,38)` at tick 9607 to consume operand 61 with no residual stack; verify the pair has identical IP/direction prefix up to that gate. Independently check existing QA31D ZIP receipt and hashes; never assume the committed code has a passing CI result merely because the local reconstructed-source test worked.

Run 10 targeted hostile trace mutations; each must fail the validator. The bounded oracle consumes exactly 19,214 signed STEP rows in two cases. CI must execute this exact script against the original source and existing ZIP, verify counters/markers, save output JSON and audit log, and avoid any Native execution.

## Local versus CI evidence
Local fixture built only from opcode-position pairs in the original signed Native STEP records (not the full source) passed replay of 2×9,607 STEPs and 10/10 negative tests. It was independently checked that original QA31D ZIP SHA256 and CRC agree. **This local fixture is not an original-source verification.** CI is required for that claim.

## Scope / NEXT
The witness is finite: two valid inputs converge on `q=4` and jump operand 61, so row41's conditional source route is consistent with these traces, but this new audit does not revisit the later row41 path or show that all valid inputs reach it. This is neither new Native, nor an all-input source ownership proof, nor `FULL_FUNCTIONAL_QA_PASS`, `GEOMETRIC_SPAGHETTI_QA_PASS`, or Stage1 PASS. Next inspect completed exact-SHA QA31P log/artifact and its original-source readback; then use the now-grounded per-value `p` chain to investigate unvisited-source/control ownership without claiming global reachability. No Stage2, main modification, merge, or publication.
