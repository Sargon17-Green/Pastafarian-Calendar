# Befunge-98 / Кыргызча: first lower-loop literal, finite signed-grid Native causality

**Measured on 12 October 2026 · Stage 1 QA ONLY · not a production change.**

## Immutable program provenance

- QA branch: `qa-befunge98-stage1-order-isolation-20261008`; exact source-pinned commit: `94e8d6a81efa5874e8128b5864a0ac4268ac14fb`.
- Production source: `src/interleaved_work_counts.b98`, Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`.
- Experimental four-cell candidate: Git blob `d965ce4bdfa282f2d3b82690808def5a2dde10a8`. Exactly four physical source-cell edits, all confined to a test-only emitted Funge-space program; not committed into production.
- Candidate edits: `(948,1331): 6→7`, `(951,1337): ^→1`, `(951,1338): space→^`, `(952,1336): 1→space`.
- Measured newly inserted executable literal: `1` at `(951,1337)`; the intervention temporarily substitutes `0` only **on the first actual Native visit**, executes one real PyFunge `Program.execute_step`, and immediately restores `1` in a `finally` block. An actual physical Funge-space read verifies this immediate restoration.
- Test and independent auditor: `qa/stage1_native_four_cell_grid_literal_intervention.py` and `qa/stage1_native_four_cell_grid_literal_intervention_audit.py`.
- PyFunge 0.5-rc2, pinned source archive SHA-256 `e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac`. Seven expected output fields were computed by three genuine independent Befunge reference-program runs per signed input, **not** by Python calendar arithmetic.

## Observed complete finite grid

Both calculation and target day range over exactly `{-3,-2,-1,0,+1,+2,+3}`. Every one of 49 input pairs was run both as a normal test-only candidate and as a counterfactual with the one-execution literal replacement; each normal output was checked against three independent Befunge references (147 reference runs).

| Calculation day | Target days tested | Executed new literal | Changed final output **or** termination | No observed final effect |
| --- | ---: | ---: | ---: | ---: |
| -3 | 7 | 7 | 7 | 0 |
| -2 | 7 | 7 | 7 | 0 |
| -1 | 7 | 7 | 7 | 0 |
| 0 | 7 | 0 | 0 | 7 |
| +1 | 7 | 0 | 0 | 7 |
| +2 | 7 | 0 | 0 | 7 |
| +3 | 7 | 0 | 0 | 7 |
| **Total** | **49** | **21** | **21** | **28** |

**Interpretation:** on these 21 signed-day negative-calculation inputs, the inserted lower-feedback literal is genuinely executed and its first push has a causal effect on the final output **or** termination status. On the other 28 inputs, the literal is never executed and the counterfactual is inert. This is a finite, selective causal witness, **not** a universal proof for all signed integers, not proof of numeric output divergence specifically in all 21 cases, and not a complete Funge-space ownership or geometry proof.

## CI and failure provenance

- The initial [exact-head Native run 38300158142](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38300158142/job/114980853039) failed only the new causality test; 84 other checks passed. The defect was in the **QA observer**, which incorrectly demanded that source cell `(951,1337)` still contain `1` **after the entire calculation**. Native Befunge may legitimately overwrite this cell later using `p`.
- The repair [commit `94e8d6a`](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/94e8d6a81efa5874e8128b5864a0ac4268ac14fb) separates immediate restoration (mandatory `1` just after the edited step) from the actual final mutable Funge-space value (recorded, not assumed).
- The corrected [Native job 114986292105](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38301816768/job/114986292105) **SUCCESS**; it reports `NATIVE_FOUR_CELL_FIRST_LOWER_LITERAL_49_GRID_CAUSALITY_PASS reached 21 unreached 28 causal 21`.
- The independent Python-3 evidence auditor also reports `NATIVE_FIRST_LITERAL_INTERVENTION_49_CASES_INDEPENDENT_AUDIT_PASS` and rejects all **12/12** synthetic forged reports. The job's report and underlying Native artifact are retained by GitHub Actions for its configured retention period. The full CI workflow must be evaluated separately; the focused job SUCCESS is not a claim that every other job completed at the same moment.
- Previous independent functional comparison: [Native job 114972851705](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38297750145/job/114972851705) executed **261 real BF98 processes**: 49 valid signed pairs, 8 invalid-lexeme cases, 57 production programs, 57 candidate programs, 147 independent reference programs. It passed source/output parity and 12 adversarial-report checks; its exact-head workflow [38297750145](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38297750145) was **84/84 SUCCESS**.

## Boundaries that remain OPEN

1. The grid is finite. The signed integer domain is arbitrary width, so no 7×7 experiment certifies universal semantic equivalence.
2. Causality is demonstrated for an inserted **arithmetic literal**; this does not by itself prove that every required algorithm family contributes through the full 2D intertwined routing and state.
3. The comparison does not exhaustively establish temporal ownership of every program state component and every runtime memory write over all inputs, concurrency schedules, failures, or restarts.
4. No automatic promotion or merge of the four-cell candidate is allowed. `main` and `Befunge+Кыргызча` are unchanged; PR #17 remains Draft until separate final acceptance.

```text
CURRENT_STAGE=1
LAST_COMPLETED_STAGE=0
FULL_FUNCTIONAL_QA_PASS=NO
GEOMETRIC_SPAGHETTI_QA_PASS=NO
STAGE2_STARTED=NO
```
