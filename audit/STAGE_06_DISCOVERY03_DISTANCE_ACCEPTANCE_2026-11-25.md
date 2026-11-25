# Stage06 DISCOVERY03 — post-Native artifact acceptance audit

PROJECT_ID=PC-BRANCH-RUST-AZERBAIJANI
BRANCH=Rust+Azərbaycan-dili
VALIDATED_CODE_SHA=674b2cf4b9229d6d08ad0a65ee3c59a5695be0c0
STAGE06_RUN_ID=45671229977
STAGE06_JOB_ID=139406744135
STAGE06_RUN_STATUS=completed
STAGE06_RUN_CONCLUSION=success
NAMES_LOCK_RUN_ID=45671229679
NAMES_LOCK_JOB_ID=139406741825
NAMES_LOCK_STATUS=completed
NAMES_LOCK_CONCLUSION=success
STAGE06_ARTIFACT_ID=15049022965
STAGE06_ARTIFACT_BYTES=11842
STAGE06_ARTIFACT_SHA256=795d0e3e9639be1de5a98a754c7b6d8f268f4d19b09a9664fd5b02c8ed7ab6e7
STAGE06_ARTIFACT_CRC=PASS
STAGE06_EXIT=0
STAGE06_DISTANCE_ROWS=169
STAGE06_DISTANCE_ORACLE=169/169
STAGE06_DISTANCE_RED=153
STAGE06_DISTANCE_CONTROL=16
STAGE06_GUARDS=170
STAGE05_WRAPPER_ROWS=69
STAGE05_WRAPPER_ORACLE=69/69
STAGE05_WRAPPER_RED_SCAR=34
STAGE05_WRAPPER_CONTROL=35
STAGE05_WRAPPER_GUARDS=69
STAGE06_STONE_PROBE=AUXILIARY_ONLY_PASS
STAGE06_CLOSURE=ACCEPTED
CURRENT_STAGE=6
LAST_COMPLETED_STAGE=6
EXPECTED_REPOSITORY_STATE=DISCOVERY03_STAGE06_ACCEPTED_HOLD_NO_STAGE07
STAGE07=NOT_STARTED
HISTORICAL_PRE_STAGE03_RUST_RED=NOT_CLAIMED
FULL_CALENDAR=BOOTSTRAP_ONLY
MAIN_MERGE_RELEASE=NOT_PERFORMED

## Evidence reviewed

1. GitHub Actions run 45671229977 and job 139406744135 are completed/success on the exact checkout SHA 674b2cf4b9229d6d08ad0a65ee3c59a5695be0c0. The decoded job log records the exact checkout, successful scope/format step, independent-oracle self-test, Native Stage01–Stage06 step, and successful artifact upload.
2. The job executed cargo fmt --all -- --check and cargo test --all-targets -- --nocapture. All reported test suites passed: 44 passed, 0 failed; the empty target reported 0 tests.
3. The Native stdout contains the complete 13×13 ordered distance matrix. The independent Python oracle was run both inside CI and again against the downloaded artifact stdout. It independently recomputed each tag from the piecewise mathematical definition with arbitrary-precision integers; all 169 unique pairs matched both L and Q, with 153 RED and 16 CONTROL. The 170 guard marker follows the 169 per-row duplicate-call assertions and the missing-observation guard assertion.
4. The same independent audit checked the Stage05 PATCH02 wrapper chain: 69 unique inputs, 69/69 raw and corrected tag matches, 34 pre-foundation scars, 35 controls, and 69 guards.
5. Artifact 15049022965 is 11,842 bytes. Its SHA-256 795d0e3e9639be1de5a98a754c7b6d8f268f4d19b09a9664fd5b02c8ed7ab6e7 matches the GitHub artifact digest. ZIP CRC passed. sha.txt contains the exact PROJECT_ID and VALIDATED_CODE_SHA; exit.txt is 0. result.txt records STAGE06_DISCOVERY03_DISTANCE_NATIVE=PASS and STAGE06_DISCOVERY03_DISTANCE_ORACLE=PASS.
6. Canonical Names Lock run 45671229679/job 139406741825 is completed/success on the same exact SHA.
7. The 46×5 stone probe also passed its 230-value, bounds, determinism, and BootstrapOnly checks. It is retained strictly as auxiliary QA, not as the Stage06 semantic acceptance basis.

## Artifact marker versus closure

The run artifact intentionally retains STAGE06_CLOSURE=NOT_CLAIMED: the workflow does not self-assert whole-stage closure before a separate exact-SHA artifact audit. That audit is now complete and recorded here. This report therefore records STAGE06_CLOSURE=ACCEPTED without altering the original run artifact or its hash.

## Counter reconciliation

DEVELOPMENT_STAGE.md at VALIDATED_CODE_SHA was read back and already contained CURRENT_STAGE=6, LAST_COMPLETED_STAGE=6, and EXPECTED_REPOSITORY_STATE=DISCOVERY03_STAGE06_ACCEPTED_HOLD_NO_STAGE07. Those counters are consistent with the newly verified Stage06 distance evidence and are retained unchanged. The prior scope-divergence audit remains historical; this report resolves its Stage06 scope contest using the exact Native and artifact evidence above. The stone probe remains auxiliary.

No Stage07 work, stage-counter advance, main update, merge, or release is authorized or performed.
