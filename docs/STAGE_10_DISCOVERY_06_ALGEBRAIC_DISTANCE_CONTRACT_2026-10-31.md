# Stage10 / DISCOVERY06 — 三点距离代数一致性：对称与组合

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Date: 2026-10-31. Status: contract ready, implementation NOT_STARTED, Native NOT_RUN. No presumed defect, no expected-red, no PATCH04.

## Entry proof
Stage9 source SHA 30d02fc13d835d95eb4ac99378f32476fe061d71; Actions run 41193134644 completed/success 10/10 jobs, 12/12 native calls, 0 unexpected and 0 heap live. Stage9 only checked reuse of identical input pairs. Stage8 checked aliasing. Stage10 checks independent three-point mathematical relations without copying another branch implementation.

## Definitions and independently calculated oracle
For all signed integers x,y: d(x,y) = abs(y-x) + 1. For each ordered triple (a,b,c) where b lies between a and c: d(a,b)=d(b,a), d(b,c)=d(c,b), and d(a,c)=d(a,b)+d(b,c)-1.
For each triple perform exactly five production route calls (AB,BA,BC,CB,AC), 20 calls total. Compare exact decimal results against hardcoded test-only independent oracle:
(1) a=-2, b=0, c=2: AB=BA=3, BC=CB=3, AC=5.
(2) a=-10,b=0,c=5: AB=BA=11, BC=CB=6, AC=16.
(3) a=7,b=3,c=-1: AB=BA=5, BC=CB=5, AC=9.
(4) a=10^63,b=0,c=-10^63: AB=BA=BC=CB=10^63+1, AC=2*10^63+1.
Build big integers from exact character strings, without floating point or fixed-width arithmetic. All four triples satisfy the composition relation using independent integer arithmetic.

## Native implementation contract
Create isolated test/stage10_discovery_tests.cob using GnuCOBOL 3.x and caller-owned BigInt input groups A,B,C with independent snapshots of sign/chunks/head/tail. After every production MONSTER-DISTANCE/DISTANCE-PATCH call, assert status=0, message=PATCH03:DISTANCE-PATCH, decimal result exact, three inputs unchanged, and correct release of empty output slot. Release all three inputs after five calls; final HEAP-LIVE must be zero. Neither oracle nor fixtures may use production computation to form expected values; do not modify existing legacy or patched implementation.

Extend existing canonical workflow with stage10-algebraic-discovery-native job, -Werror, bounded compile 300 seconds, execution 120 seconds, output artifacts even on failure. Exact log counts: STAGE10_RUNS=20, STAGE10_PASS=20, STAGE10_UNEXPECTED_FAILURES=0, STAGE10_HEAP_LIVE_POST_RELEASE=0 and RESULT=PASS_STAGE10_ALGEBRAIC_DISCOVERY_NATIVE. Verify all 11 jobs (verify, Stage1-10) completed/success for same SHA and inspect log before acceptance. If any real failure: retain minimal witness, expected/actual/status and run ID; do not assert expected-red before reproduction. If all pass: only NO_DEFECT_REPRODUCED_IN_TWENTY_CALLS, not proof for every BigInt. No main/merge.
