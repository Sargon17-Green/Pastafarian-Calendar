# Lua/Kreyòl-ayisyen — targeted six-gate window discovery (2026-11-20)

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Parent: 2b7ba9ec3395849d4ea96cc4efeb4396a3ffdfa6
Scope: bounded QA only; **no Stage56, production integration, composition, weaving, calendarDate, main, merge, or release**.

## Prerequisite: verified bounded negative result
Canonical Names Lock run 44633728318 completed/success on exact parent SHA; 89/89 jobs; job 135946825837 completed/success. Target artifact 14583039516, SHA-256 b6986c93e55fcbe2be4519e606bd625e1279cbe7461cb7ab7691e3ff5639c6cf, 6/6 ZIP members CRC PASS, manifest/source lock, exit=0, stderr empty.
Five negative offsets -500/-1500/-2500/-3500/-4500 produced years of lengths 5349/5214/5534/5490/3382 and minimum month counts 44/43/45/45/28; 0/5 static admissions. 31 gate-gap evaluations and no composition. Independent integer recheck passed 5/5 (close-open, gate index difference, ceil(length/123), anchor inclusion). This is a finite sample, not an impossibility theorem.

## Falsifiable next strategy
Every normative year has at least six gate gaps. Any year whose length is <=16*123=1968 necessarily contains **a contiguous six-gap window of length <=1968**. The earlier 20 offset probes did not target this necessary condition and failed their 16-month bound.

Precompute gate days for indices -24..24 inclusive using only the unchanged frozen normative oracle (49 positions, 43 six-gap windows). Keep exactly those 6-gap windows with normative length 252..1968, sorted by (window length, |start index|, start index). Then evaluate at most eight **distinct** candidate days at the 1/3 and 2/3 interior positions of the selected short windows. This deliberately chooses plausible gate geometry before asking the existing year-5000 selector; the selector may still pick a long year. Only a **selected** year of length <=1968 can continue to precomposition month-count selection. Compute an upper bound on composition states; do not invoke composition.

Hard caps: 200 combined gate-gap evaluations; 55 Lua CPU seconds; 60-second process wall timeout; 128 MiB Lua heap and ulimit -v 131072 KiB; 16 selected months; static composition-state estimate <=20000; at most 8 distinct target-day calls; gate index scan -24..24. Abort when caps exceeded; no silent widening. This is not a claim of independent full-date correctness.

Expected machine-readable lines: GATE_WINDOW_SCAN: -24/24; SHORT_SIX_GAP_WINDOWS: N; GATE_TARGET_PROBES: n/8 (0<=n<=8); SHORT_SELECTED_YEAR_INTERVALS: m; exactly one admission line GATE_TARGET_ADMISSION_PASS: 1/1 or GATE_TARGET_ADMISSION_NONE: 0/n; GATE_GAP_EVALUATIONS: g (g<=200); COMPOSITION_NOT_INVOKED: YES; exact scope marker. One GATE_TARGET row per tested day; no duplicates; every selected interval independently checkable by integer arithmetic from its open/close indices and days.

Source blob locks: normative_oracle.lua 8fab731dff7011b1a4c3a241c5d1cdefef1c2f1d; bigint.lua fcff58bcaaf8bb3f205e7a9c624a51069c0e5a5d; source_language_catalog.lua 5b59ee6bb0ea2c2a551185929b5531ea28a50e49. Preserve SHA-256 for probe, contract, and three source files in the ZIP. Require exact checkout/commit, exit 0, empty stderr, log and artifact validation.

If selected/admitted witness occurs, independently verify its gate-index interval, bound and precomposition month count, then open a separate bounded composition differential on that exact interval. If 0 admitted, record the negative result and inspect window count versus selected-year result; extend the deterministic gate-index window only under a new explicit budgeted contract, not by blind offset guesses. No acceptance inference from queued/in_progress jobs.
