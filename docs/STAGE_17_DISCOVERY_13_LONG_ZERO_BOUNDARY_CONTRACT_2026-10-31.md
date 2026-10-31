# Stage17 / DISCOVERY13 — 长零串边界与九位分块归一化

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Date: 2026-10-31
Prerequisite: Stage16 accepted in strict Native run 41230714962 on ec07effca4604d909e8faef0c57b0aa475103391, 17/17 jobs, measured HEAP-LIVE=0, 24/24 tests.

## Independent target
Probe textual BigInt parser normalization for long spans of leading zero digits at and across base-10^9 chunk boundaries and near the 320-character input fixture capacity. The production path remains MONSTER-DISTANCE / DISTANCE-PATCH with d(c,t)=|t-c|+1. Stage16 tested small fixed leading-zero prefixes; Stage17 adds k in {8, 9, 18, 27, 255, 318}, including fully occupied PIC X(320) source fields. This is a bounded source-validated input stress test, not an assertion of historical defect.

For each k, z=0 repeated k times. Four original independent calls:
1. c="-"+z, t="+0" => 1.
2. c="+"+z, t="-0" => 1.
3. c="-"+z+"1", t="+1" => 3.
4. c="+"+z+"1", t="-"+z+"1" => 3.
Total 24 cases; each expected decimal oracle separately checked using BigInt abs(t-c)+1 and the closed-form zero/±1 identity. Long COBOL source literals are written with constant-position reference modifications in <=100-character segments; maximum operand string is 320 bytes. No production routine reused as an oracle, and no external branch fixture imported.

## Acceptance contract
- Single independent test/stage17_discovery_tests.cob with 24 fixed cases, status 0, message PATCH03:DISTANCE-PATCH, unchanged input structures and owned output release; zero unexpected failures.
- Real BIG-INTEGER-SERVICE/HEAP-LIVE probe after every release phase; exact HEAP_MEASURED=YES and HEAP_LIVE_POST_RELEASE=0 at end.
- Strict GnuCOBOL 3.1.2 -Werror native compilation under 300 seconds, execution under 120 seconds; keep failed logs.
- 18/18 verify and Stage1–17 jobs completed/success on exact branch SHA.
- Required markers: STAGE17_RUNS=24, STAGE17_PASS=24, STAGE17_UNEXPECTED_FAILURES=0, STAGE17_HEAP_MEASURED=YES, STAGE17_HEAP_LIVE_POST_RELEASE=0, RESULT=PASS_STAGE17_LONG_ZERO_BOUNDARY_DISCOVERY_NATIVE, STAGE17_NATIVE_GATE=PASS.
- Do not infer expected-red until observed, preserve the historical code, do not change main, merge or claim complete calendar integration.
