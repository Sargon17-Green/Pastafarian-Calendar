# QA31F upper-band standard-entry ingress graph — 2026-10-31

Project: PC-BRANCH-BEFUNGE98-KYRGYZ. Work branch: `qa-befunge98-stage1-order-isolation-20261008`. Immutable original production blob `560d6aa5807a7f766213a33835cce85eab0fa40c`.

## Target and evidence

Investigate alternative entries into rows 14 and 23 without repeating signed QA20 48-case scans or the former 263 q-writer model. The new Python `qa/stage1_qa31f_upper_ingress_graph.py` is an independent bounded **standard-entry** interpreter over original source rows 8/11/14/17/20/23/26/29/32/35/38/41. Its independent finite sweep covers 12 starting rows × 12 selected stored character codes × 5 q values × 2 m values = **1,440 source-model segment cases**; it pins the original source blob, tests exact directed exits and rejects three deliberate physical `j`-opcode mutations.

The predicted source-graph exits, to be accepted only after the newly committed script completes in exact-SHA CI, are:

| Entry y | Direct exits (x,y) |
| --- | --- |
| 8 | (10,11), (10,17) |
| 11 | (10,14), (10,44) |
| 14 | (10,5) |
| 17 | (10,20), (10,44) |
| 20 | (10,5), (10,23) |
| 23 | (10,26), (10,44) |
| 26 | (10,5) |
| 29 | (10,32), (10,38) |
| 32 | (10,35), (10,44) |
| 35 | (10,38) |
| 38 | (10,41), (10,44) |
| 41 | (4,0) |

Thus, among these ordinary standard-entry directed segments, row14 has only row11 as a direct predecessor, while row23 has only row20. However, ASCII whitespace (9/10/13/32) goes row8→row17→row20, bypassing row11, so the row11 q>3 diversion **alone** is not a global proof of row23 inaccessibility. On the source-model graph, row20→row23 requires m=(3,49)=1; row23 q>3 then exits to row44. Row41 exits to (4,0) retaining four stack operands, so it must not be modeled as a memory-only reset.

## Scope, conditions, and next step

Inputs are hypothetical cells `(0,49),(1,49),(2,49),(3,49)` and four output-memory cells, with each segment entered at (10,y), stack empty, storage offset zero, and source unchanged. This is **not** a natural stdin witness, Native test, proof of globally exhaustive incoming edges, proof against Funge `p` self-modification, or Stage1 PASS. The graph is a directed local claim only. No production modifications, main updates, merge, or Stage2.

NEXT: trace the cross-iteration source-backed q/m physical write ancestry for the **whitespace bypass** row8→row17→row20→row23, including the row14→row5 re-entry and row35→row38→row41→(4,0) escape. Check whether m=1 and q>3 can coexist at row23 under real stack, storage offsets and signed receipts. Require a grounded natural stdin candidate before any bounded new Native probe and independently audited receipts.
