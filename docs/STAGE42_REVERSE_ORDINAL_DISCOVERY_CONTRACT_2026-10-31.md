# Stage42 / DISCOVERY21 — reverse ordinal historical current-day exclusion
PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Gate: Stage41 run 41192520586, completed/success, 70/70 jobs; lua_stage41_patch job 124514563224 success, Lua 5.3, exact 3 PASS markers, exit=0, stderr empty. Artifact 13040076401, zip SHA256 f35059d0f6742a1fd26a9c2cf204b960c6c069ec009e360da7f78e8897d715e5; tested branch HEAD 9bca231587095efd18d63336d359fc5953e7b2de.
Status: OPEN; Stage42 Native NOT VERIFIED. First CI run 41211435678 completed/failure (70/71 jobs); target-day contract mismatch corrected for re-gate, not a verified expected-RED PASS.

## Scope and rationale
New observable behaviour: reverse position (days remaining **including** current day) within a single corrected signed gate interval. This is not a full calendar, does not implement year5000 or postStir12 and does not change previous Stage38..41 source files. This deliberately tests an independently derived reciprocal index, instead of repeating the ordinal's forward output.

Inputs: same caller-provided 17 signed sorted gate records (-8..8), validated gaps 42..963, target day d in [G(k),G(k+1)), k=-7..7. All arithmetic uses exact BigInt (including signed magnitudes ~2^127). Stage41 returns one-based ordinal o=d-G(k)+1, and four valid historic semantic commits. Stage42 appends *one historic fifth commit* with **deliberately wrong** reverse ordinal R_legacy=gap-o. Independent normative expectation (test only): R=G(k+1)-d, so R_legacy=R-1. At interval opening: gap-1 vs gap; last day: 0 vs 1. Stage42 must not repair that mistake or modify Stage41.

## Failed run 41211435678 and correction rationale
The 2026-10-31 completed run returned 70 successful jobs and one failed lua_stage42_discovery job (124570455280), with traceback at test/stage42_tests.lua:55 from src/legacy_gate_index_lookup.lua:26. The locked Stage38 validator admits targets only G(-7) <= day <= G(7), while the original Stage42 test attempted last-day target G(8)-1 for k=7. This is a test-contract error, not a proven production reverse-ordinal defect beyond the deliberate exclusion. Do not widen historical validator, rewrite previous stages, or claim PASS from this run. Preserve 15 opening probes; use 14 full last-day probes; restrict 96 synthetic last-day cases to k=-7..6; add G(8)-1 as an explicit reject. A new completed CI/log/artifact gate is required before Stage43.

## Evidence and measurable acceptance
- 15 canonical opening witnesses (k=-7..7) and 14 last-day witnesses (k=-7..6): all expected-RED; oracle from test/normative_oracle.lua's independently generated gate list and direct G(k+1)-d, never from production's fourth commit formula.
- 96 deterministic synthetic, alternating signed BigInt ~2^127 scenarios with monotonic 17 records and valid gaps; choose k=-7..6 (14 complete intervals within the existing Stage38 target-day domain); last-day 0 vs 1 expected-RED.
- 9 malformed/out-of-range rejects (fail closed), explicitly including the unsupported day G(8)-1; 2 independent replay contexts with mutation isolation.
- Historical Stage38/39/40/41 trace preserved, fifth semantic state committed, no pending/rollback; immutable Stage41 module and four prior source hash locks; luac5.3 syntax over src/test, Lua 5.3 native test script, exactly three stdout markers, empty stderr and exit=0.
- Separate source/version/stdout/stderr/exit/result CI artifact. A green CI **verifies expected-red witnesses**, not that normative reverse ordinal has been implemented. No assertion of PASS until completed/log/artifact and run SHA verified.
- Next only after Stage42 accepted: Stage43/PATCH21 may repair reverse ordinal with legacy untouched and a separate sixth commit; define precise contract then.
