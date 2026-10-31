# Stage14 / DISCOVERY10 — base-10^9 多块借位与进位级联
PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Date: 2026-10-31
Previous accepted HEAD: a240bd0fc8eaf5fec41da497771909a945765434
Stage13 evidence: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41206916984 (14/14 completed/success); Native 60/60, zero unexpected, heap=0; artifact 13043594923.

## Scope and independent oracle
Production route: MONSTER-DISTANCE/DISTANCE-PATCH. Normative result is d(c,t)=abs(t-c)+1 for signed arbitrary-precision integers.

The implementation uses BI-BASE=1,000,000,000; each linked-list node stores one nine-decimal-digit chunk, ordered from most significant at HEAD to least significant at TAIL. SUB-ABS-H1-H2-INTO-R walks backward from TAIL and propagates WS-BORROW; ADD-ABS-H1-H2-INTO-R walks backward from TAIL and propagates WS-CARRY. PATCHED-DISTANCE first subtracts the signed operands, normalizes the magnitude, then adds one. This discovery targets a long borrow through zero-valued low chunks followed by a long carry through all-999999999 low chunks, rather than another generic random-pair or decimal-power-boundary sample.

Let B=10^9, k in {3,5,11,17,22}, and p=B^k=10^(9k). For each k, perform exactly these six ordered calls, with the independent expected result shown:
1. (1,p) -> p
2. (p,1) -> p
3. (-1,-p) -> p
4. (-p,-1) -> p
5. (2,p+1) -> p
6. (-(p+1),-2) -> p

Each expected literal is computed independently using JavaScript BigInt: abs(t-c)+1. The COBOL test contains only hard-coded decimal operands and expected results; it contains no runtime PRNG or oracle. For (1,p), subtraction produces p-1, whose k low base-B chunks are all 999999999; the subsequent +1 must carry across all k chunks. The (2,p+1) case reaches the same p-1 through a low-chunk 1-2 borrow and propagates through the k zero chunks. Reverse and negative variants exercise signed comparison/swap paths. The five p values have 28, 46, 100, 154, and 199 decimal digits respectively; maximum signed operand length is 200 characters. Total: 5 groups x 6 calls = 30.

## Measurable native gates
- Exactly 30 calls through MONSTER-DISTANCE/DISTANCE-PATCH; every call must return status 0 and message PATCH03:DISTANCE-PATCH, exact decimal value and length, and leave input sign/chunks/head/tail unchanged.
- Each output is freed to an empty slot; both inputs are released; HEAP-CHUNK-LIVE returns status 0 and length 0.
- Branch-only canonical Native job, GnuCOBOL 3 strict -Werror; compile <=300s and execution <=120s; upload the full log on success and failure.
- Acceptance requires exact branch HEAD and 15/15 completed/success jobs (verify plus Stage1–14), plus STAGE14_RUNS=30, STAGE14_PASS=30, STAGE14_UNEXPECTED_FAILURES=0, STAGE14_HEAP_LIVE_POST_RELEASE=0, RESULT=PASS_STAGE14_BASE_CHUNK_CARRY_DISCOVERY_NATIVE, and STAGE14_NATIVE_GATE=PASS.
- No expected-red or production defect is assumed. If all gates pass, conclude NO_DEFECT_REPRODUCED_IN_THIRTY_BASE_CHUNK_CASCADES (limited evidence); otherwise inspect the real log and reproduce a witness before any defect claim.
- No production change, no main/merge, no user-machine Native dependency. Full five-field calendar integration remains NOT_YET_AVAILABLE.
