# Stage08 / DISCOVERY04 — exact-SHA Native and artifact acceptance

PROJECT_ID=PC-BRANCH-RUST-AZERBAIJANI
BRANCH=Rust+Azərbaycan-dili
STAGE08_CODE_SHA=8ff743af4b4b2c94ca9484bbe6480b6d06584e2d
STAGE08_RUN_ID=45688431657
STAGE08_JOB_ID=139467126063
STAGE08_STATUS=completed
STAGE08_CONCLUSION=success
STAGE08_ARTIFACT_ID=15056849026
STAGE08_ARTIFACT_BYTES=33531
STAGE08_ARTIFACT_SHA256=1619c188c71351a5028dfbe1ae64cc047ed27d2ffd0e3782d4fd09e937eab314
STAGE08_ARTIFACT_CRC=PASS
STAGE08_ARTIFACT_MEMBERS=10
STAGE08_EXIT=0
STAGE08_RUST_TESTS=46
STAGE08_RUST_FAILURES=0
STAGE08_DISTANCE_CELLS=225
STAGE08_EXPECTED_RED=224
STAGE08_MATCH=1
STAGE08_UNEXPECTED=0
STAGE08_GUARDS=4
STAGE08_ORACLE=PASS
STAGE08_CLOSURE=ACCEPTED
CURRENT_STAGE=8
LAST_COMPLETED_STAGE=8
EXPECTED_REPOSITORY_STATE=DISCOVERY04_STAGE08_ACCEPTED_HOLD_NO_STAGE09

## Stage08 Native and independent oracle

1. GitHub Actions run 45688431657/job 139467126063 completed/success on the exact checkout SHA 8ff743af4b4b2c94ca9484bbe6480b6d06584e2d. The log records the exact checkout, successful rustfmt/scope gate, independent Python oracle self-test, Native all-targets run, Stage06/07/08 oracle checks, and artifact upload.
2. Native Rust test output contains 46 passed, 0 failed tests across 12 non-empty test targets; one empty target reported 0 tests. The Stage08 test executed the actual PATCH02 -> DISCOVERY03 -> PATCH03 -> DISCOVERY04 route.
3. The Stage08 production table has 46 logical rows and 230 bounded components. Rows 2..46 yield 225 compared components. The exact classification is 224 RED, 1 MATCH, 0 unexpected; four guards passed. Row 2 sequential output is [378, 1434, 3780, 9932, 25047], while the independent snapshot reference is [378, 1073, 2375, 6195, 10493]; only w matches.
4. The Python oracle in CI independently recomputed the sequential and snapshot tables using arbitrary-precision integers and verified every raw cell, row/field coverage, and the 224/1 classification. I downloaded the artifact and independently repeated the verification against its raw stdout: 225/225 cells matched the independent oracle, 224 RED, 1 MATCH, 4 guards.
5. Artifact 15056849026 contains 10 evidence files. Its size is 33,531 bytes; independently computed SHA-256 1619c188c71351a5028dfbe1ae64cc047ed27d2ffd0e3782d4fd09e937eab314 matches the GitHub digest; ZIP CRC passed. sha.txt contains the exact PROJECT_ID and code SHA, exit.txt is 0, and result.txt records Native PASS, Oracle PASS, closure NOT_CLAIMED before this audit.

## Prior-stage regressions on the same exact code SHA

STAGE05_RUN_ID=45688431283
STAGE05_JOB_ID=139467123906
STAGE05_STATUS=completed
STAGE05_CONCLUSION=success
STAGE05_ARTIFACT_ID=15058500150
STAGE05_ARTIFACT_BYTES=32628
STAGE05_ARTIFACT_SHA256=b0ab3adb48e8500d0c0c6be98cb9f3129c583abc4c7414c3ac7f4aa7af1586a9
STAGE05_WRAPPER_ORACLE=69/69
STAGE05_RED_SCAR=34
STAGE05_CONTROL=35
STAGE05_GUARDS=69

STAGE06_RUN_ID=45688431434
STAGE06_JOB_ID=139467124430
STAGE06_STATUS=completed
STAGE06_CONCLUSION=success
STAGE06_ARTIFACT_ID=15056883449
STAGE06_ARTIFACT_BYTES=33089
STAGE06_ARTIFACT_SHA256=ad9b3ee7cf2764a96ca36881e8140fbfda32cd9a5f4244590f5735979e67a46b
STAGE06_DISTANCE_ORACLE=169/169
STAGE06_RED=153
STAGE06_CONTROL=16
STAGE06_GUARDS=170

STAGE07_RUN_ID=45688431299
STAGE07_JOB_ID=139467125964
STAGE07_STATUS=completed
STAGE07_CONCLUSION=success
STAGE07_ARTIFACT_ID=15056699333
STAGE07_ARTIFACT_BYTES=33034
STAGE07_ARTIFACT_SHA256=e2a6f3f42b77b50b65d5cf024f1953af28a17ea710ca1b46b3f870ac76cb6151
STAGE07_ORACLE=225/225
STAGE07_MISMATCH=204
STAGE07_MATCH=21
STAGE07_GUARDS=226

NAMES_LOCK_RUN_ID=45688431343
NAMES_LOCK_JOB_ID=139467123989
NAMES_LOCK_STATUS=completed
NAMES_LOCK_CONCLUSION=success
NAMES_LOCK_CHECKED_SHA=8ff743af4b4b2c94ca9484bbe6480b6d06584e2d

The Stage05, Stage06 and Stage07 workflows each completed/success on the same exact code SHA. Their artifacts were downloaded and independently checked: respectively 6, 8 and 8 files; ZIP CRC passed; GitHub SHA-256 digests matched the downloaded bytes; sha.txt contained the exact PROJECT_ID/code SHA; exit.txt was 0. The Stage05 wrapper oracle, Stage06 distance oracle and Stage07 distance oracle also passed. Canonical Names Lock completed/success on the same exact SHA.

The Stage04 workflow also completed/success on this SHA, including its whole-stage evidence-consistency check. Stage08 Native all-targets included Stage01–Stage07 regression tests. A separate Stage05 run was initially queued but later completed/success; it is not being treated as PASS until its completed result and artifact above were verified.

## Formatting-only attempt

The first Stage08-triggered runs on the preceding source commit stopped at cargo fmt before Native execution. The rustfmt-only corrections were committed in 8ff743af4b4b2c94ca9484bbe6480b6d06584e2d. No algorithmic Native failure was observed on the formatting-only attempt; the exact-SHA Native run and artifact acceptance above are on the corrected SHA.

## Scope and closure

DISCOVERY04 deliberately exposes the sequential mutation defect; it does not fix it. The expected RED is an intentional discovery result, not a failing test. Stage09/PATCH04 snapshot correction is the next documented stage and is not started here. The historical pre-Stage03 Rust RED remains NOT_CLAIMED. Full calendar remains BootstrapOnly. No main update, merge, or release was performed.
