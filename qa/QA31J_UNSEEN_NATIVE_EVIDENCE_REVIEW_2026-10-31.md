# QA31J — accepted finite unseen-byte Native evidence (2026-10-31)

PROJECT_ID: PC-BRANCH-BEFUNGE98-KYRGYZ
Scope: QA-only branch qa-befunge98-stage1-order-isolation-20261008. Stage 1 OPEN. Production source unchanged.

## Exact provenance

- Code commit c0bbb2dbeec066009d72417ad677f4f5b2af54e4; original production Git source blob 560d6aa5807a7f766213a33835cce85eab0fa40c.
- GitHub Actions run https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41212541539 completed/success on the exact code commit; job 124570370386 completed/success. Workflow reruns neither earlier b'1' nor b'1 ' input. It executes only b'1\\n' and b'1\\t'.
- Artifact https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41212541539/artifacts/13046736767 was separately downloaded; ZIP SHA256 57c185ab238602574d45d1a2e9ba58431e1ae567ec2fcb184baaaa89e5a57a37 (matches GitHub upload digest); ZIP CRC PASS 6/6 entries.
- Both compressed original native traces verified against receipt hash: digit_lf SHA256 97e15edf6450fc6b7b4757ebbd202ebb38b7ab0cffbf23761d0cccdb90a65ca8; digit_tab SHA256 84d6868e5a098f4eccabbd91f0d3182807bc97eea0b399402d946378a2fbdc2b. All STEP ticks 1..3038 continuous in each, 6076 total. CI Python 3 source/overlay/p-g-j auditor completed; eight adversarial mutations rejected. No source/IP/input splices.

## Finite original-native observations

| Measurement | stdin hex 310a (digit_lf) | stdin hex 3109 (digit_tab) |
| --- | --- | --- |
| Native terminal status | HALT, 3038 STEPs | HALT, 3038 STEPs |
| First physical read | tick 292, hex 310a | tick 292, hex 3109 |
| Next EOF read | tick 2554, empty bytes | tick 2554, empty bytes |
| Literal p at (60,5), physical tick 1179 | writes value 10 to (0,49) | writes value 9 to (0,49) |
| j at (89,29) | tick 2676 operand 0 | tick 2676 operand 0 |
| Output | seven -1 tokens | seven -1 tokens |

Separate independent ZIP-pair comparison (original signed JSONL, not an expected model): **every one of 3038 IP positions, opcode bytes and next IP positions agrees** between the two Native executions. Despite matching control flow, 252 physical STEPs have distinct pre/post stack state or other state fields, in seven bounded contiguous intervals: [1132,1179] (48); [1226,1251] (26); [1371,1395] (25); [1465,1466] (2); [1587,1685] (99); [1732,1757] (26); [1805,1830] (26). First physical-state difference is at tick 1132. Among the twelve physical p instructions per trace, only the tick 1179 physical write differs in the value; all writer coordinates and write ticks agree. Seven g post-read values differ.

The new result therefore separates an actual input-byte-dependent memory value from execution-route divergence: the two different unseen natural input separators have a finite visible data effect, but the observed instruction path and final outputs coincide. It **does not show global source/memory ownership**, a new unvisited control node, or Stage 1 acceptance.

## Scope, limitations, NEXT

- One fixed original source blob, two extra raw inputs, original PyFunge-98 0.5-rc2 Native, single IP, <=7000 STEPs per case. Existing branch's QA31G observer was reused, not a new independent interpreter.
- The separate independent auditor is source-pinned and accepts only offset-free/stringmode-free physical sequences. No claim of behavior beyond these two recorded executions. The no-duplicate-Native rule is preserved.
- FULL_FUNCTIONAL_QA_PASS and GEOMETRIC_SPAGHETTI_QA_PASS remain NO; 15 historical unobserved source candidate cells remain unresolved absent additional evidence.
- Next substantive bounded frontier: source-ownership/last-writer analysis of physical (0,49) across both newly signed cases and the prior finite (3,49)/(1,49) gates, seeking a distinct naturally reached control gate or changed effective memory owner. Distinguish observed signed traces from hypothetical paths. No Stage2, main/merge, or repeat of accepted input pairs.
