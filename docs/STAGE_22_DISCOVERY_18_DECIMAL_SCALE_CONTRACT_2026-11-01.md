# Stage22 / DISCOVERY18 — 十进制缩放与跨九位块边界

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage21 exact-SHA 1824bc51f480997829c954e36b60937e7ee3dd5c, run 41282890208, all 22/22 jobs completed/success; strict GnuCOBOL 3.1.2.0 -Werror, 24/24 native and 0 unexpected, real measured HEAP-LIVE=0, artifact 13074332324.

## New bounded family and independent oracle

For six original n-digit pairs, use n={8,9,17,18,45,299} and scale exponents k={1,9,8,10,17,18} respectively. A is decimal digit 2 followed by repeated digits of `27182818284590452353602874713526624977572470936999595749669676277240766303535475945713821785251664274`; B is digit 7 followed by repeated digits of `14142135623730950488016887242096980785696718753769480731766797379907324784621070388503875343276415727`. Truncate each string to exactly n digits. Hence 0<A<B, with distinct unrelated suffixes, without using fixtures or implementation from another branch.

Let D=B-A. For each (n,k), the 4 exact ordered input pairs (c,t), independently instantiated, are:
1. (+A,+B) => D+1.
2. (+(A*10^k),+(B*10^k)) => D*10^k+1.
3. (-(A*10^k),-(B*10^k)) => D*10^k+1.
4. (+(B*10^k),+(A*10^k)) => D*10^k+1.

This probes **decimal scale equivariance with the mandatory +1 correction** across internal 9-decimal-digit chunk boundaries (k=1,8,9,10,17,18). It differs from Stage11 translation invariance, Stage18 all-nines carry and Stage21 nines-complement duality. Exactly 24 distinct ordered fixtures. Every independent JavaScript BigInt oracle `abs(BigInt(t)-BigInt(c))+1n` agreed with the stated independent closed forms: 24/24. Largest signed input length 318; largest unsigned expected length 317. Inputs/expected X(320), literal fragments <=80, COBOL source lines <=230.

## Native and integrity gate

Run 24 MONSTER-DISTANCE/DISTANCE-PATCH calls and compare all 24 exact decimal outputs against independent fixture expectations. Verify return status and route marker, snapshots (sign/chunks/head/tail) of caller-owned inputs, output FREE-A reset and both input releases. Query BIG-INTEGER-SERVICE/HEAP-LIVE after all releases: it must return status 0 and zero live allocations (not a constant). GnuCOBOL 3.1.2 on ubuntu-24.04; strict -Werror; compile timeout 300 s, execution timeout 120 s; job 20 minutes; preserve evidence artifact even on failure.

Accept only completed/success 23/23 jobs on exactly the Stage22 commit SHA and:
STAGE22_RUNS=24
STAGE22_PASS=24
STAGE22_UNEXPECTED_FAILURES=0
STAGE22_HEAP_MEASURED=YES
STAGE22_HEAP_LIVE_POST_RELEASE=0
RESULT=PASS_STAGE22_DECIMAL_SCALE_DISCOVERY_NATIVE
STAGE22_NATIVE_GATE=PASS

Failures require reproducible witness/log diagnostics; no predeclared historical defect, expected-red, or patch. No production, main, merge, release, or full-calendar readiness claim.
