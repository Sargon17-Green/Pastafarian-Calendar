# Stage21 / DISCOVERY17 — 九补数双重距离关系

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage20 on a8375c037f6387603835eab5dd1bab12104d1696, 21/21 completed/success; strict Native 24/24; measured HEAP-LIVE=0. Run 41245827541.

## Novel case construction and independent oracle

Use lengths n={8,9,18,27,127,318}. Let A be the n-digit integer whose first decimal digit is 1, followed by n-1 digits from repetitions of this fixed decimal sequence:
`31415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679`.
Let B=10^n-1-A, computed also by digitwise nines-complement. Then A+B=10^n-1 and 0<A<B. This investigates **same-sign subtraction and opposite-sign magnitude addition using the same complementary digits**, a different algebraic family from Stage20.

Four ordered pairs per n (exact sign text is part of the input):
1. (c=+A, t=+B) => 10^n-2A.
2. (c=+B, t=+A) => 10^n-2A.
3. (c=+A, t=-B) => 10^n.
4. (c=-B, t=+A) => 10^n.

Every expected decimal was generated with independent JavaScript BigInt oracle `abs(t-c)+1n` and checked against the independent symbolic identities above: 24/24 agreements. No fixture/code imported from another branch. Duplicate exact ordered pairs forbidden.

## Measurable acceptance

24 calls to MONSTER-DISTANCE/DISTANCE-PATCH with 24 exact text comparisons, input snapshots (sign/chunks/head/tail), output ownership/FREE-A guards, input release and actual BIG-INTEGER-SERVICE/HEAP-LIVE query. Input max 319 characters; result max 319 decimal digits; all fields X(320); literal fragments <=80 chars; COBOL source lines <=230 chars. Strict Ubuntu 24.04 GnuCOBOL -Werror, 300s compiler timeout, 120s binary timeout, job 20m, evidence artifact always.

Only accept completed/success 22/22 jobs on exact commit and:
STAGE21_RUNS=24
STAGE21_PASS=24
STAGE21_UNEXPECTED_FAILURES=0
STAGE21_HEAP_MEASURED=YES
STAGE21_HEAP_LIVE_POST_RELEASE=0
RESULT=PASS_STAGE21_COMPLEMENT_DUALITY_DISCOVERY_NATIVE
STAGE21_NATIVE_GATE=PASS

Failure is research evidence, not a presupposed historical bug. No main/merge/production/release; full five-field calendar remains incomplete.
