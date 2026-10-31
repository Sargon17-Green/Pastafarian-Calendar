# Stage11 / DISCOVERY07 — 变换不变性（平移、反号、交换输入）

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Date: 2026-10-31.
Entry: Stage10 on SHA 8d9d4be61da645cf2473a9bde3159ccbb618df19 — run 41193916398 completed, 11/11 jobs success; GnuCOBOL 3.1.2.0 strict -Werror; 20/20 calls, 0 unexpected failures, heap=0. Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41193916398/artifacts/13041111295
Status: implementation committed; Stage11 Native NOT YET ACCEPTED. No assumed defect, no expected-red, no PATCH04.

## 独立数学预言机 / independent test-only oracle
For arbitrary signed integer x, y and translation k, patched production contract is d(x,y)=|y-x|+1.
Check four separately instantiated pairs for every base pair: (x,y), (x+k,y+k), (-x,-y), (y,x). Each result must equal the same precomputed decimal oracle, not a value obtained from production. This is transformation invariance; it does NOT assert that Stage10's three-point composition test was sufficient.

Exactly 4 groups * 4 independent calls = 16.
1. (2,9), k=-5: (2,9), (-3,4), (-2,-9), (9,2), each exactly 8.
2. (-10,5), k=10: (-10,5), (0,15), (10,-5), (5,-10), each exactly 16.
3. (0,0), k=123: (0,0), (123,123), (0,0), (0,0), each exactly 1; tests identical operands and zero.
4. (10^63,10^63+1), k=-10^63: base large positive pair, (0,1), pair (-10^63,-(10^63+1)), reverse large positive pair; each exactly 2.
Fixtures are decimal literals/test-only constructions, independent of production BigInt arithmetic; every mathematical identity above was checked with arbitrary precision before committing. Boundary magnitude: 65-character signed decimal representation; not limited by machine-sized signed integers.

## Native acceptance gate
- Isolated test/stage11_discovery_tests.cob, no production changes; initialize each pair via BIG-INTEGER-SERVICE INIT-TEXT.
- Call MONSTER-DISTANCE/DISTANCE-PATCH once per pair (16 total).
- Each call must have status=0, message=PATCH03:DISTANCE-PATCH, exact independent decimal expectation, no input sign/chunks/head/tail mutations, caller-owned output freed to empty.
- Release all input BigInts for each call; final HEAP-LIVE returns zero.
- Canonical GitHub Actions adds stage11-transform-discovery-native: 300-s bounded -Werror compile, 120-s execution, artifact on failure too.
- Acceptance: 12/12 jobs verify + Stage1–11 completed/success on exact new HEAD; STAGE11_RUNS=16, STAGE11_PASS=16, STAGE11_UNEXPECTED_FAILURES=0, STAGE11_HEAP_LIVE_POST_RELEASE=0, RESULT=PASS_STAGE11_TRANSFORM_DISCOVERY_NATIVE and STAGE11_NATIVE_GATE=PASS.
- If failing: capture observed witness/status/log and distinguish compile/harness/production failure; never invent expected-red. If passing: NO_DEFECT_REPRODUCED_IN_SIXTEEN_TRANSFORM_CALLS, not a universal proof.
No protected branch changes, no main/merge, no publication.
