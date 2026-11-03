# Stage51 / PATCH25 — exact midpoint equality repair

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Locked parent: 8dba369e929a0becbfc405d9e0051c5d5c2da68d
Stage50 gate: [run 41536633248](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41536633248) **79/79 completed/success**; Lua 5.3 job 125614567004 completed/success, 3 stdout PASS markers, empty stderr, exit=0; 12 historical source locks; artifact 13187571235 SHA256 d0638d9451ada104e35763469d363204188e835ca8ec5a07945553c7a72669e3.

## Scope and oracle

Input is exactly 17 strictly increasing caller-supplied signed BigInt gate records G(-8)..G(8), adjacent gaps 42..963, and query d in [G(-7),G(7)]. For its enclosing half-open interval [a,b), calculate the diagnostic midpoint label using exact signed-integer comparison of 2(d-a) with b-a: BEFORE_MIDPOINT for <, AT_MIDPOINT for =, AFTER_MIDPOINT for >. No floating point, normalized fractions, year5000, postStir12, public sixth calendar component, or full calendarDate.

Keep the authenticated Stage50 legacy route and controlled comparator error verbatim; a new gate_midpoint_patch module verifies the 13-commit context and original diagnostic provenance, then appends one semantic commit (14 total). Preserve separate owned snapshots of Stage49 and Stage50. Production does not import normative_oracle/test fixtures. Test-only oracle independently computes midpoint from raw caller endpoints, without calling the production comparator for expected results.

## Acceptance

- Canonical 15 opening/14 closing MATCH and all 14 ordered semantic commits.
- 96 synthetic signed near-2^127 BigInt even-gap exact-midpoint corrections (Stage50 BEFORE vs Stage51 AT) plus 192 immediate flanking MATCH witnesses. Verify the historical 96 EXPECTED_RED values remain callable.
- Nine malformed/out-of-window rejects, two independently owned replays, Stage49 patch preserved, Stage50 source and historical route unchanged, and no normative oracle in production.
- Native Lua 5.3 CI: 13 source locks for previous modules, luac src/test, 1200-second bound, exactly three stdout PASS lines, empty stderr, exit=0, six evidence files (source, Lua version, stdout, stderr, exit, result) and SHA256 artifact.
- Stage51 acceptance only after **80/80 completed/success** jobs including lua_stage51_patch and matching run HEAD, job log and artifact verified. Queued/in_progress is neither PASS nor blocker.
- No main/merge/publication, year5000, postStir12 or full calendarDate.

Future Stage52 is subject to its own measurable contract, based on verified Stage51 and existing staged architecture; Stage51 does not implement it.
