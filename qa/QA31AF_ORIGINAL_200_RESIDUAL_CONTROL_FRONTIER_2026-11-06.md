# QA31AF — bounded original signed Native residual control frontier (2026-11-06)

**PROJECT_ID:** `PC-BRANCH-BEFUNGE98-KYRGYZ`
**Working branch:** `qa-befunge98-stage1-order-isolation-20261008`
**Pre-review HEAD verified against GitHub:** `8153f84001989464ed6f482199d18ea9f1cb89bc`
**Frozen original Git source blob:** `560d6aa5807a7f766213a33835cce85eab0fa40c` (production unchanged).
**Original QA31V Native source run:** [41689861481](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689861481).

## Reproducible, bounded inputs and method

The frozen [QA31Y evidence archive](https://drive.google.com/file/d/1N3QeYs6FTJEafeHyeU0u5wiLdIRfv5CV/view) is 46,421,841 bytes with SHA256 `1c97b51823ed98b3d333fcb2d0b35d72f7546b04ed8e86c5adebe3aca5703e8a`. It carries eight original signed QA31V ZIPs, 200 original HALT receipts and complete original gzip traces. Each shard SHA256 and CRC, each raw-input SHA256, each compressed STEP SHA256 and the 25,000-STEP/case bound were checked. Five exact original source rows were retrieved from GitHub by original blob SHA; the snapshot is **not** a fully locally rehashed 1.8MB source blob.

Two independently implemented Python auditors inspected the same physical corpus: the forward scanner checks source opcodes, STEP ticks/continuations, jump stack operand and next-IP; the reverse scanner derives the branch displacement from physical next-IP and compares case-by-case with the forward 200-row result, including q and EOF reflection behavior. The two implementations do not import each other. No new Native or CI run, no change to production, no main/merge/Stage2.

## Measured finite results

| Item | Original signed evidence |
|---|---:|
| Original shard ZIP SHA256 + CRC | 8/8 |
| Original HALT cases, raw receipts and gzip SHA256 | 200/200 |
| Sequential original physical STEP records | 3,628,390 |
| `j(164,5)`, before `x(286,5)` | 1,800 visits; all operand 0 |
| Original `~(13,5)` visits | 1,940; 1,800 successful nonnegative values; **140 reflected EOF**; zero negative returns |
| `x(286,5)` | **0 witnessed** |
| `j(113,23)`, before `x(235,23)` | 680 visits; all operand 0; physical q at gate at most 3 |
| `x(235,23)` | **0 witnessed** |
| `j(113,32)`, before `x(235,32)` | 100 visits; all operand 0; physical q=3 |
| `x(235,32)` | **0 witnessed** |
| Independent reverse oracle, physical gate events | 2,580 confirmed |
| Forward hostile source/gate mutations rejected | 16/16 |
| Reverse hostile route mutations rejected | 10/10 |

In this interpreter, an observed EOF `~` physically reflected the IP from `(13,5)` to `(12,5)` without a negative stack return. Thus the source-only hypothetical signed negative-return path to `(286,5)` is **not** an observed physical Native witness.

The source-only counterfactual table holds 297 conditional rows: 256 nonnegative plus one hypothetical -1 for row5, plus two sets of 2×10 (m,q) cases for rows23 and32. Thirteen conditional scenarios select otherwise unobserved targets (one hypothetical negative return and six `m=1,q>3` cases per later row). They are **not natural input witnesses** and are never counted as Native PASS.

The QA31AE 200×15 matrix was in a conversation artifact not inside frozen QA31Y; this audit independently rewalked all 200 original physical traces and checked its own 200-row case matrix. It does **not** claim byte-for-byte revalidation of the missing QA31AE package.

## Reproducible QA31AF package

Created 14-member Windows/Python-standard-library reproduction archive:
`QA31AF_BEFUNGE98_KYRGYZ_FINITE_RESIDUAL_FRONTIER_20261106.zip` (46,453,889 bytes), SHA256 `6dbdad9baa6bed6eed65517ef5ee9c6c572bd98e23fdce2da9fc9bead07de427`, ZIP CRC valid.
It includes the full frozen original QA31Y archive, source-row snapshot, two complete runnable independent scripts, Windows CMD launcher, package manifest, full 200-row case CSV, all 2,580 gate-event rows, 297 hypothetical rows, JSON summaries and audit logs.

Local source scripts SHA256:
- `stage1_qa31af_residual_frontier.py` = `137da49c6b53ee146d4e7077ae7c6ec3f4c3355b9699f0143890afa2073ecbdb`
- `stage1_qa31af_independent_reverse.py` = `2ed0e33f480513a5c25d398f113dac99946cc077b49c4a8fb9f6b17ee1a51115`

The reproduction ZIP is a conversation deliverable. Attempted persistent Library mirror at `/Befunge_QA_Artifacts/` returned `container_session_unavailable`; **do not claim it exists in Library or Drive**. This GitHub QA report is persisted, and the original QA31Y archive remains in Drive.

## Verdict, limitations and NEXT

**QA31AF finite offline original signed audit: PASS**. Stage1 remains **OPEN**. All three non-observations are finite, and do not prove global unreachability, ownership of all input bytes, or full functional and geometric QA acceptance. No Native rerun, no CI claim for this QA-only document, no production/branch-main modification.

**NEXT QA31AG:** bounded source-pinned upstream feasibility test of row23/row32 ingress and q>3 with m=1 *at the physical gate*, plus real-interpreter EOF behavior at row5. Use an independent oracle and bounded concrete prefix/path checks. Generate a new Native probe only after a source-grounded natural input candidate, rather than inventing expected-red or proving absence from finite counts.
