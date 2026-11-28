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

The §R CI oracle checks forward and backward adjacent-year selection at Foundation, Foundation±1 and Gregorian 2026-11-28, independently enumerating §O signed gaps and the §M/§N choice. The public CLI/API inverse test uses the modern fixed calculation day, obtains the first day of year 5001, verifies the forward public label 5001, and round-trips the five numeric components to the exact serial/Gregorian day. The independent §R CI oracle separately verifies both 5001 and 4999 directions. The inverse test also checks zero-budget refusal, the 64-transition ceiling, nonpositive ordinals, conflicting component coordinates and CLI usage.

## Differential inverse boundary oracle

The differential test retains c=2026-11-28. It seeds the independent NormativeReference gate lattice at the selected year-5000 opening gate, independently reconstructs the surrounding local gate sequence, reselects year 5000, and checks the adjacent 4999/5001 year records. The seed avoids replaying every historical gate from Foundation; therefore this is an independent local §R/§O check conditioned on the selected absolute anchor, not a fresh derivation of the absolute gate origin.

For the selected year, the existing NormativeReference routines independently derive §S/T cutlet count, partition and names, §U month count and lengths, and §W month names. The existing Stage14 weave validator is reused (not copied) for §V multiplicities and first/last appearance ordering; the bowl rank is independently recomputed from the reference sauce. The selected full-year weave word is production-generated, not independently unranked by the slower reference counter. The reference structure is then projected at the year start/end, an interior cutlet boundary, and an interior month transition. For each sample, cutlet and month coordinates are independently inverted and must agree on the same serial day before the production fixed-c inverse is called with maxTransitions=0.

This checks the five-field inverse at year, month and cutlet boundaries without re-anchoring c at the requested day. It is differential CI evidence, not a user-host Native run, release, or overall production acceptance.

Required markers: PRODUCTION_INVERSE_DIFFERENTIAL_PASS samples>=3 fixed_c=2026-11-28 year=5000 transitions=0; and PRODUCTION_INVERSE_FIXED_C_PASS checks>=18 modern_calculation_day=2026-11-28 fixed_c=true transitions=1 differential_samples>=3 elapsed_ms<=450000. Differential timing is emitted separately and bounded to 330000 ms; the complete inverse test is bounded to 450000 ms. Dart 3.13.2 formatting must report zero changes; dart analyze must report no issues. This is a branch-only readiness gate, not a release or a claim that the overall converter is production complete.

Required marker: PRODUCTION_INVERSE_FIXED_C_PASS checks>=18 modern_calculation_day=2026-11-28 fixed_c=true transitions=1 elapsed_ms<=240000; timing is emitted separately before the bound assertion. Dart 3.13.2 formatting must report zero changes; dart analyze must report no issues. This is a branch-only readiness gate, not a release or a claim that the overall converter is production complete.
