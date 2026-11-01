# Stage15 DISCOVERY12 — two-dimensional real input differential (open)

## Predecessor
Stage14 accepted on run 41283018346 / SHA 648e3e71720e39dabd3871bf5b6aa970ad210ca4 (16/16 completed/success; 436 reference selftests, 21 GNAT domain/repeat checks, 15 five-field real-date comparisons, 61 synthetic). Stage14 used only Calculation_Day=Foundation_Day.

## Contract and independence
Use calculation days C={Foundation-1,Foundation,Foundation+1} and target days T={Foundation-1,Foundation,Foundation+1}, forming 9 ordered (C,T) pairs. For each pair call the actual public Ada Calendar_Date and emit exactly (cal,target,year,canonical_cutlet,cutlet_day,canonical_month,month_day). Python independently computes the five scalars with the existing self-contained, source-specification-derived Stage14 reference; it does not copy any native output or any other branch. This reuses the independent Stage14 Python algorithm, and is *not* a second independent reference implementation.

Native observer: five field-domain checks for each of nine pairs (45); year-5000 anchor for center pair (1); one extra invocation at center compared on five fields (5). Total 51 GNAT invariants. Python: 9×5 independent-reference domain controls (45), center five scalar established goldens (5), three same-day deterministic repeats (3). Total 53 Python selfchecks. Comparator must parse exactly nine unique pairs with exact pair-set matching and compare all 9×5=45 scalars. A mismatch must identify cal/target/field/Ada/Python and fail.

## Acceptance
Use GNAT 13 compile, bind and link; observer timeout 600 seconds; Python stages each <=60 seconds; job timeout 15 minutes. Require same-SHA completed/success on verify and native-stage15-multi-calibration plus exact markers:
STAGE15_INDEPENDENT_MATRIX_SELFTEST_ASSERTIONS=53
STAGE15_NATIVE_DOMAIN_REPEAT_ASSERTIONS=51
STAGE15_REAL_FIVEFIELD_SCALARS=45
Missing/malformed/duplicate record, timeout, mismatch or nonzero exit means NOT ACCEPTED. Do not conflate Python selftest with GNAT; no main/merge or external publication.
