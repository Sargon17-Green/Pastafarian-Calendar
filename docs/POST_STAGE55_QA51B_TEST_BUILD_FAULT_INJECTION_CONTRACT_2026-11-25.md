# Post-Stage55 QA51-B — test-build-only fault-injection diagnostic

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE  
Authorized branch: COBOL+简体中文  
Baseline branch HEAD: 5574f8ae5029aa7c4941c030b6b671217e3c603a  
Tested Stage55 source: d05b92288d70ae4fd1659d3cd478c89b0a2f49cc  
Scope: a separately requested, supplemental QA diagnostic. This is NOT Stage56, does not change the accepted 55-stage plan, and does not start full-calendar integration.

## Purpose

The user explicitly requested continuation after checking Stage55 completion. This scope advances the four disclosed QA51-B residuals using a deterministic test-build-only fault controller. The test build compiles an instrumented temporary copy of the real BIG-INTEGER-SERVICE plus the unchanged tracked PATCHED-DISTANCE source. No tracked production COBOL source is edited.

## Exact test-build architecture

1. Copy src/big_integer.cob to a temporary build directory and verify its tracked Git blob is 982c1f266a18c2bcaba79b994177a93750f27bfa.
2. Rename only the temporary copy's program ID to BIG-INTEGER-SERVICE-REAL.
3. Insert one test-only ALLOC-R hook before the PREPEND-CHUNK-R allocation. A one-shot controller can return a chosen status before the second allocation, after the first chunk has already been allocated.
4. Compile a test-only BIG-INTEGER-SERVICE shim. For a one-shot selected operation (SUB, INIT-TEXT, ADD, FREE-A, or HEAP-LIVE) it returns an exact injected status before delegating; otherwise it calls the instrumented real service.
5. The production src/patched_distance.cob is compiled unchanged and calls the shim through its existing nine-argument service ABI.
6. All injected faults are one-shot. The test checks descriptor snapshots, exact returned statuses, heap baseline restoration and final zero.

The instrumented copy, shim and controller are not the production executable. Their output is labelled PASS_TEST_BUILD_ONLY, never Native production acceptance.

## Seven bounded scenarios

| Scenario | Injection / input | Required result |
|---|---|---|
| Normal control | C=1000, T=990 | Real PATCHED-DISTANCE result is exactly 11; result owner released |
| Partial construction abort | 18 digits, fail second ALLOC-R check with status 96 | First allocated chunk is released by INIT-TEXT error cleanup; output remains empty; heap returns to baseline |
| Valid-owner FREE-A boundary failure | Inject status 94 before real FREE-A on a valid two-chunk owner | Descriptor and heap remain unchanged; one-shot retry performs real free and restores prior heap |
| HEAP-LIVE boundary failure | Inject status 95; initialize text length to sentinel 777 | Status 95 propagates and sentinel remains 777; subsequent real measurement returns the original count |
| PATCHED-DISTANCE / SUB failure | Inject status 91 | Exact status propagates; output empty; inputs preserved; heap baseline restored |
| PATCHED-DISTANCE / INIT-TEXT failure | Inject status 92 after successful SUB | Local difference owner released; output empty; inputs preserved; heap baseline restored |
| PATCHED-DISTANCE / ADD failure | Inject status 93 after SUB and INIT-TEXT succeed | Both local owners released; output empty; inputs preserved; heap baseline restored |

Independent oracle: abs(990 - 1000) + 1 = 11; the 18-digit partial-construction input is exactly two base-10^9 chunks. The oracle is separate from the COBOL implementation.

## Four residuals — exact evidence limits

- Allocation denial / partial construction: the diagnostic can prove cleanup after a controlled parser abort between chunk allocations. It does NOT force the operating system to deny memory. GnuCOBOL's documented ALLOCATE syntax has no ON EXCEPTION phrase; the documented exception clauses apply to ACCEPT, CALL, and DISPLAY. Therefore a test-only pre-allocation status is not evidence of recoverable OS out-of-memory handling. True allocator exhaustion remains explicitly NOT TESTED.
- Valid-owner FREE-A failure: the shim injects a service-boundary status before the real operation. It proves that the caller's valid descriptor is preserved and can be retried; it does not demonstrate an internal failure of GnuCOBOL's FREE or of the real FREE-A implementation.
- HEAP-LIVE service failure: the shim injects a status before the real operation. It proves the caller does not consume a stale length as a measurement and can retry. The real HEAP-LIVE branch itself has no error-producing statement; this is not a claim that an internal heap-measurement failure was reproduced.
- PATCHED-DISTANCE cleanup: this is the strongest dynamic witness: injected subordinate failures are returned through the existing service ABI while the actual tracked PATCHED-DISTANCE procedure executes its cleanup. Success requires unchanged C/T descriptors, empty result, and exact heap baseline after each failure.

No pointer corruption, dangling pointer, aliased owner, heap-counter mutation, real memory exhaustion, production edit, merge, main change, release, or full-calendar integration is permitted by this contract.

## Acceptance gates

- Exact parent and tracked source blobs are checked before instrumentation.
- Git diff from the parent is exactly the QA files listed in the workflow; git diff --exit-code HEAD -- src must pass.
- Compile with GnuCOBOL strict flags including -Werror.
- Seven cases, all assertions, all expected injected statuses, heap baseline after each case, and final HEAP-LIVE=0.
- Preserve logs and temporary-source diff on pass or failure.
- Only this test-build diagnostic can be accepted from this run. It does not reopen or reaccept Stage55, close true OOM/real FREE-A/real HEAP-LIVE failures, create Stage56, or assert whole-calendar completion.

NEXT: inspect the natural exact-SHA run, job log and artifact; diagnose any compile/runtime failure before a narrow test-only repair. Keep the four nonclaims above in the tracker.

## CI wiring correction — 2026-11-25

The repository's existing canonical-names-lock workflow is the active push-triggered workflow on this branch. A newly added standalone workflow file was not discovered as a run for the branch commit, while the existing canonical workflow did run. To avoid claiming a run that does not exist, the standalone workflow is removed and this diagnostic is appended as one supplemental job to the already-active canonical workflow. Expected total: 57 jobs (the existing 56 plus this separately labelled diagnostic job). This does not create Stage56 or change the 55-stage acceptance.
