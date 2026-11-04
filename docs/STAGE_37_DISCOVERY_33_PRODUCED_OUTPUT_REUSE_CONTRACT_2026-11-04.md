# Stage37 / DISCOVERY33 — Produced-result ownership and repeated call (2026-11-04)

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage36 exact 4833c8a01655da8e830bcedeb31cfa4f0c0ddfbf accepted, 37/37 Native CI, 24/24 occupied-output/retry, zero measured live heap.
Evidence: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41869880583/artifacts/13342844748

## Distinct target

Stage36 used an artificially initialized output (777) before its rejection. Stage37 instead requires an output **actually produced by MONSTER-DISTANCE**, tests whether a second computation rejects overwriting its allocated result (status 175) without corrupting it, then frees the record and successfully recomputes. This tests a real production-result ownership lifecycle not exercised by Stage36. No defect or expected-red is presumed.

## Independent 24-case oracle and input contract

For n in {3,9,320,8192} and j in {1,...,6}, let X=10^(n-1)+(3j+1), Y=10^(n-1)-(j+2). For odd j call (c,t)=(X,Y); for even j swap. All values are positive, all 24 ordered pairs distinct, and the independent closed form for |c-t|+1 is 4j+4 (8,12,16,20,24,28). Compute each expected value separately with JavaScript BigInt from actual input literals and compare to the closed form. Exactly six input cases reach 8192 decimal characters; source line maximum 115.

For each case: INIT-TEXT both inputs, snapshot input sign/chunk-count/pointers; leave output structurally empty. First DISTANCE-PATCH must succeed (status=0, message=PATCH03:DISTANCE-PATCH) and TO-TEXT(output) must equal oracle. Snapshot produced output sign/chunk-count/head/tail. Immediately call identical operation into still-occupied output: must return status 175; both inputs and output metadata unchanged; TO-TEXT(output) still equals oracle. FREE-A output, verify empty record, make third call with same inputs: must succeed with exact message/oracle; verify inputs unchanged; release all records and measure HEAP-LIVE=0. No production change.

## Native contract and limits

All prior 37 jobs stay successful; add Stage37 for expected total 38 jobs. Strict GnuCOBOL 3.1.2.0 -Werror; compile timeout 300s, program timeout 120s, job timeout 20 minutes. Preserve full diagnostic log artifact even on failure. Required markers:

STAGE37_INITIAL_SUCCESSES=24
STAGE37_REJECTS=24
STAGE37_PRESERVED_OUTPUT=24
STAGE37_RETRY_SUCCESSES=24
STAGE37_RUNS=24
STAGE37_PASS=24
STAGE37_UNEXPECTED_FAILURES=0
STAGE37_HEAP_MEASURED=YES
STAGE37_HEAP_LIVE_POST_RELEASE=0
RESULT=PASS_STAGE37_PRODUCED_OUTPUT_REUSE_DISCOVERY_NATIVE
STAGE37_NATIVE_GATE=PASS

Source code/contract and static preflight are not Native acceptance. Do not claim production defect or full calendar integration without evidence; no main/merge/release.
