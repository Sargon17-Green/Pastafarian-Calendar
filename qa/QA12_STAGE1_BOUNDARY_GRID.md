# QA12 — Stage-1 finite Native boundary grid (independent of QA11B)

**Scope: new finite Stage-1 functional coverage, not global Stage-1 acceptance.**
QA11B 17-dimensional three-worker acceptance is preserved verbatim and not re-run as an oracle.
No new non-Befunge calendar arithmetic or source code is introduced.

## Remaining contractual problems

The branch's `artifacts/stage-01/STAGE1_COMPLETENESS_QA.md` records open final
`FULL_FUNCTIONAL_QA_PASS` and `GEOMETRIC_SPAGHETTI_QA_PASS` gates, and unfinished
production semantic ownership. Full `calendarDate` orchestration is *not* a
Stage-1 bootstrap gate. Do not silently redefine the scope.

## This experiment

* Freeze QA production `src/interleaved_work_counts.b98` at Git blob
  `560d6aa5807a7f766213a33835cce85eab0fa40c`, independent reference
  `work_counts` at `f941efc793c9eee4accf5d03873f8ed029b16725`, and `save`
  at `7b5e79aa6e2bfb636717cb018a3db6a13fb2bb44`.
* Define exactly 16 signed days: zero, immediate positive/negative neighbors,
  the Foundation day and its ±1/±2 neighbors, `2^127-1`, `2^127` with both signs,
  and opposite-sign 81-digit magnitudes. Unique unordered pairs: 136;
  actual ordered pairs: 256, including every reversal and all equal days.
* Partition unordered pairs deterministically over four Native CI jobs (34
  per shard), each running original and reversed orientation where distinct.
  Every orientation compares three **separate Native Befunge programs**:
  `reference/work_counts.b98`, two calls to `reference/save.b98`, against
  `src/interleaved_work_counts.b98`. Python only conducts calls and checks
  output/reversal invariants; Python is not a calendar oracle.
* Reject sixteen malformed input types (invalid sign, negative zero,
  explicit +/- lexical signs, garbage, missing/extra fields). Count one
  production Native execution for each negative input. Four independently
  uploaded Native receipts go to a fifth fail-closed audit job.
* The independent Python 3 receipt auditor checks full pair/negative-set
  identity, frozen SHA provenance, native output shape, direction reversal,
  equal-day rules and six forged-report rejections.

Expected overall finite coverage if the Native workflow succeeds:
**256 valid production runs + 768 independent Befunge reference calls +
16 negative Native runs = 1,040 native process executions**. The exact
number assumes each of 256 valid orientations has 3 independent reference
calls; do not claim these runs before an actual GitHub Actions PASS.

This deliberately does **not** claim full production functional correctness,
independence of all 49 reference helpers, whole-program ownership,
complete geometry, or permission for Stage 2 / branch merge. A Native FAIL
should be retained as an actionable defect, not masked by changing expected
output or weakening checks.
