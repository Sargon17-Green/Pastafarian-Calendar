# Stage44 / DISCOVERY22 — nearest-gate midpoint tie

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Prerequisite: Stage43 run 41222004307 completed/success, 72/72 jobs; job 124613784255; Lua 5.3; three PASS lines, stderr empty, exit=0; source locks; artifact 13051509309, zip SHA256 51f95c6cd18b724e5e20bf551872f43f24af86990d32332ccd385305b6ba35d6.
Status: IMPLEMENTED_AWAITING_NATIVE_CI, no Stage44 PASS yet. This Discovery deliberately introduces a wrong formula; it is not a claim of a pre-existing bug.

## Input, output, oracle
Input: 17 caller-supplied validated signed gates -8..8, gaps 42..963, target d within locked Stage38 domain [G(-7),G(7)]. Output: OPENING or CLOSING, plus independent seven-commit diagnostic context. For interval G(k)<=d<G(k+1), the independent test-only oracle computes L=d-G(k) and R=G(k+1)-d. It chooses OPENING if L<=R (tie to opening), else CLOSING. The new historical probe intentionally compares the **one-based** Stage41 ordinal L+1 with the Stage43 reverse distance R, producing CLOSING at even-gap midpoint (L=R) instead of OPENING. Preserves prior six commits, no production oracle, no calendarDate.

## Acceptance
- 15 canonical openings (-7..7); 14 midpoint probes (-7..6) with parity-derived red/match expected; 14 closing-adjacent matches. Do not test k=7 midpoint, which exceeds the historical Stage38 G(7) upper bound. Do not invent the number of even canonical gaps.
- 96 deterministic signed approximately 2^127 BigInt scenarios with even gaps 42..962, all midpoint EXPECTED_RED. Direct-independent boundary distance oracle, never output-derived.
- 9 malformed/out-of-window rejects including G(8)-1; 2 independent replay contexts; seven semantic commits and diagnostics with original six intact; no pending state/rollback.
- Native Lua5.3 syntax verify all src/test, six historical file source locks, exactly three stdout markers, exit=0, stderr empty; six-file evidence artifact source/version/stdout/stderr/exit/result. completed/success + job logs + artifact + matching SHA required before acceptance.

No Stage45/PATCH22 until gate accepted; no year5000, postStir12, calendarDate, main, merge, or external publication.
