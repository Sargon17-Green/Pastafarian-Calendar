# Stage12 / DISCOVERY08 — 十的幂边界：进位、借位、跨零及超长整数

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Date: 2026-10-31
Entry: Stage11 accepted at 712651a40183e058f3148768d320bed1ff80fb07, run 41196615127 (12/12 completed/success), native 16/16, zero unexpected failures, heap baseline zero.
Status: Stage12 independent bounded discovery; no assumed bug, no expected-red or PATCH04 before a reproducible witness.

## 问题与独立预言机
Patched production distance contract: d(c,t) = |t-c| + 1 for signed arbitrary-precision integers.
Investigate carry, borrow, zero-crossing and decimal-length boundaries at n in {9,18,72,127}; p = 10^n, without using production to compute expected results.
For each n perform exactly six calls with test-only decimal oracle:
1. (p-1,p) => 2
2. (p,p+1) => 2
3. (0,p) => p+1
4. (-p,0) => p+1
5. (-p,p) => 2p+1
6. (p,-(p-1)) => 2p
Total = 4 magnitudes x 6 calls = 24. Fixtures are explicit decimal strings generated from the above independent integer identities; JS BigInt oracle verified all 24 before source commit. Source COBOL test contains only literal expected strings, not a copy of the patched production arithmetic. Largest operand is 128+sign characters, within PIC X(320).

## Native acceptance and evidence
- New isolated test/stage12_discovery_tests.cob derived from this branch's existing caller/heap-safety test harness, with NEW boundary fixtures; production sources unchanged.
- 24 calls to MONSTER-DISTANCE/DISTANCE-PATCH with exact independent expected decimal result, status=0, message PATCH03:DISTANCE-PATCH.
- Snapshot sign/chunk/head/tail of input BigInts before each call; no input mutation, output freed to empty and inputs released; global heap live=0.
- Canonical CI stage12-boundary-discovery-native: GnuCOBOL 3 -Werror, compile <=300s, execution <=120s, upload log also on failure.
- 13 of 13 jobs (verify plus Stage1–12) completed/success on exact branch HEAD; strict log STAGE12_RUNS=24, STAGE12_PASS=24, STAGE12_UNEXPECTED_FAILURES=0, STAGE12_HEAP_LIVE_POST_RELEASE=0, RESULT=PASS_STAGE12_BOUNDARY_DISCOVERY_NATIVE, STAGE12_NATIVE_GATE=PASS.
- If a test fails, inspect actual compiler/test log and reproduce witness before classifying a production bug; otherwise verdict NO_DEFECT_REPRODUCED_IN_TWENTY_FOUR_BOUNDARY_CALLS (not universal proof). Do not rerun successful CI on same SHA.
No main/merge; no user-machine Native required.
