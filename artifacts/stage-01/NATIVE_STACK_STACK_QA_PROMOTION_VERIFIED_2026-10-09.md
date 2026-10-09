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
