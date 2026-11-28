# Production inverse conversion with fixed calculation day

PROJECT_ID: PC-BRANCH-DART-HEBREW
BRANCH: Dart+עברית only
STATUS: Production-readiness work item; not a numbered historical stage and not a release.

## Contract

Input: one proleptic Gregorian calculation date c, a five-component Pastafarian date (year number, cutlet canonical index, day in cutlet, month canonical index, day in month), and maxTransitions in 0..64.
Output: the exact proleptic Gregorian serial day t, or the corresponding Gregorian civil date. No time zone, DateTime normalization, locale sorting, or external runtime dependency is involved.

The year is resolved by starting at year 5000(c) and applying §R NEXT/PREVIOUS while retaining the same c for every transition. The inverse must never re-anchor at t. It reconstructs the §S/T cutlet partition and §U/V/W month components under that same c, maps the month name index to its unique chronological month ID, selects the requested occurrence, and independently checks that the cutlet ordinal identifies the same serial day.

## Validation and bounds

- Year number is reachable only within the explicit 64-transition budget; exceeding it throws IncompleteMonsterYearNumberTraversal before producing a date.
- Invalid transition budgets outside 0..64 throw RangeError.
- Cutlet and month canonical indices must exist in the locked Hebrew source catalog.
- Day ordinals must be positive and within the selected cutlet/month.
- A month name not selected in the year, a cutlet name not unique in the year, or conflicting cutlet/month coordinates is rejected; no best-effort or guessed date is returned.
- Existing year, month and gap bounds remain authoritative: year 252..5778 days, §O gaps 42..963, month lengths 4..123, 3..47 months, and at most 137 intervals per year.

## Independent evidence

The §R Native oracle checks forward and backward adjacent-year selection at Foundation, Foundation±1 and Gregorian 2026-11-28, independently enumerating §O signed gaps and the §M/§N choice. The public package inverse test uses the modern fixed calculation day, obtains the first day of year 5001 and last day of year 4999, verifies forward public API labels 5001/4999, and round-trips the five numeric components to the exact serial/Gregorian day. It also checks zero-budget refusal, the 64-transition ceiling, nonpositive ordinals and conflicting component coordinates.

Required marker: PRODUCTION_INVERSE_FIXED_C_PASS checks>=10 modern_calculation_day=2026-11-28 fixed_c=true transitions=1 elapsed_ms<=240000. Dart 3.13.2 formatting must report zero changes; dart analyze must report no issues. This is a branch-only readiness gate, not a release or a claim that the overall converter is production complete.
