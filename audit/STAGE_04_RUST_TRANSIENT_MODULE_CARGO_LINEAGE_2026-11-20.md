# Stage04 — transient Rust module and Cargo lineage witness search (2026-11-20)

PROJECT_ID: `PC-BRANCH-RUST-AZERBAIJANI`
Branch: `Rust+Azərbaycan-dili`
PREVIOUS_VERIFIED_HEAD: `35de5c531437ea463230dedcc77307e908c97bdb`
STAGE03_CLOSURE: `716e5a6f335b1a15464029b446edb468f3a8482c`
Stage04 disposition: **OPEN / NOT_CLAIMED**; CURRENT_STAGE=4; LAST_COMPLETED_STAGE=3.

## Purpose and distinction from prior QA

Previous audit verified four historical `src/lib.rs` versions and the Stage03-pinned modules, but did not examine *transient versions of other production Rust modules* on the Stage01-to-Stage03 ancestry. This bounded check inspects that additional possible witness class, plus the complete *historical Cargo.toml change list*, without treating test-only or reconstructed Rust as historical production.

## Provenance and source-surface evidence

1. GitHub REST `commits?sha=716e5a6f...&path=Cargo.toml&per_page=30` returned **one commit**, `9a46739c981605875958f9b167bad6049f01fa79`, introducing the Rust manifest. At the Stage03 closure its full blob remains `e82b6ae2a5da27031bdd055be784088599cd8ca7`; edition=2021, `[lib].path=src/lib.rs`, no explicit binaries, examples, benches or build script. This is a *path-history result* on the pinned ancestry, not a blanket claim about all repository branches.
2. The separately bounded GitHub `src/` path-history query returned 15 commits, including **7 predating the Rust Stage01 introduction** (with JavaScript/assembly/no `.rs` files). Those seven were excluded as Rust witnesses; they must not be counted as 15 Rust-stage snapshots.
3. For the **8 Rust-stage `src/` commits** below, independently fetched recursive Git trees were all `truncated=false`, showed only the expected Rust production paths, and showed **zero** `src/main.rs`, `src/bin/**/*.rs`, `examples/**/*.rs`, `benches/**/*.rs`, or `build.rs` entries:

| Commit | Production Rust source inventory |
|---|---|
| `9a46739c` | lib.rs; source_language_catalog.rs |
| `301d25cb` | lib.rs; source_language_catalog.rs |
| `0c32cfc` | lib.rs; source_language_catalog.rs |
| `fd31a099` | lib.rs; source_language_catalog.rs |
| `f6ce3fa8` | lib.rs; discovery01_legacy_save.rs; source_language_catalog.rs |
| `b818990d` | lib.rs; discovery01_legacy_save.rs; source_language_catalog.rs |
| `805827c2` | lib.rs; discovery01_legacy_save.rs; patch01_save.rs; source_language_catalog.rs |
| `932e35d4` | lib.rs; discovery01_legacy_save.rs; patch01_save.rs; source_language_catalog.rs |

4. Across these 8 snapshots there are **11 unique source blobs**: 4 lib versions, 3 catalog versions, 2 discovery SAVE versions, 2 patch SAVE versions. Each was fetched by its **exact Git blob SHA** and its public Rust function names inspected:
   - **4/4 lib.rs**: `calendar_date_spaghetti(BigInt, BigInt)->Result<[String;5],MonsterError>` has the complete body `Err(MonsterError::bootstrap_only())`. It is a public *unavailable* five-field entry, not a numeric day-tag witness.
   - **3/3 catalog versions**: `cutlet_name`, `month_name`; no day-tag function.
   - **2/2 discovery versions**: `legacy_remainder`, `observe_legacy_save`, plus SAVE data/handler types. These are explicitly legacy SAVE, **not** a day-tag.
   - **2/2 patch versions**: `normative_save`, `calculate_save`, plus SAVE data/handler types. These are normative SAVE, **not** a day-tag.

## Bounded check ledger

- Historical Cargo manifest change-list: **1** returned introducing commit; pinned manifest blob checked.
- Rust-stage recursive trees: **8/8 complete**, **8/8 no alternative Cargo auto-target source paths**.
- Distinct Rust production source blobs: **11/11 inspected for public function surface** (4/4 lib bootstrap, 3/3 catalog-only, 2/2 discovery SAVE-only, 2/2 patch SAVE-only).
- Rust Native executions for this new QA: **0**.
- Historical production day-tag numeric outputs: **0**.
- Observed historical Rust numeric RED: **0**.
- No prior accepted CI was rerun and no production source, test or workflow was changed.

The absence of an eligible symbol in these *bounded, ancestry-pinned source/target surfaces* does **not** establish global historical absence. The independent normative calendar oracle in `tests/support/normative_oracle.rs` is test-only; previous archived Python `oldDayTag` RED values remain Python evidence. A callable SAVE function is not a callable day-tag.

## Exact dependent CI resolved

GitHub Actions Names Lock run [44707663425](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44707663425): event=push, attempt=1, status=`completed`, conclusion=`success`, head SHA=`35de5c531437ea463230dedcc77307e908c97bdb`. Job `verify` 136191182540 completed/success; checkout and canonical-names verification steps completed/success. This is **Names Lock only**, *not* Stage04 acceptance.

## Decision and next

No **new** pre-Stage04 production Rust day-tag was found in the newly examined transient modules or manifest history; do not invent one. Stage04 remains **OPEN / NOT_CLAIMED**, not PASS and not Stage05. A further witness is eligible only when supported by a *new*, ancestry-confirmed commit/path/blob and production-callable Rust day-tag symbol, compiled original invocation, numeric outputs, independent normative oracle and observed Rust runtime RED. Do not repeat previous audit of these exact blobs or accepted Stage04 code SHA `d292f66eac36282a0c7074ca51e6729b13a32c6f` without new evidence. No main/merge or publication.
