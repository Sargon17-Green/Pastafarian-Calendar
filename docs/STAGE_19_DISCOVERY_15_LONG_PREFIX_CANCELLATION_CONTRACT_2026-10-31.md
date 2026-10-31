# Stage19 / DISCOVERY15 — 长共同前缀相消边界研究

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage18 completed-success run 41239059490 on 678015d04975c1ce97a2bedfcc16d58afe9fa71d: all 19 jobs success, 24/24 strict Native, measured HEAP-LIVE 0.

## Original bounded test contract

Purpose: test cancellation of almost identical huge positive or negative BigInt operands with up to 318 significant decimal digits. This differs from Stage18's all-nines to power-of-ten cascade: inputs here share almost their whole high-order prefix, but the result is only one or ten digits.

For each n in {10,19,46,103,229,317}, let M = 10^n, Q = 10^9 and use four original ordered pairs (c,t):
1. (+M, +(M+1)) -> expected 2.
2. (-M, -(M+1)) -> expected 2.
3. (+(M+Q+7), +(M+7)) -> expected Q+1 = 1000000001.
4. (-(M+7), -(M+Q+7)) -> expected Q+1 = 1000000001.

The independent oracle computes abs(BigInt(t)-BigInt(c))+1 in JavaScript for each of 24 distinct literals and compares to the simple closed-form values above before committing. Fixtures are independently constructed in this branch, without importing any other branch's code or test fixtures. Long literals are split into at most 80-character MOVE fragments with indexed destinations.

## Execution, acceptance and boundaries

- 24 COBOL RUN-PAIR invocations via MONSTER-DISTANCE/DISTANCE-PATCH, 24 exact text comparisons to oracle, status and route guards, caller input immutability, output ownership and FREE-A guards.
- Inputs must fit the 320-character fields; longest signed literal: 319 chars (10^317 and signed fixed offset). Longest generated free-form source line <230 chars.
- BIG-INTEGER-SERVICE/HEAP-LIVE must be measured after all releases, status=0, heap live=0, not an initialized constant.
- Ubuntu 24.04 / GnuCOBOL 3.1.2.0, strict -Werror; compile ≤300 s, run ≤120 s; evidence logs preserved even on failure.
- Previously accepted 19 jobs plus Stage19: 20/20 completed-success at exactly the same new commit SHA.
- Required markers: STAGE19_RUNS=24, STAGE19_PASS=24, STAGE19_UNEXPECTED_FAILURES=0, STAGE19_HEAP_MEASURED=YES, STAGE19_HEAP_LIVE_POST_RELEASE=0, RESULT=PASS_STAGE19_LONG_PREFIX_CANCELLATION_DISCOVERY_NATIVE, STAGE19_NATIVE_GATE=PASS.
- No expected-red or historical bug asserted without reproduced failure. No claim of full-calendar readiness, no main/merge or release.
