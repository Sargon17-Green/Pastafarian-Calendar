# Stage51 QA51-B: bounded FREE-A rejection — test-only contract

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Authorized branch: COBOL+简体中文
Parent verified HEAD: ad0b47a416c5e48074604257a60a9ba7f82d4d5d
Production big_integer.cob blob: 982c1f266a18c2bcaba79b994177a93750f27bfa
Scope: existing accepted Stage51, test-only negative-path extension. No Stage52, production, main, merge, release, or allocator instrumentation.

## Source oracle, independent of runtime result

At src/big_integer.cob 439-449, operation FREE-A executes LOAD-A-H1, UNREGISTER-H1-FROM-ARENA, FREE-H1 and clears the caller's A descriptor. At 579-589, REBUILD-H1-BACKLINKS rejects any nonzero SIGN paired with CHUNKS < 1 or HEAD=NULL using status 49, *before a node dereference*. At 1848-1851, UNREGISTER-H1-FROM-ARENA exits for NULL HEAD. At 1789-1802, FREE-H1 exits its loop for NULL HEAD and clears scratch. The FREE-A branch does **not** short-circuit on status 49; that is why the expected after-state is a cleared, not preserved, malformed scratch descriptor. No owned pointer is passed as the rejected argument.

For each of the already defined 25 Stage51 cases, with five existing distinct live outputs and two valid input descriptors, pass a separate four-field scratch A descriptor with SIGN=+1 and then SIGN=-1, CHUNKS=0, HEAD=NULL, TAIL=NULL. Keep B/OUT/REM separate empty zero descriptors. Use the same nine-operand BIG-INTEGER-SERVICE ABI as the existing test. Each of two direct FREE-A calls must return exactly 49, clear A completely to zero/NULL, leave the five output owners and both inputs intact, leave HEAP-LIVE equal to a nonzero measured pre-probe baseline, and leave the existing end-of-case HEAP-LIVE=0. All checks fail closed. Emit exactly 25*2=50 accepted direct rejections and STAGE51_FREE_A_GATE=PASS only when every case and its owner/heap checks pass. Extend the existing strict GnuCOBOL -Werror Stage51 CI job to reject any other count, retaining all previous gates.

## Explicit nonclaims

This is a **structural descriptor rejection** through the real FREE-A service and a bounded no-live-pointer free path. It does **not** inject an allocator fault, a failing OS FREE operation, a mid-operation error in PATCHED-DISTANCE, a failure of HEAP-LIVE, or any valid-owner release failure. The HEAP-LIVE operation (234-235) contains no status-setting error branch. Raw ALLOCATE statements (811, 955, 975, 995, 1018, 1039, 1294) expose no supported deterministic allocation-failure control. Forcing allocator exhaustion, editing production, passing dangling live pointers, or altering counters would breach the scope. No whole-stage acceptance is implied by source-only work.

## Evidence gates

1. Exact branch/HEAD and production blob verified before change; test + canonical CI + this contract committed atomically, no production edits.
2. Static gate: COBOL test source no line exceeds column 72, one bounded probe in the original five-live case lifecycle, numeric 50 + explicit PASS in the canonical Stage51 job.
3. Native **undecided until** a naturally triggered completed run on the *new exact commit* has 52/52 jobs completed/success, strict GnuCOBOL -Werror Stage51 25/25, FREE_A_REJECTS=50, FREE_A_GATE=PASS, INIT 75, TO-TEXT 50, invalid-sign 25, preserved owners, unexpected0 and heap0.
4. Independently inspect the resulting Stage51 job log and single-artifact ZIP SHA256, CRC, embedded PROJECT_ID and HEAD before counting the extension as Native verified. Source/static checks and mere CI start are not Native PASS.
