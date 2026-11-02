# Stage30 / DISCOVERY26 — 循环数字前缀与近邻差异边界 (2026-11-02)

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Stage29 prerequisite: 6d51b2481b876fd6ab9730d779fb7f2eea752cdb; completed 30/30 https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41503669773; native 24/24, heap measured live after release 0; artifact https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41503669773/artifacts/13168918872.

## Independent bounded contract
Production under test (unchanged): MONSTER-DISTANCE / DISTANCE-PATCH f(c,t)=|c-t|+1, with unchanged caller input signs, chunks, and head/tail pointers; release caller-owned output and observe HEAP-LIVE zero.
Construct six long cyclic-prefix integers A: first n-k decimal digits repeat 31415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679, followed by k zeros. B=A+delta.
n,k,delta=(9,2,-9),(18,3,-1),(37,7,0),(73,17,1),(127,31,7),(318,64,9).
For each, test four ORDERED signed pairs: (+A,+B),(-A,-B),(-A,+B),(+B,-A): exactly 24 unique native calls; same sign expected |delta|+1, cross sign A+B+1.
The varied trailing-zero run plus patterned nonzero prefix creates long common-prefix cancellation and negative-delta borrow through k trailing zero digits; unlike Stage29 alternating decimal complement.
Preflight 1 independent oracle: grade-school positional decimal addition, magnitude comparison and borrowing; preflight 2: JavaScript BigInt exact abs(c-t)+1. Neither derives outputs from COBOL production.
Algebraic identities checked per n: both same-sign paths agree; both cross-sign paths agree; cross - same = 2*A + delta - abs(delta): 18/18.
Static contract: 24/24 independent expected values, 18/18 identities, 24 unique ordered pairs; max signed input 319 characters, max expected output 318 digits, maximum COBOL source line 110; exactly 24 PERFORM RUN-PAIR statements.
No expected-red defect inferred without Native reproduction. Fixtures fixed at source time, no runtime random generation.

## Native/CI
ubuntu-24.04, GnuCOBOL 3.1.2.0, -Wall -Wextra -Wstrict-typing -Wcall-params -Wlinkage -Wtruncate -Werror; 300s compile, 120s executable, 20min job; upload log even on failure.
Acceptance requires same-branch exact pushed head SHA, 31/31 completed-success jobs, native job stage30-cyclic-prefix-near-neighbor-discovery-native and the exact markers:
STAGE30_RUNS=24
STAGE30_PASS=24
STAGE30_UNEXPECTED_FAILURES=0
STAGE30_HEAP_MEASURED=YES
STAGE30_HEAP_LIVE_POST_RELEASE=0
RESULT=PASS_STAGE30_ALTERNATING_COMPLEMENT_DISCOVERY_NATIVE
STAGE30_NATIVE_GATE=PASS
Static preflight does NOT equal Native PASS. Five-component calendar remains outside Stage30 scope. No main/merge/release.
