# Native two-VALID-branch w and semantic _ (Stage 1 QA, 9 October 2026)

**QA experiment only**. No canonical merge, no change to `src/`, no Stage 2, and no Stage-1 final gate accepted.

## Frozen implementation

- Base, independently qualified w source: `qa/interleaved_work_counts_w_data_branch_candidate.b98`, Git blob `31807edb2b44b141d2af340555d6e97e63428613`.
- New experimental source: `qa/interleaved_work_counts_w_valid_two_arithmetic_arms_candidate.b98`, Git blob `b6cf50de9ed45376db5fc4ebd003157210dff03b`.
- Exactly 18 byte edits from that base, retaining 1531 by 2016 source coordinates and every source row width.
- Current running QA production remains the earlier reflective version: `src/interleaved_work_counts.b98`, Git blob `8f2cf8afef61818244747582fe7c20a74ee18943`.

## What Native execution proves

- Both valid input subsets pass through the same executed `w` comparator `(951,1332)`. Nine valid examples go right into the upper arithmetic; five valid examples go straight into the lower arithmetic.
- For the lower route a stack sentinel is reconstructed using *Funge-98 code*, then consumed by `_` at `(951,1331)` to select a westward return path. The original lower turn cell `(951,1336)` is executed twice in a single native run, first entering from above and then from below, and exits west/east respectively.
- An upper-route invalid sign also reaches the straight `w` outcome; its empty-stack `_` path turns east to the historical invalid computation, preserving all seven error fields. This fixes the first attempted experiment's invalid-input regression.
- Real PyFunge-98 provides all arithmetic. Python only tests exact code bytes, dispatches signed inputs and inspects Native STEP/READ/WRITE events. 17 original (14 valid, 3 invalid) and 22 wider signed-domain (18 valid, 4 invalid) inputs have complete seven-value parity with the historical w source and independent Befunge native references.
- For **each of all 17 traces**, the complete post-rejoin native instruction/velocity/stack-depth suffix matches the preceding qualified source exactly.
- Removing **one `w` opcode** changes the numeric result with exit status 0 on two independent valid arithmetic inputs (upper and lower). This is stronger than a timeout or source-only claim.
- Two independently authored replay auditors verify the true input-selected edges, 18-cell source map, Funge-space g/p memory lifecycle, no newly introduced mutable scratch-cell collision and both actual dual graph nodes.
- The test-only source also passes the existing native two-live-Program p/g fault injection and 3 explicit same-Program reset experiments.

GitHub Actions evidence: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37918069528 (focused candidate job PASS on its exact head); later CI runs additionally validate the tighter lower-turn stack-depth guard. Refer only to the CI conclusion for an exact commit before asserting a full all-jobs pass.

## Historical diagnostics and still-open gates

An initial 15-cell candidate failed `invalid_big_sign` parity; the corrected 18-cell source retains the historical invalid-upper computation. The initial script also incorrectly used a Python 2 list-comprehension variable that overwrote an index; the source-level Native routing was correct, the harness index was repaired. A second independent auditor's lower turn first-visit stack depth was corrected from 2 to **1**, matching actual Native STEP evidence.

`CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`. Full functional and geometric acceptance remain **OPEN**. Meaningful nested Funge stack-stack `{`, `}`, `u`, additional recursive entanglement and broader state ownership still require proofs. `t` and fingerprint functionality are never treated as proven under disabled interpreter capabilities. No merge to `Befunge+Кыргызча` or `main`.
