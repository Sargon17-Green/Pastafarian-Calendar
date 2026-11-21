# QA51-B direct TO-TEXT validation rejection
PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Date: 2026-11-21
Parent: 39c146cb67fd5d88fd628f95e6354c1b70a752c8
Scope: Stage51 post-acceptance test/CI only; NO Stage52, production, main, merge or release.

## Code-grounded independent oracle
In src/big_integer.cob blob 982c1f266a18c2bcaba79b994177a93750f27bfa, TO-TEXT dispatch (439-441) calls LOAD-A-H1 then HANDLE-H1-TO-TEXT. LOAD-A-H1 invokes REBUILD-H1-BACKLINKS (507-512), which checks SIGN != 0 and (CHUNKS < 1 or HEAD = NULL) at 579-589 and returns status49 before dereference at 598. HANDLE-H1-TO-TEXT clears all TEXT and LEN=0 then returns the same 49 (1710-1725). SIGN=0 would normalize to zero and is not a valid failure witness.

Test input: two deliberately incomplete but nonaliased and pointer-safe scratch descriptors: SIGN=+1 then -1, CHUNKS=0, HEAD=TAIL=NULL. No live pointer corruption. Pre-fill TEXT with "X", LEN=999. Assert exact STATUS=49, LEN=0, entire 8192-byte TEXT cleared to spaces, unchanged scratch descriptor fields, and no retained allocations. Five original output owners and two C/T owners stay live and untouched. For every rejection verify CHECK-DISTINCT, CHECK-INPUT-PRESERVED, and HEAP-LIVE==preprobe measured positive baseline. Preserve all old cleanup tests (final heap0).

Matrix: 5 widths (3,9,128,320,8192) x 5 ordered cases x 2 signs = 50 direct calls. Fail closed unless STAGE51_TO_TEXT_REJECTS=50 and STAGE51_TO_TEXT_GATE=PASS. Retain strict GnuCOBOL -Werror and existing Stage51 job; CI checks numeric 50 and marker, plus all prior counters including INIT rejects=75, invalid-sign rejects=25, 25/25 native, and unchanged 52 job matrix.

Evidence classification: SOURCE-PROVEN CONTRACT + TEST/CI IMPLEMENTATION until exact-SHA natural completed workflow run, job log, native gate and independently verified ZIP SHA256/CRC/embedded PROJECT_ID and HEAD. This does not test allocator denial, partial allocation, TO-TEXT overflow, FREE-A or HEAP-LIVE failures, or PATCHED-DISTANCE internal cleanup fault. No general failure-path acceptance and no duplicate CI dispatch.
