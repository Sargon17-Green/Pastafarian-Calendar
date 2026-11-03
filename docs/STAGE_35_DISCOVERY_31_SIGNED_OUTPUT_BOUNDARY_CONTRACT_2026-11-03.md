# Stage35 / DISCOVERY31 — 异号边界与最大输出长度 (2026-11-03)

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage34 accepted on exact adb8e5ac0f6cfeeaa67de182a894e95f86560310, completed/success 35/35, strict native 24/24, heap-live post-release 0.
Evidence: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41617857942

## Distinct engineering target
Stage34 covered invalid declared lengths plus valid *positive* operands of up to 8192 decimal characters with a small output. Stage35 instead tests opposite-sign arithmetic where both input textual envelopes are maximal and the *actual output* is exactly 8192 decimal digits. This checks full-width signed parsing, magnitude addition, TO-TEXT capacity, preserved caller ownership and heap release. No bug or expected-red is asserted without a reproduced failure.

## Bounded deterministic test
For n in {3,9,320,8192} and j in {1,...,6}, define positive A=10^(n-1)+j and positive B=10^(n-2)+1. For odd j, c=A and t=-B; for even j, c=-B and t=A (operand symmetry). Both signed textual inputs are n characters, even at the n=8192 upper bound, because -B has n-1 magnitude digits plus '-'.

Native production under test (unchanged): MONSTER-DISTANCE / DISTANCE-PATCH returns |c-t|+1. Independent closed-form decimal oracle: 11*10^(n-2)+(j+2); with j+2 in [3,8], expected text is '11' followed by (n-3) zeroes and digit j+2; output width is n. Independent arbitrary-precision JavaScript BigInt recomputes |c-t|+1 over the full signed literals and must equal the decimal oracle for all 24 cases. 24 distinct ordered operand pairs, 12 operand order A/-B and 12 -B/A; 6 cases at actual maximum width 8192. No imported fixtures from other branches.

Native test compares exact 8192-capacity TO-TEXT output length and bytes, verifies nonmutation of both sign/chunk/pointer input records, frees output and inputs, checks return status/message, measures HEAP-LIVE after all releases. Any unexpected status, wrong text, mutation or leak fails. Maximum source line must be <=115 characters.

## Gates
Static source and oracle 24/24 BigInt versus closed form, 24 distinct ordered pairs, longest input=8192, longest expected output=8192, maximum source line <=115. CI: branch and new SHA exact; 36/36 completed/success, strict Linux GnuCOBOL 3.1.2.0 -Werror, compile timeout 300s, runtime timeout 120s, job timeout 20min, artifact upload even on failure.
Markers: STAGE35_RUNS=24; STAGE35_PASS=24; STAGE35_UNEXPECTED_FAILURES=0; STAGE35_HEAP_MEASURED=YES; STAGE35_HEAP_LIVE_POST_RELEASE=0; RESULT=PASS_STAGE35_SIGNED_OUTPUT_BOUNDARY_DISCOVERY_NATIVE; STAGE35_NATIVE_GATE=PASS.
Static PASS is not Native PASS; acceptance only on completed run/log. No production/main/merge/release. No general calendar-completion claim.
