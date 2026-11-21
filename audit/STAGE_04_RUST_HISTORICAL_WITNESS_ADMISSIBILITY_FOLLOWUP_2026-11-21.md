# Stage04 Rust Azerbaijani — independently pinned witness eligibility and current-head CI closure (2026-11-21)

**PROJECT_ID:** `PC-BRANCH-RUST-AZERBAIJANI`  
**Branch:** `Rust+Azərbaycan-dili`  
**Verified starting HEAD:** `a3f438332545d86d145b5fa7822c4db56256d255`; compare against branch returned `identical`, ahead=0, behind=0.  
**Scope:** bounded historical-witness QA, and resolution of one pending current-head canonical-names run. No production code changes, fresh native execution, Stage05, merge, or main edit.

## Independently rechecked immutable historical source

- Stage03 closure pin `716e5a6f335b1a15464029b446edb468f3a8482c`; fetched `src/lib.rs` exact Git blob `8a813ba020c9101276007148c93cb00ae7836644`. The exposed `pub fn calendar_date_spaghetti(_calculation_day: BigInt, _target_day: BigInt) -> Result<[String;5], MonsterError>` returns `Err(MonsterError::bootstrap_only())`. This is **not** a numeric day-tag entry point; the error is `BootstrapOnly`. This finding is **static source inspection**, not newly executed Rust.
- Fetched historical `Cargo.toml` blob `e82b6ae2a5da27031bdd055be784088599cd8ca7`: package `pastafarian-calendar-rust-az`, Rust 2021, explicit library `src/lib.rs`; no directly declared binary in that file.
- GitHub historical compare `932e35d466595477827a09dafb50a97157f5ee65...716e5a6f335b1a15464029b446edb468f3a8482c` => ahead=1/behind=0; only `DEVELOPMENT_STAGE.md`, `README.md`, `audit/STAGE_03_EXECUTION_STATUS_2026-10-30.md` changed. That closure transition introduced no production Rust source.
- Previous **separately evidenced** inspection of three original Stage02/03 ZIP artifacts found only six text/log entries each, no compiled original Rust executable. This report does not rerun or redownload accepted historical tests, and does not claim the inspection exhausts external archives.

## Newly resolved current-HEAD run

- Automatic Names Lock **run `44910557230`**, job `136865259267`: job `completed/success`.
- Decoded job log shows `git fetch` of exact `a3f438332545d86d145b5fa7822c4db56256d255`, checkout of `Rust+Azərbaycan-dili`, and exact SHA printed after checkout; named `Verify canonical names lock` step is `completed/success`.
- This is **canonical names only**. It cannot certify Stage04, historical Rust numeric RED, current-code Rust Native, or a new differential run.

## Bounded independent candidate-source discovery

GitHub repository-scoped search using the linked GitHub account (all queries executed 2026-11-21):
1. Issues/PR index query `"Azərbaycan" created:<2026-10-31` -> 0 returned matches.
2. Issues/PR index query `"Rust" "day-tag" created:<2026-10-31` -> 0 returned matches.
3. Issues/PR index query `Rust created:<2026-10-31` -> 0 returned matches.
4. Commit-message query `Rust` -> 0 returned matches; `day-tag` -> 0 returned matches.
5. Current default-branch code-search query `calendar_date_spaghetti` -> 0 returned matches (default branch search **cannot** be used to infer absence on the scoped historical branch).

These are **bounded search/index results, not an exhaustive proof of nonexistence**. In particular GitHub issue, commit and code search behavior/index completeness is not a historical runtime oracle. No independently sourced, previously unexamined, pre-Stage04 executable or production numeric day-tag witness was found *in these search results*. Do not promote a zero-hit search to a negative Native test.

## Candidate witness admission contract and precise NEXT

A new candidate is admissible for historical Stage04 only if all of the following are established on a **pre-Stage04 original source**: (1) exact original commit and reachable ancestry from the allowed Stage03 boundary; (2) immutable blob/binary SHA and non-symlink original source path, Cargo target and direct callable production signature; (3) native original invocation, with toolchain, args, stdout/stderr, exit status and evidence artifact; (4) independent integer day-tag oracle with explicit examples, boundary conditions, and an observed source-native numerical discrepancy (not archived Python or legacy SAVE). A post-stage patch, a test-only oracle, `BootstrapOnly` or legacy SAVE RED is ineligible.

**Decision:** no newly eligible witness demonstrated. `Stage04=OPEN/NOT_CLAIMED`; `CURRENT_STAGE=4`; `LAST_COMPLETED_STAGE=3`. Existing Stage04 code/test QA on `6e81098c9666e340cb48989a5f59ca9f169b8714` remains independently accepted only for its specified gates: run `44896130285`, Names Lock `44896130342`, artifact `14703787631` and previously validated independent numeric oracle 15/15. It cannot create an original historical runtime RED.

**NEXT:** admit and investigate only a genuinely new independently identified pre-Stage04 executable/production day-tag witness meeting the contract; otherwise retain `NOT_PROVEN` and do not repeat the same search or accepted same-SHA CI, claim Stage04/Stage05, or change main/merge. No pending user-execution results were supplied here; cleanup is not applicable.

## Immutable links
- Prior historical artifacts and release assessment: https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/a3f438332545d86d145b5fa7822c4db56256d255/audit/STAGE_04_RUST_HISTORICAL_ACTIONS_BINARY_SURFACE_2026-11-21.md
- Current-head names run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44910557230
- Historical source: https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/716e5a6f335b1a15464029b446edb468f3a8482c/src/lib.rs
- Historical Cargo: https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/716e5a6f335b1a15464029b446edb468f3a8482c/Cargo.toml
- Exact last accepted code QA run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44896130285
