# QA25 — Original physical source-byte ownership on QA24 Native routes (DISCOVERY)

**Status at creation: GitHub Actions Native run 39915235834 queued; no QA25 Native PASS asserted.**

QA24 closed with a finite **24/24 Native** and **776,706 executed STEP** receipt audit, but its raw STEP files alone could not prove whether an instruction fetched at an originally populated coordinate was still the original source byte, or a byte previously rewritten by a real `p` instruction. QA25 is a separate, more narrowly grounded Native control for that distinction.

QA25 keeps the signed production `src/interleaved_work_counts.b98` Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c` unchanged. Its predecessor source-coordinate roles (QA18 SHA-256 `263a73a40afa17a8a9b1c831a01239be671d9ea0a9c331fd3f725f83cf1cfea7`), 48-input QA20 aggregate (SHA-256 `75d2ee07eaf998fcb69bcb238d5fcb2163ab8305efe4abe4378af95f41385117`), and original QA24 run `39841651046` at commit `68bfc0d8118a6705d0a0af318f4a48a38e3a159f` are mandatory exact evidence.

## New actual Native protocol

1. Rehydrate original QA24 shard artifacts from GitHub. Split the exact existing 24 inputs across four groups of six; no new or fake candidate inputs.
2. For each group, run **six fresh actual PyFunge 0.5-rc2 Befunge-98 Programs** on the unchanged production source, no manual IP relocation, source mutation or calendar algorithm in Python.
3. At every Native `execute_step`, compare **the full tick, physical coordinate, delta, opcode and stringmode** against the complete original compressed QA24 raw STEP stream. Require the same seven-field output and exact total steps.
4. Observe actual `FungeSpace.put` calls, recording physical writes to each of the original 21 source candidate cells: tick, origin IP, source runtime opcode, prior physical value and stored value. This is a temporary instrumentation hook on disposable interpreter memory, not a test mutation.
5. A separate Python 3 auditor recomputes physical candidate writes from the original initial source values, aligns them to the matching original Native STEP tick, and classifies every reached candidate coordinate into **unwritten original-owned** versus **previously physically written**, even if a rewritten byte equals the original opcode. It applies eight forged-report rejections per shard, plus four-shard aggregate accounting.
6. Save the complete source-anchored original QA24 routes, new real Native write/ownership evidence and independent receipts in GitHub artifacts on success **and RED**.

A subsequent Native write to a source cell after a STEP cannot retroactively own the fetched byte during that earlier STEP. A prior write that restores the same opcode also does **not** prove continued ownership by immutable original source. Records must be fail-closed on changed source byte, original route, output, missing case, missing write or historical receipt drift.

**Scope limitation:** This verifies lineage against observed real `FungeSpace.put` calls for these finite 24 runs. It does not prove no mutation through any other API, no dynamic `k` nested semantics outside the observed hook, all-input impossibility for the remaining 15, global source-byte ownership or full Stage 1 geometry. All original historical QA evidence is immutable. `main`, canonical `Befunge+Кыргызча` and PR #17 remain untouched.

`CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`, `FULL_FUNCTIONAL_QA_PASS=NO`, `GEOMETRIC_SPAGHETTI_QA_PASS=NO`. No Stage 2.
