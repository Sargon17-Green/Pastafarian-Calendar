# Stage26 / DISCOVERY22 — 有符号输入与输出的 320 字符极限（2026-11-01）

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage25 CI 41354768546 completed/success 26/26 at SHA 3a92780771998094c0d1f13b48d94fbe837719ab. Native job 124992380991 24/24, 0 unexpected, GnuCOBOL 3.1.2.0 -Werror, measured HEAP-LIVE=0; artifact 13103150181 digest sha256:3ca4cf6906833ca2c4ed1d6036a254262b205c4f513493515de70d94858cc385.

## Test oracle and contracts

Entrypoint MONSTER-DISTANCE/DISTANCE-PATCH returns f(x,y)=|x-y|+1. For n in {1,8,9,18,127,319}, set M=10^n, A=M-1, B=M-9. Four pairs per n: (-A,+B), (+A,-B), (+A,+B), (-A,-B), exactly 24 unique pairs. Expected cross-sign value is 2M-9, represented independently as decimal digits 1 + (n-1) nines + 1; expected same-sign value 9. Verify each independently against JS BigInt abs(x-y)+1: 24/24; check six cross-sign symmetry, six same-sign symmetry, six separation equations (2M-9)-9=2M-18. No code or fixtures copied from another language branch.

n=319 exercises exact 320-character signed input for BOTH operands and exact 320-digit output in the opposite-sign cases. Other n=1/8/9/18/127 cover small, 9-digit chunk boundaries, and long decimals. Buffer PIC X(320) for both input literals and expected output, all must fit; split literals into <=80-character fragments. Require 24 RUN-PAIR, max source line <=150. Preserve route=status PATCH03, input sign/chunk/pointer snapshots, explicit free and heap ownership checks, actual HEAP-LIVE measured and zero, unexpected-failure counter. Do not infer expected-red without a reproduced failure.

## Native gate (pending, not PASS)

Exact new SHA, Ubuntu 24.04, strict GnuCOBOL 3.1.2 -Werror, compile <=300s, run <=120s, job <=20min, failure logs always saved. Require completed/success 27/27 jobs and stage26-max-width-envelope-discovery-native:
STAGE26_RUNS=24
STAGE26_PASS=24
STAGE26_UNEXPECTED_FAILURES=0
STAGE26_HEAP_MEASURED=YES
STAGE26_HEAP_LIVE_POST_RELEASE=0
RESULT=PASS_STAGE26_MAX_WIDTH_ENVELOPE_DISCOVERY_NATIVE
STAGE26_NATIVE_GATE=PASS
No production/main/merge/release changes; complete five-component calendar not yet available.
