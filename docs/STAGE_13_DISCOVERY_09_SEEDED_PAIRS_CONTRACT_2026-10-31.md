# Stage13 / DISCOVERY09 — 有界确定性多位随机对数值检查
PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Date: 2026-10-31
Previous accepted HEAD: 4d5ba6bf663c97cc402a93f9736b3e69c5ea0afd
Stage12 evidence: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41199708996 (13/13 completed/success), job 124532916210 GnuCOBOL 3.1.2.0 -Werror; 24/24; 0 unexpected; heap=0; artifact 13042800671.

## Scope and independent oracle
Production route MONSTER-DISTANCE/DISTANCE-PATCH, expected d(c,t) = abs(t - c) + 1. No production code changes, no asserted historical defect, no expected-red without observed reproduction. Investigate arbitrary non-boundary signed operands, reversals and coincident operands, unlike Stage12's power-of-ten boundary targets.
Generate exactly 6 base pairs with a deterministic xorshift32 (initial unsigned state 0x13c0b013; each step: x ^= x << 13; x ^= x >>> 17; x ^= x << 5, with unsigned 32-bit wrap); decimal digits: first 1+(next % 9), then repeated next % 10.
Decimal lengths: 1, 19, 53, 89, 149, 199. For each length generate a and b; if identical, change b's first digit to 8 if it is 9, otherwise 9. For each length exactly ten ordered pairs:
(a,b); (b,a); (-a,-b); (-b,-a); (-a,b); (b,-a); (a,-b); (-b,a); (a,a); (-b,-b).
The 60 corresponding expected literals in test/stage13_discovery_tests.cob were computed independently with JavaScript BigInt using (t>=c ? t-c : c-t)+1, not by calling COBOL production arithmetic. Each positive magnitude has the prescribed decimal length; operands <=200 characters with sign; expected results <=201 decimal digits. The test uses hard-coded decimal literals; it has no PRNG or oracle implementation in the COBOL execution path.

## Measurable native gates
- Exactly 60 calls with status zero and PATCH03:DISTANCE-PATCH, exact decimal value and length, untouched input sign/chunks/pointers, output released and empty.
- All inputs freed; HEAP-LIVE must return status=0 and length=0.
- New canonical native CI job on this branch only, strict GnuCOBOL 3 -Werror; <=300s compile and <=120s execution, artifact preserved on success/failure.
- CI acceptance requires exact HEAD, 14/14 completed/success jobs including verify and Stage1–13, and log STAGE13_RUNS=60, STAGE13_PASS=60, STAGE13_UNEXPECTED_FAILURES=0, STAGE13_HEAP_LIVE_POST_RELEASE=0, RESULT=PASS_STAGE13_SEEDED_PAIRS_DISCOVERY_NATIVE, STAGE13_NATIVE_GATE=PASS.
- Otherwise inspect real logs and reproduce witness before any defect/expected-red claim. If all pass: NO_DEFECT_REPRODUCED_IN_SIXTY_SEEDED_PAIRS (limited evidence only).
- No merge/main, no Stage14 until verified Stage13 acceptance; Stage13 is independent test-only exploration, not full five-field calendar implementation.
