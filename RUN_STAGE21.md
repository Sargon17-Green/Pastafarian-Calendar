# Stage21 — visible-drop update of six bowls (bounded design contract)

PROJECT_ID: `PC-BRANCH-FALSE-ARABIC` · BRANCH: `FALSE+العربية` · 2026-11-23

**Current status (2026-11-25): CORRECTED_OP38_CANDIDATE; NOT_ACCEPTED.** Stage20 remains the last accepted stage (`ACCEPTED_BOUNDED`). Original-runtime Stage21 measurement is prepared; no Native result or acceptance is claimed. Historical design and QA entries below are preserved as history; the neighbor correction supersedes the original formula.

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

Then, for each bowl ID `b=1..6`, let `p=P[b]`, `L=B[O[1+((p+4) mod 6)]]`, `R=B[O[1+(p mod 6)]]` and compute

`N[b]=SAVE(B[b]^2 + 2L + 3R + A[p] + t + S(u,K[p]) + 5LR + u*p)`.

All six `N[b]` must be computed from the **same old snapshot**; only then replace `B=N`. No per-bowl in-place mutation is equivalent to the normative operation. At the end return `B` and the `O` calculated for `u=46`. The distinction between bowl ID `b` and its position `p` is essential: neighbor positions must be mapped through the permutation `O` to bowl IDs before reading `B`; the stone-type lookup uses position `p` directly, whereas `B[b]` uses bowl ID.

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

## Mathematical oracle QA execution — 2026-11-23

Two independently arranged evaluations were executed in a standalone JavaScript V8 environment: bowl-ID/factoradic/BigInt remainder vs. order-position/recursive enumeration/Mersenne folding. Exact executable source: `tools/stage21_bounded_independent_math_oracle.mjs`; result JSON: `evidence/stage21_bounded_math_qa_2026-11-23.json`.

The 13 deterministic anchors and 384 seeded full 46-drop cases agreed: 397 inputs, 18,262 transitions, 109,572 bowl comparisons and positive-range checks, 109,572 canonical Base512 encode/decode roundtrips, 397 input-immutability and final-order checks, three full replays and all 720 factoradic/permutation cross-checks. First-drop hand witness confirmed `[19,22,25,19,20,21]`. Twelve malformed semantic inputs, eight malformed canonical BigInt representations, five actual numeric mutants, one corrupted numeric expected result and one corrupted output marker were rejected. The reproducibility checksum is a **noncryptographic** rolling digest modulo `2^64`, `0x56ee1bf9c94c2ead`; it is not SHA-256, FNV-1a, or artifact-integrity proof.

QA source and result were read back from their Git blobs. This is **mathematical/design QA only**, not a Node.js or original-interpreter Native execution, CI result, new FALSE op38, differential runtime acceptance, or Stage21 acceptance. Stage20 is still the last `ACCEPTED_BOUNDED` stage. Physical invalid pointers/truncated allocations stay unassessed.

**NEXT:** Independently implement append-only FALSE production op38 based on the bounded contract; add source-pinned positive/negative Native fixtures and CI; only then perform an independent ZIP/source/math audit and decide Stage21 acceptance. No main/merge.


## 2026-11-25 — source-level correction and diagnostic preparation

Normative op55 (blob `3e9acc012bedf83294a6ec3cccb081a069556b5b`, lines 383–423) explicitly maps both neighboring positions through the current order using seqAt before reading the old bowl values. The earlier design and both old oracle paths omitted this mapping. Agreement between those paths did not establish normative correctness. The original 2026-11-23 math QA report remains historical and is superseded for neighbor semantics; do not reuse its numerical expectations.

Counterexample: initial bowls [2,3,5,7,11,13], first visible drop 720, stones [2,3,5,7,11], order [6,5,4,3,2,1]. Correct first transition is [974,813,886,519531,519786,519468]; the previous erroneous formula gave [872,1255,1076,519351,519353,519551]. The identity-order all-ones witness remains [19,22,25,19,20,21].

Append-only op38 candidate commit `b7a909b4ac323c5f7e46fba1b6be81d2ba54c4ff` was corrected at `c260b2058c1240e91df8df49fd0483bf7e939b9c` (production blob `e9cf5c3d6933aabf23176ea208baf2a1291a7dfd`); accepted op0–37 unchanged. Corrected executable QA `tools/stage21_corrected_neighbor_oracle.mjs` and report `evidence/stage21_corrected_neighbor_math_qa_2026-11-25.json` were read back from commit `c3909c68723a8a78783d8cce36962fc65f572e5b`. Executed in V8: 397 full cases, 18,262 drops, 109,572 numeric comparisons and Base512 roundtrips, 720 order cross-checks, one full replay, six genuine numeric mutation witnesses (including the actual old-contract defect), noncryptographic digest 0x945a235052e22203. This does not establish original-runtime correctness; the earlier invalid-domain QA is not represented as newly rerun.

The diagnostic harness `tools/stage21_native_diagnostic.py` (commit `4dd600de607e8c858d23dd6189789ba69c69377e`) generates complete allocated Python-integer fixtures for identity, reverse and boundary inputs, exact output and input-cell assertions, and prepares invalid-record fixture construction. The first measurement uses an explicitly instrumented one-drop prefix and then an unmodified full 46-drop identity-input program, each in a separate bounded original-interpreter process. Caps: 2 GiB address space, 180 s per short case, 600 s for the full case; these are conservative diagnostic limits, not measured acceptance thresholds. If any diagnostic fails, preserve its logs and stop the sequence. Run short and full measurement in a separate source-pinned CI diagnostic because local original-interpreter execution was not available in this session. No stage acceptance, no full Native gate, no claims of physical invalid-pointer safety, no merge/main.

NEXT: inspect the diagnostic run only after completion (job/log/exit/artifact/source SHA), diagnose any actual failure or resource pressure, and use observed measurements to establish full Native limits and run at least three independent full paths, intermediate probes, replay, semantic invalids and genuine numeric mutations. Independent offline source/artifact/math audit remains mandatory.
