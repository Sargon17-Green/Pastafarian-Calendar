# Stage40 / DISCOVERY20 — legacy gate-day ordinal (zero based)

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Parent: 9dbb8173b99ea65314fd6c975025b38238182a1e
Gate: Stage39 run 41179375049 completed/success 68/68 jobs, lua_stage39_patch 124482917475 completed/success; 15 boundary corrections, 14 unchanged interiors, 96 signed BigInt chains, 9 rejects, two owned replays; native Lua 5.3 exit=0 and stderr empty; artifact 13035403269.
Status: OPEN; Stage40 native evidence is NOT YET VERIFIED.

## Kontra / contract
Input: integer day (Lua integer / decimal string / BigInt), corrected 17 gate records indexed -8..8, adjacent gaps 42..963, day in [Gate(-7),Gate(7)]. The caller must supply gate days; production does not ask the normative oracle. The authentic Stage39 PATCH19 gate index is k=max{j:Gate(j)<=day}, with interval Gate(k)<=day<Gate(k+1). Stage40 adds a *historical and intentionally incorrect* zero-based within-interval ordinal z=day-Gate(k), with local valid range 0..(Gate(k+1)-Gate(k)-1). The normative future one-based ordinal is o=z+1. This is a newly specified contract discrepancy, not a claim of a pre-existing bug. No PATCH20 in this stage.

Three authentic semantic commits, in order: Stage38 strict LT, Stage39 index LEQ correction, Stage40 zero-based ordinal legacy. Stage39 semantic state preserved in an independently owned snapshot; new metric/diagnostic; no aliases or oracle calls in production. No year5000, postStir12, calendarDateSpaghetti, full calendar, or change to main.

## Measurable gates
- Canonical 15 exact signed gates k=-7..7: ordinal legacy 0 vs independent expected 1 (15 expected RED), 14 interior day Gate(k)+1: legacy 1 vs expected 2 (14 expected RED).
- 96 deterministic signed 2^127 synthetic chains, 17 strictly increasing gates, valid gap bounds: historical ordinal 5 vs future contract 6 (96 expected RED).
- Nine malformed inputs rejected; two equal-result replays with distinct semantic contexts and mutation isolation.
- Verify historical source blobs for Stage38, Stage39, PATCH17, PATCH18; syntax-check src/test with Lua 5.3. Native test code is test/stage40_tests.lua and must emit exactly three PASS marker lines, exit 0, stderr empty; upload source SHA, interpreter version, stdout/stderr/exit/result.
- Prior Stage39 completed/success is a prerequisite. Stage40 may only be marked verified after its own completed CI/log/artifact. No Stage41 or PATCH20 before evidence.
