# Stage25/DISCOVERY22 — cross-axis ±5778 / ±1 real-date five-field differential

## Verified predecessor and novelty
Stage24 was accepted bounded on exact SHA `ec55ed9f17141f354b003658c496ace512dab265`, automatic push CI [41869345911](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41869345911): 26/26 completed/success, verify and GNAT13 Native job 126711826529, markers 139/131/125, 25 unique ordered real-date pairs.

Let F=Foundation_Day. Test all 25 row-major ordered pairs (F+c,F+t) with each offset in {-5778,-1,0,+1,+5778}. Prior matrices: Stage15 {-1,0,+1}²; Stage16 {-31,-7,0,+7,+31}²; Stage17 calculation {-1,0,+1}, target {-5779,0,+5779}; Stage18 axes transposed; Stage20 {-5779,-31,0,+31,+5779}²; Stage21 {-5779,-5778,+5778,+5779}²; Stage22 {-5778,-31,0,+31,+5778}²; Stage23 {-5779,-7,0,+7,+5779}²; Stage24 {-5778,-7,0,+7,+5778}². Stage19 is a subset of Stage20. Exactly eight ordered crossings ±5778×±1 and ±1×±5778 are new. Stage15 must be counted or the four ±1×±1 previously tested corners would falsely appear new. Seventeen other pairs are regression coverage. No defect is presumed.

## Exact checks and oracle
Invoke public Ada Calendar_Date on each pair and compare all five numeric fields year, cutlet, cutlet_day, month, month_day with the independently source-derived Stage14 Python oracle; never derive expected numbers from Ada logs or foreign branches. Domains: 4900..5100, 1..17, 1..5778, 1..47, 1..123. Fixed center anchor (5000,10,503,30,52); repeat pivot (F-5778,F+1). No monotonicity assumption.

- Python: 1 cardinality/uniqueness, 1 exact novel-pair coverage, 2 axis norms, 125 field domains, 5 pivot repeats, 5 center anchors = **139 assertions**.
- Native Ada: 125 domain controls +5 repeat equalities +1 center-year = **131 assertions**.
- Strict comparator: exactly 25 unique ordered expected pair records, reject missing, extra, malformed or duplicate keys or marker; **125 numerical scalar equalities**.
- Bounded Python preflight 180s, GNAT Native executable 600s, Python comparison 180s, CI job 15 minutes. Nonzero failure exit on error.

## Acceptance — PENDING
Require exact-stage-SHA automatic push CI **completed/success in 27/27 jobs**, including verify and native-stage25-limit-one, GNAT13 compile/bind/link and markers:
`STAGE25_INDEPENDENT_LIMIT_ONE_SELFTEST_ASSERTIONS=139`
`STAGE25_NATIVE_LIMIT_ONE_ASSERTIONS=131`
`STAGE25_REAL_FIVEFIELD_SCALARS=125`
Static QA, queued or in_progress CI do not establish Native PASS. No main/merge/publication.
