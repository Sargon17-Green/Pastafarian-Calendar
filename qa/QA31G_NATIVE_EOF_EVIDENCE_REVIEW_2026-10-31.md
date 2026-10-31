# QA31G Native EOF evidence review — 2026-10-31

Project: PC-BRANCH-BEFUNGE98-KYRGYZ; branch: `qa-befunge98-stage1-order-isolation-20261008`.

## Immutable scope

Code under exact commit `d3b9351dc8891fef436617e2ee27e7397e89cae1` (parent QA31G build `84f135e106ce032fda5efca9d335e33d81d6428c`). Source original Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`. PyFunge-98 0.5-rc2 SHA256 `e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac`. Three unmodified natural stdin byte sequences: `b''`, `b'1'`, `b'1 '`.

First run [41190630467](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41190630467) was completed/failure in *auditor*, not Native: Python `IndexError` accessing non-existent original source row 49; 3 Native HALTs already recorded, artifact 13038308520 retained. Auditor-only correction makes out-of-source original Funge-space cell (3,49) evaluate to ASCII space 32. Exact-head corrected run [41190694847](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41190694847), job `124506712054`, completed/success. No other production change.

## Independently recovered artifact

[Artifact 13037899716](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41190694847/artifacts/13037899716), ZIP SHA256 `e74e4ad35d5653ffd1610827e1351fce62552b0912dc78430908cc288f4e1161`. Downloaded once, ZIP CRC fully valid, all 7 files present. Manifest hashes match all three complete gzip traces; independent audit receipt `cases_verified=3`, `forgeries_rejected=5`, `verdict=MODEL_MATCH`, `stage1_pass=false`. Total original Native physical STEPs: 776+2046+3038=5860. Full-step audit includes opcode/source overlay, pre/post stacks, g/p/j semantics, IP continuity and genuine input cursor/EOF receipts.

| Input | Native physical STEPs | EOF `~` tick | row29 `j` tick, operand, m | row32 `j` | row35 `p` | Exit |
|---|---:|---:|---|---|---|---|
| `b''` | 776 | 292 | 414; 0; m=0 | none | none | HALT |
| `b'1'` | 2046 | 1132 | 1254; 61; m=1 | 1398, operand=0 | 1684 writes `(1,49)=1` | HALT |
| `b'1 '` | 3038 | 2554 | 2676; 0; m=0 | none | none | HALT |

Both nonempty sequences write `(3,49)=1` at original `p(248,14)`, physical tick 1082. The trailing-space case also writes `(3,49)=0` at `p(344,26)` at tick 2504, **before** the row29 gate at tick 2676. The one-byte case has no intervening write to (3,49) before its gate at tick 1254. This is a finite original-Native **last-writer** witness for the different m values; it is not a universal state-ownership result.

Per-case original compressed SHA256 digests:
- Empty: `8e58dc53a786f59f1825a477b212f298fdbd3dbe09a291225d2de80a8e57cab3`.
- Digit: `018091d998f546a918575f3f93e07cad68bd88d5adcdf8a36663cfafdcc4aa`.
- Digit+space: `69f868bd3969b77e7640cb355c6429e73822c6845e8968d82ef2b45ecbf04ad7`.

The source-only model and physical Native code do not produce identical STEP counts: the model counts every source cell, whereas PyFunge native stepping has different blank-cell scheduling. Agreement is limited to **EOF reflection, key p/g/j topology and observed values**, not absolute model tick numbers.

## Acceptance boundary and NEXT

This review accepts the finite original Native EOF witness and the three independent audit results. It **does not** accept Stage 1: no global source/operand-stack ownership proof, no all-input reachability theorem, no FULL_FUNCTIONAL_QA_PASS or GEOMETRIC_SPAGHETTI_QA_PASS. No Stage2, merge, or main modification.

**NEXT / QA31H:** formulate and implement a narrow *last-writer/reader lineage audit* for the newly signed QA31G traces: parse every original `p` to `(3,49)` and `(1,49)`, link each `g` and row29/32 `j` to the nearest preceding physical write, reject missing/reordered write/read and IP tampering, contrast `b'1'` with `b'1 '`. Then decide whether an additional controlled Native input comparison is necessary to establish a causal mechanism beyond these three paths. Do not scan previous QA20/QA31A ZIPs again and do not extrapolate globally.
