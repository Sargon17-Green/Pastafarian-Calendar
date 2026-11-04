# Stage23 DISCOVERY20 — cross-axis 5779-day and 7-day five-field differential (accepted: bounded)

## Verified predecessor and uncovered scope
Stage22 exact SHA c3f26a380585133ce931ab6965f337d2a64903a9, push run 41712444973, completed/success 24/24 including verify and native-stage22-limit-mixed job 126183680869; GNAT13 compile/bind/link and 138/131/125 markers observed.
Stage16 covers local offsets {-31,-7,0,+7,+31} on both axes; Stage20 covers {-5779,-31,0,+31,+5779} on both. Stage21 and Stage22 add ±5778 but do not cross ±5779 with ±7. Stage23 adds exactly eight previously uncovered ordered pairs: (-5779,-7), (-5779,+7), (+5779,-7), (+5779,+7) and their coordinate transposes (offsets from Foundation). No defect is presumed.

## Exact contract
Set F=Foundation_Day. Calculation_Day and Target_Day independently use offsets {-5779,-7,0,+7,+5779}; test the row-major Cartesian product (25 distinct ordered pairs). Call public Ada Calendar_Date. Compare year, cutlet, cutlet_day, month and month_day against Stage14 independent source-derived Python oracle, never values manufactured from Ada or a different branch.
Field domains: year 4900..5100; cutlet 1..17; cutlet_day 1..5778; month 1..47; month_day 1..123. Do not assume monotonicity.

## Independent checks and limits
- Python selftest: 1 pair cardinality/uniqueness, 2 axis magnitudes, 25*5 field domains, five repeated-pivot comparisons at (F-5779,F+7), five center anchor comparisons (5000,10,503,30,52): exact 138.
- Ada Native: 25*5 domain assertions, 5 repeated-pivot field comparisons and 1 center-year anchor: exact 131.
- Strict comparator: exactly 25 expected unique pairs, one native count marker, no duplicate/missing/malformed/extra pair records, 25*5 exact numerical scalar comparisons: 125.
- Python selftest timeout 180s; Native execution 600s; comparator 180s; GitHub job <=15min.

## Acceptance gate (satisfied on the exact SHA)
Require a completed/success **push** run for the exact new Stage23 commit, 25/25 completed/success jobs including verify and native-stage23-remote-seven; observe GNAT13 compile/bind/link and exact markers:
STAGE23_INDEPENDENT_REMOTE_SEVEN_SELFTEST_ASSERTIONS=138
STAGE23_NATIVE_REMOTE_SEVEN_ASSERTIONS=131
STAGE23_REAL_FIVEFIELD_SCALARS=125
Do not claim PASS for a queued/in_progress run, duplicate manual dispatch, change main, merge or publish.

## Acceptance evidence — 2026-11-04
Exact commit `4fe6f92f47d0321456d17b284f471a7210dfeee0`: automatic push CI [41775736259](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41775736259) completed/success, 25/25 jobs (including verify and native-stage23-remote-seven, job 126395532007). Inspected Native log: GNATMAKE 13.3.0, gcc-13, gnatbind-13, gnatlink-13; observed 138 independent Python assertions, 131 Ada Native assertions, 125 exact five-field scalar comparisons and 25 distinct ordered input pairs. Acceptance is limited to the explicit 25-pair matrix; no universal correctness claim.
