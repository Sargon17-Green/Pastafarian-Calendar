# Stage07 / PATCH03 — chronological distance correction contract

PROJECT_ID=PC-BRANCH-RUST-AZERBAIJANI
BRANCH=Rust+Azərbaycan-dili
STAGE=7
KIND=PATCH03
STAGE07_SCOPE=PATCH03_DISTANCE_CORRECTION
PREREQUISITE_STAGE06=ACCEPTED
STAGE06_CODE_SHA=674b2cf4b9229d6d08ad0a65ee3c59a5695be0c0
STAGE07_ACCEPTED=NO
HISTORICAL_PRE_STAGE03_RUST_RED=NOT_CLAIMED
FULL_CALENDAR=BOOTSTRAP_ONLY
CONTRACT=FROZEN

## Scope selection and provenance

The 2026-11-25 Stage06/07 reconciliation identifies the next semantic step as Stage07/PATCH03, after Stage05 wrapper reconciliation and Stage06 legacy-tag distance discovery. The exact-SHA Stage06 Native run and separate artifact acceptance audit are complete. This contract therefore implements the PATCH03 selection rule described in that reconciliation and anticipated by the frozen Stage06 distance contract.

The earlier 2026-11-23 non-executing readiness note listed seven hidden drops as a possible technical dependency, but explicitly did not establish that they were the next normative stage. That candidate is not adopted here; the later Stage06/07 reconciliation supersedes it for the present transition. No code, fixture, or oracle implementation is copied from another language branch.

## Mathematical contract

Let F = -15,055,671. For an absolute day d, define the reconstructed Stage05 tag:

- N(d) = 2(F-d), when d < F.
- N(d) = 2(d-F)+1, when d >= F.

For the two input days c and t:

- L = abs(N(c)-N(t)): the observed Stage06 legacy-tag distance, read from the real PATCH02 -> DISCOVERY03 production chain.
- B = abs(t-c): the chronological base distance.
- mismatch = (L != B).
- selected_base = B, when mismatch is true; otherwise selected_base = L.
- PATCH03 result D = selected_base + 1.
- Independent normative result Q = B + 1.

The selection preserves the legacy base only when it already equals the chronological base; otherwise it explicitly selects the chronological base. Thus selected_base is B in either branch and D=Q, while the separate mismatch flag preserves whether Stage06's legacy distance diverged. Stage07 does not rewrite or erase the Stage06 observation L.

The predicates L != B and L != Q are distinct and must not be conflated. Stage06's 153/16 RED/CONTROL classification remains historical and unchanged.

## Input domain and exact expectations

Inputs are signed arbitrary-precision BigInt absolute days. The bounded Native matrix uses offsets from F:

- Local offsets: -11, -5, -2, -1, 0, 1, 2, 5, 11.
- Wide offsets: ±2^130, ±2^1032, and ±(2^4097+1).

The ordered Cartesian product contains 15×15 = 225 unique pairs. The independent Python oracle derives N from the piecewise definition using Python integers, not Rust code or Rust output helpers. Exact mismatch classification is 204 mismatches and 21 matches. The matrix includes all nine ordered combinations of F-1, F, F+1 and both pair directions.

Each Native row records c, t, L, B, mismatch, selected_base, and D. The independent oracle checks every field, exact pair coverage, duplicate/missing rows, symmetry, and D=abs(t-c)+1. It also checks the exact marker for 225 duplicate-call guards plus one missing-Stage06-observation guard: 226 total.

## Production route and invariants

1. Each call uses a fresh MonsterContext and the real dispatcher order: WorkCountsPatch02 -> LegacyTagDistanceDiscovery03 -> Patch03DistanceCorrection.
2. PATCH03 requires exactly one completed PATCH02 work-count call, one legacy action call, one legacy target call, and one Stage06 distance call.
3. PATCH03 stores its result in a separate call-local context field. The Stage06 WorkCounts.distance remains L and is not overwritten.
4. The result records legacy_distance, chronological_base, legacy_mismatch, selected_base, and distance.
5. Exactly one PATCH03 call is recorded. A repeated call returns InvalidState without changing context.
6. Missing Stage06 evidence returns InvalidState without changing context.
7. All arithmetic remains BigInt; no i64 narrowing, global mutable state, cross-call cache, external runtime, or test-oracle import.
8. The five-field calendar remains BootstrapOnly. No Stage08, main, merge, or release is part of this contract.

## Required gates

1. Exact branch and checkout SHA; stage identity and source markers; cargo fmt --all -- --check.
2. Native cargo test --all-targets, including all Stage01–Stage06 regressions and the 225-row Stage07 production-chain test.
3. Exact 225-row matrix; independent per-row recomputation of L, B, mismatch, selected_base, and D; 204/21 classification; symmetry; 226 guards.
4. Completed/success exact-SHA workflow run and job; decoded logs must prove exact checkout SHA, formatting, Native tests, and oracle success.
5. Downloaded artifact must match GitHub's SHA-256 digest; independently verify ZIP CRC, PROJECT_ID/SHA, exit.txt=0, and all raw oracle rows.
6. Whole-stage closure remains NOT_CLAIMED in the run artifact until the separate exact-SHA artifact audit is complete. Only then may DEVELOPMENT_STAGE advance LAST_COMPLETED_STAGE to 7.

## Stage boundaries

Stage06 remains accepted on its validated code SHA and is regression-tested, not redefined. Stage07/PATCH03 is the only new semantic scope. The historical pre-Stage03 Rust runtime RED remains NOT_CLAIMED; the approved 2026 reconstruction is not historical provenance. No full-calendar claim is made.
