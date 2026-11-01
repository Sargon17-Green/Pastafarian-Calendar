# Stage27 / DISCOVERY23 — 分离尺度扰动与跨零抵消（2026-11-02）

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage26 completed/success 27/27, exact SHA 9399004472a68891863df0ced4f8f792feb46add, native job 124993814790, 24/24 strict GnuCOBOL, real HEAP-LIVE=0, artifact 13102924201 sha256:dc15367d18dc4e54d8fbf784843235ca567375ccccf14d04eaf25afc84ed8a10.

## Input/output and independent oracle

MONSTER-DISTANCE/DISTANCE-PATCH must return f(x,y)=|x-y|+1.
For six (n,k) pairs (9,1), (18,8), (27,9), (73,17), (127,26), (318,317), define M=10^n, Q=10^k, A=M+Q+1 and B=M-Q-1 (>0). Four unique ordered pairs per scale: (-A,+B), (+A,-B), (+A,+B), (-A,-B).
Cross-sign expected 2M+1, independently represented by decimal "2", then n-1 zero digits, then "1"; same-sign expected 2Q+3, independently represented by decimal "2", k-1 zero digits, then "3". Preflight must compare each of all 24 symbolic expectations against an independent JS BigInt abs(x-y)+1 oracle; verify 18 scale/sign identities (three for each scale, including reversal and same-sign/cross-sign decomposition), 24 distinct pairs, exact signed input max 320 chars, expected output max 319 chars, 24 calls and max COBOL source line <=150.
The construction exercises sparse, two-scale mixed carry/borrow at nine-digit boundaries and signed cancellation, distinct from Stage26 dense-nine operands. Never assume historical expected-red without a witnessed production failure; do not import foreign branch fixtures.

## Native contract

Retain unchanged proven Stage26 same-branch test harness for PATCH03 result/status, input sign/chunk/pointer immutability, explicit free of output and caller-owned inputs, actual HEAP-LIVE reading and zero after release. Use PIC X(320) and <=80 character source fragments. No production changes.

GitHub CI gate on exact new Stage27 SHA: 28/28 completed/success, native stage27-split-scale-perturbation-discovery-native on Ubuntu 24.04 with GnuCOBOL 3.1.2 strict -Werror; compile <=300 seconds, execution <=120 seconds, job <=20 minutes, failure log always uploaded. Required markers:
STAGE27_RUNS=24
STAGE27_PASS=24
STAGE27_UNEXPECTED_FAILURES=0
STAGE27_HEAP_MEASURED=YES
STAGE27_HEAP_LIVE_POST_RELEASE=0
RESULT=PASS_STAGE27_SPLIT_SCALE_PERTURBATION_DISCOVERY_NATIVE
STAGE27_NATIVE_GATE=PASS

Source fixture preflight does not constitute native PASS. Full five-component calendar still unavailable. No main, merge, release or production changes.
