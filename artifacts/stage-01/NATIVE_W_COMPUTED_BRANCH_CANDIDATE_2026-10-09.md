# Native w computed arithmetic candidate — 9 October 2026

Scope: QA-only; no Stage-1 acceptance, no canonical merge, no Stage 2.

Frozen Native Befunge-98 candidate: qa/interleaved_work_counts_w_data_branch_candidate.b98.
Git blob 31807edb2b44b141d2af340555d6e97e63428613.
SHA-256 9b1fb027286ca8bf881d9edcd97385843760fc0be48eb83d4c08d1a84c3d739e.
Exact source diff: 28 cells. Grid retained at 1531 x 2016.
QA production continues to use original reflective Git blob 8f2cf8afef61818244747582fe7c20a74ee18943.

## Native proof

- 17 original cases (14 valid, 3 invalid) and 22 additional boundary cases (18 valid, 4 invalid) have seven-field parity with the prior QA production and independent Befunge-only reference programs.
- On real Native traces, executed w at (951,1332) selects 10 right turns, 1 straight route, and is skipped by 6 lower-branch cases.
- The only straight route among the 17 cases is invalid_big_sign; neither w outcome has yet been demonstrated on *different valid inputs*. Avoid falsely claiming fully diverse valid comparisons.
- Replacing exactly the executed w byte by a space changes the numerical output of a valid zero_equal input, and the mutant exits with status zero. This proves observable arithmetic dependence, not merely a timed noncompletion.
- Two independent Python 3 auditors read real Native PyFunge STEP, READ and WRITE trace events, replay the Funge-space lifecycle, verify changed-byte provenance, Funge-space ownership and the original reflective dual node.
- Native two-live-Program overlapping p/g scratch and fault injection, with three explicit same-Program resets, also passed against the exact candidate bytes.

Evidence CI runs: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37913635531 and https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37913951794 . Check completion by exact commit before asserting a fully green workflow.

## Open Stage 1 requirements

Do not promote to QA src without a complete exact-source pin migration, full production Native CI, additional valid-operand diversity review and independent memory proof at the newly promoted head. The input-selected underscore _, meaningful stack-stack { } u, broader recursive spaghetti routing, and final functional/geometric acceptance remain unproved. Fingerprints and threading remain scoped/disabled by the pinned interpreter.

CURRENT_STAGE=1; LAST_COMPLETED_STAGE=0; FULL_FUNCTIONAL_QA_PASS=NO; GEOMETRIC_SPAGHETTI_QA_PASS=NO.
