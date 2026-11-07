# QA31Q — exact original source frontier for 15 controls not executed in QA20

Project `PC-BRANCH-BEFUNGE98-KYRGYZ`. Branch `qa-befunge98-stage1-order-isolation-20261008`. Stage 1 **OPEN**. Source `src/interleaved_work_counts.b98` must have Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`.

## Original historical receipts, not new Native

QA18 original 49 Native traces: artifact `12265002965`, `qa18_glyph_roles.json` SHA256 `263a73a40afa17a8a9b1c831a01239be671d9ea0a9c331fd3f725f83cf1cfea7`: **21** candidate control glyphs. QA20 original 48 Native cases (27 valid, 21 invalid; 1,939,997 physical STEP records): run `39761821210`, aggregate artifact `12419050654`, `qa20_native_48_aggregate.json` SHA256 `75d2ee07eaf998fcb69bcb238d5fcb2163ab8305efe4abe4378af95f41385117`. Exactly **6** of those 21 controls had natural physical execution in QA20, leaving **15 not observed in that finite corpus**. This does not mean never visited in every subsequent test, nor universally unreachable.

| Row y | Original QA20-unvisited controls (x, opcode) | Conditional standard-entry source path |
|---|---|---|
| 5 | (286, `x`) | Hypothetical negative `~` return `-1`; **not** proven EOF/native behavior |
| 23 | (235, `x`) | Row20 can enter row23 when m=(3,49)=1; then q=(1,49)>3 selects this `x` |
| 29 | (211, `x`) | On standard entry, m=1 routes to row32 |
| 32 | (10, `>`), (57, `g`), (113, `j`), (174, `x`), (235, `x`) | Entry requires row29 m=1 in the restricted graph. q<=3 selects x174 to row35; q>3 selects x235 to row44 |
| 35 | (10, `>`), (57, `g`), (127, `g`), (152, `p`), (199, `g`), (248, `p`), (309, `x`) | Row32 q<=3 enters row35; first p writes value of (2,49) to indexed (10+q,49); second p writes q+1 to (1,49); exit to row38 |

Count: 1+1+1+5+7=**15**. Every coordinate must match the original Git-blob-pinned byte, and QA18/QA20 must match their exact report SHA256. The new `stage1_qa31q_original_frontier.py` implements its own finite operand-stack, `g`, `p`, `j`, `x`, and one-row transition model, rather than trusting prior QA31F aggregate exit labels. Source model grid: 256 nonnegative byte hypotheses plus one **explicitly artificial** `-1`, 6 row23 q cases, 2 row29 m cases, 6 row32 q cases, 4 row35 owner cases, 16 chained row29→32→35→38 segments: **291 bounded segment evaluations**. All 15 potential source-control sites are hit under some *modeled hypotheses*, but not proven naturally reachable. **18** deliberately forged source/report controls must be rejected (15 source-cell mutations, three altered historical-receipt fields). No numeric calendar oracle or new Native executions.

One useful conditional dependency: if a program truly enters row29 with `m=1` and `q=3`, and reaches row32 and row35 along the modeled path with the modeled stack/storage state, row35 increments `q` to `4` and row38 may then exit to row41. This is **not** a demonstrated natural input path, full global memory ownership, or unrestricted IP geometry. The historical signed QA31D pair proved q=4 at the row38 gate in another finite trace; it does not thereby prove that row29→32→35 ingress occurred. The fresh QA31Q checker does not replay the already accepted QA31D pair.

## Acceptance / next

Before marking QA31Q source-model accepted, require exact-SHA completed GitHub CI and inspect log, full JSON, artifact ZIP SHA256 and CRC; the locally constructed six-row fixture is **not** the original full source and is **not** an acceptance substitute. Then examine actual signed STEP owner/read chains for row29→row32 and row35 indexed output writes, and search for grounded natural stdin witness; do not fabricate it. Stage1 needs `FULL_FUNCTIONAL_QA_PASS` and `GEOMETRIC_SPAGHETTI_QA_PASS` separately. No main, merge, source production edit, or Stage2.
