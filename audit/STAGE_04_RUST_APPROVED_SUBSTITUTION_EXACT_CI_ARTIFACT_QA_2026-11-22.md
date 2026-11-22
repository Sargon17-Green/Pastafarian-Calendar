# Rust Azərbaycan Stage04 — exact-SHA approved reconstruction substitution CI and artifact QA

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Date: 2026-11-22
Original branch: Rust+Azərbaycan-dili
Exact tested source/workflow HEAD: 756b680eb8acbd59145440e2d480dd51546b28b0
User decision: APPROVED_RECONSTRUCTION_SUBSTITUTE (2026-11-22)
Decision scope: only Stage04's historical Rust RED evidence requirement.
Historical pre-Stage03 Rust numeric RED: NOT_PROVEN (no retrospective relabeling).
Stage04 whole: OPEN / NOT_CLAIMED; CURRENT_STAGE=4, LAST_COMPLETED_STAGE=3.

## Exact completed CI and archive

- Stage04 automated push run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45068619686
- Stage04 job 137350317045 completed/success, exact checked-out SHA confirmed in decoded log; all steps completed/success, including the new approved substitution verifier.
- Names Lock run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45068619709
- Names Lock job 137350317136 completed/success; exact checked-out SHA confirmed in decoded log; canonical-name verification step completed/success.
- Native run artifact 14772551617, https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45068619686/artifacts/14772551617
- Downloaded original ZIP: 21,463 bytes, SHA-256 7135b75eb3772f38d202e23883df47952f8bce2b3e92d7d8faf12a7ea47f0de0, 19/19 ZIP members and CRC validation successful, exit.txt=0, sha.txt exact PROJECT_ID and SHA.
- Native original-branch baseline/regression cargo tests all passed; source/provenance Python tests 16/16, callable-source controls 19/19, original TSV protocol 6/6, new substitution negatives 5/5. No unexpected failed Rust tests.
- Direct archived Python↔Rust differential markers: RED=8, CONTROL=7, UNEXPECTED=0; PATCH_OK=15, CANDIDATE_OK=15; CI step concluded success.
- evidence/stage04_reconstructed_substitution.json: reconstruction_substitution_static_eligible=true, independently_verified_observed_rows=128, before_foundation=64, on_or_after_foundation=64, original_historical_gate_unchanged=true, historical_pre_stage03_rust_red_proven=false, native_ci_live_status_checked_by_this_script=false, stage04_closure=NOT_CLAIMED.
- The substitution script does not independently fetch historical Actions runs; separate immutable Native evidence was checked: RED run44937766996 job136948055584, 3 numerical mismatches + 3 controls; reconstructed GREEN run44947008707 job136976416170, 6/6 correction/control cases; exact 128-case observed Native run45067993657 job137348363963, independently compared to 128-row original-branch oracle with 0 mismatches. The SHA, CRC, stdout and evidence are documented in previous permanent audits.

## Code and policy boundaries

- Policy decision and specific exception: audit/STAGE_04_RUST_AUTHORIZED_RECONSTRUCTION_SUBSTITUTION_2026-11-22.md.
- Static validator: tools/stage04_rust_reconstruction_substitution.py; 5 negative/positive unit checks: tools/tests/test_stage04_rust_reconstruction_substitution.py.
- Existing original historical provenance verifier blob remains 4969623f859827a603f88c5811d03ac9463bbd3c.
- Current original production Rust code was not changed to transplant reconstructed code; reconstructed implementation remains isolated on its branch. No main/merge/Stage05 activity, no claimed original historical Rust RED.

## Disposition

The *authorized reconstructed evidence substitution gate* is evidenced by completed exact-SHA CI and independent artifact inspection. It is not the same as accepting Stage04 as a whole: the existing workflow records stage04_closure=NOT_CLAIMED and DEVELOPMENT_STAGE.md still records current=4, last_completed=3. A separate explicit, testable Stage04 completion transition is necessary; do not silently rewrite the stage counter or infer that a static verifier creates a historical witness. Keep the branch READY for that engineering step.
