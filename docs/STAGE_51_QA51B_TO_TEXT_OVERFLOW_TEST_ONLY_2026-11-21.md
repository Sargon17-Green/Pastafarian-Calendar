# Stage51 QA51-B TO-TEXT overflow: test-only implementation

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Parent SHA: f128dacea1a990c56b5f4940dde604123d1d6880
Status at authoring: SOURCE+CI COMMITTED ONLY; Native and whole-stage acceptance are NOT claimed.

Independent oracle: for M=10^8192-1, C=M, T=-M, patched distance |T-C|+1=2*10^8192-1 has exactly 8193 decimal digits. Two distinct legal INIT-TEXT magnitudes are loaded; T gets sign -1 in its descriptor. Real MONSTER-DISTANCE / DISTANCE-PATCH computes a distinct third owner. Real BIG-INTEGER-SERVICE TO-TEXT is expected to report status 45 with text length 0 because its buffer holds at most 8192 digits. Partial contents of the text buffer are explicitly not asserted.

The post-25-case test requires initially zero measured HEAP-LIVE; distinct C/T/result owners; owner-group snapshots; unchanged heap after TO-TEXT rejection; safe actual FREE-A of three owners; and final measured heap zero. Only full success increments STAGE51_TO_TEXT_OVERFLOW_REJECTS to 1 and emits STAGE51_TO_TEXT_OVERFLOW_GATE=PASS. Failures add to unexpected failures and prevent the main success result. Descriptors observed mutated are not passed to FREE-A. No allocator/OS failure was injected.

The existing strict Stage51 job now asserts the numeric 1 and explicit PASS marker in addition to all prior checks. Test and workflow are changed without touching production or opening Stage52. Static source checks: 1328 COBOL lines, maximum width 72, one probe paragraph, prior gates retained. These are static checks, not GnuCOBOL compilation or Native PASS. NEXT: completed natural exact-SHA push run (52 jobs), Stage51 strict native job/log, independently checked ZIP digest/CRC/PROJECT_ID/HEAD. No duplicate dispatch.
