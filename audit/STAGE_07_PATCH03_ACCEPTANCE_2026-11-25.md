# Stage07 / PATCH03 — exact-SHA Native and artifact acceptance

PROJECT_ID=PC-BRANCH-RUST-AZERBAIJANI
BRANCH=Rust+Azərbaycan-dili
STAGE07_CODE_SHA=f8c0d1e3475082c367f14c4db962085e494eae6b
STAGE07_RUN_ID=45684356045
STAGE07_JOB_ID=139452885812
STAGE07_RUN_STATUS=completed
STAGE07_RUN_CONCLUSION=success
STAGE07_ARTIFACT_ID=15055034210
STAGE07_ARTIFACT_BYTES=22710
STAGE07_ARTIFACT_SHA256=64095b90bd7840ec25e57eaaf65f7bfde6b2b39152647ee767f0197f69fb116b
STAGE07_ARTIFACT_CRC=PASS
STAGE07_ARTIFACT_MEMBERS=8
STAGE07_EXIT=0
STAGE07_RUST_TESTS=48
STAGE07_RUST_FAILURES=0
STAGE07_DISTANCE_ROWS=225
STAGE07_ORACLE=225/225
STAGE07_MISMATCH=204
STAGE07_MATCH=21
STAGE07_GUARDS=226
STAGE07_BOOTSTRAP_ONLY=PASS
STAGE07_CLOSURE=ACCEPTED
CURRENT_STAGE=7
LAST_COMPLETED_STAGE=7
EXPECTED_REPOSITORY_STATE=PATCH03_STAGE07_ACCEPTED_HOLD_NO_STAGE08

## Exact Native evidence

1. GitHub Actions run 45684356045, job 139452885812, completed/success on the exact checkout SHA f8c0d1e3475082c367f14c4db962085e494eae6b. All workflow steps completed successfully: exact checkout, Stage07 scope and formatting, independent-oracle self-test, Native Stage01–Stage07, independent oracle, and artifact upload.
2. The decoded job log confirms the exact checkout SHA, successful `cargo fmt --all -- --check`, Native test completion, the 225-row Stage07 marker, independent oracle PASS, and artifact upload.
3. Native `cargo test --all-targets -- --nocapture` completed with 48 passed and 0 failed tests; one empty target reported 0 tests. The Stage07 integration test passed and emitted all 225 ordered pair observations.
4. The independent Python oracle recomputed the piecewise tag function using arbitrary-precision Python integers. It checked all 225 unique ordered pairs, every L/B/mismatch/selected/result field, pair symmetry, the 204/21 classification, and the 226 guard marker. Result: STAGE07_PATCH03_ORACLE=PASS ROWS=225 MISMATCH=204 MATCH=21 GUARDS=226.
5. Artifact 15055034210 was downloaded and independently inspected. It contains 8 files; ZIP CRC passed. Its actual size is 22,710 bytes and independently computed SHA-256 64095b90bd7840ec25e57eaaf65f7bfde6b2b39152647ee767f0197f69fb116b matches the GitHub artifact digest. sha.txt contains the exact PROJECT_ID and code SHA; exit.txt is 0; result.txt records Native PASS and Oracle PASS. The run artifact deliberately leaves whole-stage closure NOT_CLAIMED until this separate audit.

## Stage06 regression and Names Lock

STAGE06_RUN_ID=45684355500
STAGE06_JOB_ID=139452885615
STAGE06_STATUS=completed
STAGE06_CONCLUSION=success
STAGE06_ARTIFACT_ID=15055252821
STAGE06_ARTIFACT_BYTES=22770
STAGE06_ARTIFACT_SHA256=1f1b18760d3c5d031944d8f2712d2664b9c531333824abe979524fefb1637577
STAGE06_ARTIFACT_CRC=PASS
STAGE06_ARTIFACT_EXIT=0
STAGE06_DISTANCE_ORACLE=169/169
STAGE06_DISTANCE_RED=153
STAGE06_DISTANCE_CONTROL=16
STAGE06_GUARDS=170
STAGE05_WRAPPER_ORACLE=69/69
STAGE05_WRAPPER_RED_SCAR=34
STAGE05_WRAPPER_CONTROL=35
STAGE05_WRAPPER_GUARDS=69

NAMES_LOCK_RUN_ID=45684355653
NAMES_LOCK_JOB_ID=139452884342
NAMES_LOCK_STATUS=completed
NAMES_LOCK_CONCLUSION=success
NAMES_LOCK_CHECKED_SHA=f8c0d1e3475082c367f14c4db962085e494eae6b

The Stage06 regression workflow also checked out the same exact SHA, completed successfully, and uploaded an independently verified 8-file artifact (22,770 bytes, SHA-256 1f1b18760d3c5d031944d8f2712d2664b9c531333824abe979524fefb1637577; CRC PASS; exact PROJECT_ID/SHA; exit 0). Its independent oracle confirmed the 169/169 Stage06 rows and the 69/69 Stage05 wrapper chain. The Canonical Names Lock run completed/success on the same exact code SHA.

## Scope and state reconciliation

The Stage07 implementation is confined to PATCH03 chronological-distance correction. It preserves the Stage06 legacy distance in WorkCounts and stores the PATCH03 observation separately in the call-local context. No full-calendar claim is made; BootstrapOnly remains enforced. The historical pre-Stage03 Rust runtime RED remains NOT_CLAIMED.

The Stage04 whole-stage compatibility verifier initially rejected the new Stage07 successor state after the Stage07 code commit. This was a stale enumerated-successor check, not a Rust Native or Stage07 oracle failure. The verifier and its self-tests were updated to recognize Stage07 pending/accepted states in commit e6a284a87797be3d421a306133c05208ff95c955. Its automatic Stage04 run 45685064394 was queued when this acceptance record was prepared and is not counted as PASS here. Stage07 acceptance is based on the completed exact-SHA Stage07/Stage06 Native evidence, independent artifact audits, and exact-SHA Names Lock above.

The branch HEAD immediately before this acceptance-only commit was e6a284a87797be3d421a306133c05208ff95c955. Compared with the validated Stage07 code SHA, that intervening commit changes only the Stage04 audit verifier and its workflow; no Stage07 production source, test, oracle, or Native workflow content changed.

No Stage08 work, main update, merge, or release is authorized or performed. Stage07 closure is ACCEPTED; the next action is targeted identification of the already-defined Stage08 scope. Do not invent or create a new stage if no authoritative sequence or scope is found.
