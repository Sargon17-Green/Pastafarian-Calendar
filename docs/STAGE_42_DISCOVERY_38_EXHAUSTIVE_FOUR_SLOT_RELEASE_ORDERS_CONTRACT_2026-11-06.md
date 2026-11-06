# Stage42 / DISCOVERY38 — exhaustive four-output release orders
PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage41 exact d8a38016c49aef45d940bf5edea2d45f7d45483e accepted in run 42173374442,
42/42 jobs, independent 96/96 oracle, lifecycle 24/24, measured heap zero.

Stage42 tests all 4! = 24 distinct release orders of FOUR simultaneously
owned outputs, unlike Stage41's single endpoint-first schedule. Each
release must clear the released sign/chunk/head/tail, preserve metadata,
decimal text and disjoint ownership of all survivors. After all four
are freed, measured HEAP-LIVE must be 0 for EACH of 24 cases.
Rebuild the four in reverse order with fresh inputs, validate live
survivors after each creation, then release again in original order
with survivor checks after each release. All failure paths clean up.

Inputs: widths n={3,9,320,8192}, j=1..6.
Own-branch deterministic basis X=10^(n-1)+(5j+2),
Y=10^(n-1)-(2j+5); odd j (C,T)=(X,Y), even j (Y,X).
For slot k=1..4, emit C'=C+s*(k-1), s=+1 for odd j, else -1;
unsigned expected text=abs(T-C')+1=7j+8+k-1.
A separate Node.js BigInt oracle parses actual source-emitted decimal
literals and compares against closed form, requiring 96/96.
A recursive permutation enumerator independently checks the 24 source
orders are unique and exhaustive. Six cases must span 8192 digits.

Native acceptance requires completed/success 43/43 jobs at exact SHA,
GnuCOBOL 3.1.2.0 strict -Werror, compile <=300s, run <=120s,
job timeout 20min, artifact log even on failure.
Markers: ORACLE_PASS=96/96, PERMUTATIONS_STATIC=24/24,
INITIAL_OUTPUTS=24, QUAD_LIVE=24, ORDER_COVERAGE=24,
MID_HEAP_ZERO=24, REVERSE_REBUILT=24, FINAL_CLEANUP=24,
RUNS=24, PASS=24, UNEXPECTED_FAILURES=0, HEAP_MEASURED=YES,
HEAP_LIVE_POST_RELEASE=0, exact RESULT/GATE=PASS.
No presumed expected-red without reproduced witness.
No production/main/merge/release changes.
