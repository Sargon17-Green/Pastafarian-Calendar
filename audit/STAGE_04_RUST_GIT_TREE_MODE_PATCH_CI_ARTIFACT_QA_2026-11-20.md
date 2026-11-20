# Rust Azerbaijani Stage04 — Git tree-mode PATCH CI and independent artifact QA

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Validated source/test/workflow commit: `e7730c9e9e9e4420195f04da0b36157c26e5c2d7`
Branch: `Rust+Azərbaycan-dili`
Stage04 status: OPEN / NOT_CLAIMED (CURRENT_STAGE=4; LAST_COMPLETED_STAGE=3).

## Completed exact-SHA runs

- Stage04 DISCOVERY02 baseline CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44812150928 — completed/success, attempt 1, job `136551167000` completed/success.
- Canonical Names Lock: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44812150897 — completed/success, attempt 1, job `136551167122` completed/success.
- Decoded logs from both jobs show checkout of the full exact commit `e7730c9e9e9e4420195f04da0b36157c26e5c2d7`; the Names Lock verification step and every Stage04 CI step concluded success.

## Gate counts from exact logs and artifact

- Provenance synthetic Git regressions: **16/16 PASS**, including new symlink-mode rejection and executable regular-file preservation.
- Callability controls: **16/16 PASS**, positive Rust execution is *synthetic*, not historical Rust day-tag.
- Four-column TSV protocol: **6/6 PASS**.
- Rust native baseline/regression groups: **34/34 PASS**; test summary groups show 16, 3, 4, 2, 3, 3, 3 (plus 0-test binary runners).
- Direct Python-Rust numerical comparison: **15/15 PASS**; archived Python RED=8, CONTROL=7, UNEXPECTED=0. These are **not** historical production Rust runtime RED observations.
- Completion reported `STAGE04_CLOSURE=NOT_CLAIMED`.

## Byte-level independent artifact validation

- Artifact ID: `14668955999`
- Run: `44812150928`; exact artifact head SHA `e7730c9e9e9e4420195f04da0b36157c26e5c2d7`
- ZIP length: **20,437 bytes**; SHA-256: `27fcab718d727ab223111a1b7bb1913013ee1eed8363508207120db7c2fee6e3`, identical to provider digest.
- ZIP entries: **17/17** successfully decompressed/CRC-validated.
- `sha.txt`: exact project and source SHA.
- `exit.txt`: `0`.
- `stage04_provenance_result.txt`: `STAGE04_PROVENANCE_QA=16_PASS`, `HISTORICAL_RUST_ROUTE=NOT_PROVEN`.
- `stage04_old_rust_callability.json`: `SOURCE_ONLY_NO_SUPPORTED_SIGNATURE`, `callable_numeric_function_verified=false`, `observed_runtime_red=false`.

## Independent integer re-computation of all 15 TSV/JSON cases

Using foundation `F=-15055671`, independently calculate:
- `oracle(day)=2*(F-day)` for `day<F`;
- `oracle(day)=2*(day-F)+1` for `day>=F`;
- archival old value `legacy(day)=2*abs(day-F)`.

Independently compared each of the 15 JSON cases against its matching TSV row, verifying day, oracle, patched, candidate, legacy, classification, and pass flag. **15/15 matched**; archival difference classification **8 RED / 7 CONTROL**. This arithmetic check is independent of the CI runner and separate from the Git tree-mode tests; it is not evidence that a historical Rust production implementation was callable.

## Change isolation and acceptance

Patch commit `e7730c9e9e9e4420195f04da0b36157c26e5c2d7` was verified one fast-forward commit above previous HEAD `879d161a98522bb6beb4c37d1d84755f78e9dc62`; exactly four intended files changed: provenance gate, tests, Stage04 workflow, audit report. No production Rust, main, merge, Stage05 or acceptance-policy change.

The demonstrated provenance weakness (mode 120000 symlink accepted as ordinary blob) is now covered by the exact new-SHA regression. **Stage04 cannot close** without a separately demonstrated ancestry-pinned, executable historical production Rust day-tag and independently verified normative numeric Rust RED. Neither has been established.

This report is an audit-only file; the completed Stage04 CI and Native evidence applies to the **source commit above**, not automatically to any later audit-only report commit.
