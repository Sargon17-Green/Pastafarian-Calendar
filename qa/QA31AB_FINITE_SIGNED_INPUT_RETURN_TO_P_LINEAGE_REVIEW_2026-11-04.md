# QA31AB — bounded original `~(13,5)` return → `p(60,5)` stack lineage (2026-11-04)

PROJECT_ID: `PC-BRANCH-BEFUNGE98-KYRGYZ`  
Working branch: `qa-befunge98-stage1-order-isolation-20261008`  
Verified pre-change branch HEAD: `dc382457fb356952bb26cdfd847750278f2fc209`  
Production original source Git blob: `560d6aa5807a7f766213a33835cce85eab0fa40c`.

## Frozen evidence and scope

No Native rerun, production edit, main/merge, or Stage2. Reused the exact [QA31Y frozen 17-file archive](https://drive.google.com/file/d/1N3QeYs6FTJEafeHyeU0u5wiLdIRfv5CV/view?usp=drivesdk), 46,421,841 bytes, SHA256 `1c97b51823ed98b3d333fcb2d0b35d72f7546b04ed8e86c5adebe3aca5703e8a`, CRC PASS. Its 8/8 original QA31V shard ZIP SHA256+CRC, 29/29 original Native trace hashes, and 510,835 signed STEP records were rechecked locally. QA31Y's 3,557 original source-site opcode observations were also checked. QA31AA's frozen witness archive was separately verified, SHA256 `a051f9e656b41e3492e4767b497c88ee750b34abd79ceb152b107d40cf0a2efe` and ZIP CRC PASS.

The original Git blob was fetched and read on this turn; its row 5, columns 13–60 has the exact 48-byte opcode segment:

```
~00a*0+a*0+a*0+a*0+a*0++00a*0+a*0+a*0+a*4+a*9++p
```

Both independent analyzers compare every executed opcode and coordinate to this fixed original-source slice and require pre/post arithmetic correctness, tick/IP continuity, and no `p`/`s` writes to the original instruction segment in the verified traces.

## Finite result

The 261/261 previously accepted QA31AA `j(185,8)` witnesses had an exactly 47-tick physical interval from executed `~(13,5)` to `p(60,5)`. All 261 local segments were source-matched and had a directly measured stack transfer: `~` returns one observed integer `X` with empty pre-stack; then 46 physical instructions deterministically build `p`'s pre-stack `[X,0,49]`, which writes numeric `X` to Funge-space `(0,49)`.

The **forward** analyzer computes an independent affine expression `aX+b` for each stack item from the `~` result, re-evaluated against original signed pre/post stacks at all 48 instructions. In all 261 cases the exact expression for `p`'s value is `1*X+0`. Local synthetic checks: **7/7** affine points and **7/7** hostile edits rejected.

The **independent backward** analyzer reconstructs required stack indices from `p`'s value through 46 physical operations, without importing the affine proof. It resolves exactly one origin at the observed `~` push in **261/261** records, with **12,006/12,006** backward operation transfers and **12,528/12,528** original-source-row opcode-site checks. It rejected **20/20** mutations of an original physical segment. No matching alternate stack root was observed in these 261 segments. Repeated numeric equality was *not* used as the dependency oracle.

The 261 observed `~` instructions include **33** with a physical `reads` record and **228** without a new `reads` record. The trace records a returned integer at `~`, but does not independently prove which original raw stdin byte, buffered input mechanism, or EOF convention owns each return. Some returns were `0` and `255`. Thus the proven claim is local **executed-`~` return → `p` stack-value ancestry** in the frozen physical cases, not global external input-byte causality, sensitivity, or reachability. The existing QA31AA `p → g(57,8) → j` conclusion remains bounded and separate; multiplying by zero can erase numerical sensitivity while retaining structural ancestry.

## Reproduce

Python 3 standard library. Extract the existing QA31Y archive and the QA31AB package into a directory, preserving `QA31V_SHARD0.zip`–`QA31V_SHARD7.zip`, the original `QA31W_200_PHYSICAL_TRACE_CLASSIFICATION.csv`, and `QA31AA_WITNESSES.json`. Execute:

```
python stage1_qa31ab_stdin_to_p_forward.py --zip-dir . --qa31w-csv QA31W_200_PHYSICAL_TRACE_CLASSIFICATION.csv --qa31aa-witnesses QA31AA_WITNESSES.json --out QA31AB_REPRODUCED
python stage1_qa31ab_independent_backward_oracle.py --zip-dir . --qa31w-csv QA31W_200_PHYSICAL_TRACE_CLASSIFICATION.csv --forward-witnesses QA31AB_REPRODUCED/QA31AB_FORWARD_WITNESSES.json --out QA31AB_REPRODUCED
```

Evidence outputs and logs are packaged without duplicating 46 MB of prior frozen Native evidence. Verify package manifest SHA256 and CRC before use. This is offline finite verify, **not a new Native/CI PASS**.

## Stage gate and NEXT

Stage1 remains **OPEN** (`FULL_FUNCTIONAL_QA_PASS=NO`, `GEOMETRIC_SPAGHETTI_QA_PASS=NO`, global raw input-byte owner UNKNOWN). No claim of global byte-level ownership, source reachability or completion.

**QA31AC (next):** bounded original `~` return/`reads` buffer-boundary ownership audit. Use the frozen 29 trace `reads` records, distinguish same-call line acquisition vs subsequent buffered character returns vs EOF/sentinel cases, and compare only those transitions justified by physical tick, read cursor, and original source; mark any ambiguous owner unknown. Require an independent cursor/byte-stream oracle, hostile mutation controls, and strict 8-ZIP/29-trace SHA/CRC verification. Do not change original Native or infer global Stage1 pass from a finite mapping.