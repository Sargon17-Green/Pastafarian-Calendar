# Stage54 / VERIFICATION31 — independent fourth-hop failure isolation

PROJECT_ID: PC-BRANCH-PHP-MALAY | PHP+Bahasa-Melayu | 2026-11-03

## Entry gate
Stage53 source fc901da8e26480f6ab3ba7c1a96e5735fd3ff3e4, Actions #41523893343 completed/success 24/24. Native PHP8.3.36/64-bit #125546545856: lint PASS; checks=81 cases=4 faults=16 recovered=16 baselines=4, exit0/stderr empty; artifact #13181070486 ZIP SHA256 8350ad6e25ceaffeafd001c625bbb31f70c1323aab99509d75adf0eeaf73f5ec.

## Distinct question
Stage53 tested late failure in edge three. Stage54 tests **edge four** in each direction and, for depth five, requires **complete suppression of edge five** following failure. Do not claim expected-red or a historical defect without reproducing one. No production edit.

## Input, independent oracle, and assertions
- Under tests only, build genuine immutable years 4995..5005 by deriving previous/next from NormativeOracle and NormativeMath::FOUNDATION_DAY. Keep original serialized snapshot.
- Four cases: forward/backward x traversal depth 4/5, target strictly interior to destination year; exact step budget=depth. Assert candidate equals oracle destination, steps=depth, matching direction, usedLegacyOutput=false.
- Derive entire expected callback sequence from oracle years (never from received callbacks): trusted Year5000, its open and close gates, then proposed, canonical, open and close for every hop.
- For each case inject four fourth-hop faults: proposed throws S54_PROPOSED_THROW, canonical throws S54_CANONICAL_THROW, gate-open throws S54_GATE_OPEN_THROW, gate-close returns oracle day+1 and is rejected as PATCH20_GATE_DAY_MISMATCH_close. Guard shared physical seams by both index and **per-request gate callback ordinal**: edge-four opening=9, closing=10; first two belong to Year5000, six to prior edges.
- Each failure returns the exact error and trace prefix length 3+12+(1..4) for the four failure points, with no later callbacks. Immediately rerun the same case healthy and compare the complete result and trace to its independent baseline. Depth-five failures verify fifth-edge suppression.
- Four baselines, 16 deliberate faults, 16 recoveries; original oracle data unchanged; no NormativeOracle or NormativeMath in src/Patches/CanonicalAdjacentPatch22.php.

## Native/CI contract
PHP 8.3, 64-bit, lint PASS, memory 512MiB, timeout 900s; exit 0, empty stderr; stdout exact:
`^STAGE54_FOURTH_HOP_ISOLATION checks=[0-9]+ cases=4 faults=16 recovered=16 baselines=4$`
Preserve source SHA, version, stdout/stderr, exit, artifact ZIP digest. Require all **25/25** jobs completed/success on the new branch SHA for Stage54 PASS. Earlier queued or running jobs neither block progress nor count as PASS. No main/merge/publish. This stage does not establish full five-component calendar accuracy; Stage55 requires separate end-to-end acceptance.
