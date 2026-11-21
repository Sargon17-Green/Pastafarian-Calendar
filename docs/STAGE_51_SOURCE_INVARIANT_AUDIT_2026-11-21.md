# Stage51 / DISCOVERY47 — source invariant and coverage audit (2026-11-21)

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Authorized branch: COBOL+简体中文
Audited HEAD before patch: fd06df3def010a10c877817fcb31f1950b71aebc
Accepted executable source: 99a291cb189a5efc35f3c1c1d5d80c43fb5691c3
Audited Stage51 COBOL blob: 470f0e2673e240d4539b212c20f6e9a62e76407b
Scope: existing Stage51 only. No Stage52, production change, merge, main, or release.

## Prior verified runtime evidence (not evidence for this patch)

- Natural push run 44820017879, attempt 1, exact audited HEAD: completed/success, 52/52 jobs completed/success.
- Stage51 job 136578184990: completed/success, 25/25 Native cases, 25 occupied-output rejects, 5/5 slots balanced, zero unexpected failures, 26 measured heap probes, final live heap 0.
- Artifact 14673261090: 750-byte ZIP, GitHub digest SHA256 01c82684b1801b84c7b583763030f4cb285fb60828821d310864c1adfe05bc41. Historical acceptance remains run 44811119586, artifact 14667696720.
- This audit and its test-only patch are NOT independently Native-accepted merely because the earlier source passed.

## Source traceability (audited file line numbers refer to pre-patch blob)

| Invariant | Existing source | Finding |
|---|---|---|
| Five widths x five pairs, 25 cases | 161-175, 582-594 | Covered by the accepted bounded run |
| Five owned outputs, distinct live heads and exact decimal text | 233-246, 416-440, 678-746 | Covered; metadata, pointer aliasing and values checked |
| Input release/rebuild, positive/negative same-sign operands | 248-261, 292-304, 329-371, 501-548, 623-675 | Covered for successful initialization paths |
| Occupied-output rejection preserves five snapshots | 263-268, 442-468 | Covered (expected status 175); not a generic fault-injection test |
| Four survivors, selected free/reuse and original restoration | 269-319, 485-499, 716-729 | Covered for selected slot rotating 5,5,5,5,5 |
| End-of-case cleanup and measured heap | 321-327, 550-580 | 25 successful cleanups and measured heap 0; fault paths not induced |

## QA51-A: observed assertion coverage gap; fixed in this test-only patch

The original CLEANUP-CASE loop (551-555) called RELEASE-RESULT only if O-HEAD was non-NULL. RELEASE-RESULT checked all descriptor fields only for slots visited (749-764). Thus a slot with HEAD=NULL but nonzero sign/chunks or non-NULL tail could bypass the post-cleanup descriptor assertion. Similarly, RELEASE-C / RELEASE-T / RELEASE-PROBE were conditional on their HEAD fields. This is an assertion-path gap, NOT an observed malformed descriptor, leaked allocation, or production defect.

The same atomic commit adds unconditional checks of SIGN, CHUNKS, HEAD and TAIL for all five output descriptors and the C/T/probe descriptors after cleanup, before the existing HEAP-LIVE call. A mismatch sets WS-CASE-FAIL and is rejected by the existing per-case and final gate. No arithmetic oracle, fixture, ABI, expected counter, job policy or stage changes. The fixed guard must be assessed as STATIC until an exact new-SHA completed strict Native run is inspected.

## QA51-B: residual negative-path coverage gap; not fixed here

The accepted 25/25 run exercises success paths plus a deliberately rejected occupied destination. It does NOT establish coverage of injected INIT-TEXT, MONSTER-DISTANCE non-occupied errors, TO-TEXT, FREE-A, or HEAP-LIVE failures. Their recovery branches are present in the source but have no documented controlled fault-injection witnesses. An injection design must first define a supported, deterministic ABI-level failure and expected resource state; do not invent a failure status or assert expected-red. This is a limitation of evidence, not a demonstrated failure.

## Verification and next gate

Static preflight for this patch: exact prior blob and branch HEAD checked, unique cleanup anchor, fixed-form maximum source line width <=72, only Stage51 test and this report changed. No compiler or Native execution is claimed for the patch in this report.

NEXT: inspect the natural push run from this single atomic branch-only commit; require exact new HEAD, all 52 jobs completed/success, Stage51 strict -Werror, 25/25, exact counters, zero unexpected, measured final heap zero and artifact provenance/digest/CRC. If the run is not complete, retain existing Stage51 acceptance and do not mark this patch Native PASS. Then separately scope deterministic negative-path tests within the existing Stage51 contract, without opening Stage52.
