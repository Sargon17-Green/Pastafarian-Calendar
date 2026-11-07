# Dart+עברית — Stage 2 / PRODUCTION16 — §X complete calendar date

PROJECT_ID: PC-BRANCH-DART-HEBREW
BRANCH: Dart+עברית; no main, merge, protected-branch write or release.
PRECONDITION: P15 accepted at de9114343521c2d50afc0bc3409e0555fe668d12 with https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42250557965 19/19 completed/success; job 128004194225: PRODUCTION15_NAMES_PASS checks=1077 brute_domains=17 independent_ranks=804 canonical_anchors=1 names_ready=true. Dart SDK 3.13.2 format/analyze clean.
SOURCE: normative main README §X and retained-sum table AC.1, not the superseded rawBowlSum table AC.2.
STATUS: Candidate only pending fresh Native CI.

## Deterministic contract
Input: BigInt (calculationDay c, requestedDay t), with bounded §R year traversal max 64 transitions. Find exactly one §R year from year5000(c); resolve only the forward NEXT11 or backward PREVIOUS12 path; all year-structure components §S–T, §U, §V, §W use fixed sauce (c, year.openGate+1). Compose without re-ranking the selected components.

Output: immutable (yearNumber, cutletCanonicalIndex, dayInCutlet, monthCanonicalIndex, dayInMonth), with Hebrew strings retrieved from SourceLanguageCatalog. Cutlet day is t-cutlet.openGate; §V month ID comes from weave[t-openGate-1]; month day is the INCLUSIVE count of this ID from the start of year through that day, including interleavings, not elapsed days since its first appearance.

Validate strict (openGate,closeGate] containment, total span, month lengths 4..123, exact month-ID multiplicities and first/last appearance order, 3..47 distinct names, 1..17 contiguous named cutlets, and text/catalog consistency. Pure projection accepts small synthetic years for independent testing only. Full calculate() uses the existing exact selectors; no cache, approximation, or algorithm change. Projection time O(L+m+k), memory O(m), max L=5778; stage-wide total time includes upstream selectors.

## Independent oracle and gate
- Three independent 12-day synthetic weaves (6 two-day cutlets, 3 four-day months), 36 daily projections, 10 checks per day: derive cutlet by independent fixed interval arithmetic and month day by fresh inclusive prefix enumeration; verify immutable numeric tuple and locked Hebrew text.
- Five refusal cases: year opening/after closing, duplicate names, month length below four, wrong weave multiplicity.
- Three full normative AC.1 vectors for c=Foundation, t=F-1,F,F+1: (5000,10,502,32,21), (5000,10,503,20,56), (5000,14,1,29,38) respectively; ≤240 seconds cumulative canonical time. These outputs come from normative data, not production code or another branch.
- Fresh auto-push Native workflow: completed/success 20/20 jobs, Stage1 and P16 Dart 3.13.2 formatter 0 changed/analyze 0; P16 marker PRODUCTION16_DATE_PASS checks>=380 synthetic_cases=36 canonical_anchors=3 five_component_calendar_ready=true. Read exact job log and SHA before accepting Stage2 milestone.
- On failure patch only evidenced defect, never manually duplicate an automatic CI run. No main/merge.
