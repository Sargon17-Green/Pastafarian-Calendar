# Rust Azərbaycan Stage04: reconstructed differential oracle — 2026-11-22

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Status: EVIDENCE_PREPARATION_ONLY; ORIGINAL_STAGE04=OPEN/NOT_CLAIMED.
Original branch (prior to this audit-only report): `f4a09704e962400ee0944f26aa66ea1b95207680`
Reconstruction live branch: `35bda9d2a62a17b4c0afe00ea1eb7ce875bdfbb5`
Exact GREEN tested SHA: `3eed23d0664ef7484649194776c0327c18280cd0`
Exact RED tested SHA: `108833d04786be22bfcadc987c7208b35c373451`

## Purpose and pinned input

The 2026 GREEN test in `tests/reconstruction_stage03_daytag_red.rs` (blob `da4b41027e5e1ca71f8c5f30666f66b078fcc08d`) covers deterministic signed BigInt inputs for indices 0–127. The GitHub CI log reports `RECONSTRUCTED_RUST_DAYTAG_DIFFERENTIAL=128 GREEN=128 UNEXPECTED=0`; the artifact and job log do **not** preserve each of the 128 observed Rust outputs.

A separate signed-integer implementation (JavaScript BigInt), without importing Rust production code, generated the 128 explicit independent expected rows in `audit/fixtures/rust_az_stage04_128_independent_oracle_20261122.tsv`. A second, separately executed Python integer implementation cross-checked the serialization and SHA-256. The tab-separated fixture has 128 data rows and a header; 9,593 UTF-8 bytes; SHA256 `9fb7051a993abe6c37980848ef912c8f5a438c51a782fb7e0d786944a45ffb80`.

Input formula (from the pinned Rust test contract, *not* from Rust runtime output):
- `F=-15055671`; for each integer `i` from 0 through 127,
- `distance=((i+1) << (i % 120)) + 37*i + 3`;
- `day=F-distance` when `i` is even; otherwise `day=F+distance`.
- Independently derived mathematical oracle: `P(day)=2*abs(day-F)+(1 if day>=F else 0)`.

Coverage inventory: 64 pre-foundation, 64 after-foundation; all 128 strictly nonzero distances; 128 distinct indices. The fixture was crosschecked using `2*distance+(i%2)`; no arithmetic contradictions. Maximum `abs(day)` bit length: 126. The first row is `0, -15055675, 8`; the last row `127, -15034585, 42173`.

## Evidence and exact limits

- RED: run [44937766996](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44937766996), job `136948055584`, completed/success on exact RED SHA, checkout/log verified; three compiled-dispatcher mismatches and three controls. Successful *expected-RED test* is not correct Rust production.
- GREEN: run [44947008707](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44947008707), job `136976416170`, completed/success on exact GREEN SHA, checkout/log verified; six printed shared-case outputs match the previously checked independent oracle, and 128 additional differential cases pass according to Rust assertions and the log *summary*. Names Lock [44947008592](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44947008592) also completed/success on GREEN SHA.
- The 128 TSV expected outputs are **independent static oracle data**, not observed per-case Native Rust outputs. The 128 per-case equality checks ran inside Rust but are only evidenced in aggregate. Therefore this report does not claim independently re-evaluated observed Rust outputs for all 128.
- This report adds no runtime test, source change, rerun or Stage04 policy change.

## Admission boundary and next decision

Canonical Stage03 closure `716e5a6f335b1a15464029b446edb468f3a8482c` is **two ancestors behind** reconstructed RED. The unchanged original provenance gate at `tools/stage04_rust_witness_provenance.py` requires a historical Rust production witness that is an ancestor of that Stage03 closure, which retrospective reconstruction cannot satisfy. Exact `Rust+Azərbaycan-dili` original HEAD was `f4a09704e962400ee0944f26aa66ea1b95207680` at preflight; do not replace it with reconstructed SHA.

**USER DECISION REQUIRED**: explicitly authorize an amendment accepting actual 2026 RED→GREEN reconstruction as a substitute for *historical* Rust RED for Stage04, with provenance clearly labeled as reconstructed; OR retain the original historical-witness gate pending a genuinely earlier source artifact. Until then Stage04 stays OPEN/NOT_CLAIMED; CURRENT_STAGE=4, LAST_COMPLETED_STAGE=3. Do not run Stage05, merge/main or claim historical Rust RED.
