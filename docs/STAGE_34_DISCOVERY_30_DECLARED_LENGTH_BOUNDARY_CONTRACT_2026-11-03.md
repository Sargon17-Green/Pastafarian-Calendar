# Stage34 / DISCOVERY30 — 声明长度边界、解析与恢复 (2026-11-03)

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage33 exact 9906783b858e876b09c4ddfaf2886596ccb46254; run 41537390944, completed/success 34/34; native 24 rejects, 24 recoveries, measured heap=0.

Original, independent bounded experiment: test declared-length rejection at BOTH 0 and 8193 with valid immediate recovery, including maximum legal text length 8192. Stage33 tested malformed content and an oversized declaration but not 0 or the 8192-digit accepted boundary.

For n in {1,9,320,8192}, j in {1,2,3,4,5,6}:
  1. Call INIT-TEXT with '?' and declared length 0 (j odd) or 8193 (j even); parser is expected to report status 43 and leave its output empty. This status follows the inspected source's 1..8192 length guard; it is not an asserted defect or expected-red.
  2. Check actual HEAP-LIVE=0 after rejection, not a hardcoded marker.
  3. Immediately generate two exactly n-digit positive valid literals. For n=1 they are decimal j and 9-j. For n>1 they are "1" + (n-2) zeroes + digit j, and the same prefix ending in digit (9-j). No leading sign; maximal input width is exactly 8192.
  4. Execute MONSTER-DISTANCE / DISTANCE-PATCH; expected decimal |c-t|+1 = |2j-9|+1 (8,6,4,2,2,4), with a second independent arbitrary-precision BigInt oracle over actual full literals. Compare exact returned text, preserve input pointers/signs/chunks, release output and both inputs, probe final HEAP-LIVE=0.

24 unique ordered valid pairs, 12 zero-length invalid and 12 oversized invalid, 24 immediate recoveries, 4 width classes; expected length 1. The independent script-level preflight checks 24/24 BigInt against digit-only closed form, the 8192 input length and 24 distinct ordered input pairs. Test uses no external branch fixtures.

Native gate: exact pushed SHA and branch, 35/35 completed/success CI jobs, strict GnuCOBOL 3.1.2.0 -Werror, compile timeout 300s, execute timeout 120s, job <=20m; upload log artifact on success/failure. Required markers STAGE34_REJECTS=24, STAGE34_HEAP_CLEAN=24, STAGE34_RUNS=24, STAGE34_PASS=24, STAGE34_UNEXPECTED_FAILURES=0, STAGE34_HEAP_MEASURED=YES, STAGE34_HEAP_LIVE_POST_RELEASE=0, RESULT=PASS_STAGE34_DECLARED_LENGTH_BOUNDARY_DISCOVERY_NATIVE, STAGE34_NATIVE_GATE=PASS.
No Native PASS before completed CI/log verification. No main/merge/release or production modification; no general calendar claim.
