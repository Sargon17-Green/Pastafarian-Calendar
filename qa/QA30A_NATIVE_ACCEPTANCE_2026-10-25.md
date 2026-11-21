# QA30A — Accepted finite Native control-frontier audit

**PASS, finite observational audit only. Stage 1 remains OPEN.**

- GitHub Actions: [40125781530](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40125781530), SUCCESS, on exact tested commit `1e13b9c5579c05af0013e7ab089f2abee4782748`.
- Original CI artifact `12575013982` was downloaded independently; ZIP SHA-256 `57d6bee1b4aa8c6569e0a8fd2b040ab140d9d5834c252efe2e602e0022a10c7f`; ZIP member CRCs PASS.
- Original independent CI recomputed **136 authentic original PyFunge-98 routes**, **4,513,423 actual STEP records**, and SHA-256 of each of 136 compressed original traces (QA20 48 / 1,939,997; QA24 24 / 776,706; QA26 64 / 1,796,720). It rejected **70 of 70 manipulated provenance/edge records** (60 original manifest and 10 altered actual STEP-edge controls).
- Static source Git blob still `560d6aa5807a7f766213a33835cce85eab0fa40c`; source-role provenance SHA-256 `263a73a40afa17a8a9b1c831a01239be671d9ea0a9c331fd3f725f83cf1cfea7`.

## Observed runtime opcode counts (not original-byte ownership)

| Runtime byte | Observed non-stringmode steps |
|---|---:|
| `x` | 70,794 |
| `j` | 7,623 |
| `#` | 2,312 |
| `k` | 97 |
| `g` | 37,157 |
| `p` | 19,366 |
| `>` | 25,758 |
| `<` | 15,029 |

Out of the 15 previously unobserved original source cells, 12 have at least one recorded control/memory-access opcode STEP within Manhattan distance 9. The other three have **zero matching near-control observations**: `(235,23)`, `(286,5)`, `(309,35)`. Every one of the 15 is still unresolved; zero observation is not proof of nonreachability or dead code.

The artifact preserves the four nearest *observed* runtime control edges (where available) per target, with actual before/after IP states, not simulated target arrivals. The proximity threshold is a finite analysis filter, not a completeness theorem.

## Next gate

QA30B: reexecute selected naturally reached original QA20 input-origin programs and capture **real FungeSpace byte/mutation provenance** at the QA30A signed near-control witnesses. Require full original raw STEP parity, output parity and independent falsification controls. Do not relocate the instruction pointer, patch original production, claim an unseen target has been reached, or infer all-input control-state properties.

`CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`, `FULL_FUNCTIONAL_QA_PASS=NO`, `GEOMETRIC_SPAGHETTI_QA_PASS=NO`. No changes to `main`, canonical `Befunge+Кыргызча`, signed production bytes, QA10–QA29 historical evidence, or PR #17; do not open Stage 2.
