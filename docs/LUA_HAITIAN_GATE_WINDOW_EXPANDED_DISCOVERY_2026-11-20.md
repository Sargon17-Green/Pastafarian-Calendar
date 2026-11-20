# Lua/Kreyòl-ayisyen — expanded gate-window discovery v4 (2026-11-20)

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Parent: 55bdd095b0d3569e98e95b55ff4d77805007a6a9
Scope: QA-only, static admission. No Stage56, composition, weaving, calendarDate, product changes, main, merge or release.

## Input and measured predecessor
Canonical Names Lock run 44701154225 completed/success on parent SHA; job 136169590059 success; artifact 14613869643 SHA-256 f4a4e6f434431410cfdecb5e1de7c69a2c06071a2016d21631158929df0ca269. ZIP has six CRC-valid files; exit 0; stderr empty; exact output: 43 six-gap windows scanned at indices -24..24, 0 short windows, 0/8 probes, 48 gate-gap evaluations, COMPOSITION_NOT_INVOKED=YES. This is a finite negative, not a general impossibility result.

## Falsifiable v4 experiment
Extend the unchanged canonical gate-index calculation to -40..40 inclusive (81 gate days, 80 adjacent gaps, 75 six-gap windows). A selected year that could have at most 16 months must have length L<=16*123=1968 days. A normative year contains at least six consecutive gate gaps, therefore any qualifying year must contain a six-gap window of at most 1968 days. Preserve the pre-existing priority ordering (length, absolute index, signed index), selecting at most eight distinct 1/3 and 2/3 interior days for year5000. This necessary condition does not imply the year selector will choose the short candidate.

Print all 81 GATE_INDEX positions and 75 GATE_WINDOW intervals, plus GATE_WINDOWS_TOTAL=75 and the observed minimum window length, so interval arithmetic can be verified independently without calling normative composition. Each adjacent gate gap must lie in the frozen oracle range 42..963, and each reported six-gap length equals last-first and equals the sum of exactly six adjacent differences. Verify short-window count against printed rows. If an admitted witness appears, independently verify year boundaries, ceiling(L/123), selected month count <=16, composition-state upper bound <=20000 before any later, separate bounded composition differential. When none is found, record the finite negative and plan a further bounded expansion only from the new evidence.

Hard ceilings (no silent widening): 80 initial adjacent gap calculations plus dynamic candidates, 200 total gate-gap evaluations, 110s Lua CPU, 120s wall timeout with two-second kill grace, 128MiB virtual and Lua-heap limit, 16 selected months, 20000 static states, at most eight distinct sampled days. Abort explicitly on budget failure. No composition invoked.

Machine-readable evidence: exact branch/SHA/source locks, stdout, empty stderr, exit_code=0, SHA-256 manifest for v4 probe and this contract plus three frozen sources; GATE_WINDOW_SCAN=-40/40, 81 GATE_INDEX rows, 75 GATE_WINDOW rows, GATE_WINDOWS_TOTAL=75, MIN_SIX_GAP_WINDOW, SHORT_SIX_GAP_WINDOWS, GATE_TARGET_PROBES (0..8), SHORT_SELECTED_YEAR_INTERVALS, exact admission marker, GATE_GAP_EVALUATIONS<=200, COMPOSITION_NOT_INVOKED=YES, scope marker.

Frozen blob SHA: test/normative_oracle.lua 8fab731dff7011b1a4c3a241c5d1cdefef1c2f1d; src/bigint.lua fcff58bcaaf8bb3f205e7a9c624a51069c0e5a5d; src/source_language_catalog.lua 5b59ee6bb0ea2c2a551185929b5531ea28a50e49.

Acceptance requires completed native job, correct exact SHA, full ZIP digest/CRC, exit=0, stderr empty, and independent interval reconstruction. CI success or static QA alone is not full-date correctness.
