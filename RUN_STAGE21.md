# Stage21 — visible-drop update of six bowls (bounded design contract)

PROJECT_ID: `PC-BRANCH-FALSE-ARABIC` · BRANCH: `FALSE+العربية` · 2026-11-23

**Status: DESIGN_CONTRACT_ONLY.** Stage20 remains the last accepted stage (`ACCEPTED_BOUNDED`). Stage21 production, Native, CI and acceptance have NOT occurred.

## Normative evidence and adaptation

Pinned normative source: `test/normative_reference.false`, Git blob `3e9acc012bedf83294a6ec3cccb081a069556b5b`, **operation 55 at lines 383–423**. Its declared input is `[bowls,visible,stones]` and the output is `[updatedBowls,orderAt46]`. It follows Stage20 reference op54, whose independently implemented production operation is op37. Stage21 would append independent production **op38**, without altering accepted op0–37 or copying the normative implementation. The normative source uses immutable linked sequences; the authorized production representation uses newly allocated direct tables, so byte-level identity with the reference is not the criterion.

The transition to a routine next stage is authorized by `STAGE_TRANSITION_POLICY=ROUTINE_STAGE_ADVANCE_REQUIRES_NO_SEPARATE_USER_APPROVAL` in `DEVELOPMENT_STAGE.md`. This design changes no protected branch, release, policy, or existing Native gate.

## Input and output contract

`M = 2^127 - 1`. Argument is a fully allocated three-cell physical tuple of valid handles to:
- `bowls = [6, B1, B2, B3, B4, B5, B6]`: six allocated canonical BigInt handles with values in `1..M`.
- `visible = [46, D1, ..., D46]`: 46 allocated canonical BigInt handles with values in `1..M`.
- `stones = [46, R1, ..., R46]`: 46 valid row handles, each row `Ru = [5, S(u,1), ..., S(u,5)]` with five allocated canonical BigInt handles in `1..M`.

Proposed output is a newly allocated direct record `[2, outBowls, outOrder]`; `outBowls=[6,B1',...,B6']` holds six canonical BigInt handles, and `outOrder=[6,o1,...,o6]` holds the six distinct small integers from the **46th** drop's lexicographic order. Every input cell and input BigInt digit must remain unchanged. Pointer identities of newly allocated output handles need not match across executions; values must be deterministic.

An allocated canonical Base512 BigInt uses sign `+1` for positive values, digit count at least one, base-512 little-endian limbs in `0..511`, no redundant highest zero limb. The bounds above are the domain of the bounded production contract, not a claim that normative op55 rejects all other values.

## Complete independent mathematical specification

For positive `x`, define `SAVE(x)=1+((x-1) mod M)` using an exact nonnegative remainder. It maps the interval of positive multiples `M,2M,...` to `M`; `SAVE(M+1)=1`.

For every drop `u=1..46`, read `t=Du` and compute `rank(u)=1+((t-1) mod 720)`. Let `O[1..6]` be the lexicographically ranked permutation of IDs `1..6` (rank is 1-based), and `P[b]` its inverse position. Define `K=[1,2,3,4,5,1]`, as returned by normative constant table index 16.

Using only the *old* six bowl values, compute six auxiliary quantities indexed by order position:

`A[p]=SAVE(t*t + B[O[p]]*S(u,p) + u*(2p+1))` for `p=1,2,3`, and `A[p]=2` for `p=4,5,6`.

Then, for each bowl ID `b=1..6`, let `p=P[b]`, `L=B[1+((p+4) mod 6)]`, `R=B[1+(p mod 6)]` and compute

`N[b]=SAVE(B[b]^2 + 2L + 3R + A[p] + t + S(u,K[p]) + 5LR + u*p)`.

All six `N[b]` must be computed from the **same old snapshot**; only then replace `B=N`. No per-bowl in-place mutation is equivalent to the normative operation. At the end return `B` and the `O` calculated for `u=46`. The distinction between bowl ID `b` and its position `p` is essential: neighbors and the stone-type lookup use position `p`, whereas `B[b]` uses bowl ID.

### Independently hand-computable witness

For `B=[1,1,1,1,1,1]`, all `D[u]=1`, all stones equal to 1 and `u=1`, the order is `[1,2,3,4,5,6]`, the auxiliaries are `[5,7,9,2,2,2]` and the simultaneous new bowls are `[19,22,25,19,20,21]`. This witness was calculated independently from the algebra; it verifies the first transition only, **not** any completed 46-drop Native execution.

## Independent oracle and measurable quality gates

Prepare a stand-alone mathematical oracle without imports from production code, the normative interpreter or other language branches. Use two independently organized evaluation paths: one iterating bowl IDs and using exact integer modulo, the other iterating positions and using Mersenne folding `x mod M = ((x & M) + (x >> 127)) mod M` with repeated folding as needed. Separately generate all 720 lexicographic permutations and cross-check factoradic unranking.

**Design QA target, not yet executed:** 13 boundary/structure anchors plus 384 deterministic seeded cases, each with all 46 transitions; this amounts to 397 cases, 18,262 transitions, and 109,572 individual bowl-value comparisons. Check each of the 109,572 results is in `1..M`, order-at-46 is a permutation and equals `rank(D46)`, input immutability, deterministic replays, and `SAVE(M)` / `SAVE(M+1)`. Check off-by-one ranks `1,720,721`, very small/large bowl values, all-ones witness, and position/bowl-ID asymmetries.

Require at least these **semantic** negative controls: bowls header 5/7, visible header 45/47, stones header 45/47, an individual stones row header 4/6, zero/negative/out-of-range BigInt, and corrupted digit/sign metadata. Specify observable diagnostic markers with exit!=0 when creating the production fixtures. Mutation controls must show actual numeric disagreement (swap neighbors, use bowl ID instead of order position, omit the `5LR` term, alter `2p+1`, and omit an auxiliary stone factor); a shared parser fault is **not** a successful mutation rejection. Test that an independently corrupted expected numeric result and a corrupted stdout marker are rejected by the offline auditor.

## Native and acceptance gates

Only after this contract is documented, implement an append-only op38 and source-pinned test harness. Before CI, measure native runtime for short and full paths; set explicit elapsed-time and memory thresholds based on those measurements. The Native suite must exercise at least three full 46-drop paths, selected intermediate states, all six final Base512 values, `orderAt46`, input byte/handle immutability, replays, semantic negative controls and genuine mutant rejections.

Pin the *original* FALSE interpreter to `eb3135565a8670cced3f6bbca4dbf7b014c45634`. No duplicate dispatch against an already checked source SHA. Stage21 acceptance is conditioned on completed source-locked run/job, logs with exact stdout/stderr/exit codes, downloaded artifact with verified SHA-256 and ZIP CRC, matched Git source blobs and an independent offline auditor which recomputes from serialized inputs and rejects corrupted evidence. Design QA, code/static QA, Native success, and full bounded stage acceptance must be reported separately.

**Excluded:** invalid or unallocated physical pointers, truncated allocations, corrupt heap and memory-unsafe aliasing. An interpreter with no allocation-extent metadata cannot prove safe dereference of these. Do not call unassessed behavior PASS or expected-red. No main/merge, release or Windows execution is part of this design step.

## NEXT

Build and execute the standalone mathematical oracle for this contract, persist its exact source and result report, and only then implement independent production op38 and Native fixtures. Stage20 remains `ACCEPTED_BOUNDED`; Stage21 remains `DESIGN_ONLY_NOT_ACCEPTED`.
