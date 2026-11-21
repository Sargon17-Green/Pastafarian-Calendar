# QA51-B follow-on: deterministic TO-TEXT overflow witness feasibility contract

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Authorized branch: COBOL+简体中文
Source baseline: a8162a9ed254e04623a2f9865e15cc29587a6eee
Production big_integer.cob blob: 982c1f266a18c2bcaba79b994177a93750f27bfa
Classification: **source-backed test design, NOT implemented and NOT Native PASS**.
Scope: existing accepted Stage51 post-acceptance failure-path QA only; do not open Stage52 or edit production.

## Feasibility verdict and independent oracle

A safe, deterministic *mid-formatting* service error exists without fault injection. Use legal, independently allocated inputs rather than malformed pointers:
- Let M=10^8192-1 (exactly 8192 ASCII '9' digits), C=+M and T=-M.
- Create both through valid INIT-TEXT of 8192 unsigned digits, then assign T's descriptor sign=-1. Source src/big_integer.cob: 875-877 validates text length 1..8192, 918-955 parses chunks and normalizes; current harness shows the same sign-in-descriptor convention.
- Run the real DISTANCE-PATCH path on distinct C and T owners, with a fresh empty result descriptor. src/patched_distance.cob: 57-113 computes abs(T-C)+1 using BIG-INTEGER-SERVICE SUB, INIT-TEXT('1'), ADD, then cleans temporary owners.
- Independent mathematical result: abs(-M-M)+1=2*10^8192-1, decimal representation '1' followed by 8192 '9' digits, width **8193**. Independently checked with JavaScript BigInt (8193 digits, exact digit pattern). No expected string copied from a different project branch.
- Call the **real** TO-TEXT operation on the valid result owner. src/big_integer.cob: 1704-1770 clears the 8192-byte text buffer and LK-TEXT-LEN; formatting rejects a write past 8192 with status **45** and leaves LK-TEXT-LEN=0. This failure occurs during formatting of a valid, computed BigInt result. It does not mean PATCHED-DISTANCE itself failed.
- Do not require the text buffer to remain blank: part of the decimal may have been written before status 45. Do not pass any dangling pointer or alias an input and output. Do not mutate runtime counters.

## Proposed bounded test-only harness

Input: one synthetic 8192-digit all-nines C and T; signed descriptor T=-1, distinct owned live heads; one initially empty output descriptor and separate empty B/REM scratch. Only one new post-25-case probe, after original Stage51 cleanup reached HEAP-LIVE=0. Verify precondition no old owners.
1. INIT-TEXT each operand: status 0, two distinct non-null valid owners. Call DISTANCE-PATCH: status 0, result owner non-null and distinct; snapshot all three descriptors; HEAP-LIVE >0.
2. TO-TEXT using this result owner: **status 45 and TEXT-LEN 0**, no corruption of the three owner metadata snapshots; HEAP-LIVE remains equal to pre-call count. The partial TEXT content is explicitly not an oracle.
3. Free result, C, and T through actual FREE-A; each status 0, descriptors cleared; final measured HEAP-LIVE=0. Test must attempt cleanup even after an assertion failure when it can do so with valid, independently owned descriptors; never free an unknown/dangling pointer.
4. Emit exactly one success count and explicit PASS marker only after every status, owner, and heap assertion. On failure emit reason, nonzero exit, and no success marker. Preserve the existing 25/25 Stage51 cases and all old numeric gates.

Proposed new log keys: STAGE51_TO_TEXT_OVERFLOW_REJECTS=00001 and STAGE51_TO_TEXT_OVERFLOW_GATE=PASS; strict existing Stage51 CI job checks numeric 1 and PASS, alongside all prior checks. Before source commit, review any generated COBOL for <=72-column fixed contract and compile under GnuCOBOL -Werror. Acceptance requires a new exact-SHA natural completed push run, all 52 jobs successful, job log and artifact independently verified SHA256/CRC/PROJECT_ID/HEAD. No duplicate CI dispatch.

## Remaining unproven fault classes

- **Allocator denial**: src/big_integer.cob has raw ALLOCATE statements (e.g. 811, 955, 975, 995, 1018, 1039, 1294) and no supported deterministic fault-injection switch or status contract for allocation denial. Do not force memory exhaustion or claim coverage.
- **PATCHED-DISTANCE internal service failure**: src/patched_distance.cob: 76-127 has cleanup conditional on service status and release of WS-DIFF and WS-ONE; the planned TO-TEXT formatting failure occurs *after* a successful PATCHED-DISTANCE call and does not exercise that internal cleanup failure path.
- **HEAP-LIVE service failure**: src/big_integer.cob: 234-235 only copies BI-LIVE-ALLOCATIONS to LK-TEXT-LEN and has no explicit error branch. Existing heap-equality/zero assertions verify successful measurement, not failure of the measurement service.
- **FREE-A valid-owner failure**: prior completed run verifies only independent NULL-head structural rejection with status 49, not allocator/OS deallocation failure.

This contract is evidence-based planning, not a claimed Native outcome. Next authorized step: implement exactly the bounded TO-TEXT overflow probe in the existing Stage51 test and its strict CI job, preserving production and previously accepted gates; inspect natural exact-SHA CI and artifact before any new acceptance.
