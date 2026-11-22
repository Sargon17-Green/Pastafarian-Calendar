# Logo+Ido Stage 2 Appendix-A — general wide selection (k >= 3)

PROJECT_ID: PC-BRANCH-LOGO-IDO
QA_BRANCH: qa/logo-ido-stage2-wide-general-k3plus-20261122
BASE_QA_HEAD: 1fea4a9a2b1f595151411b1f3457546deb8bd2e4
CANONICAL_SOURCE_SHA: ad001c6aeeb6c758f5004b206a656fec5d6fc403
STATUS: QA_CONTRACT_AND_INDEPENDENT_HOST_ORACLE_ONLY
PRODUCTION_CHANGED: NO
NATIVE: NOT_RUN
STAGE2_ACCEPTED: NO
LAST_COMPLETED_STAGE: 1

## 1. Scope and frozen reference

This contract defines the general Appendix-A wide-selection domain N > M^2, where the minimal digit width k is at least 3. It does not implement or promote production code, change the canonical Logo+Ido branch, complete Stage 2, or define downstream unranking/year/calendar operations.

The in-repository test-only normative reference is test/normative_reference.logo, functions nr.smallest.power, nr.wide.initial, nr.choose.wide, nr.choose.wide.walk and nr.choose.rank (source blob 625171ecd5fd93fb8381686f2b6b29ed3649cf). Those functions are evidence of the mathematical contract only. Neither the future production implementation nor the independent Python oracle may call or import them.

The existing isolated two-digit QA contract and Native acceptance remain unchanged:
- WIDE2 QA branch: qa/logo-ido-stage2-wide-selection-audit-20261121
- accepted WIDE2 SHA: 1fea4a9a2b1f595151411b1f3457546deb8bd2e4
- Native run 44947067097, job 136976590289, completed/success, exact head SHA above; 112 cases / 400 checks and Native PASS markers.
- Names Lock run 44947067066, job 136976589889, completed/success on the same SHA.
- WIDE2 artifact 14723548134, digest sha256:18c8614e84a53cf41f0c799dada7d63cbbf412d622781ca2bc72a7019121bf51. The downloaded ZIP digest was independently recomputed and matched; its commit file, source manifest, host log and Native log were inspected.
These are bounded k=2 QA results only. They are not evidence for k >= 3 and do not constitute Stage 2 acceptance. The accepted runs are not to be dispatched again on their original SHA.

## 2. Exact input/output contract

Let M = 2^127 - 1, represented by the existing exact-BI library in base 10000.

Proposed pure QA reporter: monster.stage02.choose.wide.general :stream :N.

Valid input:
- stream is exactly a two-element Logo list [firstValue step].
- firstValue is a canonical positive exact BI integer with 1 <= firstValue <= M.
- step is exactly the small integer +1 or -1.
- N is a canonical positive exact BI integer with N > M^2. No fixed upper bound on N is introduced by this contract.
- k is derived, not supplied: the least positive integer for which S = M^k >= N. Consequently k >= 3.

Define the digit stream without an index-based helper:
- x0 = firstValue.
- For each j >= 0, x(j+1) is x(j)+step, wrapping M to 1 for +1 and 1 to M for -1.
- Generate exactly k digits x0,...,x(k-1).

Construct the one-based initial wide value:
W = 1 + sum from j=0 to k-1 of (xj - 1) * M^j.

Define:
- S = M^k.
- L = floor(S / N) * N = S - (S mod N).
- The accepted candidate interval is [1,L]; the rejected suffix is (L,S].

Return a canonical exact-BI rank in [1,N]:
- If W <= L: R = 1 + ((W - 1) mod N).
- If W > L and step = +1: R = 1.
- If W > L and step = -1: R = N.

Invalid bounded inputs return [] without error, global mutation, context mutation, or floating-point conversion. The guard promise covers malformed stream shape, noncanonical BI values, out-of-range firstValue/N, and invalid step. As in prior Stage-2 contracts, arbitrary corrupted BI-internal memory that cannot be safely inspected is outside the promise.

## 3. Proof and k=2 compatibility

