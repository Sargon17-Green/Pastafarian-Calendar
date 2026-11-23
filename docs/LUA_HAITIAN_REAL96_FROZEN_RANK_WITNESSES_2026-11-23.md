# Lua Haitian — real 47×5294 count acceptance and frozen 96-symbol rank witnesses (QA only)

PROJECT_ID: `PC-BRANCH-LUA-HAITIAN`  
Branch: `Lua+Kreyòl-ayisyen`  
Evidence source commit: `7bac3d896c332976cde5e97f6527b84084ce95b2`  
2026-11-23. No production calendar, normative weaving, fullDate, Stage56, main, merge or release changes.

## Scoped Native evidence

- Canonical [run 45087322675](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45087322675) = **completed/failure**; do not call this full-suite PASS. The unrelated legacy `lua_haitian_real_year_interval_discovery` [job 137408814887](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45087322675/job/137408814887) failed with `ABORT_CPU` after 11 emitted anchors, under the existing 55-second CPU budget. No rerun was requested.
- Focused `lua_haitian_real_polynomial_count / lua53_real_polynomial_count` [job 137408816059](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45087322675/job/137408816059) = **completed/success**, checked from the actual job log and downloaded [artifact 14781275883](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45087322675/artifacts/14781275883).
- Exact source blob `df7a6d31714d111a93aced5ccb74a55c09fd78b1`; raw Lua exit code 0, empty stderr, exactly eight stdout records, 3/3 tiny recurrence witnesses, 4/4 vector guards, 123326 DP recursion cells.
- Real 47-month, 5294-day count: 8654 decimal digits; ASCII decimal SHA-256 `e3d498d39d6b4dfc401a85b8d9135ff1089a81ace85565ac5dcb123870c09f34`. Resource receipt: wall 73.27 seconds, user CPU 73.20 seconds, system CPU 0.06 seconds, peak RSS 149164 KiB. All are within the scoped QA count limits (450s wall, 420s CPU, 262144 KiB virtual-address-space cap).
- Independently downloaded ZIP: outer SHA-256 `73eadef693d5815ca1b331ea43355ccb21efad86a51e7c220b271924463fd004`; nested ZIP SHA-256 `63226ec10164880ca7ab4ba89478d5ef8e218c303f08899a909b40b5a90fcdf8`; outer CRC 2/2, inner CRC 11/11 including directory, SHA256SUMS 9/9, project/commit/source manifest and nested ZIP checksum consistent.

## Frozen independent Python rank witnesses

Executable oracle: `test/lua_haitian_real96_frozen_oracle.py`. Immutable fixture: `test/fixtures/lua_haitian_real96_frozen_oracle.json`.

The Python QA recomputes the recurrence with arbitrary-precision integers and, independently of the Lua implementation, recomputes each candidate branch's exact suffix cardinality for all 96 selected positions. Every step asserts sum of disjoint next-symbol block counts = remaining suffix cardinality. Six small multiset domains are exhaustively enumerated, filtering ordered first/last appearances, then compared for every rank. The real month vector is source-attested (47 elements, 5294 days, CSV SHA-256 `9c623663a0d48455634df29749e1034a322a412a1898d7b24a77c2e29d708154`). Prefix symbols are **zero-based**; rank and residual rank are **one-based**.

Fixture locks three ranks: `FIRST=1`, `MIDDLE=floor((N+1)/2)`, `LAST=N`. For each rank it stores its full 96-label prefix CSV and SHA-256, residual rank's ASCII decimal digit length, SHA-256 and first/last 32 digits, and residual suffix cardinality length and SHA-256. Hashes deliberately avoid checking 8500-digit ranks into a massive CI stdout. These are **locally generated and checked Python QA fixtures, not Lua Native differential PASS**.

To reproduce (Python 3.11+): `python3 test/lua_haitian_real96_frozen_oracle.py test/fixtures/lua_haitian_real96_frozen_oracle.json`. Expected: `TINY_EXHAUSTIVE= 6` and `FROZEN_REAL96=PASS 3/3`. To intentionally regenerate fixture (not a validation substitute), append `--write`; any change to the fixture requires a new reviewed SHA and new evidence.

## NEXT / acceptance isolation

Author a QA-only Lua 5.3 lexicographic prefix/rank adapter. It must use genuine Lua arbitrary precision, take the attested length vector and the three rank definitions, return 96 zero-based labels, residual one-based rank and suffix total. Compare exactly to this **pre-frozen** fixture (prefix bytes/digests and residual decimal SHA/digit counts), and test out-of-range ranks and independent small exhaustive multiset cases. Do not regenerate expected JSON from the Lua program. Use exact-SHA source-lock, resource budgets, stdout/stderr/exit and ZIP SHA/CRC/manifest in one focused workflow; no duplicate dispatch.

Gate distinctions: Lua real **count Native focused PASS**; independent Python 96-prefix **local QA PASS**, not yet CI; Lua real prefix/differential **NOT_RUN**; normative weaving/composition/fullDate **NOT_RUN**; entire canonical run **FAILURE** due to unrelated pre-existing CPU cap. This document alone does not approve any larger stage.
