# Stage23 / DISCOVERY19 — 有序四点路径距离分解

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage22 exact SHA 9323495ba6570b308ffb2d003b7196dc0276d9ae; run 41285534380 completed 23/23 success, Native job 124785937261 (GnuCOBOL 3.1.2.0, -Werror), 24/24, zero unexpected, real HEAP_MEASURED=YES and HEAP_LIVE_POST_RELEASE=0; artifact 13075202325 digest sha256:07ad7e1c6f5ddd6e5b51d13641a40e55ef7570e5eedc197d641a5a98c101aa0f.

## Independent bounded contract

For each n in {8,9,18,27,127,317}, construct four distinct signed n-digit integers a<b<c<d: a=-8[suffix A], b=-3[suffix B], c=+2[suffix C], d=+7[suffix D]. Each suffix has n-1 decimal digits produced by the explicitly defined deterministic recurrence x(0)=97*n+137*j+41, x(i+1)=(48271*x(i)) mod 2147483647 and digit(i)=x(i+1) mod 10, where j=0,1,2,3 corresponds to a,b,c,d. This construction is independently authored in this branch for this stage. Digits after the first may be zero. All four inputs remain distinct and strictly ordered for every n.

Execute exactly four different ordered pairs per n: (a,b), (b,c), (c,d), (a,d), 24 unique native distance calls in total. For f(x,y)=|y-x|+1, the independent symbolic oracle (write A=|a|, B=|b|, C=c, D=d) is:
f(a,b)=A-B+1;
f(b,c)=B+C+1;
f(c,d)=D-C+1;
f(a,d)=A+D+1.
A second, independently evaluated JavaScript BigInt oracle computes abs(to-from)+1 on every ordered pair. Verify 24/24 exact equalities and the separately derived four-point path identity f(a,d)=f(a,b)+f(b,c)+f(c,d)-2 for all six groups. This identity checks the +1 offset for a three-segment path crossing the sign boundary; it is different from Stage20 opposite-sign *individual* pair arithmetic, Stage21 complement duality, and Stage22 decimal scaling.

Boundary n values include both sides of 9-digit COBOL BigInt chunk transitions and a 317-digit stress input. Largest signed literal 318 characters, largest unsigned expected 318 characters, both <=320; source line maximum 115 <=230. Literal fragments <=80. Native route MONSTER-DISTANCE/DISTANCE-PATCH is unchanged.

## Native memory, reproducibility and acceptance

All 24 calls must verify status, route marker PATCH03:DISTANCE-PATCH, exact decimal oracle, preservation of both caller-owned inputs, explicit release of returned output and both inputs, and genuine BIG-INTEGER-SERVICE/HEAP-LIVE measurement returning zero allocations. GnuCOBOL 3.1.2 on ubuntu-24.04 with -Werror; compile timeout 300s, execution timeout 120s, job timeout 20 minutes; preserve log even on failure.

Accept Stage23 only for CI completed/success 24/24 jobs on exact Stage23 commit SHA, and:
STAGE23_RUNS=24
STAGE23_PASS=24
STAGE23_UNEXPECTED_FAILURES=0
STAGE23_HEAP_MEASURED=YES
STAGE23_HEAP_LIVE_POST_RELEASE=0
RESULT=PASS_STAGE23_ORDERED_PATH_DISCOVERY_NATIVE
STAGE23_NATIVE_GATE=PASS

No expected-red claim without an actual reproduced witness. No production modifications, main/merge/release, or full five-component-calendar readiness claim.
