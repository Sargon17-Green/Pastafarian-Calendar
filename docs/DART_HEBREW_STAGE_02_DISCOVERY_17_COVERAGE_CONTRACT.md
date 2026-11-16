# Dart+עברית — Stage 2 / DISCOVERY17 — bounded coverage and performance

PROJECT_ID: PC-BRANCH-DART-HEBREW
BRANCH: Dart+עברית; branch-only, no main/merge/release.
PRECONDITION: P16 §X accepted at 464f15102bf7fb2f213f867453b9157f0880f3b0 (run 43767128751, 20/20); numeric-time QA accepted at 0334c6428cdeed9c0ca0c60e95b3753d7be54707 (run 43938809355, 20/20 completed/success). P16 job 133550466402: PRODUCTION16_DATE_PASS checks=391 synthetic_cases=36 canonical_anchors=3 five_component_calendar_ready=true; PRODUCTION16_CANONICAL_TIME_MS=30116. Stage1 job 133550466408: 41 files/0 changed and analyze clean.
STATUS: Discovery17 candidate, pending its own fresh Native CI; P16 acceptance is not Discovery17 acceptance.

## Independent oracle and deterministic test inputs

QA-only, no §X production changes. Four 3-month length vectors: (4,4,4), (4,5,4), (4,4,5), (5,4,4), spanning 12/13 days, each paired with four contiguous cutlets, fixed distinct Hebrew canonical names and negative BigInt gates. An independent brute algorithm recursively enumerates every multiset permutation in natural index order and only at each completed leaf checks increasing first/last occurrences. It never uses production dynamic programming or unrank to obtain expected values.

Exhaustive expected totals: 304920 raw multiset words; 11002 admissible weaves, split 1301,3499,3101,3101. Per domain choose 67 distinct one-based ranks by deterministic 31-bit LCG seeded 170101+domain*97, including first, rounded-up middle and last. For 268 ranks compare production unrankFull to the independent lex word; for each selected word project every day and independently compute its absolute cutlet, five numeric components and inclusive month occurrence count across interleavings. Exactly 3417 independently checked daily projections, nine assertions each. Separate rejection tests cover bad year bounds, month count, multiplicities, first/last order, name cardinality/indices, cutlet continuity/index/name and rank out-of-range (32 rejections).

## Native test and acceptance contract

New test: bin/stage2_discovery17_coverage_tests.dart.
New marker: DISCOVERY17_COVERAGE_PASS, checks>=30000, raw_words=304920, valid_words=11002, rank_probes=268, projection_cases=3417, rejections=32, canonical_anchors_retained=3. Numeric DISCOVERY17_SYNTHETIC_TIME_MS must be <=90000. Job deadline 8 minutes. Dart SDK 3.13.2 must show scoped format 0 changed, analyze No issues, and clean execution.
Retain existing Stage1/P16 as regression jobs on the SAME SHA. Existing P16 alone must prove its three normative AC.1 anchors, numeric PRODUCTION16_CANONICAL_TIME_MS<=240000 and five_component_calendar_ready=true. Do not repeat full-year canonical computation inside Discovery17.
Accept only after natural push CI run completed/success with 21/21 jobs, including new Discovery17 job, Stage1 and P16 exact logs. queued/in_progress is neither PASS nor blocker.
On failure inspect completed log and fix evidenced issues only. No duplicate manual dispatch, main, merge or publication.
