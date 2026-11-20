# Stage04 — historical integration-test oracle boundary (2026-11-20)

PROJECT_ID: `PC-BRANCH-RUST-AZERBAIJANI`  
Branch: `Rust+Azərbaycan-dili`  
Live HEAD **before** this report: `73457319f35cd8313bc72af6ad8ff0c9cc09218b` (GitHub comparison `identical`, ahead 0, behind 0).  
Pre-Stage04 provenance pin: `716e5a6f335b1a15464029b446edb468f3a8482c`.  
Scope: **new, bounded** inspection of the previously uninspected historical `tests/` subtree. This is not a Rust Native run, not an old production day-tag witness, and not Stage04 acceptance.

## Discovery that matters

The historical snapshot **does** contain a full Rust `calendar_date(calculation_day: &BigInt, target_day: &BigInt) -> OracleDate` implementation, but it is in **`tests/support/normative_oracle.rs`** (test-side independent oracle; blob `8881f34deadecf43a2c897088b791f4892a160db`). Its `tests/support/mod.rs` exposes `pub mod normative_oracle;`, and the integration tests import it through `support::normative_oracle as oracle`. This is **not** a `src/` production API and cannot establish an historical Rust production day-tag RED.

Conversely, the actual historical library `src/lib.rs` (blob `8a813ba020c9101276007148c93cb00ae7836644`) declares `calendar_date_spaghetti(BigInt, BigInt) -> Result<[String; 5], MonsterError>`, which returns `Err(MonsterError::bootstrap_only())`. `tests/stage02_discovery01.rs` and `tests/stage03_patch01.rs` explicitly test that the five-field production route is unavailable. The `oldDayTag` string appears in `tests/stage01.rs` in a test checking absence of future patch names, not as callable Rust production code.

## Exact pinned file inventory

| Historical file | Git blob |
| --- | --- |
| `Cargo.toml` | `e82b6ae2a5da27031bdd055be784088599cd8ca7` |
| `src/lib.rs` | `8a813ba020c9101276007148c93cb00ae7836644` |
| `tests/stage01.rs` | `71f7c3abc981df330978d01fb8d3893ac537ab9e` |
| `tests/stage02_discovery01.rs` | `f27a429bc8dec306860c04be4285d25d65cc6a74` |
| `tests/stage03_patch01.rs` | `b2900395832b0f0fa47c171dfcebbcdc0d7480c2` |
| `tests/support/mod.rs` | `364f0a65aa8a7f91d4ce96126b356115cf277f6e` |
| `tests/support/normative_oracle.rs` | `8881f34deadecf43a2c897088b791f4892a160db` |

The exact pinned `tests/` directory contains `stage01.rs`, `stage02_discovery01.rs`, `stage03_patch01.rs`, and `support/`; `support/` contains only `mod.rs` and `normative_oracle.rs` in the checked snapshot.

## Automated bounded source checks — 12/12 passed

1. **PASS** — branch HEAD exactly pinned before change
2. **PASS** — test root has exactly 3 Rust integration suites and support dir
3. **PASS** — test support has only mod.rs and normative_oracle.rs
4. **PASS** — support mod explicitly includes normative_oracle
5. **PASS** — full calendar_date() exists in historical test oracle
6. **PASS** — test oracle has no original oldDayTag function
7. **PASS** — stage01 imports test-only support oracle
8. **PASS** — stage01 specifically checks future scar oldDayTag absent from production
9. **PASS** — stage02 still expects five-field production API to refuse calendar
10. **PASS** — stage03 still expects five-field production API to be unimplemented
11. **PASS** — production lib does not import test oracle and five-field route returns bootstrap error
12. **PASS** — historical manifest's production library source is src/lib.rs

These assertions used GitHub Contents API on exact pinned paths plus the live-branch comparison. They are **static source/path assertions**, not compiled Rust test cases, differential day-tag results, or CI. A positive source oracle implementation must not be counted as a production RED. The Stage02 historical SAVE RED is a distinct function and does not satisfy Stage04's day-tag witness requirement.

## Acceptance disposition and NEXT

`CURRENT_STAGE=4`; `LAST_COMPLETED_STAGE=3`; `Stage04=OPEN/NOT_CLAIMED`. No new authenticated pre-Stage04 **production** Rust day-tag route with compiled numeric output was found in the targeted historical test subtree. Prior accepted code SHA `d292f66eac36282a0c7074ca51e6729b13a32c6f` and its CI runs are unchanged; do **not** rerun them.

NEXT: only admit a **new** historical Rust production witness verified by ancestry, commit/path/blob, public callable signature, native compiled invocation, numeric output, independent normative oracle, and an observed Rust runtime RED. Neither this test-side oracle nor archived Python `oldDayTag` may substitute. No Stage05, main/merge, stage PASS, or publication. No need for user policy approval; this is unresolved *evidence*, not a CI or authorization blocker.

Relevant permanent paths:
- https://github.com/Sargon17-Green/Pastafarian-Calendar/tree/716e5a6f335b1a15464029b446edb468f3a8482c/tests
- https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/716e5a6f335b1a15464029b446edb468f3a8482c/tests/support/normative_oracle.rs
- https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/716e5a6f335b1a15464029b446edb468f3a8482c/src/lib.rs
- https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/73457319f35cd8313bc72af6ad8ff0c9cc09218b/audit/STAGE_04_RUST_HISTORICAL_CARGO_AUTODISCOVERY_2026-11-20.md
