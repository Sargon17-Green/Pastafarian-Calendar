# Stage19 DISCOVERY16 — joint wide-axis real-date differential (accepted, bounded)

## Verified predecessor
Stage18/DISCOVERY15 was accepted for its *bounded nine-pair scope* on exact SHA b46abde0c596e0ffc85fe24bb71bd2a4808d32c7. GitHub Actions run 41523605711 completed/success 20/20, including verify and native-stage18-wide-calibration; GNATMAKE 13.3.0 compiler, gnatbind-13 and gnatlink-13 executed; log markers observed: independent=53, native=51, five-field numerical=45. No general proof or newly discovered defect is claimed.

## Why
Stage17 tested Calculation_Day offsets {-1,0,+1} against Target_Day offsets {-5779,0,+5779}. Stage18 tested the orthogonal arrangement. The four noncentral corners where *both* inputs have distant offsets remain uncovered. Stage19 covers all corners using a bounded 3x3 grid; five of nine input pairs were already covered by Stage17/18 and four are new. This is coverage discovery, not historical bug evidence.

## Exact contract and independent oracle
For Foundation_Day F, enumerate exactly nine ordered pairs (F+a, F+b) in deterministic row-major order with a,b each from {-5779,0,+5779}. Feed every pair to the public Ada Calendar_Date API; compare the five output components separately to the Stage14 source-derived independent Python numerical oracle, never to a copied Ada fixture. Require nine unique input pairs and exactly 45 numerical scalar equalities. The field tuple is (year, cutlet, cutlet_day, month, month_day); domain bounds: year 4900..5100; cutlet 1..17; cutlet_day 1..5778; month 1..47; month_day 1..123. At the center pair (F,F) require the known golden tuple (5000,10,503,30,52) in the Python oracle, center year 5000 in Ada, and deterministic repeat of all five Ada fields. No monotonicity assumption on either input axis.

## Test and acceptance gates
Python: 9 pairs x 5 field-domain assertions + 5 golden center equalities + 3 deterministic recalculation checks = 53 independent oracle selfchecks.
Ada GNAT observer: 9 x 5 field-domain assertions + 1 center-year anchor + 5 repeated field checks = 51 Native assertions.
Numerical comparator: exactly nine unique row-major input pairs from Ada output, exactly one valid marker, 9 x 5 = 45 independent field comparisons; reject malformed, missing, extraneous and duplicate inputs.
Execution limits: Python selftest <=180s; native GNAT observer <=600s; Python differential <=180s; Actions job <=15min.
Acceptance only after push CI on the exact committed SHA is completed/success across **all** jobs including verify and native-stage19-joint-wide, GNAT 13 compile/bind/link observed, and exact markers:
- STAGE19_INDEPENDENT_JOINT_SELFTEST_ASSERTIONS=53
- STAGE19_NATIVE_JOINT_WIDE_ASSERTIONS=51
- STAGE19_REAL_FIVEFIELD_SCALARS=45

Stage19 ACCEPTED for exactly nine ordered pairs, run 41536457335 completed/success 21/21 at 39207ca0f8c22eef36f0035b207c9d1d446dcd1d; job 125589408198 GNATMAKE13.3.0 compile/bind/link, and exact markers 53/51/45 observed. This is bounded acceptance; no universal proof. Changes restricted to Ada+తెలుగు; no main, merge or release.
