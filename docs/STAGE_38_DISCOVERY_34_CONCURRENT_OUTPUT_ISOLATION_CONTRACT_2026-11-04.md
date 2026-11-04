# Stage38 / DISCOVERY34 — Concurrent caller-owned outputs (2026-11-04)

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage37 exact SHA f4394026645b12441b56811c83110bbfd2f43e94; 38/38 successful Native CI jobs; Stage37 independent produced-output lifecycle accepted.
Evidence: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41875055246/artifacts/13347340618

## Distinct investigation

Stage37 reused one output record sequentially. Stage38 instead retains **two different simultaneous production-owned result records** for the same immutable inputs and asserts that freeing the first cannot mutate the second, even while the first is re-created. A reused pointer or shared allocated node is rejected; the contract presumes independently caller-owned output records (the established output ownership API). It is a bounded discovery, not a claim of an existing defect or expected-red.

## 24 independent witnesses and oracle

For n in {3,9,320,8192} and j in {1,...,6}, set B=10^(n-1), X=B+(5j+2), Y=B-(2j+5). Use (C,T)=(X,Y) for odd j, swapped for even j. The independent decimal oracle is abs(T-C)+1 = 7j+8, giving 15,22,29,36,43,50 for j=1..6. The emitted COBOL substrings are the two-decimal-digit suffixes of these expressions, checked against JavaScript BigInt and this closed form. All 24 ordered pairs must be unique, six input pairs attain 8192 digits, and all inputs must be positive. No copied cross-branch implementation or fixture.

For every case, parse C and T with INIT-TEXT; preserve sign/count/head/tail for both inputs. Call MONSTER-DISTANCE DISTANCE-PATCH into empty output A; require status 0, exact PATCH03:DISTANCE-PATCH and expected text. Without freeing A, call into distinct empty B; require status 0, exact message, correct text, non-null distinct result heads, and intact output A. Snapshot B sign/count/pointers, free A, assert B metadata and text unchanged. Recompute A while B remains live, assert both output values, distinct heads, preserved B metadata, and both inputs unmodified. Finally free both outputs and both inputs; assert measured HEAP-LIVE=0. Each case is PASS only if all assertions succeed.

## Native gate

Expected 39/39 CI jobs (38 previous + Stage38). GnuCOBOL 3.1.2.0 strict -Werror, compile timeout 300s, run timeout 120s, job timeout 20 min. Preserve Stage38 log even on failure. Required markers:

STAGE38_INITIAL_SUCCESSES=24
STAGE38_CONCURRENT_SUCCESSES=24
STAGE38_ISOLATED_OUTPUTS=24
STAGE38_RECREATED_SUCCESSES=24
STAGE38_RUNS=24
STAGE38_PASS=24
STAGE38_UNEXPECTED_FAILURES=0
STAGE38_HEAP_MEASURED=YES
STAGE38_HEAP_LIVE_POST_RELEASE=0
RESULT=PASS_STAGE38_CONCURRENT_OUTPUT_ISOLATION_DISCOVERY_NATIVE
STAGE38_NATIVE_GATE=PASS

Static oracle checks and source creation are not Native acceptance. If CI fails, inspect actual GnuCOBOL job log before classifying cause; no assumed expected-red. No production changes, main/merge/release, or assertion of full calendar integration.
