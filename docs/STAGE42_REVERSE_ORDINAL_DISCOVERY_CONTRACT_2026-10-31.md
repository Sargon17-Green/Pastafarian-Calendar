# Stage42 / DISCOVERY21 — reverse ordinal historical current-day exclusion
PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Gate: Stage41 run 41192520586, completed/success, 70/70 jobs; lua_stage41_patch job 124514563224 success, Lua 5.3, exact 3 PASS markers, exit=0, stderr empty. Artifact 13040076401, zip SHA256 f35059d0f6742a1fd26a9c2cf204b960c6c069ec009e360da7f78e8897d715e5; tested branch HEAD 9bca231587095efd18d63336d359fc5953e7b2de.
Status: OPEN; Stage42 Native NOT RUN / NOT VERIFIED.

## Scope and rationale
New observable behaviour: reverse position (days remaining **including** current day) within a single corrected signed gate interval. This is not a full calendar, does not implement year5000 or postStir12 and does not change previous Stage38..41 source files. This deliberately tests an independently derived reciprocal index, instead of repeating the ordinal's forward output.

Inputs: same caller-provided 17 signed sorted gate records (-8..8), validated gaps 42..963, target day d in [G(k),G(k+1)), k=-7..7. All arithmetic uses exact BigInt (including signed magnitudes ~2^127). Stage41 returns one-based ordinal o=d-G(k)+1, and four valid historic semantic commits. Stage42 appends *one historic fifth commit* with **deliberately wrong** reverse ordinal R_legacy=gap-o. Independent normative expectation (test only): R=G(k+1)-d, so R_legacy=R-1. At interval opening: gap-1 vs gap; last day: 0 vs 1. Stage42 must not repair that mistake or modify Stage41.

## Evidence and measurable acceptance
- 15 canonical opening and 15 last-day witnesses: all expected-RED; oracle from test/normative_oracle.lua's independently generated gate list and direct G(k+1)-d, never from production's fourth commit formula.
- 96 deterministic synthetic, alternating signed BigInt ~2^127 scenarios with monotonic 17 records and valid gaps; last-day 0 vs 1 expected-RED.
- 9 malformed/out-of-range rejects (fail closed); 2 independent replay contexts with mutation isolation.
- Historical Stage38/39/40/41 trace preserved, fifth semantic state committed, no pending/rollback; immutable Stage41 module and five prior hash locks; luac5.3 syntax over src/test, Lua 5.3 native test script, exactly three stdout markers, empty stderr and exit=0.
- Separate source/version/stdout/stderr/exit/result CI artifact. A green CI **verifies expected-red witnesses**, not that normative reverse ordinal has been implemented. No assertion of PASS until completed/log/artifact and run SHA verified.
- Next only after Stage42 accepted: Stage43/PATCH21 may repair reverse ordinal with legacy untouched and a separate sixth commit; define precise contract then.
