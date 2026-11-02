# Stage50 / DISCOVERY25 — controlled midpoint-tie classification discrepancy

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Locked parent: b2b56b20aac8807fdb0e59370d3b3f42a54c43fa
Stage49 gate: completed/success run 41523263786, 78/78 jobs; Lua 5.3 job 125567858193 completed/success; 3 PASS markers, stderr empty, exit=0. Evidence artifact 13180908315, ZIP SHA256 26be83fe1d97b2e80b9336ee4a7fffe0c0516aa0c86569cced8efcb51c3ad6b1.

## Contract, scope and independent oracle
Input: exactly 17 strictly increasing caller-supplied gate records G(-8)..G(8), adjacent gaps [42,963], signed BigInt query d in [G(-7),G(7)]. Stage49 produces unreduced fraction (d-a)/(b-a) from enclosing interval [a,b). Stage50 adds a *diagnostic-only* midpoint classification. Normative output is BEFORE_MIDPOINT when 2(d-a)<b-a, AT_MIDPOINT on equality, and AFTER_MIDPOINT when greater. This is derived from existing gate state, not a public sixth calendar-date component; no floating point/GCD/year5000/postStir12/calendarDate.

Stage50 deliberately introduces a NEW, explicitly controlled legacy error: comparison <= labels exact midpoint as BEFORE_MIDPOINT instead of AT_MIDPOINT. This is not a claim of an existing bug. Preserve authenticated Stage49 twelve-commit history and source verbatim; append exactly one new MonsterManager semantic commit (13 total), maintain owned snapshots. Production does not import normative_oracle or test fixtures. Test-only independent oracle computes 2*(d-a) versus (b-a) from raw caller endpoints; it does not invoke the legacy algorithm to construct expected results.

## Measurable acceptance
- Canonical: 15 opening matches, 14 last-day matches, full 13-commit semantic trace.
- Synthetic: 96 even-gap signed near-2^127 BigInt streams, with 96 exact-midpoint EXPECTED_RED and 192 flanking MATCH witnesses. No fabricated historical expected-red.
- Hardening: nine malformed/out-of-window rejects, two isolated replays, historical Stage49 snapshot preserved and unaliased.
- Native Lua 5.3 CI: 12 historical SHA source locks; luac across src/test; timeout 1200 seconds; precisely 3 stdout PASS lines; exit=0, empty stderr; six artifact evidence files (source, version, stdout, stderr, exit, result), artifact digest SHA256.
- Acceptance only on new **79/79 completed/success** jobs including lua_stage50_discovery, identical run HEAD, verified log and artifact. queued/in_progress is not PASS or blocker.
- Future Stage51/PATCH25 may correct exact midpoint using independent oracle only after Stage50 native acceptance. Do not merge/publish/change main, year5000, postStir12 or full calendarDate.
