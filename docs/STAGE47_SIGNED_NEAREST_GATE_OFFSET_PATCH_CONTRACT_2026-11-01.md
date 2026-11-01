# Stage47 / PATCH23 — restore signed nearest-gate displacement

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Predecessor: 4edaf858ada306adc654b6466445fa5afc2c76ef
Stage46 gate: [run 41349919772](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41349919772) completed/success, 75/75 jobs; lua_stage46_discovery job 124989455384 passed in Lua 5.3. Three exact stdout markers: 15 opening MATCH +14 midpoint MATCH +14 closing EXPECTED_RED; 96 signed BigInt closing EXPECTED_RED; 9 rejected inputs + 2 owned replays. Evidence artifact 13101784648, SHA256 a93910cecfb302647b88d19f798f8fd3cc82cdfb5b6d53a202b2879ee54ee78f. Stage46 demonstrates a controlled newly introduced sign-loss defect, not a claim of pre-existing historical misconduct.

## Behavior and independence
Input: 17 caller-supplied indexed gate records G(-8)..G(8), with signed decimal gate days and gaps 42..963, requested d in [G(-7), G(7)]. Use the authenticated Stage46 nine-commit context and Stage45 corrected nearest-gate choice. If d-G(k) <= G(k+1)-d (including tie), return the **decimal string** d-G(k); otherwise return the decimal string -(G(k+1)-d). Exact gate returns "0". No sixth calendar date component. Production never imports or calls test normative_oracle.

Historical source src/legacy_gate_signed_offset.lua remains unchanged and independently callable, exhibiting closing-direction EXPECTED_RED. New src/gate_signed_offset_patch.lua validates the nine historical semantic commits and appends only the tenth signed correction, with owned snapshots, metric, diagnostic, no uncommitted or rolled-back state. The patch must not alter Stage1–46.

## Measurable acceptance
- Canonical independent oracle from raw gap endpoints: 15 opening MATCH, 14 midpoint MATCH (including tie-to-opening), 14 closing PATCHED with historical positive magnitude and corrected negative sign; 10 ordered semantic commits.
- Synthetic: 96 independently supplied signed ~2^127 gate sequences with even gaps [42,962], 96 closing positive historical magnitudes vs corrected negative offsets.
- Hardening: same nine malformed/out-of-window rejects, two distinct owned contexts, historical Stage46 snapshot preserved, exactly three stdout markers, exit code 0, empty stderr.
- Native: Lua 5.3; source locks of nine historical modules including legacy signed-offset; syntax-compile all src/test Lua; no normative oracle in production; timeout 1200 seconds; six evidence files (source, version, stdout, stderr, exit, result), SHA256 artifact.
- CI: expected **76/76** successful jobs including lua_stage47_patch; completed/success and real log/artifact are mandatory before Stage47 acceptance. A queued/in_progress run is not a blocker or PASS.
- No main/merge, year5000, postStir12, full calendarDate, or sixth returned date component.
