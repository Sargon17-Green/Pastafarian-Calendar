# Stage33 / DISCOVERY29 — 非法文本恢复与内存隔离 (2026-11-03)
PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: exact Stage32 832c362ffeaec3fc6c7dbd425de28b1068450d1e, run 41530091453 completed/success 33/33 and Native 24/24, zero heap.

New behavior: test parser failure-to-success transition, not Stage32 valid leading-zero text equivalence. Inspecting src/big_integer.cob yields expected status 44 for sign-only/nondigit and 43 for length outside 1..8192. These are hypotheses; do not assert a defect or expected-red without Native reproduction.

n in {9,18,127,299}, j=1..6. Invalid forms: '+', '-', '+' followed by n-1 digits and 'Q', a '?' inside n digits, '-' plus n digits plus '.', or n digits but a declared length 8193. First five expect 44, last 43. After each of 24 rejections, assert empty output and HEAP-LIVE=0, then valid input:
M=10^n, c=(-1 if j odd else +1)(M+17j), t=(-1 if j divisible by 3 else +1)(M-(23j+7)).
Expected MONSTER-DISTANCE/PATCH03 = |c-t|+1, independently checked via grade-school decimal signed addition/subtraction and JS BigInt against emitted COBOL literals. 24 unique ordered valid pairs. Bound input, invalid literal, expected decimal <=320 characters; source line <=115. Valid calls must preserve input pointers/sign/chunk counts, route PATCH03 and release all input/output.
Native gate on exact push SHA: 34/34 completed/success, Stage33 Native strict GnuCOBOL 3.1.2.0 -Werror, compile <=300s and execute <=120s, job <=20m; artifact even on failure. Required STAGE33_REJECTS=24; STAGE33_HEAP_CLEAN=24; STAGE33_RUNS=24; STAGE33_PASS=24; STAGE33_UNEXPECTED_FAILURES=0; STAGE33_HEAP_MEASURED=YES; STAGE33_HEAP_LIVE_POST_RELEASE=0; RESULT=PASS_STAGE33_INVALID_PARSE_RECOVERY_DISCOVERY_NATIVE; STAGE33_NATIVE_GATE=PASS.
Static QA is not Native acceptance. No production/main/merge/release change, no whole-calendar acceptance.
