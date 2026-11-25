# Issue 29 — GMP family lifecycle regression draft

**Status:** source-only draft. Not compiled, not Native, not accepted, and not a calendar-converter result.

## Purpose and scope

This draft tests the resource lifecycle of **Canonical_Full_Weave_GMP_V164.Family** only. It does not invoke **F(c,t)**, the calendar converter, or a year-scale soak. It does not change the production package or resolve the already-recorded original Ada/Python month-index disagreement.

The exact source lock is:

- Spec Git blob: **0b68edf7eddbc33869358bcfcc21e32465fc591e**
- Body Git blob: **845bd8905943a54e63d6aba0334404a5051fe666**

The instrumentation generator refuses to proceed if either blob differs.

## Contract under test

### A. Fresh and pre-allocation states

1. On a fresh Family, **Count** and **Unrank(valid_rank)** must raise **Program_Error**.
2. Each of these invalid **Build** inputs must raise **Constraint_Error** before any **H** row allocation:
   - supplied length count differs from **Family.Month_Count**;
   - a late invalid month length, e.g. **(2, 124)**;
   - a null Natural_Array range;
   - total family length exceeds 5,778, e.g. 47 months of length 123 (5,781).
3. After each pre-allocation rejection, the same Family object must accept a legal **Build**. For 47 months, use 47 lengths of 2; assert Count > 0 and the independently enumerated lexicographically first word 11 22 ... 47 47, without asserting an unverified exact large count.

### B. Successful build and repeat behavior

For literal small-family oracles, assert exact **Count** and every one-based Unrank result:

| Month lengths | Exact lexicographic words |
|---|---|
| **(2)** | **11** |
| **(2,2)** | **1122**, **1212** |
| **(2,3)** | **11222**, **12122**, **12212** |
| **(3,2)** | **11122**, **11212**, **12112** |
| **(3,3)** | **111222**, **112122**, **112212**, **121122**, **121212**, **122112** |
| **(2,2,2)** | **112233**, **112323**, **121233**, **121323**, **123123** |

After a successful **Build**, a second **Build** on the same object must raise **Program_Error**; **Count** and all previously checked small ranks must remain unchanged.

### C. Partial allocation and finalization

The generator creates a temporary instrumented copy of the locked package body; no production hook is added. It places test-only counters and one-shot exceptions at these exact points:

1. immediately before the terminal **H(Month_Count)** allocation;
2. immediately after the terminal allocation succeeds;
3. immediately after the first lower-row allocation succeeds;
4. immediately after each successful **Free_Row** call.

Expected behavior:

- Injection before the terminal allocation leaves zero allocated rows; **Count**/**Unrank** still raise **Program_Error**, and the same object can be retried successfully after disabling injection.
- Injection after the terminal allocation leaves exactly one allocated row. **Count**/**Unrank** raise **Program_Error**; retrying **Build** raises **Program_Error**; leaving scope invokes **Finalize**, which frees that row exactly once.
- Injection after the first lower-row allocation leaves exactly two allocated rows (terminal plus first lower row). The same partial-state API/retry behavior applies, and **Finalize** frees both rows exactly once.
- No deliberate real out-of-memory condition is used. The probe injects a dedicated exception at deterministic source locations.

The tests deliberately do **not** claim a strong exception guarantee after allocation begins. A failed pre-allocation validation can leave a partially rewritten Lengths/Prefix prefix, but a subsequent legal **Build** rewrites those fields before allocation. Once the terminal row has been allocated, retry is rejected and the object is expected to be finalized rather than reused.

## Source-only verification

From the repository root:

    python3 tests/issue29_lifecycle_instrument.py --check

This checks the pinned source blobs, exact instrumentation anchors, generated source layout, and manifest. It does not call GNAT, compile Ada, execute the test driver, or dispatch CI.

To prepare a temporary tree for a separately authorized native run:

    python3 tests/issue29_lifecycle_instrument.py --output-dir /tmp/issue29-lifecycle
    cd /tmp/issue29-lifecycle
    (
      ulimit -v 1048576
      ulimit -t 180
      timeout -k 5s 180s gprbuild -p -j2 -P issue29_lifecycle_regression.gpr
    )
    (
      ulimit -v 1048576
      ulimit -t 180
      timeout -k 5s 180s bin/issue29_lifecycle_regression
    )

Those commands are instructions for a later authorized run, not evidence that a compile or Native test has occurred. No workflow or dispatch is added by this draft.

## Current evidence boundary

The separate v194 component-index test was repaired on its isolated QA branch by v195 commit **8d25c64a5fbc3435cad035ee4bb883c2ea370556**. The original v194 run **45655856525** failed at the source-lock guard before GNAT installation/build; it did not observe an algorithmic RED or GREEN. The v195 push run **45660563515** completed/success on that exact SHA; job **139368954902** passed all steps. Its verified artifact is **15044293608**, SHA-256 **ad11e958d03cc363153c088b2482cdeb4b4911f8a7881d8f129d762578009168**.

The v195 artifact records both baseline and candidate GNAT13/GMP builds succeeding, baseline exit code 1 with the expected **overflow check failed** at the maximum index, candidate exit code 0 with 1,422 assertions, six V194_BOUND_MATCH records, empty candidate stderr, and **calendar_calls=0**. This is a bounded Native component-index RED/GREEN for the helper's index arithmetic only. It does not execute the calendar converter, does not establish full-family lifecycle correctness, and does not accept a development stage.
