# Stage20 DISCOVERY17 — 5x5 joint mixed local/remote differential (open)

## Verified predecessor and gap
Stage19/DISCOVERY16 at 39207ca0f8c22eef36f0035b207c9d1d446dcd1d accepted bounded nine-pair grid: GitHub Actions 41536457335 completed/success 21/21 including verify and native-stage19-joint-wide. GNATMAKE13.3.0 compile/bind/link and markers independent=53, Native=51, numerical=45 were observed in job 125589408198.
Stage19 used both axes {-5779,0,+5779} relative to Foundation. Stage16 used both axes {-31,-7,0,+7,+31} near Foundation. Stage20 is a *mixed* five-by-five matrix, exercising both remote and local axes together. Relative to Stage19, 16 of the 25 matrix cells are new; this stage claims coverage extension, not a known defect.

## Contract
F=Foundation_Day. Enumerate row-major (Calculation_Day, Target_Day) pairs (F+a,F+b) for a,b in {-5779,-31,0,+31,+5779}. Exactly 25 unique ordered input pairs. Call the public Ada Calendar_Date API with each pair. Extract and compare precisely five numerical fields: year, cutlet, cutlet_day, month, month_day, against the established independent Stage14 source-derived Python oracle, without deriving expected values from Ada outputs.

## Invariants, limits and counts
Python independent selftest: 25*5=125 field domain checks + five golden center comparisons (5000,10,503,30,52) + five deterministic center-target recalculations = 135 assertions.
Ada GNAT observer: 25*5=125 domain assertions + one center-year assertion + five repeat-field checks = 131 assertions.
Comparator: exact 25 unique pair set and only one Native assertion marker, no malformed/duplicate/missing/extra pairs; 25*5=125 scalar field equality checks.
Domain constraints: year 4900..5100; cutlet 1..17; cutlet_day 1..5778; month 1..47; month_day 1..123. Do not assume monotonicity in either input axis. An observed failure must be diagnosed before assigning a historical bug cause.
Budget: Python selftest <=180s, native executable <=600s, independent comparator <=180s, Actions job <=15 min.

## Acceptance gates (not yet met)
Only completed/success push CI on the exact new commit SHA; all 22 jobs including verify and native-stage20-joint-sparse; GNAT13 compile/bind/link evidence; and exact log markers:
- STAGE20_INDEPENDENT_JOINT_SPARSE_SELFTEST_ASSERTIONS=135
- STAGE20_NATIVE_JOINT_SPARSE_ASSERTIONS=131
- STAGE20_REAL_FIVEFIELD_SCALARS=125

No acceptance while queued/in_progress, no duplicate manual dispatch, no modification to main, no merge or publication.
