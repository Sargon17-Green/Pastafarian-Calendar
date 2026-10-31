# Stage15 / DISCOVERY11 — 交错九位数块的借位与加法相互作用
PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Date: 2026-10-31
Previous verified HEAD: fe290ebd805584b21db629b3ad90701ef7120eda
Stage14 Native: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41208174568 (15/15 completed/success); 30/30, zero unexpected, heap=0; artifact 13045571127.

## Purpose and independent oracle
The current production action is MONSTER-DISTANCE/DISTANCE-PATCH, with exact arbitrary-precision signed integers and normative d(c,t)=abs(t-c)+1. Stage14 exercised homogeneous all-zero/all-nine chunk cascades around powers of B=10^9. Stage15 instead exercises alternating interior chunks (B-1 and 1) combined with signed subtraction and addition. No claimed historical defect or expected-red is assumed.

For k in {3,5,11,17,22} define P=B^k and Q=SUM_{i=0}^{k-1}(i even ? B-1 : 1)*B^i. Therefore 0<Q<P. Low-order nine-digit chunks alternate 999999999 and 000000001. For each k test the six pairs in this exact order:
1. (Q,P) -> P-Q+1
2. (P,Q) -> P-Q+1
3. (-Q,-P) -> P-Q+1
4. (-P,-Q) -> P-Q+1
5. (-Q,P) -> P+Q+1
6. (P,-Q) -> P+Q+1

All 30 expected decimal literals were generated with a separate JavaScript BigInt oracle using (t>=c ? t-c : c-t)+1, with a second algebraic identity check against the right-hand formulas above. These literals are hard-coded in test/stage15_discovery_tests.cob; production arithmetic and runtime test execution do not contain the generator. Max operand/expected magnitude is less than 2*10^198, so decimal literal length <=199 for magnitudes and <=200 including sign. There are exactly 5*6=30 Native calls.

## Gates
- Each call to MONSTER-DISTANCE/DISTANCE-PATCH returns status zero and message PATCH03:DISTANCE-PATCH; exact decimal output value and length must match the independent oracle.
- The sign, chunk count, HEAD/TAIL of each input must be unchanged; output FREE-A must leave zero sign/chunks and NULL pointers; release all inputs and assert heap live=0.
- Compile with GnuCOBOL 3 and -Werror, bounded to 300 seconds; execute within 120 seconds; preserve Native log even on failure.
- Accept only exact Stage15 source HEAD and 16/16 completed/success jobs including verify and Stage1–15. Require STAGE15_RUNS=30, STAGE15_PASS=30, STAGE15_UNEXPECTED_FAILURES=0, STAGE15_HEAP_LIVE_POST_RELEASE=0, RESULT=PASS_STAGE15_MIXED_CHUNK_ARITHMETIC_DISCOVERY_NATIVE and STAGE15_NATIVE_GATE=PASS.
- On failure analyze actual log and reproduce before calling any case a production defect. On success report NO_DEFECT_REPRODUCED_IN_THIRTY_MIXED_CHUNK_CALLS, limited to the cases tested. No main/merge, production change, or assumption of complete five-field calendar implementation.
