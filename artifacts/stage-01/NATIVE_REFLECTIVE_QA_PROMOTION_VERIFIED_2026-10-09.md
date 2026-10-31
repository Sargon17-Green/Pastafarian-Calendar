# Stage 1 QA promotion — verified Native reflective dual node (2026-10-09)

This is a **QA-only** history entry, not authorization to merge PR #17 or begin Stage 2.

- Exact QA promotion commit: `dcadb5d16f725d2911e67843427f4fbf876da7fd`.
- [26/26 successful Native CI jobs](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37911217309) on that exact commit.
- Production QA executable: `src/interleaved_work_counts.b98`, Git blob `8f2cf8afef61818244747582fe7c20a74ee18943`.
- Prior production archived byte-for-byte at `qa/interleaved_work_counts_pre_reflective_production.b98`, Git blob `44c5c33f4fe88ad82b8172235f18ad5d5175e517`.
- Candidate-to-prior difference: exactly five Befunge-98 source-map cells in the 1531-by-2016 space. The native program, not a Python calendar implementation, performs the computation.
- 17 Native diverse traces (14 valid and 3 malformed numeric cases) verify exact independent Befunge reference parity and mutable-code read/write provenance.
- Real Native geometry after promotion: 11 distinct route fingerprints, 4 cross-input forks, 3 joins, 1 dual merge-and-fork. In 11 of 17 inputs the `(958,1324)` pivot receives two actual incoming edges and emits two outgoing edges in one execution.
- The QA source executes `r` on those 11 upper routes. The one-cell `r` removal causes an 8-second bounded noncompletion with exit 124; the byte-identical sham succeeds. This is evidence of causal dependence, **not proof of infinite nontermination**.
- Overlapping Native Program p/g write ownership, injected fault, explicit same-Program reset, and independent trace replay passed before promotion and were repeated on the candidate bytes.
- Native test-only negative controls added after the promotion require forged code/trace/manifest evidence to be rejected. They do not expand final acceptance by themselves.

Outstanding Stage-1 requirements are separate: real computational `w` and `_` execution, meaningful `{ } u` stack-stack execution and ownership, further recursive entanglement, full formal semantic-state audit, and independent functional/geometric acceptance. Fingerprints and concurrency remain explicitly scoped. **FUNCTIONAL_QA_PASS=NO; GEOMETRIC_SPAGHETTI_QA_PASS=NO; LAST_COMPLETED_STAGE=0.** The canonical language branch and main must not be changed or merged.
