# Lua/Kreyòl ayisyen — bounded real-year interval discovery (2026-11-18)

PROJECT_ID: `PC-BRANCH-LUA-HAITIAN`  
Branch: `Lua+Kreyòl-ayisyen`  
Base HEAD: `8c70e83872784fe91068cfe3fb808a54601b1d7d`  
Frozen source locks:
- `test/normative_oracle.lua`: blob `8fab731dff7011b1a4c3a241c5d1cdefef1c2f1d`
- `src/bigint.lua`: blob `fcff58bcaaf8bb3f205e7a9c624a51069c0e5a5d`
- `src/source_language_catalog.lua`: blob `5b59ee6bb0ea2c2a551185929b5531ea28a50e49`

## Purpose and prior evidence

The bounded reference-composition probe on the base HEAD passed its own 10/10 synthetic assertions, with F0 profiles explicitly excluded. This document defines the next, separate search: find one *genuine* year interval whose actual month-count choice is small enough to admit a later bounded composition experiment.

The two already accepted F0 `year5000` witnesses are not repeated:
- calculation day `-15055671`, interval length `4244`, minimum possible month count `35`;
- calculation day `-15043671`, interval length `4358`, minimum possible month count `36`.

The earlier conservative F0 screen rejected 25/25 month-count profiles. That was a policy-based resource screen, not evidence of a timeout or mathematical impossibility.

## Bounded discovery procedure

The Lua 5.3 probe uses the frozen normative source only to select actual reference intervals and the exact month-count choice made before month composition in `buildYearStructure`.

1. Reset the gate cache once, then inspect at most 12 fixed calculation-day anchors:
   `FOUNDATION_DAY + {500,1500,2500,3500,4500,5500,6500,7500,8500,9500,10500,11500}`.
   This is a finite sample inside the span between the two historical F0 anchors, not an exhaustive search of all days.
2. For each anchor, call `O.year5000(calculationDay)`; require year number 5000, integer boundaries, at least six gate gaps, normative year length 252..5778, and `openGateDay < calculationDay <= closeGateDay`. Set the genuine target-day witness to `targetDay = calculationDay`.
3. If `L > 16*123 = 1968`, reject the anchor before computing the month-count sauce: at least 17 months would be required.
4. Otherwise reproduce only the pre-composition month-count selection: `O.sauce(calculationDay, openGateDay+1)`, `O.askBowl(...,3,O.SEAL_MONTH_COUNT)`, and `O.chooseRank`. Do **not** call the composition family.
5. For the selected month count `m`, compute a static upper bound on memoized `(remaining, slots)` coordinates in the normative bounded-composition recurrence:

   `U(L,m) = sum(k=1..m) max(0, min(L,123k) - 4k + 1)`.

   This counts every integer remaining-total that can survive the recurrence's lower/upper feasibility checks for each slot count. It is an upper bound, not a measured allocation count.
6. Admit the witness only when `m <= 16` and `U(L,m) <= 20000`. Stop at the first admitted witness. If none is found, report that bounded search result and do not infer impossibility.

The month-count choice is read from the real reference path; the interval and target are not synthetic fixtures. No month lengths, month weaving, or date tuple are computed in this discovery task.

## Hard bounds

- At most 12 anchors, in the exact order listed above.
- At most 200 newly evaluated positive/negative gate gaps across the whole search.
- Lua CPU budget: 55 seconds; outer GNU `timeout`: 60 seconds.
- Lua heap budget: 128 MiB; outer Linux virtual-memory limit: 131072 KiB.
- Composition static state upper bound: 20,000.
- Maximum admitted month count: 16.
- The workflow checks the exact commit SHA and all three frozen source blob locks, and uploads stdout, stderr, exit code, source SHA, and SHA-256 manifest even on failure.

## Strict exclusions

This probe must not call `makeBoundedCompositionFamily`, its `count` or `unrank1`, `makeWeavingCounter`, `buildYearStructure`, `calendarDateIds`, `calendarDate`, or any production date facade. It must not run the two F0 profiles, construct a full year structure, or claim date integration.

F0 2/2 Native, F1 interface design, F2 synthetic 4/4 + 546/546 + 5/5, Stage55, and the 10/10 bounded synthetic composition probe remain separate evidence scopes. This is not Stage56, production implementation, main, merge, or release.

## Acceptance and next step

A completed CI run on the exact HEAD must show:
- source locks and checkout SHA pass;
- `REAL_YEAR_INTERVAL_DISCOVERY_COMPLETED: n/12`;
- either `REAL_YEAR_STATIC_ADMISSION_PASS: 1/1` with one full `REAL_YEAR_ADMITTED_WITNESS` record, or `REAL_YEAR_STATIC_ADMISSION_NONE: 0/n`;
- `COMPOSITION_NOT_INVOKED: YES`, zero exit, empty stderr, and a verifiable evidence artifact.

Only if an admitted genuine witness exists may the next task construct a *separate* bounded composition experiment for that exact pair, with independent guarded composition, memo/heap/time aborts, and a separately bounded reference differential. If no witness is found, expand only the finite anchor set in a later contract; do not relax the resource limits or invoke reference composition speculatively.
