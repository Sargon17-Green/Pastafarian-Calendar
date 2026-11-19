# Lua/Kreyòl ayisyen — bounded real-year anchor expansion (2026-11-19)

PROJECT_ID: `PC-BRANCH-LUA-HAITIAN`  
Branch: `Lua+Kreyòl-ayisyen`  
Parent/source SHA: `e3a61d458485b660b6899bb1a89eef16ba85bdd8`  
Prior contract: `docs/LUA_HAITIAN_REAL_YEAR_INTERVAL_DISCOVERY_2026-11-18.md` (retained unchanged).

## Grounded result of the first discovery

Canonical Names Lock run `44393932386`, discovery job `135118725449`, completed/success on exact source SHA. The Lua 5.3 stdout reports `REAL_YEAR_INTERVAL_DISCOVERY_COMPLETED: 12/12`, `GATE_GAP_EVALUATIONS: 43`, `REAL_YEAR_STATIC_ADMISSION_NONE: 0/12`, and `COMPOSITION_NOT_INVOKED: YES`. All 12 recorded candidates had `MIN_MONTHS_OVER_CAP`; the observed year lengths were 3342–5711 days, requiring at least 28 months for the shortest. The search did **not** prove that a shorter admissible interval cannot exist. The source-locked evidence artifact is https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44393932386/artifacts/14470453757 .

## One bounded, non-overlapping expansion

This second discovery keeps the original 12 offsets in order and appends exactly three distinct offsets `12500, 13500, 14500` relative to `O.FOUNDATION_DAY`. The expansion samples beyond the two historical F0 anchors (offsets 0 and 12000), so it tests additional real calculation-day candidates rather than claiming coverage within the original F0 interval. The implementation is a new versioned probe `test/lua_haitian_real_year_interval_discovery_v2.lua`; the prior 12-anchor probe and contract stay untouched for reproducibility.

The source, dependencies, oracle selection and admission equations are otherwise bit-for-bit identical to the preceding probe. Frozen locks:
- `test/normative_oracle.lua`: blob `8fab731dff7011b1a4c3a241c5d1cdefef1c2f1d`;
- `src/bigint.lua`: blob `fcff58bcaaf8bb3f205e7a9c624a51069c0e5a5d`;
- `src/source_language_catalog.lua`: blob `5b59ee6bb0ea2c2a551185929b5531ea28a50e49`.

## Unchanged hard caps and scope

At most 15 ordered anchors (stop at first admitted witness), 200 gate-gap evaluations, 55 s Lua CPU, 60 s GNU timeout, 128 MiB Lua heap plus 131072 KiB process virtual-memory limit, 16 selected months, 20,000 static composition states. For `L > 1968`, reject without computing month-count sauce. No reference month composition, weaving, date-facade calls, Stage56, integration, main, merge or release. An extension cannot be called PASS on static review alone.

## Verifiable acceptance

On the exact new commit SHA, require the canonical workflow's discovery job to complete with checkout and three blob locks matching, exit code 0, empty stderr, `REAL_YEAR_INTERVAL_DISCOVERY_COMPLETED: n/15`, `COMPOSITION_NOT_INVOKED: YES`, the no-composition scope sentinel, and an artifact with manifest/source SHA, stdout/stderr/exit, and file SHA-256 list. Inspect each of the 15 emitted candidate records (or fewer if a witness is admitted early). Require either `REAL_YEAR_STATIC_ADMISSION_PASS: 1/1` and one complete real witness, or `REAL_YEAR_STATIC_ADMISSION_NONE: 0/n`. An admission is **not** the successful completion of a reference composition.

If a real witness meets the unchanged static caps, develop a separate hard-bounded composition experiment for the exact interval and target day, with independent oracle and run evidence. If none is admitted, record the negative sample as bounded evidence, select another explicit finite non-overlapping anchor set in a separate contract, and retain all caps. Do not infer global impossibility.
