# Mərhələ 4 / DISCOVERY02 — CI icrası və mənbə yoxlamasının davamı

**PROJECT_ID:** `PC-BRANCH-RUST-AZERBAIJANI`  
**Branch:** `Rust+Azərbaycan-dili`  
**Code SHA:** `e9f2a1c6042a6bfa1ba448a8f6a4ea09c66ce818`  
**Yoxlama tarixi:** 2026-10-31  
**Status:** müsbət Native baza təsdiqləndi; Stage4 açıqdır.

## 1. Branch və dəyişiklik identikliyi

GitHub branch endpoint-i `Rust+Azərbaycan-dili` üçün HEAD-in `e9f2a1c6042a6bfa1ba448a8f6a4ea09c66ce818` olduğunu təsdiqlədi. Stage4 düzəliş commit-i əvvəlki `0b10298d15a163dc8df49b18265b1d7c1326baf3` üzərində yalnız iki Rust faylında üç rustfmt dəyişiklikindən ibarətdir:

- `src/discovery02_work_counts_probe.rs`
- `tests/stage04_discovery02_work_counts.rs`

Commit diff-də məntiqi dəyişiklik yoxdur. Əvvəlki üç CI xətası `cargo fmt --check` mərhələsində baş vermişdi; bu SHA üzrə Native yoxlamalar yenidən uğurla tamamlandı.

## 2. CI nəticələri — eyni Code SHA

Bütün beş workflow `completed/success` vəziyyətindədir və `head_sha`-ları Code SHA ilə eynidir.

| Gate | Run ID | Job ID | Conclusion |
|---|---:|---:|---|
| Stage1 Native | 41203445100 | 124543683641 | success |
| Stage2 DISCOVERY01 Native | 41203445152 | 124543684019 | success |
| Stage3 PATCH01 Native | 41203445099 | 124543683747 | success |
| Stage4 DISCOVERY02 baseline Native | 41203445156 | 124543683911 | success |
| Canonical Names Lock | 41203445083 | 124543683611 | success |

Run links:

- [Stage1](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41203445100)
- [Stage2](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41203445152)
- [Stage3](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41203445099)
- [Stage4](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41203445156)
- [Canonical Names Lock](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41203445083)

### Stage4 artifact

- Artifact ID: `13043472881`
- Name: `rust-az-stage04-discovery02-baseline`
- Size: 6,301 bytes
- SHA-256: `308805e4869f2557b9fe16d53155ab99f8d47f9c332103b0799e5ad36efe4070`
- Expires: 2026-11-30T13:22:18Z
- [Workflow run and artifact](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41203445156)

Artifact ZIP was downloaded and independently checked: `exit.txt=0`; `sha.txt` names PROJECT_ID and the exact Code SHA; `result.txt` contains exactly:

```text
STAGE04_DISCOVERY02_BASELINE_ONLY=PASS
EXPECTED_RED=NOT_CLAIMED
```

The downloaded ZIP SHA-256 matches GitHub's artifact digest.

## 3. Native test evidence

Stage4 job passed the stable Rust toolchain, identity/format verification, and bounded Native baseline/regression steps. The captured toolchain was rustc 1.99.1 and cargo 1.99.1. The Stage4 stdout contains six successful test groups:

- Stage1: 16 tests
- Stage2: 3 tests
- Stage3: 4 tests
- Stage4 baseline: 3 tests
- Stage4 day-tag properties: 3 tests
- Stage4 work-counts: 3 tests

**Total: 32 passed, 0 failed.** The zero-test harness entry is not included in this total.

Exact Stage4 markers:

- `STAGE04_DISCOVERY02_BASELINE_CASES=7`
- `STAGE04_DISCOVERY02_HUGE_CASES=4`
- `STAGE04_DISCOVERY02_SYMMETRIC_HUGE_CASES=8`
- `STAGE04_DISCOVERY02_TAG_PREIMAGE_CASES=398`
- `STAGE04_DISCOVERY02_BIJECTION_CASES=1025`
- `STAGE04_DISCOVERY02_WORK_COUNTS_LOCAL_PAIRS=49`
- `STAGE04_DISCOVERY02_WORK_COUNTS_HUGE_PAIRS=8`
- `STAGE04_DISCOVERY02_WORK_COUNTS_TRANSLATION_CASES=12`

