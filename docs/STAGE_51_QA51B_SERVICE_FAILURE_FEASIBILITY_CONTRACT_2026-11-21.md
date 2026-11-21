# Stage51 / QA51-B — supported service-failure feasibility contract (2026-11-21)

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Authorized branch: COBOL+简体中文
Audited source HEAD: 5609f1c126921c7cfb6f3c817661542167c50723
Audit scope: Stage51 post-acceptance negative-path QA only. NO Stage52, no main/merge/release, no production modification.
Evidence class: SOURCE-GROUNDED FEASIBILITY / TEST DESIGN ONLY. This document is NOT a test run, CI PASS, Native PASS, injected allocation failure, or acceptance.

## Exact source and ABI inspected

- `src/monster_distance.cob` blob `100c52e9c459c1ea1a1cfa291b459fe55da4f583`, lines 57-80: dispatcher validates input signs (status 22) and occupied output (status 175), then calls `PATCHED-DISTANCE`.
- `src/patched_distance.cob` blob `4e8412030716debca481306ba28be805ade76326`, lines 57-129: local temporary diff/one; SUB, INIT-TEXT("1"), ADD; cleanup FREE-A; on service failure returns that failure code and attempts to FREE-A a partial result.
- `src/big_integer.cob` blob `982c1f266a18c2bcaba79b994177a93750f27bfa`, lines 198-265: nine BY REFERENCE operands `OP, TEXT, TEXT-LEN, A, B, OUT, REM, CMP, STATUS`; `INIT-TEXT` clears scratch R, parses, exports on success, otherwise frees only local R.
- Same file lines 875-905: `INIT-TEXT` length outside [1,8192] returns status **43**; sign-only input or non-decimal character returns **44**, before any `PREPEND-CHUNK-R` allocation (which begins at line 954).
- Same file lines 234-235: `HEAP-LIVE` directly returns tracked live-allocation count in TEXT-LEN and leaves STATUS=0. There is no failure-injection parameter or failure branch in that operation.
- Same file lines 439-449 and 1710-1768: `TO-TEXT` has a fixed 8192-byte buffer; malformed descriptor yields 49 or output overflow yields 45. An overflow cannot safely be assumed reachable from existing valid Stage51 inputs without a separate source-specific witness. `FREE-A` frees the supplied owner and clears its descriptor; deliberately corrupting a live pointer is unsafe and is NOT an authorized fault-injection method.
- `test/stage51_discovery_tests.cob` blob `28bc4d9b4a96e25f9443f32b2c0a19b6d921173a`, 829 lines max 72 columns, already has 25 cases, 5 independent output owners per case, `CHECK-DISTINCT`, `CHECK-INPUT-PRESERVED`, unconditional `CLEANUP-CASE`, `MEASURE-HEAP`, and a real invalid-sign probe.
- `.github/workflows/canonical-names-lock.yml` Stage51 job already compiles with GnuCOBOL strict `-Werror`, asserts 25/25 Native cases and existing counters, and uploads `stage51-native.log`. No extra job or stage is needed.

## Supported deterministic witness chosen: INIT-TEXT input validation

This is a **real direct BIG-INTEGER-SERVICE failure**, not a mock and not an allocator/production failure. Inject it only through documented ABI inputs with five already-live, independently owned Stage51 outputs. Probe an independent zero/NULL OUT descriptor; never alias an existing output. Use an independent input `TEXT` buffer and a fresh `TEXT-LEN` value on each call. Do not alter the five live outputs, C/T descriptors, or their pointers.

The independent, source-derived oracle is the explicit parsing predicate in `PARSE-TEXT-INTO-R`, **not** the return value of the implementation under test.

| Witness | TEXT | TEXT-LEN | Expected status | Why |
| --- | --- | ---: | ---: | --- |
| A | `1#` | 2 | 44 | `#` is not a decimal digit; parser exits before allocation |
| B | empty/spaces | 0 | 43 | Invalid length, checked before parsing |
| C | `-` | 1 | 44 | Sign consumes all input; no digit remains |

For each of the current 5 widths (3, 9, 128, 320, 8192) × 5 ordered pairs, exercise A, B, C once: **25 cases × 3 rejects = 75 expected service rejections**. Treat each status as an exact numeric equality, never merely nonzero. The oracle does not depend on another branch, copied fixtures, or the Stage51 output arithmetic.

### Measurable assertions in the future test-only patch

