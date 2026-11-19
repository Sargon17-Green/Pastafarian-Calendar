# Lua/Kreyòl ayisyen — bounded negative-anchor interval discovery (2026-11-20)

PROJECT_ID: `PC-BRANCH-LUA-HAITIAN`
Branch: `Lua+Kreyòl-ayisyen`
Parent SHA: `e25cac910314bc639674d7ecd8b8449a2bc8424b`
Scope: QA-only genuine year-5000 interval static admission. No reference month composition, weaving, full date, Stage56, production integration, main, merge, or release.

## Completed prerequisite — bounded negative result

Canonical Names Lock run [44613699403](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44613699403), discovery job [135876625560](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44613699403/job/135876625560), completed/success on source `e25cac910314bc639674d7ecd8b8449a2bc8424b`. The 15-anchor v2 probe reported 15/15 candidates inspected; 0 admitted; 47 gate-gap evaluations; all `MIN_MONTHS_OVER_CAP`; candidate lengths 3,342–5,711 days; minimum months 28–47, exceeding the unchanged 16-month admission cap. `COMPOSITION_NOT_INVOKED: YES`; no month composition or full-date execution.

The [source-locked ZIP artifact 14575346632](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44613699403/artifacts/14575346632) was downloaded and verified: ZIP SHA-256 `5bceb5951cfa0375b444672d40a543165f4ae581991c76d38b5c486cd37397e9`, 6/6 CRC PASS, exit code 0, empty stderr, manifest SHA matches HEAD. Independent arithmetic review checked all 15/15 candidate year lengths, gate counts, minimum-month lower bounds, origin arithmetic, negative-rejection reasons, and the completion/noncomposition markers. This finite sample does not imply global impossibility.

## Next isolated sample — explicitly finite and non-overlapping

New versioned probe `test/lua_haitian_real_year_interval_discovery_v3.lua` evaluates exactly five distinct offsets, in order, relative to `O.FOUNDATION_DAY`: `-500, -1500, -2500, -3500, -4500`. They are disjoint from the preceding positive offsets `500, 1500, ..., 14500`. The selected `calculationDay` is also the `targetDay`. The frozen `O.year5000` / precomposition month-count oracle is reused from the *same branch*; no code or fixtures from other branches.

Rationale: the prior probe exclusively sampled positive offsets and all those years were too long to pass a 16-month bound. Sampling five offsets on the opposite side of the foundation is a bounded, falsifiable, different candidate set. An admission is neither predicted nor required for the negative-discovery job to pass.

## Frozen source and resource contract

Source blob locks before execution:
- `test/normative_oracle.lua`: `8fab731dff7011b1a4c3a241c5d1cdefef1c2f1d`
- `src/bigint.lua`: `fcff58bcaaf8bb3f205e7a9c624a51069c0e5a5d`
- `src/source_language_catalog.lua`: `5b59ee6bb0ea2c2a551185929b5531ea28a50e49`

Unchanged hard limits: 5 anchors (new count), 200 total gate-gap evaluations, 55 CPU seconds, 60-second outer timeout, 128 MiB Lua heap and 131072 KiB process virtual-memory limit; 16 selected months and 20,000 bounded composition-state *estimate*. `L > 1968` rejects before attempting month-count selection. No composition or weaving call is permitted by this probe.

## Machine-checkable outcomes

For each visited anchor emit one `REAL_YEAR_CANDIDATE` with offset and calculation day, plus either a short-interval static admission reason, long-interval `MIN_MONTHS_OVER_CAP`, or `NO_YEAR_CANDIDATE`. Stop only on an admitted witness or exhaustion of the five offsets. Require exact-commit checkout; all source blob locks; job `completed/success`; exit=0; empty stderr; `REAL_YEAR_INTERVAL_DISCOVERY_COMPLETED: n/5`; a single `REAL_YEAR_STATIC_ADMISSION_PASS: 1/1` or `REAL_YEAR_STATIC_ADMISSION_NONE: 0/n`; `COMPOSITION_NOT_INVOKED: YES` and `SCOPE=REAL_YEAR_INTERVAL_STATIC_DISCOVERY_ONLY; COMPOSITION=NOT_RUN; FULL_DATE=NOT_RUN`. The ZIP must provide source SHA, manifest, stdout/stderr, exit code, and five source SHA-256 values. Review every candidate, count, and resource bound before deciding.

If an admissible witness occurs, open a separate hard-capped, independent-oracle composition differential on that *exact* interval only. If 0/5, record the negative result; do not infer impossibility, loosen caps, or open Stage56. Derive a new targeted bounded search strategy from the proven gate intervals rather than blindly repeating this negative sample.
