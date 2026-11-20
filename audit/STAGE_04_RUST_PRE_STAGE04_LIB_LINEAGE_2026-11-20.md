# Stage04 — pre-Stage04 Rust production-library lineage QA (2026-11-20)

PROJECT_ID: `PC-BRANCH-RUST-AZERBAIJANI`  
Branch: `Rust+Azərbaycan-dili`  
Verified branch HEAD before this QA: `790f371f844ae35d36b4597d45b55cdadb2f9969`.  
Stage03 closure provenance pin: `716e5a6f335b1a15464029b446edb468f3a8482c`.  
Stage04 introduction: `2a7648c345ee63d9e5c81ca0361c6eb3060c6c4f`.

## Why this check is new

Earlier inspections examined the Stage03 pinned `src/` tree and `tests/` oracle. This investigation instead follows **the four ancestry-confirmed commits that changed `src/lib.rs` on the history reachable from the Stage03 closure**, via the narrowly scoped GitHub commits query `sha=716e5a6f...&path=src/lib.rs&per_page=15`. It checks whether an earlier production day-tag implementation existed and was removed before the pinned Stage03 source. This is *not* an unbounded repository search or a repeat of previously accepted Native CI.

## Ancestry-confirmed production library versions

| Commit | `src/lib.rs` Git blob SHA | `src/` root entries at that commit | Compare to Stage03 closure |
| --- | --- | --- | --- |
| `9a46739c981605875958f9b167bad6049f01fa79` | `c981aaae35e375ca98634d414bf761e7d0e95119` | `lib.rs`, `source_language_catalog.rs` | ahead 20; behind 0 |
| `fd31a099ca86a961520d6ecd7e65a8de49a8766a` | `6864985d43a9262244c951dde0429ecdb41d1984` | `lib.rs`, `source_language_catalog.rs` | ahead 11; behind 0 |
| `b818990de4da5a66a0765cb9bf53942daeabdfde` | `fc5841ad36a7e7f16bcace039471c7081b5bddd3` | `lib.rs`, `discovery01_legacy_save.rs`, `source_language_catalog.rs` | ahead 4; behind 0 |
| `805827c2790fca6d88a53126b4570447b09bd609` | `8a813ba020c9101276007148c93cb00ae7836644` | `lib.rs`, `discovery01_legacy_save.rs`, `patch01_save.rs`, `source_language_catalog.rs` | ahead 2; behind 0 |

All four snapshots expose `pub fn calendar_date_spaghetti(BigInt, BigInt) -> Result<[String; 5], MonsterError>`, whose complete body returns `Err(MonsterError::bootstrap_only())`. The GitHub Contents API was used on each exact SHA and path; the lineage was checked independently through `compare_commits`.

The initial `src/source_language_catalog.rs` blob is `dfceca5be541e3911119b95145aa391c0a3bc54f`, and the exposed public functions are `cutlet_name` and `month_name`, not a date-conversion/day-tag entry point. The initial `Cargo.toml` blob is `e82b6ae2a5da27031bdd055be784088599cd8ca7` and points the production library to `src/lib.rs`. The later Stage03-pinned modules and integration-test oracle were already scoped and documented in previous reports; they were not falsely counted as new witness evidence here.

## Bounded executable-source assertions — 18/18 PASS

The verification script executed these assertions against live, exact GitHub connector responses:

- 4/4: `src/lib.rs` Git blob SHA matches the expected historical object.
- 4/4: publicly declared five-field `calendar_date_spaghetti` body returns `bootstrap_only()` rather than a day tag.
- 4/4: `src/` root file inventory equals the history-specific expected inventory, with no unaccounted source file at the root.
- 4/4: GitHub compare proves the specific version is an ancestor of Stage03 closure (behind 0).
- 1/1: earliest source-language catalog exposes name functions but no public calendar/day-tag function.
- 1/1: earliest Cargo manifest matches pinned blob and explicitly points `[lib]` at `src/lib.rs`.

**Total: 18/18 scoped static/provenance checks PASS, 0 mismatches.** These are neither Rust Native tests nor observed numeric runtime values. Historical source absence cannot be proved globally by a bounded inspection, and the positive `calendar_date` function in `tests/support/normative_oracle.rs` remains **test-only**.

## Disposition

This new examination found **no eligible, previously removed Rust production day-tag witness** in the four `src/lib.rs` historical versions. It establishes no historical Rust RED and changes no Stage04 acceptance claim. The older `oldDayTag` RED rows concern archived Python, not pre-Stage04 Rust production.

`CURRENT_STAGE=4`; `LAST_COMPLETED_STAGE=3`; `Stage04=OPEN/NOT_CLAIMED`.

NEXT: A genuinely new and authenticated historical production Rust day-tag witness, if discovered, must pass ancestry, exact commit/path/blob, public callable signature, *compiled* native invocation, numeric output, independent normative oracle, and observed historical Rust runtime RED. Do not re-run already accepted Stage04 code SHA `d292f66eac36282a0c7074ca51e6729b13a32c6f` merely to fill the proof gap. No Stage05, main/merge, publication or PASS without additional evidence. No user policy/authorization decision is pending.

Sources:
- https://github.com/Sargon17-Green/Pastafarian-Calendar/tree/716e5a6f335b1a15464029b446edb468f3a8482c/src
- https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/9a46739c981605875958f9b167bad6049f01fa79/src/lib.rs
- https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/fd31a099ca86a961520d6ecd7e65a8de49a8766a/src/lib.rs
- https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/b818990de4da5a66a0765cb9bf53942daeabdfde/src/lib.rs
- https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/805827c2790fca6d88a53126b4570447b09bd609/src/lib.rs