1. Preconditions before probe: exactly five live distinct outputs with valid saved descriptors; two valid C/T descriptors; zero/NULL probe OUT; `HEAP-LIVE` baseline returned status 0 with nonzero live count. Record baseline immediately before the first failure probe.
2. For A/B/C independently, use `CALL "BIG-INTEGER-SERVICE" USING WS-OP WS-TEXT WS-LEN WS-EMPTY-A WS-EMPTY-B WS-EMPTY-OUT WS-EMPTY-REM WS-CMP WS-STATUS` with `WS-OP="INIT-TEXT"`. Ensure these scratch/empty descriptors are zero/NULL beforehand. Assert status exactly 44/43/44 respectively; OUT sign/chunks/head/tail are still zero/NULL.
3. After **each** probe, require `CHECK-DISTINCT` and `CHECK-INPUT-PRESERVED` to pass. This includes exact saved metadata, independent expected decimal serialization, and no duplicate live head pointers. The probe must not consume or mutate C/T.
4. Require `HEAP-LIVE` status 0 and count equal to the pre-probe baseline after each rejection. This checks zero new retained allocations; it does not certify that an allocator failure was exercised.
5. Continue the unchanged Stage51 success lifecycle and unconditional release. Each of 25 cases must end at measured `HEAP-LIVE=0`, with all C/T/probe/output descriptors cleared and all existing Native counter assertions retained.
6. Fail closed if any precondition, status, descriptor, snapshot, heap measurement, or cleanup assertion fails; emit `STAGE51_INIT_VALIDATION_REJECTS=00075` and explicit marker `STAGE51_INIT_VALIDATION_GATE=PASS` only after the 75 real service calls and all invariants passed. A separately checked CI numeric marker should reject any count other than 75. Keep all original gate markers and the single Stage51 job.
7. Static gate before push: ensure test source <=72 columns, no duplicate COBOL names, unchanged production blobs above, unchanged Stage51 planning oracle, expected workflow job count 52; use exact blob/branch readback. CI gate after natural push: exact SHA and attempt, completed 52/52 jobs, strict GnuCOBOL executable and Stage51 output markers, independent artifact ZIP SHA256/CRC with embedded PROJECT_ID and HEAD.

Do not claim these assertions have executed. A static checker or planning oracle alone cannot satisfy the Native or differential gates.

## Coverage distinction and exclusions

**What the chosen witness can establish if actually run:** direct `INIT-TEXT` validation failure returns a specified status, leaves an unoccupied output unchanged, preserves five other live owners and the two inputs, does not retain extra heap allocations, and allows subsequent cleanup.

**What it cannot establish:** allocator denial, `INIT-TEXT` allocation failure after partially constructed R, `TO-TEXT` failure in the production call path, `FREE-A` failure in cleanup, `HEAP-LIVE` failure, or the `PATCHED-DISTANCE` internal cleanup branch caused by an injected subordinate failure. Existing `PATCHED-DISTANCE` always passes valid literal "1" to `INIT-TEXT`; malformed direct-service probes do NOT reach that internal call. Do not claim generalized error-path coverage from 75 direct parser rejects.

There is no currently verified supported service ABI knob for allocator/cleanup fault injection. Never simulate it by corrupting a pointer, freeing a live owner out of contract, replacing production calls with a mock, patching the heap counter, or inventing a status. A future injectable seam would be a separate design/change decision; it is **not** authorized or implemented here.

## Baseline and acceptance provenance

Formal Stage51 Native acceptance remains the historical 99a291cb source and verified run 44811119586. Post-acceptance invalid-sign source SHA `1d6573306b344c3ebb555649ce46fcc11c94e3b2` was verified in run 44884376577, job 136786359002, 52/52 jobs, strict Native 25/25; artifact 14700371157 SHA256 `5e5aa7964c67d5030ca41ceb178f55ec9b95a803c628d152dd11540337d9c46a`, CRC and embedded identity/head checked. These results are NOT evidence for the proposed INIT-TEXT witness. The subsequent docs-only HEAD 5609f1c126921c7cfb6f3c817661542167c50723 has no separately claimed Native result.

## NEXT

Implement **test-only** the three direct `INIT-TEXT` validation probes within the existing Stage51 five-owner lifecycle, with the numeric and ownership/heap assertions above; minimally extend the existing Stage51 CI gate without opening Stage52. Independently check source and workflow before/after, then inspect only a natural exact-SHA completed run and artifact. If source constraints disprove the contract during implementation, document the contradiction and revise rather than inventing a PASS. Other QA51-B forced service failures stay uncovered and must be explicitly recorded as such.
