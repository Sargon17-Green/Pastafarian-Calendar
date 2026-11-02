# Stage29 / DISCOVERY25 — 交替数字补数与跨十进制进位边界（2026-11-02）

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage28 accepted exact SHA ac06677aac1f6d44ab7c75063930c8aa038da65a, CI 41409214195 completed/success 29/29; native job 125158150993 PASS 24/24, unexpected 0, actual post-release heap=0; artifact 13125225835 (SHA256 57972b0e2ef62105d66d3b0cc1d1df5c22de26fb25a01d5e0b183c4b40f0494c).

## Independent bounded test contract

Subject: same-branch MONSTER-DISTANCE/DISTANCE-PATCH f(c,t)=abs(c-t)+1; input sign/chunks/pointers must remain unchanged, output caller-owned/released, heap post-release zero.
Six (n,delta) = (9,-2),(18,-1),(37,0),(73,1),(127,2),(318,3). Let P=10^n. A is the n-digit alternating '90' string beginning with '9'; B=P-A+delta (positive). This creates a dense alternating carry/borrow frontier rather than Stage28's sparse three-spike cancellation. For each pair, test (-A,+B),(+A,-B),(+A,+B),(-A,-B): 24 unique ordered pairs.
Opposite signs: P+delta+1. Same signs: 2A-P-delta+1. Verify both with an independent digit-by-digit decimal add/subtract oracle (no BigInt), then separately with BigInt abs(c-t)+1. Check 3 independent identities at each n (18): opposite= A+B+1; same=A-B+1; opposite-same=2B. No expected RED unless actual reproduction.
Fixture limits: 24/24 independent BigInt and positional decimal expectations, 18/18 identities, 24 unique pairs; signed input at most 319, output at most 319, COBOL source line at most 115, exactly 24 RUN-PAIR. All fixture literals are explicit in COBOL; no runtime random generation.

## Strict Native/CI acceptance

GnuCOBOL 3.1.2.0, ubuntu-24.04, -Wall -Wextra -Wstrict-typing -Wcall-params -Wlinkage -Wtruncate -Werror; compiler timeout 300s, executable 120s, job 20m; evidence log uploaded even on failure. Require exact Stage29 commit SHA and 30/30 completed/success jobs, Stage29 Native job:
STAGE29_RUNS=24
STAGE29_PASS=24
STAGE29_UNEXPECTED_FAILURES=0
STAGE29_HEAP_MEASURED=YES
STAGE29_HEAP_LIVE_POST_RELEASE=0
RESULT=PASS_STAGE29_ALTERNATING_COMPLEMENT_DISCOVERY_NATIVE
STAGE29_NATIVE_GATE=PASS
Static fixture QA does NOT imply Native PASS. This does not prove five-component date integration. No production/main/merge/release.
