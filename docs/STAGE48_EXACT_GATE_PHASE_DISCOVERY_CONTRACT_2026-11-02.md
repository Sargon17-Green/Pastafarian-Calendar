# Stage48/DISCOVERY24 — exact gate-phase controlled discrepancy

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Locked parent: f10515a5a9a0363d554958f414092d1d4ab1be46
Stage47 CI run 41354852896 completed/success, 76/76; Lua 5.3 job 125009186447 PASS, empty stderr and exit 0. Evidence artifact 13104897601, ZIP SHA256 0790c54820b4e7adbaca391183cdd025f79ca3d35b0c1438049e5b3a8b326e10.

## Input/output and independent oracle
Input: 17 strictly increasing caller-provided gate records G(-8)..G(8), consecutive gaps in [42,963], signed BigInt query d in [G(-7),G(7)]. For its interval a=G(k) <= d < b=G(k+1), normative phase is **one ASCII decimal string** `(d-a)/(b-a)`, with unreduced 0-based numerator and exact denominator. No floating point or GCD; no sixth calendar-date component.

This Stage48 DISCOVERY24 deliberately introduces a **new**, clearly labeled one-based numerator error. The legacy implementation returns `(d-a+1)/(b-a)` after an authenticated Stage47 ten-commit path; append exactly one MonsterManager semantic commit (11 total). Historical Stage47 source remains callable and unchanged. The independent test computes expected and legacy witnesses directly from raw endpoints, not by importing production's formula.

## Measurable acceptance
- Canonical: 15 opening, 14 midpoint and 14 last-day expected-RED witnesses (43 total), 11 exact semantic trace entries.
- Synthetic: 96 signed ~2^127 BigInt gate sequences with even gaps 42..962, all expected-RED.
- Hardening: nine rejects, two isolated owned replays, immutable prior Stage47 snapshots; no normative oracle in production.
- Native Lua 5.3 on bounded CI: 10 historical Git blob hash locks, luac of all src/test, timeout 1200 seconds, exactly three expected stdout PASS lines, empty stderr, exit 0; six evidence files and SHA256 artifact.
- Acceptance only on completed/success **77/77 jobs**, with lua_stage48_discovery job, verified log and artifact. queued/in_progress are neither PASS nor blocker.
- After gate: Stage49/PATCH24 is authorized to repair one-based numerator independently. No main/merge, year5000, postStir12 or full calendarDate.
