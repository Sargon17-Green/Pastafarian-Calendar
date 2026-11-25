# Stage06 DISCOVERY03 — Legacy-tag distance contract

PROJECT_ID=PC-BRANCH-RUST-AZERBAIJANI
BRANCH=Rust+Azərbaycan-dili
STAGE=6
KIND=DISCOVERY03
STAGE06_SCOPE=LEGACY_TAG_DISTANCE
STAGE06_STONE_PROBE=AUXILIARY_ONLY
STAGE07=NOT_STARTED
HISTORICAL_PRE_STAGE03_RUST_RED=NOT_CLAIMED
CONTRACT=FROZEN

## Purpose and scope

The Stage06 semantic scope is the legacy tag-distance discrepancy through the real Rust PATCH02 production chain. The 46×5 stone probe and its 230-value Native evidence are retained as auxiliary regression evidence; they do not substitute for the Stage06 distance gate. Stage07/PATCH03 is not part of this contract and must not be started.

The historical pre-Stage03 Rust runtime RED remains NOT_CLAIMED. This contract measures the explicitly approved 2026 Rust reconstruction path only; it does not rewrite historical source provenance.

## Mathematical contract

Let the foundation be F = -15,055,671. For an input day d, the reconstructed tag is:

- N(d) = 2(F-d), when d < F.
- N(d) = 2(d-F)+1, when d >= F.

For signed offsets c and t relative to F, the Stage06 legacy distance is:

L(c,t) = abs(N(F+c) - N(F+t)).

The independent normative comparator is:

Q(c,t) = abs(t-c) + 1.

Stage06 reports L unchanged. It does not apply the later PATCH03 selection rule and does not replace L with Q. A row is RED exactly when L(c,t) != Q(c,t); otherwise it is CONTROL.

The Python oracle implements the tag definition directly with arbitrary-precision integers. It does not import, execute, copy, or call Rust production code.

## Bounded input domain and expected output

The ordered offset set is:

- Local values: -8, -3, -2, -1, 0, 1, 2, 3, 8.
- Wide values: -2^129, +2^129, -2^1031, +2^1031.

The Native test evaluates the complete ordered Cartesian product: 13 × 13 = 169 distinct pairs. Each emitted row contains c, t, observed legacy distance, normative comparator, and RED/CONTROL flag.

The exact independent classification is 153 RED and 16 CONTROL. The test must also exercise 169 duplicate-call guards plus one missing-observation guard, for 170 guards total. The Native test emits the guard marker only after all corresponding assertions pass.

The Stage05 wrapper dependency remains separately measured over 69 distinct signed offsets: -31 through +31 and ±2^129, ±2^1031, ±2^4097. Its independent totals are 34 pre-foundation correction scars, 35 controls, and 69 duplicate guards.

## Production-route and invariants

1. The real dispatcher executes WorkCountsPatch02 before LegacyTagDistanceDiscovery03 for each fresh call.
2. The Stage06 handler changes only the distance field to the absolute difference of the two PATCH02-observed tags.
3. The action, target, connection, direction, and their call ownership remain unchanged.
4. Each successful call records one PATCH02 observation, one legacy action call, one legacy target call, and one DISCOVERY03 distance call.
5. A repeated Stage06 call is rejected with InvalidState and leaves the context unchanged.
6. A missing PATCH02 observation is rejected with InvalidState and leaves the context unchanged.
7. BigInt inputs are not narrowed to machine integers. Stage06 does not claim the full five-field calendar; BootstrapOnly remains explicit.

## Required gates

1. Exact branch and checkout SHA; stage identity and source markers; cargo fmt --all -- --check.
2. Rust Native cargo test --all-targets with all existing Stage01–Stage05 regression tests.
3. Exact 169-row matrix, no malformed/duplicate/missing/extra rows, independent per-row L and Q recomputation, 153/16 classification, and 170 guards.
4. Stage05 wrapper regression: 69 unique rows, independent raw/corrected tag recomputation, 34/35 classification, and 69 guards.
5. Existing 46×5 stone probe: all 230 values, bounds, determinism, and BootstrapOnly marker retained as auxiliary evidence only.
6. Completed/success exact-SHA workflow run and job; decoded log must prove checkout SHA, formatting and Native step success.
7. Downloaded ZIP artifact must match the GitHub artifact digest; independently verify ZIP CRC, exact PROJECT_ID/SHA in sha.txt, exit.txt=0, and all oracle output.

The CI artifact may report STAGE06_DISCOVERY03_DISTANCE_NATIVE=PASS after the Native and Python gates. Whole-stage closure remains NOT_CLAIMED in that run artifact until the separate exact-SHA artifact audit is complete. Counter reconciliation may not create Stage07 or alter the historical RED classification.
