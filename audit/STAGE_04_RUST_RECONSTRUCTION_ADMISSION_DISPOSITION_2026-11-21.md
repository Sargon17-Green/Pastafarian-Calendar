# Rust Azerbaijani Stage04: independent reconstruction admission disposition (2026-11-21)

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Original branch: Rust+Azərbaycan-dili
Original HEAD at preflight: e438cc7982f3d765f1d6bf33088b89bfaf1bb4db
Reconstruction branch: reconstruction/rust-az-stage03-daytag-red-20261121
Reconstruction HEAD at preflight: 35bda9d2a62a17b4c0afe00ea1eb7ce875bdfbb5
Original canonical Stage03 closure: 716e5a6f335b1a15464029b446edb468f3a8482c
Original canonical Stage04 introduction: 2a7648c345ee63d9e5c81ca0361c6eb3060c6c4f
Status: RECONSTRUCTED_NATIVE_RED_GREEN_VERIFIED / ORIGINAL_STAGE04_NOT_CLAIMED
Boundary: no original production edits, no main, merge, Stage05, or policy alteration.

## Independently verified immutable Native evidence

RED production source SHA 108833d04786be22bfcadc987c7208b35c373451:
- Run 44937766996, job 136948055584, completed/success, push event, exact checkout SHA and Rust 1.100.0; original Stage01/02/03 regressions 16+3+4 passed.
- Artifact 14722536019 downloaded and independently rehashed, 6200 bytes, SHA256 81a8f8ce4346f33dc011888bb055e0d785bfce4667a5e2f24e302f755c1150b1, 6/6 ZIP CRC, exit.txt=0, sha.txt exact PROJECT_ID/branch/SHA, explicit RECONSTRUCTION=YES.
- Actual compiled Rust dispatcher produced 3 numerical mismatches before F=-15055671 (day F-2: 5 vs expected 4; day F-1: 3 vs 2; day F-2^256: expected +1), and 3 valid controls at/after F. stdout and job log agree. Process success verifies the expected-RED test, not correct production output.

Separate later GREEN correction SHA 3eed23d0664ef7484649194776c0327c18280cd0:
- Git compare against executed RED: ahead=1, behind=0, exactly 4 paths (source, test, workflow, report); the original RED remains an immutable ancestor.
- Run 44947008707, job 136976416170, completed/success on exact SHA; Names Lock run 44947008592, job 136976415644, completed/success and checkout verified.
- Artifact 14723203773 downloaded and independently rehashed, 6350 bytes, SHA256 b68c6d241178a02e3556beb4cf12df47e4674b7e0174cccfbfa9f6b5847be807; ZIP CRC6/6, exit.txt=0, sha.txt exact SHA/RED_ANCESTOR and RECONSTRUCTION=YES.
- Independent arithmetic oracle, recomputed outside Rust and without using the archived oracle: for every one of the six shared signed BigInt inputs, P(d)=2*abs(d-F)+(1 if d>=F else 0). Both archived oracle columns independently match 6/6. Actual RED mismatches=3 and actual GREEN mismatches=0. The GREEN Native test also reported 128/128 additional deterministic differential cases; these 128 were inspected through the native log summary, not independently recalculated from absent per-case rows.
- GREEN Rust tests: 2 reconstruction +16 Stage01 +3 Stage02 +4 Stage03 =25 passed.

## Canonical admission gate: ineligible as an ORIGINAL historical witness

Inspected original-branch tools/stage04_rust_witness_provenance.py, blob 4969623f859827a603f88c5811d03ac9463bbd3c. verify_pin requires witness_commit to be an ancestor of exact canonical Stage03 closure (plus exact blobs, original tree mode, Stage04 introduction ancestry and checked-out branch HEAD). Its contract is historical-source qualification; a production reconstruction created later cannot masquerade as an original Stage03 source.

GitHub compare source evidence: RED SHA -> canonical Stage03 closure status=behind, ahead=0/behind=2; canonical Stage03 closure -> RED ahead=2/behind=0. Thus the executed RED is a DESCENDANT of closure, not an ancestor. The reconstruction HEAD also diverges from original Stage04 introduction (ahead=4/behind=1), while original branch still descends from the introduction (ahead=58/behind=0 at inspected HEAD). This disqualifies the new RED and GREEN from original Stage04's historical-source gate, although both are valid as explicit 2026 reconstructed executable evidence. The original Stage03 production src/lib.rs at 716e5a6f returned BootstrapOnly on the five-field route and did not expose an original callable numeric day-tag.

## Verdict, limits, and next decision

ACCEPTED within restricted scope: 2026 reconstruction RED actually executed and corrected with separate GREEN commit; exact-SHA Native and artifact evidence verified; 6 shared rows checked with independent integer arithmetic.
NOT ACCEPTED: original pre-Stage04 callable Rust day-tag / historical numerical RED; original Stage04 as a whole; Stage05; any rewrite or merge.
CURRENT_STAGE=4; LAST_COMPLETED_STAGE=3. Original HEAD must not be replaced by reconstruction SHA.

Original Stage04 historical admission remains OPEN/NOT_CLAIMED. Without a NEW original pre-Stage04 production witness (not another repetition of previous index searches), any move to count the 2026 reconstruction in lieu of the original required historical mistake would CHANGE the Stage04 acceptance policy and needs an explicit user decision. No such change is made here. No user-machine execution package or /Pending_User_Execution cleanup is implicated.

Evidence:
- https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44937766996
- https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44937766996/artifacts/14722536019
- https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/108833d04786be22bfcadc987c7208b35c373451
- https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44947008707
- https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44947008707/artifacts/14723203773
- https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44947008592
- https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/3eed23d0664ef7484649194776c0327c18280cd0
- https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/35bda9d2a62a17b4c0afe00ea1eb7ce875bdfbb5
