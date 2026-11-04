# Stage36 / DISCOVERY32 — 占用输出槽拒绝与释放后重试 (2026-11-04)

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage35 accepted on exact a80c1e9d8ad62f59883e07cd5a5a90ff7d1f0cd3, run 41775780778 completed/success 36/36, GnuCOBOL 3.1.2.0 strict -Werror, native 24/24, heap-live 0.
Evidence: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41775780778/artifacts/13297375640

## Independent engineering target

Stage35 tested opposite-sign maximum-width output, but did not exercise rejection of a previously populated caller-owned result slot. Stage36 probes the MONSTER-DISTANCE validation rule that rejects occupied result objects with status 175, preserves original input and occupied output, and recovers after an explicit FREE-A. This is a new bounded, black-box observable behavior of this branch. No defect/expected-red is assumed.

## Deterministic 24-case contract

For n in {3,9,320,8192} and j in {1,...,6}, let A=10^(n-1)+(j+2) and T=10^(n-1)-(j+1), both positive. Odd j uses c=A,t=T; even j swaps operands. The 24 ordered pairs are distinct. The independent decimal oracle for |c-t|+1 is 2*j+4 = {6,8,10,12,14,16}, with exactly six cases at 8192-character input envelope.

Before each call, initialize both integer input records via INIT-TEXT and initialize output to decimal 777 via INIT-TEXT. Snapshot sign, chunk count, head and tail pointers for all three objects. The first call to MONSTER-DISTANCE/DISTANCE-PATCH MUST return 175, leave both inputs and the occupied output object untouched, and still permit TO-TEXT(output)=777 exactly. Explicitly release output via FREE-A and retry the same ordered input pair. The retry MUST succeed with message PATCH03:DISTANCE-PATCH and TO-TEXT equal the oracle. Verify both input records still match snapshots, release output and both inputs, and probe HEAP-LIVE=0.

The independent static oracle uses JavaScript BigInt on each full literal and compares it to the separate closed-form 2*j+4; do not import fixtures or code from other branches. Gate requires 24/24 oracle equality, 24 distinct ordered pairs, six width-8192 cases, maximum source line <=115.

## Native CI gate

Target branch and SHA exact; all prior jobs remain successful plus Stage36 (expected job count 37). Linux GnuCOBOL 3.1.2.0, strict -Werror; compile <=300s, executable <=120s, job <=20 minutes; upload diagnostic log even on failure. Required markers:
STAGE36_REJECTS=24
STAGE36_SENTINEL_INTACT=24
STAGE36_RUNS=24
STAGE36_PASS=24
STAGE36_UNEXPECTED_FAILURES=0
STAGE36_HEAP_MEASURED=YES
STAGE36_HEAP_LIVE_POST_RELEASE=0
RESULT=PASS_STAGE36_OCCUPIED_OUTPUT_RETRY_DISCOVERY_NATIVE
STAGE36_NATIVE_GATE=PASS

Static preflight is not Native evidence. If CI fails, diagnose that exact log before any acceptance. No main/merge/release, no production source edits, and no general calendar integration assertion.
