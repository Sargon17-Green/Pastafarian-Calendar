# Dart+עברית — Stage 2 / PRODUCTION15 — §W canonical distinct month names

PROJECT_ID: PC-BRANCH-DART-HEBREW
BRANCH: Dart+עברית only. No main/merge/release.
PRECONDITION: P14 accepted on exact source e7ab9e15567bad01abcefe87a942cde2b3a528bf, GitHub Actions 42187959358 completed/success 18/18; job 127792714013 prints PRODUCTION14_WEAVE_PASS checks=16146, independent_ranks=40, full_year_cases=2, canonical_anchors=1, full_weave_ready=true, P14 full-year time=26621ms, format 0/analyze 0. Stage1 job 127792713764 success.
NORMATIVE SOURCE: main README §W: select m distinct names from 47 canonical indices, lexicographically ordered by the INDEX tuple, bowl 5, seal 33. Hebrew display text is from SourceLanguageCatalog (source lock). §X final five-component date is out of scope.
STATUS: candidate, NOT ACCEPTED until matching native CI/log evidence.

## Contract and algorithm

- Canonical input: calculation day c, accepted §R year, accepted §U month length vector, accepted §V full-year weave. Validate year span, month count 3..47, weave length and exact ID multiplicities. The sauce for bowl 5 is (c, year.openGate+1); derive work and bowls from that pair, and use seal 33. Domain P(47,m)=47!/(47-m)! computed as BigInt; choose with the standard one-based §N equal mechanism.
- Pure input: population n in 1..47, take k in 1..n, rank r in 1..P(n,k). Select without replacement in increasing canonical index order using ordered surviving indices. At each position, each of n-position candidates has a common suffix block P(n-position-1,k-position-1), so quotient/remainder on one-based r-1 selects the exact lexical branch; never sort Hebrew display strings and never allocate the exponential sequence set.
- Output: immutable m canonical indices and immutable matching Hebrew month names, associated with month IDs 1..m in that order. Never reorder the already accepted §V daily month weave. No §X day tuple, month/day lookup or complete calendar claim.
- Complexity: O(m²) list removal in worst case, O(m) BigInt multiplicative count, O(m) result memory, m<=47. No floating-point or cap on the exact count.

## Independent tests and native acceptance

1. Independent recursive enumeration by bool-used index tracking (no factorials or prefix count blocks) for population 2..6 and take up to 4: 17 small domains, all 804 ranked words in strict lexicographic order checked against production.
2. First/last 47-name ranks, 3-name final tuple, count >2^127, 47-index canonical catalog lock and nonempty display names, zero/out-of-domain rank and out-of-range month count refusals, immutable return list.
3. One canonical §R+§U+§V+§W anchor: verify same year sauce, exact seal33 domain, rank, month count, index uniqueness and Hebrew text, bounded §W plan time <=120s.
4. Complete workflow on one candidate SHA: 19/19 completed/success, Dart 3.13.2 global and job formatter 0 changed, analyzer no issues; job marker PRODUCTION15_NAMES_PASS with checks>=1000, brute_domains=17, independent_ranks=804, canonical_anchors=1, names_ready=true, five_component_calendar_ready=false.

If CI fails, fix only the evidenced defect and rerun by the automatic push trigger. queued/in_progress are not PASS or a blocker. NEXT after acceptance: §X five-component calendar output, independent normative oracle and complete Stage2 gate. No main/merge.
