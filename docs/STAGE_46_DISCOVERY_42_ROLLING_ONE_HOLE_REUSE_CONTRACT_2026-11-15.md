# Stage46 / DISCOVERY42 — rolling single-hole reuse with three live survivors
PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage45 accepted on 42cd9ecbf80b3579dda6b531a29354ec7b629468, 46/46 completed/success in run 42390806307.
Evidence: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42390806307/artifacts/13581561878
Artifact SHA256 (GitHub metadata): 3034cca496641cd6530c07c024de1dc2cfdafc3e4839dc155fb11a0dde2826e4

## New independent lifetime question
Stage45 released/recreated complementary output pairs. Stage46 rotates a SINGLE
freed output position with the OTHER THREE LIVE throughout: each permutation
1..24 is traversed in forward order and then in reverse order. For each of
the eight transitions per case, free exactly one caller-owned result, verify
three live outputs remain byte-exact and pointer-distinct, then recreate the
hole and verify four distinct live outputs. The previous two complementary
partial-pair phases, all-4 release/rebuild, occupied-output 175 rejection,
input immutability, and final heap-zero checks remain. This is a new
bounded discovery scenario, not evidence of an existing production defect.

## Inputs, oracle and bounds
24 distinct ordered (C,T) base cases: n=3,9,320,8192 and j=1..6;
X=10^(n-1)+(5j+2), Y=10^(n-1)-(2j+5); C=X/T=Y when j odd and the
reverse when j even. Output slot k uses C+(k-1) for odd j, otherwise
C-(k-1). Expected decimal |T-C'|+1=7j+8+k-1 (96 comparisons).
Independent Node BigInt verifier parses source literals, validates all 96
strings and 24 permutations; its separate transition-state model checks
24*2*4=192 simulated one-hole forward/reverse transitions.
Six cases use 8192 digits. All checks reject unexpected errors.

## Required Exact-SHA Native gate
Expect 47/47 completed/success jobs after natural push, no manual dispatch.
GnuCOBOL 3.1.2 strict -Werror, compile timeout 300s, run timeout 120s,
job timeout 20min. Gate requires ORACLE_PASS=96/96,
PERMUTATIONS_STATIC=24/24, ROLLING_MODEL=192/192;
ROLL_FREES=192, ROLL_REUSES=192, ROLL_THREE=192, ROLL_QUADS=192;
all prior Stage45 lifecycle totals (24 each for initial, quad, order,
reverse, midheap, cleanup, runs, pass; partial frees/reuses 96 each;
partial cycles 48, pair switches 24; occupied reject/preserve 48 each);
unexpected=0, measured heap live=0, exact
RESULT=PASS_STAGE46_ROLLING_SINGLE_HOLE_REUSE_DISCOVERY_NATIVE and
STAGE46_NATIVE_GATE=PASS. Save run ID, job ID, artifact ID, SHA256, and logs.

No Stage47 before Stage46 acceptance. No production/main/merge/release,
and no claim of integrated complete calendar conversion.
