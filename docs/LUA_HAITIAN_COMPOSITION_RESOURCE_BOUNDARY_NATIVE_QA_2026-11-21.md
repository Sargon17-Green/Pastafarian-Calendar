# Lua Haitian — bounded native QA adapter at the composition boundary

Date: 2026-11-21
PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Authorized branch: `Lua+Kreyòl-ayisyen`
Starting HEAD: `59f3f8f5dd31b6f0c6593880bfba919b8ec78709`

## Scope / falsifiable contract

Input: a real selected year from `normative_oracle.year5000(-15017676)` with exact SHA-locked source blobs, and an **optional** QA resource month cap 16. Expected year selection: candidate count 69, rank 56, gate indices 71..82, day interval (-15018117,-15012823], length 5294, feasible normative month counts 44..47.

`A.preflight(year, cap, downstream)` is a QA-only adapter, NOT a production replacement. It validates structural and normative year-length requirements, computes `minMonths=max(3,ceil(L/123))`, `maxMonths=min(47,floor(L/4))` and **only then** compares `minMonths` to an execution cap between 1 and 47. When `minMonths > cap`, return `RESOURCE_REJECT`, `admitted=false`, `called=false` **without invoking downstream**. A feasible normative year over the QA budget is NOT an invalid year. In a resource-admissible case, call the injected callback at most once; admission is not proof it will complete.

The independent Python oracle counts compositions by inclusion-exclusion and checks constructive feasibility: the real witness permits 44..47 months, and for 44 months has exactly `C(161,43)` ordered month-length vectors. The source-lock check uses the exact Git blob `8fab731dff7011b1a4c3a241c5d1cdefef1c2f1d` for `test/normative_oracle.lua`, plus locked `src/bigint.lua` and `src/source_language_catalog.lua` blobs. The workflow requires the same GitHub SHA as checked-out HEAD.

## Test matrix and evidence

- Local Lua 5.3 adapter fixture: `luatex --luaonly test/lua_haitian_composition_resource_boundary.lua <root> selftest-only`; **15/15 tests passed** on 2026-11-21 (synthetic admission boundary L=1968/1969, normative L=252..5778, cap validation, over-cap zero-call spy). This does **not** execute `year5000` or the canonical Lua source.
- Targeted CI native: `lua5.3 test/lua_haitian_composition_resource_boundary.lua . native`, 200 fresh gate evaluations maximum, 110 seconds Lua CPU, 135 seconds wall, 131072 KiB heap. Traps on actual `O.buildYearStructure`, cutlet composition, month-length composition, weaving and full-date APIs; all must have zero calls when the resource guard refuses the real witness.
- Independent Python `--check-source` gate must show exact Git blob match and 286/286 tests, under the same SHA.
- Persist `source_sha`, SHA256 file list, Python/Lua stdout/stderr, exit code, manifest, even on failure. CI success requires zero exit, empty stderr, source lock, precise witness receipt and zero spy calls.

## Explicit non-claims and related CI

Earlier held-out Native year-selection run `44904821720` passes only selection. Later source-exact CI run `44923037213` completed/success, 95/95 jobs. Its real-year discovery job `136903004452` completed 15/15 anchors and supplied artifact `14715030652`; the previous `ABORT_CPU` occurred on a different commit/run (`44909908913`). Neither 95/95 jobs nor selection PASS proves composition or full-date conversion.

This new QA adapter is not integrated into production `calendarDateIds`. `buildYearStructure` and `chooseMonthWeaving` are NEVER invoked for the witness in this QA. The new CI result must be read back before calling the native resource gate PASS. No Stage56, no change to month normative max 47, no protected branch, merge or release.
