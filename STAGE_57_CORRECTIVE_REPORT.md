# HISTORICAL — SUPERSEDED DOWNSTREAM WITNESSES

The Stage-57 Patch-26 mechanism itself is preserved, but the concrete witnesses in the former report were computed downstream of the rejected Stage-56 raw-sum semantics and are therefore stale.

Original historical report: observed base HEAD `b8126dfe6a36f05fd6eb8c45479062e039412678`, original blob `fc9aa9aeeb09dd6501ec76a81e63a98f7dd5d1b4`.

Under canonical saved-sum semantics, the historical witness `c=-15048553, t=-15044872` resolves to canonical indices `(5000,5,347,31,123)`. The semantic Year 5000 and Patch-26 round-trip both resolve to `(-15049315,-15044808]`, gate indices 11..20, so the legacy guard passes. No Patch-26 code was rolled back or removed.

See `CANONICAL_SAVED_SUM_CORRECTION.md` and `tests/stage-57-e2e-reference.js` for current evidence.
