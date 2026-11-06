# Post-Stage55: preflight atomicity and one-step Native budget QA

Project: PC-BRANCH-TYPESCRIPT-MARATHI / TypeScript+मराठी
Parent: 2b766162b0e7917d0b8500614e1086dfaf61a835
Prerequisite: exact-SHA Actions 41711700565 completed/success, five of five jobs; negative signed marker with seven pairs, 35 components, five independently ranked families, zero mismatches and physical Patch11 856 calls / 49,648 writes.
Scope: test, package and workflow only. This is NOT Stage56, NOT a new calendar rule, and NOT a permission to merge or release.

## Coverage gap and choice

Accepted public positive/negative date tests verify correctness but do not measure whether invalid typed arguments and malformed execution budgets consume physical Patch11 Native work before rejection. The signed gate factory accepts an explicit positive safe-integer per-side execution budget. This add-on tests the early rejection contract and the first valid budget boundary, without duplicating expensive year-wide differential cases.

## Input, output, independent assertion

Ninety-seven rejection probes: nine invalid runtime day representations (number zero, NaN, Infinity, string, null, undefined, object, array and boolean) across both argument positions in four public/production entrypoints = 72; eight invalid gate budgets in the prefix and request factory = 16; seven invalid year-walk budgets = 7; two enormous signed bigint inputs accompanied by invalid zero budgets = 2. Every probe must throw MonsterValidationError and complete zero physical Patch11 runs and zero memory writes. Invalid numeric types must not be silently coerced.

One valid-bounded probe: calculation and target day equal FOUNDATION_DAY + 1n, maxPerSide = 1. The first real positive gate gap is 41 + rank with rank in [1,922], thus at most 963 days. A prefix must cover the requested upper neighbourhood at radius 5782 days, so a single gap cannot meet the coverage precondition. Its next iteration must reject the budget before a second Native run. Require exactly one completed physical Patch11 call, exactly 58 writes, and MonsterValidationError; any success, unexpected exception, or a second call fails. Count physical Patch11.run results, not only Patch14 dispatches. Always restore the prototype in finally.

## Acceptance and boundaries

Run this test once in the existing Stage27 npm test chain, without adding a sixth heavy CI job. Exact marker:
POST_STAGE55_PREFLIGHT_ATOMICITY_PASS malformedRejected=97 preflightNativeCalls=0 boundedNativeCalls=1 boundedSharedWrites=58 budgetExhausted=1

The existing five jobs remain required. Exact-SHA completed/success plus actual marker in the Stage27 log is required before accepting this follow-up. Syntax validation alone is not runtime/Native PASS. No src changes, Stage56, main merge, release, or external publication.

## Follow-up: two-sided execution-budget QA (2026-11-04)

After exact-SHA Actions 41868643598 completed/success (5/5), Stage27 logged the accepted
97-rejection preflight and one-step Native budget marker. This independently bounded
extension covers the missing positive/negative budget-exhaustion paths without changing
production semantics, input formats, or the 97 previous probes.

For maxPerSide in {1, 2, 3}, call the production signed-gate prefix for c=t=FOUNDATION+1
(positive exhaustion) and c=t=FOUNDATION-100000 (negative exhaustion). Each native
Patch11 call advances a strictly positive gap 41+rank with 1<=rank<=922, hence
42<=gap<=963. Since the complete requested radius is LEGACY_YEAR_MAX+1=5782,
three calls cannot reach the positive bound from FOUNDATION+1. For the far-negative
case, the positive walk must make exactly one Native call before reaching the
negative-side loop, and that loop cannot reach the lower requested bound in
three steps. Thus the expected physical Patch11 counts per budget k are k (positive)
and 1+k (negative). The independent oracle counts physical calls and 58 shared
writes per call, not Patch14 dispatches. Require MonsterValidationError on all six
probes and exact per-probe deltas: 6 positive calls + 9 negative calls = 15 Native
calls, 870 shared writes; no acceptance of a partial prefix.

Exact additional CI marker:
POST_STAGE55_SIGNED_BUDGET_SIDES_PASS probes=6 positiveCalls=6 negativeCalls=9 totalCalls=15 totalSharedWrites=870 budgetExhaustions=6

Acceptance is contingent on a new exact-SHA Stage27 completed/success log with both
old and new preflight markers, plus all other four existing workflow jobs completed/
success. This extends test/docs/CI grep only: no production changes, no Stage56,
no main/merge/release. Previous 41868643598 result is historical PASS for its
own SHA, not acceptance of this new extension.

## Follow-up: count attempted Native invocation before dispatch (2026-11-04)

Exact-SHA Actions 41878905211 completed/success on 80a89db5b2728d9dfa07925489fb666b65fd0345 (5/5 jobs). The earlier guard counted only *completed* Patch11.run results. A Native invocation that threw before returning could therefore escape the count. This follow-up closes that instrumentation gap: the test-only wrapper increments an independent entry counter **before** invoking Patch11.run, then increments completion and write counts only after validating a returned physical run. This does not change production or posit a reproduced bug.

