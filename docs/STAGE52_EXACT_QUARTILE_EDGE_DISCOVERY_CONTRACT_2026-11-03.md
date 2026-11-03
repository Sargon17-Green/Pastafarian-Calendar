# Stage52 / DISCOVERY26 — controlled quartile-boundary sticky-left diagnostic

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Locked parent: 57659488055a22aab61f5830e311de07de304afa
Stage51 gate: run 41617620634 completed/success, 80/80 jobs, Lua 5.3 job 125880225580 completed/success; three exact stdout PASS lines, empty stderr, exit=0; 13 historical SHA locks. Artifact 13224189533, ZIP SHA256 6a3fbc67e6841c50743aa20bf5c4dbd831384efccb642708b448b26335b3c086.

## Scope, independent oracle and controlled defect

Input: exactly 17 ascending signed BigInt gate records G(-8)..G(8), successive gaps 42..963, query d in [G(-7),G(7)]. Read the Stage51 repaired 14-commit context; preserve the 13 preceding commits, Stage49/Stage50 snapshots and Stage51 midpoint correction. Add a **diagnostic only** quarter-of-gap label Q1..Q4 using u=d-a, v=b-a, exact integer 4u compared with v, 2v, 3v. Normative labels use half-open quarters: Q1 if 4u<v, Q2 if v<=4u<2v, Q3 if 2v<=4u<3v, Q4 otherwise. Stage52 newly introduces a controlled defect: at exact internal quarter thresholds 1/4, 1/2, 3/4 it assigns the preceding bucket by using <=. This is NOT a claim about a pre-existing bug; future Stage53 may repair it only after independent reproduction and Stage52 Native acceptance.

Test-only oracle computes integer quotient (4*offset)//gap for a bounded gap <=963 after subtracting arbitrary signed BigInt endpoint values; it does not call the production comparator. Production uses BigInt add/compare exclusively, no division, floating-point, normalization, GCD, year5000, postStir12, calendarDate, nor sixth calendar component.

## Measurable acceptance

- Canonical 15 opening and 14 last-day MATCH, exactly 15 semantic commits with authenticated history.
- 96 alternating signed ~2^127 synthetic streams with gaps divisible by 4: 3 exact internal boundaries each = **288 EXPECTED_RED** cases; **576 flanking MATCH** witnesses; ensure Stage51 three-way midpoint remains correct even at 1/2.
- Nine malformed/out-of-range rejects, two isolated owned replays, owned non-aliasing Stage49–51 snapshots, source locks, production without normative_oracle import.
- GitHub Native Lua 5.3 CI: **81/81** successful jobs including lua_stage52_discovery; 14 historical git blob SHA locks; luac all Lua; timeout 1200 seconds; precisely three stdout PASS lines, stderr empty, exit=0; artifact six files and SHA256.
- No previous PASS rerun, no main/merge/publication/year5000/postStir12/full calendarDate. Queued/in_progress is neither PASS nor blocker; run/job/artifact must be read before accepting Stage52.
