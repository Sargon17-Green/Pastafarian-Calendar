# Stage04 Rust Azerbaijani — pre-Stage04 native artifacts and release-surface check (2026-11-21)

**PROJECT_ID:** `PC-BRANCH-RUST-AZERBAIJANI`  
**Branch:** `Rust+Azərbaycan-dili`  
**Starting verified HEAD:** `cb29d0261015088dc186c5596de2b7b654cc9f1f` (identical branch compare).  
**Scope:** new evidence-only investigation of pre-Stage04 GitHub Actions artifacts and repository Release assets. Not a Rust production edit, not a new Native execution, not Stage04 acceptance.

## Revisions and admissibility
- Stage03 closing/source pin: `716e5a6f335b1a15464029b446edb468f3a8482c`; `src/lib.rs` Git blob `8a813ba020c9101276007148c93cb00ae7836644`, `Cargo.toml` blob `e82b6ae2a5da27031bdd055be784088599cd8ca7`.
- Exact historical library's public five-field route `calendar_date_spaghetti(BigInt, BigInt)` returns `Err(MonsterError::bootstrap_only())`; this is not an accessible numeric day-tag implementation.
- Native evidence commit `932e35d466595477827a09dafb50a97157f5ee65` is an ancestor of the closure pin: GitHub compare `932e35d...716e5a6f` => ahead=1, behind=0, with only `DEVELOPMENT_STAGE.md`, `README.md`, and `audit/STAGE_03_EXECUTION_STATUS_2026-10-30.md` changed.

## Newly inspected historical completed runs and ZIP bytes
- Stage02 run `41109421013`, job `124247669347`, `completed/success`, artifact `13003566311`. Downloaded ZIP: **5,796 bytes**, SHA-256 `f1e77d6e54f6286c782b54c41de66dfa743a78961ffd20a57e6582427e720451`. Archive successfully read with valid CRC for all **6/6** entries. The embedded `sha.txt` pins `PC-BRANCH-RUST-AZERBAIJANI` and `932e35d466595477827a09dafb50a97157f5ee65`; `exit.txt=0`, `result.txt=STAGE02_EXPECTED_RED_NATIVE=PASS`.
- Stage03 run `41109421059`, job `124247669456`, `completed/success`, artifact `13003720839`. Downloaded ZIP: **5,788 bytes**, SHA-256 `9a4f75a1bbb5528bff0b30c180844595f66dd264a0f77f06aaa7c0e14a5f8897`. Archive successfully read with valid CRC for all **6/6** entries. Embedded `sha.txt` pins the same project and SHA; `exit.txt=0`, `result.txt=STAGE03_PATCH01_NATIVE=PASS`.
- Both archives contain only `exit.txt`, `sha.txt`, `result.txt`, `stderr.txt`, `stdout.txt`, `toolchain.txt`. **Neither contains an executable, shared library, Rust binary or compiled object.**
- The original Rust test outputs show 16/16 Stage01 tests, 3/3 Stage02 tests, and 4/4 Stage03 tests passing on `932e35d...`. `STAGE02_DISCOVERY01_EXPECTED_RED=3 CONTROL=1 UNEXPECTED=0` and `STAGE03_PATCH01_LEGACY_RED=3 CONTROL=1 UNEXPECTED=0` concern **legacy SAVE behavior**, NOT a pre-Stage04 production day-tag numeric RED. The tests explicitly include `canonical_five_fields_still_refuse_to_claim_full_calendar` and `five_calendar_fields_remain_unimplemented_at_stage_three`.
- Earlier Stage02 run `41097634181`, job `124207410421`, `completed/success` at `b818990de4da5a66a0765cb9bf53942daeabdfde`, artifact `12996533665`: ZIP **5,625 bytes**, SHA-256 `da47b564a28776babf8ddd38c2e5e4ecbb0d7bf2aedfa9fd0f733850817fbe57`, valid CRC 6/6; identical six evidence filenames, no compiled binary, and legacy SAVE RED marker only.
- Stage03 closure pin `716e5a6f...` had one `completed/success` GitHub Actions run: Names Lock `41117798075`, job `124276434680` (exact checkout SHA seen in decoded log), and **zero artifacts** in that run. This is not evidence of a Rust numerical outcome.

## Release metadata (bounded new surface)
- Repository Releases API `GET /repos/Sargon17-Green/Pastafarian-Calendar/releases?per_page=100&page=1` returned **9 release records** on 2026-11-21. Their names, target fields, asset names and metadata were inspected. None advertises a Rust/Azerbaijani historical binary or Rust+Azərbaycan-dili release asset. Some are drafts and several are for unrelated languages.
- This finding is limited to the nine returned Release records; it does NOT certify that all historical Actions outputs, external storage, or local developer machines lack a binary.

## Current HEAD QA
- Automatic push Canonical Names Lock run `44905072102`, job `136848789449`, completed/success, exact checkout log `cb29d0261015088dc186c5596de2b7b654cc9f1f`; zero artifacts. This verifies names only, not Stage04.
- Prior exact-code Stage04 CI/Native/differential acceptance remains at `6e81098c9666e340cb48989a5f59ca9f169b8714` with run `44896130285` and independent artifact QA report at starting HEAD. It does not retroactively establish historical original Rust day-tag numeric RED.

## Decision and NEXT
**Stage04 remains OPEN/NOT_CLAIMED; CURRENT_STAGE=4, LAST_COMPLETED_STAGE=3.** This audit verifies actual historical native tests and legacy SAVE RED, and rules out **a compiled Rust executable inside the three specifically downloaded artifacts**, but establishes neither a callable historical production day-tag nor its numeric RED. No fresh Rust code execution or independent Stage04 numerical differential was performed here.

**NEXT:** Only if a *new* eligible pre-Stage04 compiled artifact/entry point is identified outside the already reviewed sources/three artifacts, pin original Git commit, blob or binary hash, Cargo route, real Native call and independent numeric oracle before revisiting Stage04. Otherwise explicitly retain NOT_PROVEN; do not relabel the legacy SAVE RED as day-tag RED, rerun accepted same-SHA CI, enter Stage05, merge, or change main.

## Evidence links
- Historical code: https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/716e5a6f335b1a15464029b446edb468f3a8482c/src/lib.rs
- Stage02 run/artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41109421013/artifacts/13003566311
- Stage03 run/artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41109421059/artifacts/13003720839
- Earlier Stage02: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41097634181/artifacts/12996533665
- Closure Names Lock: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41117798075
- Current HEAD Names Lock: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44905072102
- Release metadata: https://github.com/Sargon17-Green/Pastafarian-Calendar/releases
