# QA19 one-cell Native BF98 counterfactuals

The three source x cells are (150,20), (175,38), (396,17).
A program starts from a source-pinned, earlier genuine Native QA13 trace prefix.
The experiment compares a normal unmodified run against two otherwise identical one-cell pointer displacements: execution of the source x, and execution of a neutral z substituted only in temporary program memory.
An independent Befunge oracle verifies the normal baseline.

No counterfactual result establishes reachability under an ordinary unmodified input, absence of dead code, or Stage 1 acceptance. Earlier QA evidence, production source and main remain unchanged.

## Discovery RED and focused remediation (2026-10-21)

First GitHub Actions run 39632473432 was RED at the Native precondition, not at an x opcode. Immutable QA13 witness record 12359187730 selected, for each candidate, an already executed rightward-moving neighboring source 0 with TOSS depth exactly 0 (three targets: 4, 1, 4 candidates). A test-only requirement of two pre-existing operands was therefore overrestrictive. Befunge-98 defines missing pops as zero. Retry now permits the original zero-depth prefix and records implicit-zero underflow explicitly; it does not fabricate stack operands, edit production source, or claim any ordinary route to x. Keep the original RED in the audit trail.

## Verified finite Native QA19 acceptance — 21 October 2026

- First run 39632473432: **RED**, because the discovery precondition incorrectly demanded two materialized stack elements at each existing adjacent Native STEP. Original immutable evidence shows TOSS depth 0 in all selected witness records. The discovery failure is retained; nothing wrong with original PyFunge interpreter or original arithmetic source was demonstrated by that run.
- Remediation at source/QA commit d2ff18c7b556506edf40b509cc636f396ca4e46a correctly permits Befunge-98 implicit-zero underflow, with no fabricated input operands.
- Actual [GitHub Actions run 39632960410](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39632960410) completed SUCCESS. Original receipt artifact 12360526384 was downloaded, and its five files passed ZIP integrity checks.
- The single legitimate input selected in all three cases is the original QA13 case epoch_forward_one. Complete unmodified control in each case terminated with the same seven-field independent native oracle output in exactly 19,713 interpreter steps.
- At exact frozen real-prefix STEP ticks 1979, 9608, and 1859, the IP was temporarily displaced by one Manhattan cell to original source x cells (150,20), (175,38), (396,17) respectively. Those source bytes were unmodified and executed as x (not stringmode). In each case the empty TOSS yields two implicit zero arguments, and the real x leaves delta (0,0) while z under identical pre-state yields (1,0).
- The z substitution happened **only in the disposable counterfactual Program Funge-space**, never in the repository source file; production Git blob remains 560d6aa5807a7f766213a33835cce85eab0fa40c. Three new x counterfactuals, three matched z controls and nine independently invoked Native Befunge reference subprocesses are recorded.
- Native receipt sha256 49e496a0a232de62b6661648a6b8a7aa48fb85c611879050c911653dfad0686b; independent audit sha256 33d987a96b8b9944aa60aea5ba53df8d440993b2955f90e2546705ebdf3e62dc.
- **Critical limitation:** artificial one-cell forced relocation proves source-opcode conditional behavior, NOT natural reachability under any legal calendar input, not mathematical necessity, not dead code or full Stage 1 geometry.
- QA19 has finished its *narrow, forced-execution* scope; the next separate task is direct input-reachable geometric/causal coverage, ideally guided by constraint analysis rather than simply sampling more valid inputs.

CURRENT_STAGE=1, LAST_COMPLETED_STAGE=0, GEOMETRIC_SPAGHETTI_QA_PASS=NO, FULL_FUNCTIONAL_QA_PASS=NO. No production change, canonical merge, PR #17 merge or Stage 2.
