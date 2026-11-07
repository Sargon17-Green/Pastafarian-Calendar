# QA31AH — original signed upstream-gate/input-prefix audit (2026-11-06)

Project `PC-BRANCH-BEFUNGE98-KYRGYZ`, existing branch `qa-befunge98-stage1-order-isolation-20261008`; verified prior HEAD `03cc1ae35de03468b28ca9fbf4581e36fbf54f24`. This is a **QA-only finite review**, not a new Native run or Stage1 PASS. Original production source remains unchanged; no main/merge/Stage2.

## Prerequisite QA31AG: completed, independently inspected

Original-source exact-head [CI run 42177811177](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42177811177) completed/success on `03cc1ae35de03468b28ca9fbf4581e36fbf54f24`, one job 127760243503. The downloaded [artifact 13484995107](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42177811177/artifacts/13484995107) matched SHA256 `677370286424db9380c070c2093dd2947715924731f8be9bf060b7fc3bf0ade2` and ZIP CRC. Forward JSON checked 18 original source-site pins, 30 modeled gate states, 41 bounded original-source segments, 6 negative controls. Independent inverse JSON checked 28 conditional states, 9 source sites and rejected 12/12 mutations. The JSON explicitly has `new_native_runs=0`, `stage1_pass=false`. **Finite source-model QA31AG accepted**, not any global gate.

## New measured QA31AH experiment

Input: [frozen QA31Y original signed evidence archive](https://drive.google.com/file/d/1N3QeYs6FTJEafeHyeU0u5wiLdIRfv5CV/view), 46,421,841 bytes, SHA256 `1c97b51823ed98b3d333fcb2d0b35d72f7546b04ed8e86c5adebe3aca5703e8a`. The standalone Python-standard-library auditor first checked archive SHA256/CRC, 8/8 nested ZIP SHA256/CRC against frozen manifest, 29 original selected HALT receipts, each original raw input and gzip STEP SHA256, 510,835 sequential physical STEPs and `next` to next-IP continuity. It checked physical `g`, `p`, `j` opcodes/stack values and arithmetic displacement. The source blob was locked by QA31AG; this QA31AH audit **did not** independently rehash the 1.8MB production source or inspect the remaining 171 signed cases.

| Physical site | Observations | Signed physical result |
|---|---:|---|
| `j(185,8)` | 261 | 158 with operand 61; 103 with operand 0 |
| `j(89,20)` | 100 | all with operand 61 |
| `j(113,23)` | 100 | all operand 0 |
| `j(89,29)` | 20 | 13 with operand 61, 7 with operand 0 |
| `j(113,32)` | 13 | all operand 0 |

Additional last-physical-writer evidence: all 100 `g(57,20)` reads returned `m=1` last written at `p(248,14)`; `g(57,29)` returned `m=1` 13 times (last `p(248,14)=1`) and `m=0` 7 times (last `p(344,26)=0`); all 13 `g(57,32)` returned `q=3` (last `p(248,26)=3`). The two row8 `g` sites each had 261 original observations. Eight deliberately altered event-table witnesses were rejected (8/8); these are **table-level checks**, not eight distinct Native mutations.

The finite observation is important: both row8 routes were witnessed, row20 was reached with `m=1`, and row29 showed both `m` values. But neither row23 nor row32 witnessed `q>3`; the required natural-input conjunction `m=1 AND q>3` remains unproved. An input read preceding a gate is only temporal evidence, not proof of exclusive stdin-byte causal ownership. No global unreachability can be inferred from a finite corpus. No fresh Native run or CI run occurred for QA31AH.

## Persistent reproducible deliverable

`/Befunge_QA_Artifacts/QA31AH_BEFUNGE98_KYRGYZ_ORIGINAL_29_UPSTREAM_PREFIX_20261106.zip`

SHA256 `4c17deae595262dcbcb8863da005810f60288c483273e32b3b2955b9fb13e271`, 46,450,185 bytes, 8 ZIP members, ZIP CRC and per-member manifest SHA256 verified. It contains the exact frozen 46MB source-evidence archive, complete runnable Python auditor, Windows `RUN_QA31AH.cmd`, detailed original-event JSON, gate CSV, summary JSON, report and manifest. This is the **new deliverable**, not just a statement of intent. Python 3.10+ standard library on Windows or Unix; fail-closed on SHA, receipt, STEP or physical branch mismatch. Local QA31AH run: 29/29, 510835 physical STEPs, 8/8 nested original ZIPs, 8/8 hostile table mutations.

**Next authorized QA:** trace upstream stack/input owner at row8 and row20 for original suffix classes and source-model alternative ingress, seeking a concrete natural stdin where `q>3` *before* row23/32 and `m=1` at that gate. Only propose a new bounded Native probe once an executable source-grounded candidate is found. Stage1 **OPEN**; functional/geometric/global gates still not accepted.
