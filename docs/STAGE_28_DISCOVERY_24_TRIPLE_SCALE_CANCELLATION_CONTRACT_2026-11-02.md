# Stage28 / DISCOVERY24 — 三尺度平衡扰动及跨零抵消（2026-11-02）

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage27 accepted on f8a40b576f171b77885b76b90310517f8107492f; run 41356514786, 28/28 success, native 24/24, actual post-release HEAP=0, artifact 13103452556 SHA256 66e85f67736f30a6d829291bdbb03b3ea10f2dcb9d4f3ee19a8ebf82f3bde558.

## Measurable input/output contract and independent oracle
MONSTER-DISTANCE/DISTANCE-PATCH must compute f(x,y)=|x-y|+1, preserve input sign/chunks/pointers, allocate caller-owned output, release all heap.
For six triple scales (n,k,j)=(12,9,1),(28,18,8),(64,27,9),(128,73,17),(201,127,26),(318,317,9), define M=10^n, Q=10^k, R=10^j; A=M+Q+R+1, B=M-Q-R-1>0. Four signed ordered pairs at each scale: (-A,+B),(+A,-B),(+A,+B),(-A,-B). Cross-sign symbolic answer is decimal digit 2 followed by n-1 zeros and terminal 1; same-sign symbolic answer is a decimal numeral with digit 2 in positions k and j and digit 3 in units, others zero. Independently calculate abs(x-y)+1 with JS BigInt, compare 24 symbolic expectations, verify 18 identity assertions including same/cross symmetry and symbolicSame+2B=symbolicCross. Ensure 24 distinct ordered pairs, maximum signed input <=320, output <=320, source line <=150, exactly 24 RUN-PAIR calls.
This new three-spike boundary differs from the previous two-scale Stage27 operands. No expected-red absent a reproduced bug.

## Strict native acceptance
The Stage27 same-branch harness handles ownership, snapshot immutability, release, actual HEAP-LIVE, error status. Compile GnuCOBOL 3.1.2 on ubuntu-24.04 -Werror, compile bound 300s, execution bound 120s, job timeout 20m, artifact always uploaded. On exact Stage28 commit accept only if 29/29 jobs completed/success and Stage28 native job log contains:
STAGE28_RUNS=24
STAGE28_PASS=24
STAGE28_UNEXPECTED_FAILURES=0
STAGE28_HEAP_MEASURED=YES
STAGE28_HEAP_LIVE_POST_RELEASE=0
RESULT=PASS_STAGE28_TRIPLE_SCALE_CANCELLATION_DISCOVERY_NATIVE
STAGE28_NATIVE_GATE=PASS
Static preflight is not Native PASS. No five-component calendar integration, production/main/merge/release.
