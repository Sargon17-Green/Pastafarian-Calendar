# Rust+Azərbaycan-dili reconstructed native 128-case exact-output independent QA — 2026-11-22

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
ORIGINAL_BRANCH: Rust+Azərbaycan-dili
ORIGINAL_PRECHECK_HEAD: 9dc029ec81fa1d6538113a4cc9c56ad41f160bb7
RECONSTRUCTION_BRANCH: reconstruction/rust-az-stage03-daytag-red-20261121
RECONSTRUCTED_NATIVE_SHA: 07a8e7b4b2e90cdc42886dd88c6b754fd5ebb085
STATUS: PER_CASE_NATIVE_DIFFERENTIAL_VERIFIED; ORIGINAL_STAGE04=OPEN/NOT_CLAIMED

## Exact completed execution

- Reconstructed GREEN GitHub Actions push run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45067993657
- Native job: 137348363963, completed/success. Checkout SHA and stage-root/RED ancestor checks are in the decoded log.
- Canonical Names Lock run https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45067993623, job 137348363762, completed/success on same reconstructed SHA.
- Artifact 14772565407: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45067993657/artifacts/14772565407. Downloaded ZIP is 10,443 bytes, SHA256 16f1397f91c61288a48fcf605ff41dab736ad9453ae31aa91871f08b3bdc726f. ZIP six entries, CRC 6/6, no corrupt member. sha.txt confirms PROJECT_ID, reconstruction branch, exact SHA, and RED ancestor. exit.txt is 0. result.txt explicitly says RECONSTRUCTION_NATIVE_GREEN=PASS, DIFFERENTIAL=128 and ORIGINAL_STAGE04=NOT_CLAIMED. Rust toolchain 1.100.0.
- The native stdout.txt inside the ZIP contains 128 separately printed actual Dispatcher observations, not only a summary. Independently fetched job logs also contain 128 separate observations.

## Independent 128-row differential

Input family: F=-15055671; index i=0..127; distance=((i+1) << (i mod 120))+37*i+3; day=F-distance for even i and F+distance for odd i. Independent mathematical expectation P(day)=2*abs(day-F)+(1 if day>=F else 0).

Compared all 128 observed native triples (index, day, Rust actual day-tag) against the separately committed original-branch oracle audit/fixtures/rust_az_stage04_128_independent_oracle_20261122.tsv, fixture SHA256 9fb7051a993abe6c37980848ef912c8f5a438c51a782fb7e0d786944a45ffb80, Git blob 2c4a4b02afd47744bffcbe3e5c2dd2fe6177e461. Recomputed signed arbitrary-precision arithmetic independently from the Rust runtime and compared both inputs and outputs: matched 128/128, unique sequential indices 128/128, regions 64 BEFORE and 64 ON_OR_AFTER. No mismatches.

The normalized actual-output witness is stored beside this report as audit/fixtures/rust_az_stage04_128_NATIVE_OBSERVED_20261122.tsv, columns index,day,native_tag, 128 rows + header, 5,787 bytes, SHA256 cf4c5f12392e04a3e39a80b209e155fb19b0e0f0795920a8bb459f1556ffcd6f.

## Boundary and decision

This establishes independently checked numerical agreement of all 128 reconstructed 2026 production-dispatcher outputs. It does NOT establish a historical pre-Stage04 Rust numeric RED: the executed RED SHA 108833d04786be22bfcadc987c7208b35c373451 is a post-Stage03 reconstructed descendant, not an ancestor of original Stage03 closure 716e5a6f335b1a15464029b446edb468f3a8482c. Canonical original witness provenance gate is unchanged. Original Rust production implementation is unchanged; no Stage05, main, merge or historical-acceptance policy edit.

User decision remains exclusive: authorize a precisely delimited exception for the 2026 reconstructed executed RED→GREEN as a SUBSTITUTE (never relabel as historical), or retain the original historical source eligibility gate pending genuinely earlier evidence.
