# Rust+Azərbaycan-dili Stage04: literal-placeholder patch and completed CI independent QA (2026-11-06)

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Branch: `Rust+Azərbaycan-dili`
Code commit: `455ffef83378761d421a1e4d64cf5f1ca45051de`
Parent: `66462f0d079b493452f01a3a26e668d208c47627`
CURRENT_STAGE=4; LAST_COMPLETED_STAGE=3; **STAGE04 OPEN / NOT_CLAIMED**.
No Stage05, no main or merge; no historical Rust RED is claimed.

## Newly reproduced defect and scoped fix

`tools/stage04_rust_callability_eligibility.py:test_body()` previously replaced `CRATE` and then `SYMBOL` globally after composing source. A valid crate identifier `crate_SYMBOL` was rewritten into `crate_old_numeric_probe` for symbol `old_numeric_probe`, corrupting the generated Rust harness. The old implementation demonstrably mismatched **6/9** valid crate/symbol combinations; it was not a hypothetical claim. The revised implementation directly interpolates crate and symbol names once and leaves Rust's `println!` braces literal. The independently executed local Python matrix passed **9/9** combinations.

The single code commit updates exactly three non-production files: the harness generator, `tools/tests/test_stage04_rust_callability_eligibility.py` (one test covering a 3×3 identifier matrix), and `.github/workflows/rust-az-stage04-discovery02.yml` (callability count 10→11). No historical source, production Rust code or stage metadata was changed.

## Completed native workflow evidence (exact code SHA)

- [Stage04 run 42176989343](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42176989343): completed/success; job `127757611947`; SHA exactly `455ffef83378761d421a1e4d64cf5f1ca45051de`.
- [Canonical Names Lock 42176989090](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42176989090): completed/success on the same code SHA.
- Stage04 job's exact logs: **11/11** callability Python controls (including new regression, no skips), **13/13** provenance tests, **6/6** TSV tests, Rust Native **34/34** (nonzero suite counts 16+3+4+2+3+3+3), Python↔Rust direct differential **15/15** candidate and patched controls. The comparison reports 8 RED + 7 CONTROL only for pinned **archived Python** old-rule behavior, not an executed old Rust day-tag route.
- No duplicate workflow dispatch or rerun of an already-successful code SHA.

## Independently downloaded CI evidence ZIP

[Artifact 13483851470](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42176989343/artifacts/13483851470) (`rust-az-stage04-discovery02-baseline`):
- Size **20,169 bytes**; **17** distinct ZIP entries; CRC PASS; no absolute/traversal names.
- Independent computed SHA-256 `bfcda8313c6baa605945efd29874e9fe7ba804077ec624757cf8b300b43269a2`, equal to the GitHub artifact API digest.
- Separate Python stdlib-only verifier completed **199/199 independent assertions, 0 failures** against the downloaded ZIP, including archive integrity, exact PROJECT_ID and code SHA, exit 0, per-suite test evidence, no skipped callability tests, historical pin/closure JSON, 15 unique four-column TSV rows, report consistency, and recomputation of the 15 normative values and archived Python legacy/classification outputs.
- Independent oracle used `F=-15055671`, `oracle(day)=2*abs(day-F)+(1 if day>=F else 0)` and `archived_Python_legacy(day)=2*abs(day-F)`. The independent 15-row comparison yielded 8 Python RED + 7 Python CONTROL; no unexpected, patch/candidate 15/15.
- **199 artifact assertions are not 199 Rust Native tests**, and the local 9-string matrix is not a historical Rust runtime witness.

## Stage04 acceptance boundary and NEXT

The pinned Stage3 Rust `src/lib.rs` remains `SOURCE_ONLY_NO_SUPPORTED_SIGNATURE` for `calendar_date_spaghetti`; `callable_numeric_function_verified=false`, `callable_day_tag_route_verified=false`, `observed_runtime_red=false`, and `stage04_closure=NOT_CLAIMED`. The successful synthetic Rust numeric probe is not proof of old Rust day-tag semantics.

Preserve `CURRENT_STAGE=4`, `LAST_COMPLETED_STAGE=3`, OPEN. Only a genuinely new pre-Stage04 Rust production day-tag witness, with verified commit/path/blob, strict ancestry, exact live HEAD, demonstrable semantic production route and bounded compiled execution, may advance the outstanding historical Rust RED decision using an independent oracle. Do not rescan exhausted history, invent an old Rust RED, reopen passed CI, open Stage05, or merge to main.
