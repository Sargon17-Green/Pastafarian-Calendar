# QA31Z — finite signed-original stack-lineage review (2026-11-04)

PROJECT_ID: `PC-BRANCH-BEFUNGE98-KYRGYZ`
Branch: `qa-befunge98-stage1-order-isolation-20261008`
Verified predecessor HEAD: `709aae98b2777060e15f1d33d988f8fe767334e1`.
Source blob (previously pinned by QA31Y): `560d6aa5807a7f766213a33835cce85eab0fa40c`; production unchanged.

## Input and evidence

Frozen eight original QA31V SHA256+CRC-signed shard archives and frozen QA31W 200-case CSV, rechecked using QA31X's pinned independent loader.
[Original Native run](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689861481).
[Full original evidence in Drive](https://drive.google.com/file/d/1N3QeYs6FTJEafeHyeU0u5wiLdIRfv5CV/view?usp=drivesdk) — exact ZIP SHA256 `1c97b51823ed98b3d333fcb2d0b35d72f7546b04ed8e86c5adebe3aca5703e8a`, 46,421,841 bytes, CRC PASS in this round.

Bounded to the deterministic QA31X-selected 29 original signed traces, 384-step lookback, witnessed `g` sites (151,8), (57,17), (129,17), (202,17), (275,17) feeding `j` at (185,8)/(335,17). Observed `pre`/`post` steps verified numerically and structural dependencies tracked in forward stack-tag analysis. A separate backward stack-index oracle independently validated the exported witness classifications. Unsupported stack semantics and unresolved earlier inputs remain `unknown`.

## Measured findings

* Original ZIP SHA256 and CRC: **8/8**; distinct signed Native traces **29/29**, physically signed STEPs **510,835** and checked source-site/opcode event observations **3,557**.
* Witnessed `j` events **364**, all local 4-step multiplication-and-jump tails passed physical checks.
* `j(335,17)`: **103/103** finite operand witnesses have complete *structural* stack dependence upon the observed `g` sites (57,17), (129,17), (202,17), (275,17).
* `j(185,8)`: **261/261** physically witnessed operands include contribution from `g(151,8)` but have an additional unresolved incoming stack operand. Hence **261 unknown**, not proven complete. No unsupported opcode was encountered in these 261 local transfers.
* Overall local finite structural classification: **103 complete, 261 unknown**.
* Forward synthetic checks **15/15**. Independent backward oracle **364/364** witness agreement and **11/11** hostile evidence modifications rejected.
* **No new Native/CI, no production edits, no main/merge, no Stage2 and no Stage1 PASS.**

Interpretation: Structural stack-tag dependencies can persist even if multiplication by zero makes numerical outcomes insensitive to the tagged value; no input-byte ownership is inferred from this analysis. QA31Z rechecks QA31Y's **19 previously pinned opcode locations** against 3,557 signed opcode-event records. It does not assert that this round independently re-fetched and byte-compared the entire source blob. Global ownership/reachability, full functional QA and geometric-spaghetti QA remain open.

## NEXT: QA31AA (within Stage1)

Perform bounded root-of-operand analysis for the unresolved pre-existing stack value at `g(151,8)` in the 261 `j(185,8)` witnesses, initially extending to 768 physically signed STEPs, with explicit source-coordinate checks and Funge-space mutations, independent reverse oracle and hostile controls. If unsound, keep `unknown`. No Native rerun unless a concrete new dependency demands it; no global Stage1 PASS.

## QA31Z reproducibility

QA31Z forward executable: `stage1_qa31z_bounded_stack_dependency.py`.
Independent verifier: `stage1_qa31z_independent_backward_oracle.py`.
Local reproducible package produced: `QA31Z_BEFUNGE98_KYRGYZ_OFFLINE_REPRODUCIBLE_20261104.zip`, SHA256 `59036a863fd6fdc4d8ec9e81a860d8c7c856f2e573472e56f71aa28d9934f3d4`. These executable files and their full JSON witnesses were tested locally, but are **not asserted to have been committed with this report**. Preserve them with the report and use them with the original frozen QA31Y ZIP.
