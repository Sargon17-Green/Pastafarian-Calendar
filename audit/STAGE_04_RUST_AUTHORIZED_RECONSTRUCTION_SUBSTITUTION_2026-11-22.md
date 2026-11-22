# Rust+Azərbaycan-dili — Stage04 authorized 2026 reconstruction substitution

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Decision date: 2026-11-22
Decision source: the user's explicit “מאשר” in response to the precise alternative:
“האם אתה מאשר להכיר בשחזור RED→GREEN שבוצע בשנת 2026 כתחליף מפורש ומתועד לדרישת העדות ההיסטורית של Stage04 ...?”
Disposition: APPROVED_RECONSTRUCTION_SUBSTITUTE, not HISTORICAL_RED.
Scope: the Rust+Azərbaycan-dili Stage04 historical-source **admission condition only**.

## What was approved
Accept the actual, separately executed **2026 reconstruction** of a deliberately wrong Rust day-tag production/dispatcher route, followed by a separate corrected GREEN revision, in place of an original pre-Stage03 historical Rust numeric RED witness. The alternative is explicitly labeled `AUTHORIZED_2026_RECONSTRUCTED_NATIVE_RED_GREEN`. This is a narrowly bounded policy exception. It must never be described as a historical Rust bug before Stage03, nor used to qualify unrelated projects, stages, witnesses, commits or languages.

Immutable pins:
- Original Stage03 closure: `716e5a6f335b1a15464029b446edb468f3a8482c`.
- Original Stage04 introduction: `2a7648c345ee63d9e5c81ca0361c6eb3060c6c4f`.
- Reconstructed intentionally wrong Rust RED: `108833d04786be22bfcadc987c7208b35c373451`, completed Native run [44937766996](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44937766996), job 136948055584, artifact 14722536019; 3 observed numerical mismatches before F, 3 controls.
- Corrected Rust GREEN: `3eed23d0664ef7484649194776c0327c18280cd0`, completed Native run [44947008707](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44947008707), job 136976416170, artifact 14723203773; six shared inputs corrected/preserved, 25 native tests.
- Explicit 128 observed case evidence SHA: `07a8e7b4b2e90cdc42886dd88c6b754fd5ebb085`, run [45067993657](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45067993657), job 137348363963, artifact 14772565407, 128/128 independent signed BigInt comparisons (64/64 around foundation).
- Original-branch expected TSV: `audit/fixtures/rust_az_stage04_128_independent_oracle_20261122.tsv`, SHA256 `9fb7051a993abe6c37980848ef912c8f5a438c51a782fb7e0d786944a45ffb80`.
- Original-branch observed TSV: `audit/fixtures/rust_az_stage04_128_NATIVE_OBSERVED_20261122.tsv`, SHA256 `cf4c5f12392e04a3e39a80b209e155fb19b0e0f0795920a8bb459f1556ffcd6f`.

## Machine-readable admission and exclusions
`tools/stage04_rust_reconstruction_substitution.py` performs fail-closed exact-SHA and original-branch Git ancestry checks, validates the unchanged historical provenance verifier's Git blob, checks reconstruction RED->GREEN->observed-test ancestry, and independently compares **all 128** signed BigInt observed Rust output rows with a separately preserved oracle and arithmetic. It returns `reconstruction_substitution_static_eligible=true` only when all static checks pass. Its `historical_pre_stage03_rust_red_proven` is always false and `stage04_closure` is always `NOT_CLAIMED`; it does not remotely fetch Actions logs or verify a current run. Native/CI acceptance must be supported by separately reviewed exact completed logs and artifacts.

The original `tools/stage04_rust_witness_provenance.py` stays byte-for-byte unchanged. Its historical-only output may continue to say no original callable Rust day-tag and no original historical RED, because this remains factually true. Original Stage01–03 regressions, Stage04 baseline, original Python↔Rust differential, Names Lock and production source preservation must still pass their applicable gates.

## Stage04 status
APPROVAL OF THE SUBSTITUTE is not automatic Stage04 closure. On creating this policy/verification commit: `CURRENT_STAGE=4`, `LAST_COMPLETED_STAGE=3`, `Stage04=OPEN/NOT_CLAIMED` remain until exact new-SHA CI and completion evidence is reviewed. No Stage05, no main/merge, no rewrites, no production Rust migration, no publication.