Because L is a multiple of N, every candidate in [1,L] is accepted and every candidate in (L,S] is rejected. If W is rejected, the prescribed candidate walk moves by exactly step on the cyclic interval [1,S]. A +1 walk wraps from S to 1, which is the first accepted point and has rank 1. A -1 walk reaches L first; since L is a multiple of N, its rank is 1 + ((L-1) mod N) = N. Thus the rejection gap need not be enumerated by production code.

For M < N <= M^2, the minimal width is k=2. Then x1 is the single next stream value and:
W = 1 + (firstValue-1) + M*(x1-1)
  = firstValue + M*(x1-1).
This is exactly the already accepted two-digit WIDE2 contract. The new k>=3 helper must not change the existing two-digit reporter. The independent host oracle includes a separately written legacy k=2 target and compares it with the general formula over the complete prior finite modulus matrix and additional full-M vectors.

## 4. Important implementation boundary: D20 index cap

The accepted D20 production reporter monster.stage02.answer.at is explicitly bounded to indices 0..31. A general k>=3 implementation must not call that reporter for j >= 32 and must not silently inherit its cap.

The proposed general helper generates x(j) with a local exact-BI recurrence: increment/decrement by one and wrap at 1/M. Each digit remains in [1,M]. The implementation must never convert BI values to Logo floating-point numbers. It must not enumerate the rejected suffix; only the independent finite oracle does so.

## 5. Exact-BI complexity plan

The existing M constant occupies 10 base-10000 limbs. If k is the minimal width:
- S is O(k) base-10000 limbs.
- Building S by repeated multiplication by the fixed 10-limb M costs O(k) limb work per multiplication and O(k^2) total limb work.
- Building W by k digit/weight iterations, where the weight grows linearly in limb length and each digit is bounded by M, is O(k^2) total limb work.
- The existing exact long division computes S mod N by processing O(k) limbs; each quotient digit uses a bounded 14-step binary search and O(k)-scale exact comparisons/multiplications. Its expected implementation cost is O(k^2) limb work.
- Total planned arithmetic is O(k^2) base-10000 limb work and O(k) limb storage, excluding Logo call/stack overhead.
- The production rejection shortcut is O(1) after W and L have been computed. It must not walk a rejection gap that can be as large as N-1.
- Recursion/stack behavior is a Native measurement item. The k=32, 33 and 64 vectors deliberately exceed the D20 index cap; they do not prove unlimited runtime capacity.

## 6. Independent finite enumerative oracle

QA-only file: qa/logo_stage2_wide_general_host_oracle.py.

It imports no project code and calls no Logo function, normative reference, previous WIDE2 oracle or previous fixture. It contains two separate paths:
1. The finite oracle generates each stream digit by explicit +1/-1 stepping, assembles the digits high-to-low, and then walks the rejected candidate interval one unit at a time until the first accepted candidate.
2. The mathematical target independently computes each digit from the closed-form index, constructs W, and applies the direct boundary result.

The k=2 path is additionally compared with a separately written legacy two-digit equation.

Observed local Python result:
- Total finite exhaustive differential cases: 42,748.
- k=2 compatibility: 3,340 cases.
- k=3: 14,332 cases.
- k=4: 14,852 cases.
- k=5: 7,180 cases.
- k=6: 3,044 cases.
- Rejected initial candidates: 8,672 (4,549 positive-step; 4,123 negative-step).
- Maximum explicitly enumerated rejection steps in the finite matrix: 570.
- Full production-modulus vectors: 30, including 4 full-M k=2 compatibility vectors and k=3,4,5,32,33,64 boundaries/rejection directions.
- Python-level invalid-input model cases: 14.
- Markers: WIDE_GENERAL_HOST_ORACLE=PASS; WIDE_GENERAL_NATIVE=NOT_RUN.

The Python guard model is not evidence that Logo rejects malformed BI representations. The Native fixture must test the actual Logo boundary independently.

## 7. Future pinned Native/source-lock gate (design only)

