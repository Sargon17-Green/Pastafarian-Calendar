# QA27 — Directed geometric frontier of the 15 original source opcodes

**Discovery checkpoint; Native historical CI audit pending.** The new original-evidence re-audit is [GitHub run 39966335703](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39966335703), queued when this document was prepared. Do not sign QA27 before independent original 12-artifact check.

## Exact accepted baseline
- QA18 static source roles: 21 potential original source control opcodes from the same signed production Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c` (roles file SHA-256 `263a73a40afa17a8a9b1c831a01239be671d9ea0a9c331fd3f725f83cf1cfea7`).
- QA20 = 48 original-input Native PyFunge programs, **1,939,997** actual STEP events; QA24 = 24, **776,706**; QA26 = 64, **1,796,720**. Across all three accepted original runs: **136 programs, 4,513,423 actual STEP events**.
- A read-only independent local rescan of **all 136 original gzip route files** reproduced all three exact step totals, matched each manifest's individual compressed trace SHA-256, and observed no additional source opcode contact among the remaining 15. This local rescan is additional evidence, **not** a substitute for the pending fail-closed GitHub CI verification.

## Fifteen remaining original source-cell frontier witnesses

The table below records the minimum Manhattan/L1 distance `|x-target_x|+|y-target_y|` from any actual original PyFunge IP STEP across the 136 historical trajectories. Each nearest witness was already present in QA20. The coordinate and opcode listed are **observed fetched runtime STEP values**, not inferred static state, and the pointer delta may be non-unit due to genuine two-dimensional Befunge semantics.

| Original cell | Original opcode | Min L1 | Nearest sampled real STEP coordinate | Witness input |
|---|---|---:|---|---|
| (10,32) | `>` | 3 | (10,29) | QA20 `valid03` |
| (10,35) | `>` | 3 | (10,38) | QA20 `valid03` |
| (57,32) | `g` | 3 | (57,29) | QA20 `valid03` |
| (57,35) | `g` | 3 | (57,38) | QA20 `valid03` |
| (113,32) | `j` | 4 | (112,29) | QA20 `valid03` |
| (127,35) | `g` | 3 | (127,38) | QA20 `invalid15` |
| (152,35) | `p` | 3 | (152,38) | QA20 `invalid15` |
| (174,32) | `x` | 6 | (174,26) | QA20 `valid03` |
| (199,35) | `g` | 4 | (198,38) | QA20 `valid03` |
| (211,29) | `x` | 3 | (211,26) | QA20 `valid03` |
| (235,23) | `x` | 3 | (235,26) | QA20 `valid03` |
| (235,32) | `x` | 6 | (235,26) | QA20 `valid03` |
| (248,35) | `p` | 9 | (248,26) | QA20 `valid03` |
| (286,5) | `x` | 3 | (286,8) | QA20 `valid03` |
| (309,35) | `x` | 9 | (309,26) | QA20 `valid03` |

**Interpretation and priority:** Static closeness in the rectangular source grid **does not prove a legal control transfer**. For example, observations at `y=26` only show proximity to original bytes at `y=23,29,32,35`; these rows need actual instruction-direction and control-event witnesses, not a guessed vertical jump. State changes via `x`, `j`, `p`, `g`, or non-unit deltas may make simple adjacency invalid. Equally, observed noncontact in 136 finite runs is not universal nonreachability.

## QA27 CI verification contract
- Read only historical original GitHub runs `39761821210`, `39841651046`, `39945902093`; never rewrite their evidence. Recover four original Native shards from each run (12 artifacts) and accepted QA18 roles.
- Pin original GitHub run conclusions/HEADs and source Git blob; recompute gzip hashes and monotonic Native STEP fields, independent per-run/case totals, L1 minimum and exact opcode contact, every original saved nearest/hit summary.
- For each of 15, preserve nearest input, coordinate, pointer delta, opcode and stringmode. Reject 60 adversarial mutated manifest headers. Require full accounting of **136 original programs and 4,513,423 original physical steps**.
- Keep explicitly unproven the static-byte owner where memory may be overwritten before an instruction fetch. QA25 addresses earlier 24 original programs, not every QA20/QA26 run; later semantic ownership needs separate evidence.

## Remaining gate
Analyze actual **incoming route edges and mutable memory provenance** at each of the 15 source coordinates. A finite original Native trajectory that comes close but does not arrive establishes an observed frontier, not a proof that future legal input cannot reach the cell. Global geometry/ownership and Stage 1 remain open.

`CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`, `FULL_FUNCTIONAL_QA_PASS=NO`, `GEOMETRIC_SPAGHETTI_QA_PASS=NO`. No `main`, canonical `Befunge+Кыргызча`, signed production byte edits, PR #17 merge or Stage 2.