Independent check: each of 97 invalid inputs must have zero attempted calls, zero completed calls and zero writes. The original valid one-step test must have one entry/one completion/58 writes. Across six separately bounded positive and negative budget-exhaustion probes, every physical-call delta must agree with the entry delta and the documented mathematical oracle k versus 1+k for k in {1,2,3}. Global total = 1+(1+2+3)+(2+3+4)=16 entries, 16 completions, 16*58=928 writes. The wrapper is always restored in finally. The old two accepted markers remain byte-for-byte unchanged; the new exact marker is:

POST_STAGE55_PREFLIGHT_NATIVE_ATTEMPTS_PASS invalidProbes=97 invalidAttempts=0 boundedAttempts=16 boundedCompletions=16 boundedWrites=928

Acceptance: existing five CI jobs must complete successfully for the exact new SHA; the Stage27 log must contain all three preflight markers, and the branch ref and changed file blobs must read back. Scope limited to test/docs/workflow and no new heavy jobs, no production changes, Stage56, main merge or release. Until completed logs are inspected, this is a test change and not a new-SHA PASS.

## Follow-up: write-46 physical Native throw and clean recovery (2026-11-06)

The accepted exact-SHA run 41978416339 on a4884e4d58e414cf3fadec4ffd374f15f5e3091e passed all five jobs and the original three Stage27 preflight markers, including 97 invalid attempts rejected before Patch11 and 16 completed bounded calls (928 writes). This enables a small, test-only reliability extension, not Stage56 or a production change. No production fault is asserted.

Input: c=t=FOUNDATION_DAY+1n with maxPerSide=1. On the first physical Patch11 call, run the real handler with its after-write callback; throw a unique sentinel at real write #46 (after the legacy shared write). Require exactly one entered Native invocation, zero completed Native invocations, exactly 46 observed real write callbacks and the SAME sentinel propagated by the signed-gate production factory. The factory must not return a partial prefix. The callback instrument is test-only and restored in a finally block.

Recovery oracle: retry the identical valid input without the injected fault. The first complete native result must report 58 shared writes (and 58 historical writes), then the known mathematical 1-step budget bound must throw MonsterValidationError before a second Native entry because one gate advances at most 963 days, while the neighbourhood radius is 5782. Cumulative entries=2, completions=1; fault callback writes=46; clean completed writes=58. Assert original Patch11 prototype restored. No extra year differential or workflow job.

Exact Stage27 marker: `POST_STAGE55_PREFLIGHT_NATIVE_THROW_RECOVERY_PASS injectedWrite=46 faultEntries=1 faultCompletions=0 faultWrites=46 retryEntries=1 retryCompletions=1 retryWrites=58 propagated=1 recovered=1 restored=1`.

Acceptance requires completed/success all five existing jobs and this exact new marker plus the three old preflight markers on the new commit SHA. Syntax check is not Native acceptance. Do not merge, change main, or release.


## Follow-up: valid extreme signed-bigint budget with physical Native accounting (2026-11-06)

Prerequisite: exact-SHA run 42172555915, commit 406cdbda1ac2d7edc9259646143918acf8639761, **completed/success for all five jobs**; the Stage27 log contains the four accepted preflight markers, including the write-46 throw/retry witness. This is bounded QA within the accepted post-Stage55 integration, not Stage56 or a new calendar rule.

Gap: the 97-probe preflight matrix checks enormous signed bigint values paired with an **invalid** execution budget, but has no accepted test for enormous valid bigint inputs with a *valid* one-step Native budget. A preflight rejection on invalid budget does not prove the valid budget path is free of precision loss or unbounded work.

Independent arithmetic oracle: define H=10^500 and FOUNDATION=-15055671. Every physical signed gate advances 41+rank days, with 1<=rank<=922, hence 42<=gap<=963. The requested radius is 5782 days. Check H>FOUNDATION+6745 and -H<FOUNDATION-6745 before testing. For (c,t)=(H,H), maxPerSide=1, the first positive Patch11 call completes but cannot cover the upper neighbourhood; budget exhaustion must happen before the second call: exactly 1 Native entry/completion and 58 writes. For (c,t)=(-H,-H), the first positive gate is already above the negative upper neighbourhood and takes one physical call; one negative gate still cannot reach the lower neighbourhood. Budget exhaustion must happen before a second negative call: exactly 2 total Native entries/completions and 116 writes. Both calls must throw MonsterValidationError, not return an incomplete prefix. Total: 2 probes, 3 physical calls, 174 historical writes. Restore the Patch11 prototype in finally.

Implementation scope: test/postStage55HugeSignedBudget.ts, one npm script/registration, one Stage27 CI grep and this contract appendix; no src, names, main, merge, release, new heavy CI job, or manual duplicate dispatch. The QA marker is:

