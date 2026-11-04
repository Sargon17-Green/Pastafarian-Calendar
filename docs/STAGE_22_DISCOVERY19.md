# Stage22 DISCOVERY19 — mixed local and 5778-adjacent five-field differential (accepted: bounded)

## Verified predecessor and uncovered scope
Stage21 at 1fbe72c5b962569591b7e8fffc9a4124dc22b913, push CI 41617802891, completed/success 23/23 including verify and native-stage21-edge-adjacent job 125855515689. GNAT13 compile/bind/link and exact 88/85/80 markers observed.
Stage20 tested both axes {-5779,-31,0,+31,+5779}; Stage21 tested both axes {-5779,-5778,+5778,+5779}. Neither covered crossing a +/-5778 offset on one axis with {-31,0,+31} on the other. This stage adds exactly 12 previously uncovered ordered pairs. No bug is presumed.

## Exact contract
Let F=Foundation_Day. Both Calculation_Day and Target_Day use offsets {-5778,-31,0,+31,+5778}, row-major Cartesian product = 25 unique ordered pairs. Call the public Ada Calendar_Date API; compare its year, cutlet, cutlet_day, month and month_day against the independently implemented, source-derived Stage14 Python oracle. Never construct expected values from Ada output or another language branch.
Domain checks: year 4900..5100; cutlet 1..17; cutlet-day 1..5778; month 1..47; month-day 1..123. No monotonicity assumption.

## Tests and budgets
- Python: 1 count/uniqueness + 2 axis magnitude-set + 25*5 field-domain + 5 repeat-pivot (F-5778,F+31) + 5 independently verified center anchor (5000,10,503,30,52) = 138 selftest assertions.
- Ada native: 25*5 domain assertions + 5 repeat-pivot + 1 center-year anchor = 131.
- Numerical differential: exactly 25 unique ordered pairs, one valid Native marker, no malformed/duplicate/extra/missing records, 25*5 = 125 exact scalar comparisons.
- Python selftest <=180s; native <=600s; comparator <=180s; GitHub job <=15min.

## Acceptance evidence (bounded)
Exact SHA c3f26a380585133ce931ab6965f337d2a64903a9: completed/success push run 41712444973, 24/24 completed/success jobs including verify and native-stage22-limit-mixed (job 126183680869). Native log observed GNATMAKE 13.3.0, gcc-13, gnatbind-13, gnatlink-13, 25 distinct output pairs and exact markers:
STAGE22_INDEPENDENT_LIMIT_MIXED_SELFTEST_ASSERTIONS=138
STAGE22_NATIVE_LIMIT_MIXED_ASSERTIONS=131
STAGE22_REAL_FIVEFIELD_SCALARS=125
Acceptance is restricted to the stated 25 pairs and is not a universal proof. No main/merge/publication.
