# Dart+עברית — Production readiness / Gregorian input boundary

PROJECT_ID: PC-BRANCH-DART-HEBREW
Authorization: user reopened development on 2026-11-28 to achieve a standalone production converter. No merge/main/release. KEEP_A_DEFAULT; no cache promotion. This is a production work item, not a new numbered historical stage.

## Scope and normative source

Locked specification blob 74c424b44eadd4ece3f29072ddbf873236557604, §§ A, B, Q, R, X.
F(c,t) uses two distinct civil days. Gregorian serial day 1 = astronomical year 1, January 1. Year 0 = 1 BCE. Integer BigInt civil dates are timezone-free. Invalid dates reject; no DateTime normalization. Gregorian leap rule and floor division apply equally to negative years. The civil-date adapter has no external package or subprocess dependency. It forwards exact serial days to the unchanged MonsterFiveFieldCalendar.

Gregorian serial encoding/decoding is not an inverse Pastafarian converter. The legacy calendarDateSpaghetti stub deliberately remains unchanged because Stage1 asserts rejection; use the new public PastafariGregorianConverter for this candidate. A separate public API consolidation is required before release.

## Critical open production gap (source-level proof)

The §Q anchor is year 5000 around calculation day c, not a fixed year containing Foundation. However MonsterYearLocator.sentinelSearch currently walks at most 138 gaps per side from Foundation; each gap is <=963 days. Consequently modern calculation days (e.g. 2026-11-28) cannot even be bracketed (distance exceeds 138*963). This is independent of §R's 64-year transition cap. The adapter cannot make these requests succeed. Do not claim general modern-date conversion until §Q is fixed and measured.

Next: design exact signed §O streaming traversal with explicit work budget, retain only the proven §Q window, preserve both strict sentinels and length/order selection; verify against an independent enumerator, near/far and both signs, then measure modern dates. No approximation or skipped gaps without proof. Separately address §R reach, reverse conversion contract (fixed c), and production packaging, CLI/API and documented bounds. Do not equate production readiness with historical 55-stage completion.

## Gate for this boundary only

Pure Dart native test via package import, Gregorian fixed §B anchors (-15055671, -278522), serial day 0 and 1, independent UTC DateTime oracle over full Gregorian 400-year cycle, sparse inverse checks, huge signed-year cycle identity, rejection of invalid dates and literal §X AC.1 (5000,10,503,20,56). No external oracle at runtime. Require formatter zero changes, analyzer clean, marker PRODUCTION_GREGORIAN_BOUNDARY_PASS and prior applicable regressions at exact SHA. Preserve logs; no acceptance from queued/failed runs. Not a production release or acceptance of modern date calculation.