POST_STAGE55_HUGE_SIGNED_BUDGET_PASS probes=2 digits=501 positiveEntries=1 negativeEntries=2 completions=3 sharedWrites=174 restored=1

Success of Node's syntax check is not TypeScript/Native acceptance. Accept only on a **new exact SHA** if all five Actions jobs complete successfully and the new Stage27 log contains this marker plus all four prior preflight markers; otherwise repair from the failing step/log and do not claim PASS.

## Follow-up: physical negative-gate fault after positive success (2026-11-06)

Prerequisite: exact-SHA Actions 42176982226 on cf184345c27b1504e5eab3a74911b566adc8d643 completed/success all five jobs. The Stage27 log contains the exact huge signed 501-digit/3 Native/174-write marker plus the four previously accepted preflight markers.

This additional narrow QA covers a different physical failure point: the positive gate succeeds, but the following **negative** gate throws at its real write #46. Earlier fault injection tested the first (positive) gate only. This is a test coverage gap, not evidence of a production defect.

Input: calculationDay=targetDay=FOUNDATION_DAY-100000n, maxPerSide=1. The production factory's positive loop must perform one physical Patch11 call, with 58 completed shared writes, because its first positive gate is already above the requested upper neighbourhood. Its first negative call then performs 46 real write callbacks; a test-only callback throws a unique sentinel. Require the identical sentinel to propagate with exactly two Native entries, one completed call, 58 completed writes and 46 observed negative-side writes. No partial prefix may return.

Independent bounded recovery oracle: call the same valid inputs again without a fault. The one permitted negative step moves at most 963 days (41+rank, 1<=rank<=922), strictly short of the 100000+5782-day lower bound. The factory must reject the next step with MonsterValidationError **before** entering another Native handler. The retry thus makes exactly two complete 58-write calls. Cumulative counts across fault and retry: four entries, three completions, 174 completed writes, and the fault's 46 observed callbacks. The original Patch11.run is always restored in finally.

Exact marker: `POST_STAGE55_NEGATIVE_NATIVE_THROW_RECOVERY_PASS injectedWrite=46 firstPositive=1 faultNegative=1 faultWrites=46 retryPositive=1 retryNegative=1 totalEntries=4 totalCompletions=3 completedWrites=174 propagated=1 recovered=1 restored=1`

Scope is one test-only file, package script/registration, Stage27 grep and this contract. No production code, no heavy new CI job, no Stage56, no main/merge/release. New exact-SHA typecheck + full npm test with this marker and four other completed-success jobs are mandatory before claiming the follow-up PASS. A new queued/in_progress workflow is NOT a blocker and is NOT acceptance.

## Follow-up: failure on the final negative physical write (2026-11-06)

Prerequisite: Actions 42188182926 completed/success on exact `c5675691993f4fcea0cdcb907237282db38989f3` with five successful jobs. The Stage27 log recorded the previous negative-side fault at write #46, exact recovery, and all five preflight markers. This is additional bounded reliability QA in the existing Stage27/Post-Stage55 test scope, not Stage56 or a known production bug.

Coverage gap: the after-write hook of the real Patch11 Native handler fires on write #58 as well as #46. A fault on the **last** write is different from a midstream fault: all 58 physical historical writes have occurred but the Native handler must still not report a completed return. The caller must propagate the original fault and must not accept any partial prefix. Exercise the same production signed-gate factory with `calculationDay=targetDay=FOUNDATION_DAY-100000n`, `maxPerSide=1`. Use a test-only injected sentinel at the second physical invocation's actual shared-memory write #58, after one positive 58-write completion. Require the identical sentinel and exact counts: entries=2, successful Native returns=1, completed shared writes=58, faulty invocation callbacks=58.

Independent recovery bound: the negative one-step gap is at most 963 days while the requested lower neighbourhood exceeds it by more than 100000 days. Retry without injecting another fault. The retry makes exactly two completed physical calls (one positive, one negative, 116 completed writes) before rejecting the execution budget with MonsterValidationError, without a third call. Cumulative per fault position: entries=4, completions=3, completed writes=174, injected callbacks=58. Restore Patch11.prototype.run in finally. Preserve the existing write-46 marker, and additionally require exactly:

`POST_STAGE55_NEGATIVE_FINAL_WRITE_THROW_RECOVERY_PASS injectedWrite=58 firstPositive=1 faultNegative=1 faultWrites=58 retryPositive=1 retryNegative=1 totalEntries=4 totalCompletions=3 completedWrites=174 propagated=1 recovered=1 restored=1`

Implementation updates the existing Stage27 test, this contract and one workflow grep; no package scripts, runtime production source, main, merges, release, extra jobs, or rerun of a previously accepted SHA. Accept this extension only after a new **exact-SHA** five-job completed/success CI and actual Stage27 marker. Until then the change is unverified Native QA.
