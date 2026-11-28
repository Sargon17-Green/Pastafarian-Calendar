# QA31L original Native evidence review and QA31M route audit — 2026-10-31

Scope: **PC-BRANCH-BEFUNGE98-KYRGYZ**, QA-only branch `qa-befunge98-stage1-order-isolation-20261008`. The original program remains unchanged, and Stage 1 remains OPEN.

## Identity and signed evidence

- Exact CI: [run 41238968158](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41238968158), job 124648633517, `completed/success`, run SHA `0a25584b1850c13eb5cab3e83988be2290169c29`.
- [Artifact 13057227833](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41238968158/artifacts/13057227833), 47,670 bytes, outer GitHub Actions ZIP SHA256 `7de4556fda1b3d0b746c5b08e1600e029abb8d3a3565b976ddff804b9d4043b7`. ZIP CRC verified independently after download.
- Embedded Native ZIP SHA256 `afbba1d31dd840a3d0ac7f8661ce622f8e266f07c69d604d2de7ccbe9438702c`; nested CRC verified; nested receipt and compressed STEP bytes exactly match outer copies.
- Original production source Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`, checked by CI with git hash-object and by QA31L source-pinned independent auditor. No program edits, IP relocation, or reruns of old cases.
- New input only: raw single-byte `b'0'`, hex `30`, SHA256 `5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e9`.
- Native PyFunge-98 0.5 rc2, originally pinned download SHA256, Python 2.7 Docker, execution capped at 7,000 STEPs and timeout 360 s. Actual `HALT` at physical STEP 2046, two input reads (one EOF), output seven `-1` tokens.
- Compressed original STEP SHA256 `779a58cc01255828dc76831566c31acf48395133a123611b35351aa18dff0a59`. All 2046 physical records counted and their `t` sequence validated, including terminal `@` at (179,44). QA31L independent audit: complete bounded source/STEP/EOF/p/g/j oracle coverage, **9/9 hostile mutations rejected**, `QA31L_AUDIT_PASS`; this is NOT a global Stage 1 pass.

## Previously unreported original Native cross-lane traversal

Independently decoded the exact original STEP bytes after QA31L, without a Native rerun:

| STEP | Physical instruction | Confirmed successor |
| --- | --- | --- |
| 1,254 | `j(89,29)`, stack operand = **61** | `(151,29)` |
| 1,301 | `x(211,29)` | `(10,32)` |
| 1,398 | `j(113,32)`, operand = **0** | `(114,32)` |
| 1,445 | `x(174,32)` | `(10,35)` |
| 1,731 | `x(309,35)` | `(10,38)` |
| 1,829 | `j(114,38)`, operand = **0** | `(115,38)` |
| 1,876 | `x(175,38)` | `(10,44)` |
| 2,046 | `@(179,44)` | `HALT` |

At STEP 1255 the instruction at (151,29) is `0`. **No STEP visits `x(150,29)`**. The jump at (89,29) bypasses this `x`, but another `x` at (211,29) is genuinely executed and enters row 32. The previous QA31L line `QA31L_X_CELL_VISITS 0` refers narrowly to the **(150,29) candidate**, not to all `x` executions. Original trace contains 11 executed `x` instructions in total.

An independent QA31M local Python 3 route auditor on the SHA-pinned Actions ZIP checked the exact four row transitions, six original `j` visits, 2046-step continuity and source/receipt scope. It rejected **9/9 local hostile variations** (altered `j` successor/operand, altered `x` instruction/destination/coordinates, altered terminal instruction, and deleted STEP). This independent QA31M analysis is **local/offline**, not a new CI or Native success claim; see downloadable local audit script and output from the corresponding work session.

## What this proves, and does not

The single actual original Native input `b'0'` demonstrably reaches rows 32, 35, 38 and 44 via dynamic `x` transitions, and reaches the row-29 gate with operand 61. This refutes any statement that these four cross-lane cells are unvisited in **all** original Native runs. It does **not** prove the input-to-every-branch reachability, global original-source ownership, all legal inputs, or complete functional/geometric tests. The (150,29) `x` is **not reached in this run**.

**Acceptance:** QA31L finite evidence PASS; Stage 1 OPEN; FULL_FUNCTIONAL_QA_PASS and GEOMETRIC_SPAGHETTI_QA_PASS not established; no main, merge, publication, or Stage 2.

## NEXT — targeted QA31M signed path-owner test

On the original SHA-pinned QA31L trace, extend the independent cross-lane check with last-writer / first-reader lineage at the row 32, 35, 38 and 44 segments. Use original source coordinates and full-step order as separate oracle inputs. The output is a bounded transition and owner table (instruction/tick/coordinate, predecessor writer, nearest consumer, and unknown coverage), plus deliberate negative controls. Do not conflate conditional geometry with naturally reachable input; do not rerun QA31L solely to reproduce this already signed witness. Escalate to a new Native differential only if a specific missing owner/reachability condition demands it.
