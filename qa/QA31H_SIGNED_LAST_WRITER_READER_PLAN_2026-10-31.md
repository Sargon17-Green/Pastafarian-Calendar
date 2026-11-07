# QA31H — bounded last-writer/reader chain, 2026-10-31

Project: PC-BRANCH-BEFUNGE98-KYRGYZ. Branch: qa-befunge98-stage1-order-isolation-20261008.

## Evidence and contract

**No new Native** is run. Input is exactly historical QA31G artifact 13037899716 from completed/success workflow 41190694847; ZIP SHA256 e74e4ad35d5653ffd1610827e1351fce62552b0912dc78430908cc288f4e1161. Source Git blob MUST equal 560d6aa5807a7f766213a33835cce85eab0fa40c. All three compressed trace hashes are separately pinned. Inputs: empty, b'1', b'1 '. Limits: 776/2046/3038 records; no broader QA20/QA31A scans.

The auditor rebuilds overlays from all physical p instructions, verifies g against the most recent physical write (or original Funge space), checks physical IP continuity, source/overlay opcodes, stack changes, row29/row32 j displacement, exact writer->reader->gate ordering, and independently rejects ten deep trace corruptions (not just SHA mismatches).

Finite expected chain:
| Input | last p(3,49) | g(3,49) | j(89,29) | row32 |
|---|---|---|---|---|
| b'' | tick 242, 0 | tick 389, 0 | tick 414, 0 | absent |
| b'1' | tick 1082, 1 | tick 1229, 1 | tick 1254, operand 61 | g(1,49) tick 1349 reads p tick 146 value 0; j tick 1398 |
| b'1 ' | tick 2504, 0, after previous 1 at 1082 | tick 2651, 0 | tick 2676, 0 | absent |

Secondary state cell (1,49): both nonempty cases initialize to zero at tick 146. b'1' writes 1 at tick 1684, while b'1 ' writes 1 at tick 2408; the final observed g(1,49) in each case sees the latest respective physical write.

Initial independent **local trace-only** examination of existing signed ZIP checked 5,860 records and rejected 10/10 hostile mutations. GitHub Actions is authoritative for the stronger source-blob check; do not claim exact HEAD CI PASS until completed job/log and artifact are verified.

## Evidence limit and NEXT

Even completed QA31H verifies **three original finite traces only**, not global memory ownership, input-to-stack causal generality, FULL_FUNCTIONAL_QA_PASS or GEOMETRIC_SPAGHETTI_QA_PASS. Stage 1 remains OPEN. No Stage 2, protected branch, merge or main changes.

NEXT after CI: inspect completed exact-SHA QA31H job and artifact hashes; if accepted, design the smallest *controlled* native differential that separates presence/absence of the trailing space at the last read, with no source or IP intervention and a separate negative-control auditor. Preserve original QA31G signatures. Do not run another QA20 sweep.