Prior regression signatures were retained:

- `STAGE02_DISCOVERY01_EXPECTED_RED=3 CONTROL=1 UNEXPECTED=0`
- `STAGE03_PATCH01_LEGACY_RED=3 CONTROL=1 UNEXPECTED=0`
- `STAGE03_PATCH01_BOUNDARY_OK=8`

Warnings about unused code and Node deprecations were non-fatal; all relevant workflow steps and test result summaries completed successfully.

## 4. Continued bounded legacy-source investigation

The following additional checks were performed against the exact branch history, not against other branches or other implementations:

1. The initial project commit `9a46739c981605875958f9b167bad6049f01fa79` has only `src/lib.rs` and `src/source_language_catalog.rs` under `src/`. Its `calendar_date_spaghetti` entry point returns `BootstrapOnly`; it contains no day-tag implementation.
2. The current history of `src/discovery02_day_tag_probe.rs` contains exactly one commit, `2a7648c345ee63d9e5c81ca0361c6eb3060c6c4f`, which introduced it explicitly as a positive baseline probe.
3. The current `src/lib.rs` history has six commits. The tracked sequence contains bootstrap, the Stage2 legacy SAVE path, Stage3 SAVE patch, the Stage4 positive day-tag probe, and the Stage4 work-counts QA; no earlier tracked day-tag implementation appears in that history.
4. `src/discovery01_legacy_save.rs` is a legacy SAVE remainder path (`mod_floor` with modulus `2^127-1`), not a day-tag implementation.
5. `src/patch01_save.rs` is the normative SAVE patch, not a day-tag implementation.
6. In current `src/lib.rs`, `calendar_date_spaghetti` still returns `BootstrapOnly`; the candidate day-tag module is not wired into the production five-field calendar entry point.

Relevant source/history links:

- [Initial bootstrap commit](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/9a46739c981605875958f9b167bad6049f01fa79)
- [Only commit adding the day-tag probe](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/2a7648c345ee63d9e5c81ca0361c6eb3060c6c4f)
- [Current day-tag probe](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/e9f2a1c6042a6bfa1ba448a8f6a4ea09c66ce818/src/discovery02_day_tag_probe.rs)
- [Current production entry point and module declarations](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/e9f2a1c6042a6bfa1ba448a8f6a4ea09c66ce818/src/lib.rs)
- [Legacy SAVE implementation](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/e9f2a1c6042a6bfa1ba448a8f6a4ea09c66ce818/src/discovery01_legacy_save.rs)
- [Normative SAVE patch](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/e9f2a1c6042a6bfa1ba448a8f6a4ea09c66ce818/src/patch01_save.rs)

**Finding, limited to the audited branch and paths:** no concrete historical legacy day-tag implementation or documented earlier day-tag route was found. This does not prove that no external archive, other repository, or untracked historical artifact exists. The existing SAVE legacy path must not be relabeled as a day-tag defect.

## 5. Acceptance decision and NEXT

- Positive Native baseline: **PASS** on Code SHA `e9f2a1c6042a6bfa1ba448a8f6a4ea09c66ce818`.
- Stage4 / DISCOVERY02 overall: **OPEN**.
- `EXPECTED_RED`: **NOT CLAIMED**.
- Production five-field entry point: unchanged and still `BootstrapOnly`.
- No Stage5, main update, merge, or release is authorized or performed.

**NEXT:** continue only with a concrete archived day-tag implementation, artifact, or documented historical route whose provenance and version can be pinned. Reproduce that exact route against the independent normative oracle, and create RED/CONTROL only after an observed mismatch. If no such source is identified, preserve Stage4 as OPEN; do not invent a defect or close the stage from positive-only tests.
