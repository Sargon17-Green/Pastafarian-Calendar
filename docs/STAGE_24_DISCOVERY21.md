# Stage24 DISCOVERY21 — cross-axis 5778-adjacent and seven-day five-field differential (accepted: bounded)

## Verified predecessor and uncovered scope
Stage23 exact SHA 4fe6f92f47d0321456d17b284f471a7210dfeee0, automatic push CI 41775736259 completed/success 25/25 including verify and native-stage23-remote-seven job 126395532007. GNAT13 compile/bind/link and exact independent/native/five-field counts 138/131/125 observed; 25 ordered pairs.
Earlier matrices include Stage16 {-31,-7,0,7,31}², Stage20 {-5779,-31,0,31,5779}², Stage21 {-5779,-5778,+5778,+5779}², Stage22 {-5778,-31,0,+31,+5778}², and Stage23 {-5779,-7,0,+7,+5779}². No prior matrix covers the eight ordered crossings of ±5778 and ±7. Stage24 covers these eight new pairs, plus 17 repeated coverage pairs to detect regressions. No defect is presumed.

## Exact contract
Let F=Foundation_Day. Use calculation-day offsets {-5778,-7,0,+7,+5778} and independently target-day offsets {-5778,-7,0,+7,+5778}; iterate Cartesian product row-major: 25 unique ordered real-date pairs.
Invoke the public Ada Calendar_Date and independently compare the five fields year, cutlet, cutlet_day, month, month_day against the existing Stage14 Python source-derived mathematical oracle; do not use values transcribed from Ada or any other development branch.
Domain checks: 4900..5100 years; cutlet 1..17; cutlet_day 1..5778; month 1..47; month_day 1..123. The fixed center anchor is (5000,10,503,30,52); repeat the pivot (F-5778,F+7). No monotonicity assumption.

## Oracle and test obligations
- Python: 1 cardinality/uniqueness, 1 exact eight-new-pairs coverage-difference test against the stated earlier matrices, 2 axis magnitudes, 125 per-field domains, 5 pivot repeat, 5 center anchor: **139 assertions**.
- Ada Native observer: 125 domain assertions, 5 repeated-pivot equalities, 1 center-year anchor: **131 assertions**.
- Strict differential: exactly 25 expected unique ordered pair records, no malformed/duplicate/unexpected/missing extra pair, exactly one Native count marker, **125 numerical scalar equalities**.
- Python selftest timeout 180 seconds; Ada execution 600 seconds; Python compare 180 seconds; CI job cap 15 minutes. Failure exit nonzero; retained log is printed before comparator.

## Acceptance gate (satisfied on exact SHA)
Push CI on exact Stage24 SHA must be completed/success in 26/26 jobs including verify and native-stage24-limit-seven, with GNAT13 compile/bind/link and:
`STAGE24_INDEPENDENT_LIMIT_SEVEN_SELFTEST_ASSERTIONS=139`
`STAGE24_NATIVE_LIMIT_SEVEN_ASSERTIONS=131`
`STAGE24_REAL_FIVEFIELD_SCALARS=125`
Neither static tests nor a queued/in_progress run establish Stage24 acceptance. No merge, main changes, or publication.

## Acceptance evidence — 2026-11-05
Push CI [41869345911](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41869345911), exact SHA `ec55ed9f17141f354b003658c496ace512dab265`: 26/26 jobs completed/success, including verify and native-stage24-limit-seven job 126711826529. Direct GNAT13 log confirms compilation, binding and linking, Python=139, Ada Native=131, differential scalars=125 and 25 unique real ordered pairs. Acceptance bounded to this matrix.