No Native workflow or production source is added by this contract commit. After the QA implementation and fixture generator exist, the gate shall:
1. Run only on a new commit of an isolated QA branch and assert exact branch name and git rev-parse HEAD == GITHUB_SHA.
2. Pin headless UCBLogo 6.2.5 at upstream commit a0215433f07384e4c42fe247525867f11e6f32f7.
3. Verify unchanged dependency Git blobs before execution:
   - src/exact_integer.logo: f2c1a8aa5822423402cd5825255891183f0fc83c
   - src/stage02_context.logo: f8451359e6ddcf38bb823ff2b78c9acbfbcf7830
   - src/stage02_answer_at.logo: f0951ba68a191667208b2a2b99b386c5336e49c2
   - src/stage02_choose_wide.logo: 8fb2dc47c827b8ccd8fa6fdd817b9fa088c51013
   - test/normative_reference.logo: 625171ecd5fd93fb8381686f2b2f6b29ed3649cf
   - CANONICAL_NAMES_LOCK.sha256: 0d5b3dec0b01551b1304ee7104d08a57aa1f440b
   The future general production source, Native test harness, fixture generator, contract and workflow must also be locked by their exact Git blob IDs.
4. Generate Native expected values using Python integers only. Neither the production reporter nor nr.choose.wide may generate expected values.
5. Target 48 cases / 138 assertions: 30 valid large-M vectors (four k=2 compatibility probes plus 26 k>=3 boundary/rejection vectors) with four assertions each (canonical BI shape, exact expected rank, range, deterministic repeated call), and 18 invalid cases with exact [] results (14 public input guards plus four malformed BI-structure cases such as empty digits, invalid sign, out-of-base digit and noncanonical trailing zero).
6. Use a bounded Native process timeout of 1200 seconds and a CI job timeout of 30 minutes. Require exact full-line case/check markers, a unique Native PASS marker, zero exit status and absence of failure text. Preserve commit SHA, source-lock manifest, generated fixture, host log and Native log in one artifact and verify its digest against GitHub.
7. Verify the completed Native run, job, logs, exact SHA and artifact independently. A completed/success job without the Native markers is not Native PASS. Queued/in_progress is neither PASS nor blocker. A same-SHA Names Lock run is also required; do not manually duplicate a naturally triggered run.

The current WIDE2 Native run 44947067097 is already accepted at its exact SHA and is not to be rerun on that SHA. The new general gate is not dispatched by this design-only commit.

## 8. Non-destructive boundaries and next action

- Keep the accepted WIDE2 branch unchanged.
- Keep this k>=3 work on qa/logo-ido-stage2-wide-general-k3plus-20261122.
- Canonical Logo+Ido HEAD remains ad001c6aeeb6c758f5004b206a656fec5d6fc403.
- No canonical promotion, main, merge, publication or Stage-2 completion.
- LAST_COMPLETED_STAGE remains 1.
- Next: implement only monster.stage02.choose.wide.general on this QA branch, add the Native fixture generator and source-locked workflow, then verify the exact new SHA. Do not change the accepted k=2 reporter or D20's 0..31 contract.

## 9. Diagnostic update after exact-SHA timeout (2026-11-22)

Full-k Native run 44960408541 / job 137017741464 completed FAILURE on c4371498a7bae80f3fae1dcf6a31aa2a08f1c6ef. Independent Python host enumerator (42,748 cases), fixture generation (48 / 138 planned checks), and pinned UCBLogo build passed. Native timed out after 1,200 seconds (exit 124); artifact 14729549954, ZIP SHA-256 25a0a2c043cd5dba9d8641f51e0126443e332cac39345e224f559445b5fcb4b7, contains a zero-byte Native log. No individual Native case or general-k PASS can be inferred. Generated invalid fixtures also referenced `nr.M`, but the normative reference was not loaded.

This diagnostic-only revision initializes independent exact-BI `WIDE.M`, replaces uninitialized `nr.M`, emits boot and case-start markers, and limits Native to four accepted-interface k=2 probes and four k=3 large-M probes plus 18 invalid guards: 26 cases / 50 checks; 300-second bounded runtime. This is NOT the full general-k acceptance gate, and a diagnostic PASS cannot be promoted to all-k PASS. Wider k=4,5,6,32,33,64 Native vectors are still unverified; keep Stage2 incomplete. Updated fixture-generator Git blob: 4e5eef7d8f8558579bf9a466adf7d126212e2bc2.
