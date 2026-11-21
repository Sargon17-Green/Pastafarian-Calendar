# Exact-SHA QA: native RED -> separate GREEN commit (Rust Azerbaijani reconstruction)

Date: 2026-11-21
PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Historical root: 716e5a6f335b1a15464029b446edb468f3a8482c (original accepted Stage03)
Reconstruction branch: reconstruction/rust-az-stage03-daytag-red-20261121
Original branch Rust+Azərbaycan-dili stays at e438cc7982f3d765f1d6bf33088b89bfaf1bb4db.
Original Stage04 OPEN / NOT_CLAIMED; CURRENT_STAGE=4, LAST_COMPLETED_STAGE=3.

## RED: deliberate production Rust error, actually executed before correction
SHA: 108833d04786be22bfcadc987c7208b35c373451
Native run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44937766996
Job: 136948055584, completed/success, exact checkout, Rust 1.100.0, cargo test --all-targets -- --nocapture.
Artifact ID: 14722536019; 6200 bytes; SHA256 81a8f8ce4346f33dc011888bb055e0d785bfce4667a5e2f24e302f755c1150b1; ZIP CRC 6/6; exit=0; sha.txt exact.
Observed real Rust MonsterDispatcher route: numeric mismatches 3/3 (F-2 gives 5 vs oracle 4; F-1 gives 3 vs 2; F-2^256 differs by +1); controls 3/3 (F, F+1, F+2^256); no unexpected. Original Stage01-03 16+3+4 tests passed. Test process SUCCESS means expected-red assertions passed; it does NOT mean erroneous production behavior was correct.

## GREEN: separate descendant production correction
SHA: 3eed23d0664ef7484649194776c0327c18280cd0
Parent: 108833d04786be22bfcadc987c7208b35c373451. Git compare ahead1/behind0, exactly four paths: production source, test, workflow, and initial RED->GREEN report. Live branch identical to GREEN SHA at readback. The original branch was separately re-read and remained unchanged.
Native run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44947008707
Job: 136976416170, completed/success; exact GITHUB_SHA checked; canonical Stage03 and immutable RED SHA ancestors checked.
Names Lock: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44947008592
Job: 136976415644, completed/success; decoded checkout exact GREEN SHA and canonical names verification step success.
Artifact ID: 14723203773; 6350 bytes, SHA256 b68c6d241178a02e3556beb4cf12df47e4674b7e0174cccfbfa9f6b5847be807; ZIP CRC 6/6; exit=0; sha.txt exact code SHA and RED_ANCESTOR. Rust 1.100.0.
Six original oracle cases now match: 3 previously RED corrected, 3 prior controls preserved. Independent test-side piecewise integer oracle checks the actual Rust production dispatcher, invocation isolation/context/metrics; 128 extra deterministic signed/unbounded-BigInt dispatcher cases also match. Rust test suites: corrected reconstruction 2/2; original Stage01 16/16, Stage02 3/3, Stage03 4/4. Total native tests 25/25, numerical comparisons 6+128, no unexpected errors.

## Strict interpretation / next
- Original 2026 historical Rust Stage03 production had no callable day-tag; this 2026 reconstruction cannot be treated as historical October executable witness.
- Code change, actual Native RED, actual Native GREEN, independent per-case differential, and full historical Stage04 acceptance are distinct. This report confirms reconstructed RED->GREEN only, NOT original Stage04.
- No main/merge/release. No user execution package or Pending_User_Execution cleanup required.
- Next: assess non-destructive provenance/disposition of newly verified reconstruction against original Stage04 admission gate, without rewriting prior commits or promoting it as an original historical witness; retain source proof and avoid duplicated tests.
