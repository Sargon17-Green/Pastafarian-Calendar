# Stage54 / DISCOVERY27 — controlled exact signed BigInt octile-edge sticky-left diagnostic

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Locked parent: f116a985ee155fe669c33175ce4d179a2ac847f1
Stage53 gate: GitHub Actions run 41790768618 completed/success, 82/82 jobs; Lua 5.3 job 126452668598 completed/success, 3 exact PASS stdout lines, stderr empty, exit 0; artifact 13304910261, six files, CRC valid, ZIP SHA256 896fc5c754a22f2d72146596da1ed902bbf70d6929c7e6972e6479a599603493.

## Scope and independent oracle

Exactly 17 ascending caller-provided signed BigInt gate records G(-8)..G(8), adjacent gaps 42..963, day d in [G(-7),G(7)]. Retain Stage53 corrected quartile labeling and its exact sixteen-commit provenance. This stage adds a **separate diagnostic** E1..E8 classification of the same half-open interval [a,b), with offset u=d-a and gap v=b-a. Correct bin is E_(floor(8u/v)+1); equality at an internal eighth boundary belongs to the bin to the right. Stage54 **newly introduces** a controlled legacy error at any exact eighth boundary, using <= instead of <, causing the left bin to be chosen. Do not represent this as a previously discovered production defect.

The production implementation checks 8u against k*v for k=1..7 using signed BigInt add/compare only; no division, floats, GCD, normalisation, year5000, postStir12, calendarDate or sixth calendar component. Tests independently compute (8*bounded_offset)//bounded_gap and modulo using native small integers after subtracting arbitrarily large signed BigInt values. Do not import test/normative_oracle.lua from production. Stage53 code, source SHA, and snapshots remain immutable. The next potential PATCH27 is out of scope until Stage54 Native acceptance.

## Measurable acceptance

- Canonical: 15 opening E1 MATCH; 14 last-day E8 MATCH; exactly 17 commits, all historical trace handlers in order and Stage53 quartile remains corrected.
- 96 alternating +/- near-2^127 signed BigInt 17-gate streams, gaps divisible by 8 (48..952), 7 exact internal eighth edges each: 672 controlled EXPECTED_RED witnesses, 1344 immediate flanking MATCH cases.
- Nine invalid/out-of-range rejects; two independent nonaliased replays; immutable owned snapshots for Stage49–53; no production test oracle import; 16 historical source locks.
- Native Lua 5.3: on branch HEAD only, 83/83 CI jobs success including lua_stage54_discovery, compile all src/test with luac, test <=1200 seconds, exactly three PASS stdout lines, stderr empty, exit=0, six-file evidence archive with SHA256.
- Until run/job/log/artifact verified, Stage54 is OPEN_NATIVE_NOT_VERIFIED; do not claim PASS or rerun prior PASS manually. No main/merge/protected branch change/publication.

### After acceptance
Stage55/PATCH27 may be designed and implemented autonomously with an independently proved corrected octile classifier, restoring right-hand equality while preserving the 17 Stage54 commits and diagnostic. Stage55 is not implemented in Stage54.
