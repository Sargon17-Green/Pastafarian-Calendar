# Stage25 / DISCOVERY21 — 稀疏双位借位与相反符号消去（2026-11-01）

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage24 completed/success 25/25 at bc1d1cabbbcc64cbee276eb3d994a6a60f590cec, Native 124981693201, GnuCOBOL 3.1.2.0 -Werror, 24/24, real heap measured YES and zero live, evidence artifact 13101009533 (SHA256 48de15349df455481b9293709fc40e3e659f886ba21c1f08c3fb7dea4f7d5812).

## 独立测试设计 / Independent contract

Production entrypoint MONSTER-DISTANCE / DISTANCE-PATCH returns f(x,y)=|y-x|+1.
For each (n,k) in (10,1), (18,8), (27,9), (46,17), (128,27), (317,128) define N=10^n, K=10^k, A=N+K+7, B=N-K-9, with 0<k<n and A,B>0. A and B have a large common high-order term but different sparse low-order terms, forcing a long decimal borrow crossing 9-digit chunks. Exercise exactly four distinct ordered/signed pairs per row: (A,B), (B,A), (A,-B), (-A,B); 24 unique native calls overall.

Two independently derived symbolic expectations, checked against JavaScript BigInt |y-x|+1 for every fixture (24/24 preflight):
- Same sign: f(A,B)=f(B,A)=2K+17.
- Opposite sign: f(A,-B)=f(-A,B)=2N-1.
The symbolic expectations are constructed using a separate decimal-digit addition (2K+17) and the explicit digit form 1 followed by n nines (2N-1), not from the BigInt oracle routine. Check 6/6 same-sign reversal, 6/6 opposite-sign sign-flip and 6/6 separation identities: (2N-1)-(2K+17)=2N-2K-18. This is a sparse dual-scale borrow/sum stress test, not Stage24's detour/backtrack and not fixtures copied from another branch.

Bounds: n=10/18/27/46/128/317, k=1/8/9/17/27/128, crossing one or many 9-digit chunks. All signed literal lengths <=319, expected result <=318, WS buffers 320. Split literals into fragments <=80; source line length <=150. Exactly 24 RUN-PAIR calls. Preserve input-sign/chunk/pointer snapshot, output release, input release, route marker, actual HEAP-LIVE observation and unexpected-failure count. Native compiled/ran only after completed CI logs. No expected-red verdict absent a reproduced defect.

## Native gate (PENDING; not PASS)

Ubuntu 24.04, GnuCOBOL 3.1.2, strict -Werror, compile <=300s, execute <=120s, job <=20 minutes, artifact retained on failure. Require completed/success 26/26 jobs on the exact Stage25 commit SHA and job stage25-sparse-twin-borrow-discovery-native with:
STAGE25_RUNS=24
STAGE25_PASS=24
STAGE25_UNEXPECTED_FAILURES=0
STAGE25_HEAP_MEASURED=YES
STAGE25_HEAP_LIVE_POST_RELEASE=0
RESULT=PASS_STAGE25_SPARSE_TWIN_BORROW_DISCOVERY_NATIVE
STAGE25_NATIVE_GATE=PASS

No production/main/merge/release changes; full five-component calendar integration remains NOT_YET_AVAILABLE.
