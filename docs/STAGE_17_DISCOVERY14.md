# Stage17 DISCOVERY14 — cross-year numerical five-field differential (open)
## Predecessor
Stage16/PATCH01 accepted at 07974c96a29b4f3af89a716b88a94b3459368558 with 18/18 jobs on run 41408897365; exact markers 135/131/125. The Stage16 window ±31 days produced only year 5000, leaving neighboring-year transitions untested.
## Contract
Use exactly nine ordered (Calculation_Day,Target_Day) pairs in row-major order, with Calculation_Day=Foundation_Day+{-1,0,+1}, Target_Day=Foundation_Day+{-5779,0,+5779}. YEAR_LIMIT=5778, so the extremes must fall outside year 5000 for each calculation day. Output the complete public Calendar_Date tuple of five scalars. No claimed defect and no copy from other branches.
## Oracle and counts
Stage14's pre-existing source-derived independent Python model computes expectations without using Ada logs: new test scope, not a new independent algorithm. Python preflight 9*5=45 domain +6 year-direction +5 center golden +3 repeat =59. Ada observer 45 domain +6 year-direction +1 center year +5 center repeated fields =57. Comparator parses exactly nine unique native tuples and checks 9*5=45 exact scalars. Bounds: year 4900..5100, cutlet 1..17, cutlet-day 1..5778, month 1..47, month-day 1..123; earlier/later year directions are strict.
## Acceptance
All CI jobs including verify and native-stage17-year-crossing completed/success on exact SHA; GNAT13 compile/bind/link, markers STAGE17_INDEPENDENT_CROSSYEAR_SELFTEST_ASSERTIONS=59, STAGE17_NATIVE_YEAR_CROSS_ASSERTIONS=57, STAGE17_REAL_FIVEFIELD_SCALARS=45. Python selftest and comparator each bounded to 180s; native observation 600s; CI job 15 minutes. No main/merge/publish or universal correctness claim.
