# Stage 1 — verified Native stack-stack QA promotion, 9 October 2026

**Verified on QA only**, no changes to canonical `Befunge+Кыргызча` or `main`, no merge and no Stage 2.

## Exact source
- Active QA production `src/interleaved_work_counts.b98`, Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`; SHA-256 `3e64ba67eaaaf684fef221be33c368527a50a3c986e9f0b63e73ef81b21cdb59`.
- Immutable previous w/_ source `qa/interleaved_work_counts_pre_stack_stack_production.b98`, blob `b6cf50de9ed45376db5fc4ebd003157210dff03b`.
- Independently frozen source `qa/interleaved_work_counts_stack_stack_candidate.b98`, byte-for-byte equal to QA production; **14 precisely mapped Funge-98 cell edits**, 1531 × 2016 source area unchanged.
- Prior reflective, lexical, w and w/_ snapshots and their historical tests remain separately reproducible.

## Exact Native verification
- **31 of 31 GitHub Actions jobs passed** on commit `2d5ab7799c12a33c47f5521a354a096b9c6403ec`, run [37949298574](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37949298574), with all jobs explicitly fetched using GitHub's `per_page=100` to avoid silently dropping the 31st job.
- Independent Native Befunge reference programs agree on all seven output fields for the **17 original cases plus 22 wide signed-domain cases**, including the 10 actual stack-stack detours and 7 bypasses.
- PyFunge executed `{`, `u`, `}` on real computation, with exact opcode, direction, depth, source-map and `p/g` temporal read/write proof. Two-live Program fault injection and three explicit same-Program resets passed.
- Six re-signed hostile Native trace forgeries rejected. Exact-byte sham agrees with reference.
- A single executed `u` removal causes bounded Native noncompletion; do **not** call this a successful output-producing mutant. Additional real Native adjacent-prefix checks show immediate arithmetic TOSS divergence for three valid signed inputs.
- The previous strict `|` gate causal test remains pinned to the archived reflective source.

## Still open
- On current QA production, forcing the opposite `|` operand is causally observable for `foundation_cross` and `mixed_small`, but not for `zero_equal` or `forward_short`. The mixed upstream gate evidence remains OPEN and cannot be promoted to universal causal PASS.
- Full Stage-1 functional acceptance, full geometric spaghetti entanglement, semantic ownership completeness and unsupported interpreter features such as active `t` threading and fingerprints remain outside the proven scope.
- `CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`, `FUNCTIONAL_QA_PASS=NO`, `GEOMETRIC_SPAGHETTI_QA_PASS=NO`. PR #17 remains Draft.

The 31/31 result belongs to the **exact tested commit**. Subsequent worktree/QA documentation commits require their own checks; do not treat any prior success as proof on a later HEAD.

## Additional nested-TOSS/SOSS Native fault coverage

A further independent test interrupts the **same real PyFunge Program immediately after executing `u`**, with the nested stack still open, and proves that another live Native Program can continue independently. The exact same faulted Program is then explicitly reset for three different real Native arithmetic/error input families: lower, upper and invalid upper. Each fresh IP stack/Funge-space is proven distinct, while the frozen interrupted state and the other live Program remain unchanged.

- Native test: `qa/stage1_native_stack_stack_nested_fault_reset.py`
- Result: `NATIVE_STACK_STACK_NESTED_U_OWNERSHIP_AND_3_RESET_PASS`
- **Full 31/31 GitHub Actions PASS**, exact commit `218f2c7d50e91c34ab88704848ec238019822e3f`, run [37950008918](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37950008918).
- This strengthens the ownership evidence but is **not** the final Stage-1 semantic-state acceptance gate. The open `|` issue and deeper architectural requirements are unchanged.
