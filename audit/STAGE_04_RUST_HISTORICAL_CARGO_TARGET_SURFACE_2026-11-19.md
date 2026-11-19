# Stage04 — bounded historical Rust Cargo target-surface review (2026-11-19)

Project: `PC-BRANCH-RUST-AZERBAIJANI` (Rust+Azərbaycan-dili).
Branch: `Rust+Azərbaycan-dili`; checked HEAD `6d0160104b0828ddda3aa06b414890a39552a4ee`, compare `6d0160104b0828ddda3aa06b414890a39552a4ee...Rust+Azərbaycan-dili` = **identical** at inspection.
Historical pre-Stage04 pin: `716e5a6f335b1a15464029b446edb468f3a8482c`.

## Newly inspected source surface

- `Cargo.toml` at the historical pin: git blob `e82b6ae2a5da27031bdd055be784088599cd8ca7`; package `pastafarian-calendar-rust-az`, explicit `[lib]` target `pastafarian_calendar_rust_az` at `src/lib.rs`.
- No explicit `[[bin]]`, `[[example]]`, or custom `build = ...` in this pinned manifest.
- `src/main.rs` and `build.rs` each return GitHub Contents 404 at the exact historical pin. This check is scoped to these paths; it is not a recursive tree scan.
- `src/lib.rs` blob `8a813ba020c9101276007148c93cb00ae7836644` declares `discovery01_legacy_save`, `patch01_save`, `source_language_catalog`. Its `calendar_date_spaghetti(BigInt, BigInt) -> Result<[String; 5], MonsterError>` returns `Err(MonsterError::bootstrap_only())`, not an old day-tag numeric result.
- Its declared public API does not expose `pub fn <symbol>(&BigInt) -> BigInt`, the supported direct numeric callability shape used by the bounded Stage04 witness gate. Previously inspected declared modules contain SAVE/remainder and language-name functions, not an old production day-tag.

## Exact bounded checks

**12/12 static/path assertions passed** against freshly fetched historical contents, manifest/blob hashes and live branch comparison: historical manifest blob; historical library blob; package name; crate name; library source path; absence of explicit bin/example target sections; absence of explicit build key; absence of direct day-tag numeric signature; `BootstrapOnly` return path; three expected module declarations; absence of `src/main.rs`; absence of `build.rs`.

This is **source inspection**, not a Rust Native invocation or a differential oracle execution. The lack of explicit binary targets and of these two conventional entrypoint files **does not prove global absence** of other auto-discovered sources, other pinned historical revisions, or external production witnesses. No new admissible historical Rust day-tag witness was established, and no observed historical Rust runtime RED was produced.

## Strict Stage04 acceptance disposition

`CURRENT_STAGE=4`, `LAST_COMPLETED_STAGE=3`; **Stage04 remains OPEN/NOT_CLAIMED**. All completed CI gates and independent artifact QA documented at the parent checkpoint remain unchanged. No redundant CI runs were started. No Stage05, `main`, merge or publication action.

The only stage-closing path remains a **new, independently authenticated pre-Stage04 production Rust day-tag witness**: prove ancestry and exact commit/path/blob; confirm the original production callable signature and reachability; compile and invoke exactly that source; compare observed numeric output against an independent normative oracle; observe actual Rust runtime RED. An archived Python RED, a Stage04 probe, or a test-only Rust reconstruction cannot substitute.

## References

- Historical manifest: https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/716e5a6f335b1a15464029b446edb468f3a8482c/Cargo.toml
- Historical library: https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/716e5a6f335b1a15464029b446edb468f3a8482c/src/lib.rs
- Current checkpoint: https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/6d0160104b0828ddda3aa06b414890a39552a4ee
- Existing final Stage04 code CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44374211903
- Existing current-head Names Lock: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44393053054

**Disposition:** new bounded QA evidence; not Stage04 acceptance, not proof of historical Rust RED.
