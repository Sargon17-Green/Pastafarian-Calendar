# Rust+Azərbaycan-dili / Stage05 PATCH02 — evidence-based acceptance

PROJECT_ID=PC-BRANCH-RUST-AZERBAIJANI
STAGE05_FINAL_DISPOSITION=ACCEPTED
SOURCE_CI_SHA=808c0cb999bfa56166720c73bf333ae9cd24b703
SOURCE_CI_RUN=45082297349
SOURCE_CI_JOB=137392936126
NAMES_LOCK_RUN=45082297229
NAMES_LOCK_JOB=137392935698
ARTIFACT_ID=14777727409
ARTIFACT_BYTES=6766
ARTIFACT_SHA256=a384a12d714d318e0dcea6a02ae8d19890e6a87bb46539e86f046c0fb213e023
ZIP_CRC=6/6
NATIVE_EXIT=0
CURRENT_STAGE=5
LAST_COMPLETED_STAGE=5
STAGE06=NOT_STARTED

## Qəbulun konkret sübutları

1. GitHub branch `Rust+Azərbaycan-dili` source HEAD `808c0cb999bfa56166720c73bf333ae9cd24b703` idi, compare nəticəsi `identical`. Bu sənəddən öncəki mənbə/Native yoxlamasının SHA-sı yalnız həmin komitə aiddir.
2. [Stage05 Native](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45082297349) attempt1 `completed/success`, job `137392936126` completed/success. Decoded checkout log exact commit-i göstərdi; `cargo fmt` və `cargo test --all-targets -- --nocapture` uğurlu.
3. [Names Lock](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45082297229) job `137392935698` completed/success; decoded log exact checkout and verification step.
4. [Native artifact](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45082297349/artifacts/14777727409) independently downloaded in a separate check: 6766 bytes and SHA256 above, equal GitHub metadata. Six ZIP entries all CRC-valid. `sha.txt` contains exact PROJECT_ID and SHA; `exit.txt` is `0\n`; `result.txt` contains `STAGE05_PATCH02_NATIVE=PASS` and `STAGE05_CLOSURE=NOT_CLAIMED` (subordinate CI marker; not the final disposition).
5. Rust Stage05 test executable: 5/5 completed with 7 foundation boundary samples, all 49 local day pairs, 8 1025–8192-bit signed pairs, 4 Stage02/03 SAVE isolation controls, and full-calendar `BootstrapOnly` preserved. Each sample compares every work-count field against test-only independently structured normative Rust oracle. Stage01–Stage04 native regressions also passed on exact Stage05 SHA.
6. Stage04 regression workflow `45082216435` was completed/success on earlier code SHA `2e4037d311cfdab903ae5a8538e688d3c761e46b`. Source code is unchanged from that SHA to the Stage05 source SHA: only the Stage05 workflow file changed to stop requiring unavailable `Cargo.lock`. This is supporting regression evidence, **not** a claimed exact new-head Stage04 run.
7. Original pre-Stage03 Rust numeric RED remains NOT_PROVEN. User-approved 2026 reconstruction substitution remains limited to Stage04. Stage05 does not claim Python↔Rust runtime differential; its explicit acceptance gate required Native integration tests against the test-only normative oracle, which passed.

## Etibarlı sərhəd

Bu qəbul yalnız normativ iki-gün `WorkCounts` istehsal dispetçerinə aiddir. `calendar_date_spaghetti` beş tarix sahəsini hələ hesablamır. Stage04/Stage03/Stage02 mənbə semantikası və kanonik mənbə-ad kataloqu dəyişmir.

This acceptance is recorded after the completed source SHA external job/log/artifact review. The new acceptance-record HEAD must pass its own automatic GitHub CI/Names Lock and artifact checks before asserting that *new HEAD* has passed. No manual duplicate dispatch, main, merge or release.

NEXT: verify acceptance-HEAD automatic CI and Names Lock; then proceed to a separately contracted Stage06 without additional ceremonial user authorization.
