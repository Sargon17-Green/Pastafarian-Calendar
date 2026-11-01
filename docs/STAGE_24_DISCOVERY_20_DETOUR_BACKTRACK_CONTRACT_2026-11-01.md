# Stage24 / DISCOVERY20 — 非单调路径回溯增量（2026-11-01）

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage23 run 41350004948 completed/success 24/24 jobs, Native job 124977934622 GnuCOBOL 3.1.2.0 -Werror, 24/24 cases, zero unexpected, true HEAP_MEASURED=YES, live post-release=0; artifact 13100219325 digest sha256:4d2882b27cef0a55ce5648fce41cd7a32d4a57405b14c29f7fd3c946f43f9ea9.

## Independent scope and oracles

For n in {8,10,17,19,128,317}, form distinct signed n-digit a<0<b<c using first digits a=-8, b=+3, c=+7. The remaining n-1 digits are independently generated per operand j=0,1,2 from seed x0=211*n+173*j+29, recurrence x(i+1)=(16807*x(i)) mod 2147483647, appended decimal digit x(i+1) mod 10; signed literals have n+1 characters. This Stage24 generator is not copied from other branches or previous-stage fixtures.

For each n, make four directed distance calls (a,b), (a,c), (c,b), (c,a), 24 unique calls total, calling existing MONSTER-DISTANCE/DISTANCE-PATCH with f(x,y)=|y-x|+1. With A=|a|, B=b, C=c, independently derived closed-form expectations are A+B+1, A+C+1, C-B+1, A+C+1 respectively. Cross-check every fixture against separately evaluated JavaScript BigInt abs(to-from)+1 (24/24 required). Two independent identities for each of six n:
- Backtrack surplus: f(a,c)+f(c,b)-f(a,b)=2(c-b)+1; this non-monotone detour adds twice the overshoot plus one distance-offset unit, unlike Stage23's ordered three-segment telescoping.
- Endpoint reversal: f(c,a)=f(a,c) (permutation of the directed inputs).
Require all 6/6 backtrack and 6/6 reversal checks in preflight; no reliance on another branch's algorithm/fixture.

Boundaries: n=8/10 and n=17/19 straddle 9-digit chunk transitions, n=128 and n=317 stress long decimal values. Literal length <=318, output length <=318 and buffer capacity 320; split COBOL literals into <=80-character fragments, source line length <=230. Exactly 24 RUN-PAIR calls. Preserve exact input ownership, route/status assertions, explicit frees, actual HEAP-LIVE zero, and unexpected-failure counter.

## Native gate (not yet accepted)

Ubuntu 24.04, GnuCOBOL 3.1.2, -Werror; compile <=300s, execution <=120s, job <=20 min; preserve failure logs. Require completed/success 25/25 jobs on exact Stage24 SHA, including:
STAGE24_RUNS=24
STAGE24_PASS=24
STAGE24_UNEXPECTED_FAILURES=0
STAGE24_HEAP_MEASURED=YES
STAGE24_HEAP_LIVE_POST_RELEASE=0
RESULT=PASS_STAGE24_DETOUR_BACKTRACK_DISCOVERY_NATIVE
STAGE24_NATIVE_GATE=PASS

No expected-red without reproduced counterexample, no production change, no main/merge/release, no claim of full five-component calendar completeness.
