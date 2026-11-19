# Stage04 — Cargo auto-discovery surface QA (2026-11-20)

PROJECT_ID: `PC-BRANCH-RUST-AZERBAIJANI`  
Branch: `Rust+Azərbaycan-dili`  
Pre-Stage04 historical pin: `716e5a6f335b1a15464029b446edb468f3a8482c`  
Verified parent live HEAD before this audit: `d07775ff44b7807a10a16676fd496e4f9b1749d5` (GitHub compare `status=identical`, ahead=0, behind=0).  
Scope: narrow historical Cargo auto-target path inspection; **not** a Rust Native run or a historical day-tag witness.

## Why this is a distinct check

The preceding audit examined the pinned manifest, `src/lib.rs`, `src/main.rs` and `build.rs`, but explicitly did not check Cargo's conventional auto-discovered target **directories**. Cargo edition 2021 defaults to auto-discovery unless disabled; the conventional locations include `src/bin/`, `examples/`, `tests/`, and `benches/`. Reference: https://doc.rust-lang.org/cargo/reference/cargo-targets.html .

## Fresh, pinned evidence

Fetched `Cargo.toml` directly at the historical pin, blob `e82b6ae2a5da27031bdd055be784088599cd8ca7`. Its contents are exactly:

```toml
[package]
name = "pastafarian-calendar-rust-az"
version = "0.1.0"
edition = "2021"
publish = false

[lib]
name = "pastafarian_calendar_rust_az"
path = "src/lib.rs"

[dependencies]
num-bigint = "0.4"
num-integer = "0.1"
num-traits = "0.2"
```

GitHub Contents API at **this same historical pin**:
- `src/bin`: `404 Not Found`; path not available.
- `examples`: `404 Not Found`; path not available.
- `benches`: `404 Not Found`; path not available.
- `tests`: connector reports `InvalidInputException: path points to a directory, not a file`; directory exists. Its *children were not inspected*.

## Check ledger — 9/9 bounded static/path observations

| # | Assertion | Evidence | Result |
|---|---|---|---|
| 1 | Manifest blob is `e82b6ae2...` at the historical SHA | GitHub fetched blob | PASS |
| 2 | Manifest edition is 2021 | Exact `edition` text | PASS |
| 3 | Explicit library target points to `src/lib.rs` | Exact `[lib]` stanza | PASS |
| 4 | Auto-discovery is not explicitly disabled | No `auto*` disabling keys in complete manifest | PASS |
| 5 | No explicit bin/example/bench declarations | Complete manifest | PASS |
| 6 | `src/bin` not present at requested path | GitHub Contents 404 | PASS |
| 7 | `examples` not present at requested path | GitHub Contents 404 | PASS |
| 8 | `benches` not present at requested path | GitHub Contents 404 | PASS |
| 9 | `tests` is a directory, not a fetched file | GitHub Contents directory type error | PASS |

These are **9 manually evaluated bounded source/path assertions**, not nine executed Rust unit tests. No Rust compile, native execution, independent date oracle, or differential comparison was performed in this QA.

## Interpretation and limit

The checked conventional auto-discovery directories do not supply a new production day-tag entrypoint. `tests/` remains an integration-test area; its existence must not be recast as historical production reachability. The historical `src/lib.rs` production API was previously checked and only exposed `calendar_date_spaghetti(BigInt, BigInt)->Result<[String;5],MonsterError>` returning `BootstrapOnly`; see the 2026-11-19 audit.

These limited negative path findings do **not** prove the absence of a witness at another commit, external artifact, different path, package, or deployment. No historical executable Rust day-tag with observed wrong numeric output was authenticated. **Stage04 remains OPEN / NOT_CLAIMED**, `CURRENT_STAGE=4`, `LAST_COMPLETED_STAGE=3`.

## Acceptance and next authorized action

The mandatory new witness must include independently authenticated pre-Stage04 provenance (ancestry, commit/path/blob), its actual production callable signature, compiled invocation and observed numeric output, independent normative oracle, and an observed Rust runtime RED. Previous archived Python `oldDayTag`, reconstructed test-only Rust, or Stage04 probe are inadmissible substitutes. Do not repeat accepted CI on prior code SHA, open Stage05, merge, change main, or claim PASS.

This is an audit-only report; no source/test/CI configuration was changed.

References:
- https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/716e5a6f335b1a15464029b446edb468f3a8482c/Cargo.toml
- https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/d07775ff44b7807a10a16676fd496e4f9b1749d5
- https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/d07775ff44b7807a10a16676fd496e4f9b1749d5/audit/STAGE_04_RUST_HISTORICAL_CARGO_TARGET_SURFACE_2026-11-19.md
- https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44374211903
