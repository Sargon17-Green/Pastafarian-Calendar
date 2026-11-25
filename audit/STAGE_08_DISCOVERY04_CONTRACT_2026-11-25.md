# Stage08 / DISCOVERY04 — sequential five-stone mutation discovery contract

PROJECT_ID=PC-BRANCH-RUST-AZERBAIJANI
BRANCH=Rust+Azərbaycan-dili
STAGE=8
KIND=DISCOVERY04
CURRENT_PATCH=PATCH03
STAGE08_SCOPE=SEQUENTIAL_STONE_UPDATE_DISCOVERY
PREREQUISITE_STAGE07=ACCEPTED
STAGE08_ACCEPTED=NO
STAGE09=NOT_STARTED
HISTORICAL_PRE_STAGE03_RUST_RED=NOT_CLAIMED
FULL_CALENDAR=BOOTSTRAP_ONLY
CONTRACT=FROZEN

## Scope provenance

Stage08 is the next documented unit after Stage07/PATCH03. The Rust Stage06/07 reconciliation points to DISCOVERY04 sequential stone mutation and then PATCH04 snapshot correction. The V Stage08 and Kotlin Stage08 audit records independently describe the same five-field sequential-update defect; the Rust main README defines the normative snapshot equations. Those records identify and cross-check the semantic scope only. This Rust implementation and its fixtures/oracles are authored independently; no source code or test fixture is copied from another language branch.

Stage08 is a discovery gate: expose the historical sequential mutation as a real production sub-entry and measure its difference from the normative snapshot. Do not correct the mutation in this stage. Stage09/PATCH04 is not implemented here.

## Normative reference and sequential historical route

Let M = 2^127 - 1 and SAVE(x) = 1 + mod_floor(x-1, M). The logical stone table has 46 rows, numbered 1..46. Row 1 is the seed [17, 29, 43, 71, 101].

For row i in 2..46, the correct reference computes all five new values from one immutable snapshot (w,b,s,m,r) of row i-1:
- w_ref = SAVE(w*w + 3*b + i)
- b_ref = SAVE(b*b + 5*s + w)
- s_ref = SAVE(s*s + 7*m + b)
- m_ref = SAVE(m*m + 11*r + s)
- r_ref = SAVE(r*r + 13*w + m)

The historical DISCOVERY04 mutator changes the same five-field object in sequence:
1. w' = SAVE(w*w + 3*b + i), using old w,b.
2. b' = SAVE(b*b + 5*s + w'), using the newly updated w'.
3. s' = SAVE(s*s + 7*m + b'), using the newly updated b'.
4. m' = SAVE(m*m + 11*r + s'), using the newly updated s'.
5. r' = SAVE(r*r + 13*w' + m'), using the newly updated w' and m'.

The production route starts with row 1, clones the previous legacy row for each i, and invokes the actual in-place mutator on that row. Logical rows are stored in a 46-element Vec at index i-1; no extra sentinel row is stored.

## Exact expected-RED contract

The Native comparison covers rows 2..46: 45 rows × 5 fields = 225 components. The first row is the seed control and is not part of the 225-cell classification.

For row 2:
- Sequential legacy output: [378, 1434, 3780, 9932, 25047].
- Snapshot reference: [378, 1073, 2375, 6195, 10493].
- The first field is the sole MATCH; the other four are RED.

Across all rows 2..46 the exact classification is 224 RED and 1 MATCH, with 0 unexpected outcomes. This is an expected-RED discovery test, not a failing Rust test and not a claim that the legacy algorithm is correct. The gate passes only when the production route reproduces the sequential scar and the independent oracle confirms every one of the 225 cells.

The Rust test-only snapshot oracle independently implements SAVE with arbitrary-precision BigInt and computes every row from the previous immutable snapshot. A separate Python oracle uses arbitrary-precision integers to recompute both the sequential historical path and the snapshot reference, then verifies every raw Native cell, duplicate/missing coverage, and the 224/1 classification.

## Production route and guards

1. A fresh MonsterContext runs the actual chain: WorkCountsPatch02 -> LegacyTagDistanceDiscovery03 -> Patch03DistanceCorrection -> LegacyStoneDiscovery04.
2. The Stage08 handler requires exactly one completed Stage05, Stage06 and Stage07 observation and records one call-local 46×5 table.
3. The historical mutator rejects row indices outside 2..=46 before mutating its input.
4. Re-entry is rejected without changing context. Missing Stage07 evidence is rejected without changing context.
5. Two independent invocations are deterministic and have no shared mutable table or cross-call alias.
6. The 46×5 table contains 230 positive values, each within 1..M.
7. calendar_stones_spaghetti returns the historical stone sub-result. calendar_date_spaghetti remains BootstrapOnly; no full calendar is enabled.
8. Stage09/PATCH04, main, merge, and release are outside this contract.

The explicit Native guard count is four: duplicate handler call, missing Stage07 observation, invalid row 1, and invalid row 47.

## Required gates

1. Exact branch and checkout SHA; Stage07 accepted prerequisite; Stage08 identity; cargo fmt.
2. Native cargo test --all-targets including all Stage01–Stage07 Rust regressions and the Stage08 expected-RED witness.
3. Exactly 46 rows / 230 bounded values; 225 comparison cells; 224 RED, 1 MATCH, 0 unexpected; row-2 witness; 4 guards; BootstrapOnly preserved.
4. Independent Stage06 and Stage07 distance oracles still pass on this SHA; Stage08 Python oracle independently verifies every cell.
5. Completed/success exact-SHA Native run and job; decoded checkout log; downloaded artifact SHA-256 equals GitHub digest; independent ZIP CRC, PROJECT_ID/SHA, exit 0 and raw-output verification.
6. Whole-stage closure remains NOT_CLAIMED in the run artifact until a separate exact-SHA artifact audit is complete. Only then may DEVELOPMENT_STAGE advance LAST_COMPLETED_STAGE to 8.

## Stage boundaries

Stage07 remains accepted and is regression-tested. Stage08/DISCOVERY04 exposes only the sequential stone defect. Stage09/PATCH04 snapshot correction is the next documented stage but is not started here. Historical pre-Stage03 Rust RED remains NOT_CLAIMED. No full-calendar claim is made.
