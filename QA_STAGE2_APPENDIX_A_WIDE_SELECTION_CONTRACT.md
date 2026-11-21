# Logo+Ido — Stage2 Appendix-A wide-selection audit (two digits only)

PROJECT_ID: PC-BRANCH-LOGO-IDO
QA_BRANCH: qa/logo-ido-stage2-wide-selection-audit-20261121
CANONICAL_SOURCE_SHA: ad001c6aeeb6c758f5004b206a656fec5d6fc403
STATUS: QA_CONTRACT_AND_INDEPENDENT_HOST_MODEL_ONLY
NATIVE: NOT_RUN
STAGE2_ACCEPTED: NO
PRODUCTION_CHANGED: NO

## Why this boundary follows the accepted D20/D21 work

D20 supports exact stream indexing at k=0..31; D21 covers unrestricted N in [1,M] with M=2^127-1. The isolated D20/D21 shared-stream gate passed on QA commit 33eadd49bc5f5255c952591efaa6132e2d5bb7fc:
run 44928238825 / job 136918961676, genuine UCBLogo 154 cases and 1,094 checks, Python host oracle 150 valid + 4 invalid, artifact 14717362520 SHA-256 34f706b95ef01040529a224ec15896facda406f28971f062e39f1061f471cc96; Names Lock run 44928238647 / job 136918960895 completed success, same SHA. The accepted QA branch and canonical source HEAD remain unchanged.

The next distinct Appendix-A selection family in the in-repository normative reference is choose.wide for N > M, followed by rank dispatch and the separate unranking, year, cutlet, and month operations. This document defines a **bounded two-digit subdomain**, not all wide selection and not a new development stage. No source or fixtures were copied from another language branch.

## Proposed bounded reporter contract, NOT yet implemented

Potential pure Logo reporter: monster.stage02.choose.wide :stream :N.

- Input stream is exactly [firstValue,step], firstValue a canonical exact BI in [1,M], step exactly +1 or -1.
- N is a canonical exact BI with M < N <= M^2. This strictly selects two digits. Invalid stream/BI/range returns [] without mutation or error. Arbitrary malformed BI-internal memory is outside the guard promise.
- Define x0=firstValue, x1 the next exact cyclic ±1 stream element in [1,M].
- Space S=M^2; initial wide element W=1+(x0-1)+M*(x1-1), always 1<=W<=S.
- Acceptance threshold L=floor(S/N)*N. Inspect W; if W<=L return 1+((W-1) mod N).
- If W>L, this rejected region is exactly the single suffix (L,S]. Continue the Appendix-A wide walk by ±1 around 1..S. A +1 walk reaches the next accepted point at 1 (rank 1), a -1 walk at L (rank N). Production must derive this without enumerating a potentially enormous rejection gap.
- Output is one canonical exact BI rank in [1,N]. Do not use Logo floating point for BI. This contract does **not** establish k>=3, N>M^2, arbitrary-wide dispatch, names unranking, or a full date.

## Independently executable host model

The QA-only file qa/logo_stage2_wide_selection_host_oracle.py uses a digit-by-digit ±1 walker and then directly enumerates acceptance on small modulus circles. No production Logo reporter or normative reference function is called. A separately coded mathematical fast-result function is compared to this exhaustive walker. The host code is reproducible with:

    python3 qa/logo_stage2_wide_selection_host_oracle.py

Observed local Python result (2026-11-21):
- 3,340 exhaustively enumerated cases at moduli {3,4,5,7,11}, all matching;
- 669 cases with at least one rejected candidate (341 positive, 328 negative);
- five fixed exact 127-bit modulus vectors, including the two rejection directions;
- WIDE_HOST_MATHEMATICAL_ORACLE=PASS;
- WIDE_LOGO_NATIVE=NOT_RUN.

The five full-M vectors check derived boundary properties only, **not** an independent long-gap Native differential. Local host PASS is not source, CI, or Native acceptance for a future Logo implementation.

## Requirements for a future implementation gate (not yet satisfied)

1. Implement only the bounded two-digit Logo reporter and validation in a QA branch. Do not alter canonical source, Stage1, main, or Stage2 acceptance metadata.
2. Source-lock the four D20/D21 dependencies and the new QA production file by Git blob; verify exact checkout SHA and branch before the run.
3. Generate synthetic stream cases from the independent Python oracle, including both directions, wraparound, N=M+1, N=M^2, N near S/2, and rejected suffix cases. Add malformed stream and N guards. Do not make the Logo reporter or the in-repo normative reference generate expected answers.
4. Execute genuine pinned UCBLogo 6.2.5 Native on exact QA SHA, retain raw logs/fixture/artifact and digest, prove all asserted counts and markers, and independently review job, run, and artifact before a **bounded QA acceptance**. Design a specific test budget and markers before implementation; these are not claimed here.
5. Evaluate the remaining general k>=3 wide-ranking and downstream unranking connections separately before any Stage2 completion claim.

No new CI dispatch was requested by this contract; no previous accepted gate is to be rerun without a source-relevant change. Canonical Logo+Ido HEAD and accepted composition QA SHA remain unchanged.
