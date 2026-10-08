# Stage 1 — executed arithmetic k+ detour (2026-10-09)

**Scope:** QA-only branch `qa-befunge98-stage1-order-isolation-20261008`, PR #17.
**Canonical `Befunge+Кыргызча` unchanged**, main unchanged. No Stage 2.

## Actual production change — constrained and measured

The QA-branch production blob `src/interleaved_work_counts.b98` is
`76642dd04022f294cdd036bf0ad1f86455edbd95`. This reuses the exact
Befunge source previously executed as the independent test-only
`qa/interleaved_work_counts_kplus_2d_candidate.b98`. It does not
replace the calendrical algorithm, introduce a Python computation
fallback, or edit the canonical implementation branch.

The only intentional added production circuit relative to the frozen
`qa/interleaved_work_counts_lexical_candidate.b98` is:
- `(1470,100)` original `+` becomes executable down-turn `v`;
  original executable `x` at `(1471,100)` is retained.
- Row 101 starting at x=1470 executes the native circuit
  `>1-11k+0c-01-x`, with the native repeat-next operator `k`
  at `(1475,101)`.
- The native `k` execution and ordinary following `+` are both
  meaningful: the first restores an arithmetically decremented operand
  and the second performs the original addition. The vector `x`
  returns to the preserved dynamic `x`, which must follow its original
  outgoing vector and reach `(1430,1335)` for the traced cases.
- The QA source-map guard checks that no other Funge-space code bytes
  changed outside this circuit. There is no blanket waiver of the
  older scanner's byte-exact source and post-handoff trace parity.

## Native evidence, reproducible

- [Run 37849519616](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37849519616):
  `native-kplus-2d-arithmetic-candidate` passed **5/5** exact
  native step-order, stack-depth, outgoing-vector, rejoin-location and
  independent Befunge-reference numerical parity cases.
- [Run 37849832174](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37849832174):
  **10/10** mixed signed, reverse, foundation, huge and invalid Native
  differential cases passed. The strong 5-case route proof was retained,
  not weakened.
- [Run 37850493676](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37850493676):
  promoted QA production Native write audit and geometry evidence
  passed. Trace evidence logged 25,996 post-handoff steps in the valid
  case and 11,916 in the invalid case, and the Native `k` location and
  executed source-coordinate delta were confirmed. Unmodified scanner
  remains compared byte-for-byte and trace-for-trace to its old
  baseline, independently of the new QA production.
- [Run 37850690123](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37850690123):
  the `native-kplus-2d-arithmetic-candidate` job passed the 10-case
  differential and **2/2 sham-controlled one-cell counterfactuals**.
  The exact source-copy sham retained output. Replacing only the
  actually executed `k` at (1475,101) with `0` caused the native
  executable to exceed the 8-second bound (exit 124) for both
  `zero_equal` and `foundation_cross`. This proves observed
  dependence of termination **within the stated bound**, not numerical
  inequality of eventual outputs.
  This job's PASS is narrower than a completed full workflow PASS;
  inspect all 16 jobs on the exact Git HEAD before any further gate
  decision.

The expected output is always drawn from *independent native Befunge*
references. Python harnesses operate PyFunge, compare outputs,
trace executed code and test mutants only.

## Still OPEN

`CURRENT_STAGE=1` and `LAST_COMPLETED_STAGE=0`. In particular,
`FULL_FUNCTIONAL_QA_PASS=NO`,
`GEOMETRIC_SPAGHETTI_QA_PASS=NO`, and the new
architecture's final semantic-state-ownership audit is still OPEN.

An executed `k`-assisted arithmetic excursion is an incremental route
dependency. The full input-dependent multi-route crossings, joins,
cycles, self-modifying routing, directional/control operators and
stack-stack semantics required by the Stage-1 spaghetti contract are
**not** demonstrated by this one detour; do not infer Stage-1 or Stage-2
completion, and do not merge PR #17 yet.
