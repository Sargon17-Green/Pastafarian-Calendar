# Dart+עברית — Stage7 accepted, bounded §V optimization follow-up

PROJECT_ID: PC-BRANCH-DART-HEBREW
BRANCH: Dart+עברית
MODE: Design and executable acceptance contract; **no algorithm change, no new stage, no release or merge**.
SOURCE_LOCK: 51d567f61fb5c7ff6d746af70c7925d3b79217ff
SOURCE_WEAVE_PLANNER_BLOB: f17150c66d2d601715a2a9c13df9ea7e7e690bcd
SOURCE_WEAVE_COUNTER_BLOB: 5e2321a4c9d00701f2968f2c7dbfc5d5e7c02446

## Completed evidence, not a new CI claim

Natural push https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44799781808
is completed/success, attempt 1, exact SOURCE_LOCK SHA, 26/26 jobs completed/success.
- Stage7 job 136508604286, Dart 3.13.2, format 1/0, analyze clean:
  STAGE7_HOTPATH_PASS checks=13150, year_days=4244, month_count=45,
  full_year_words=3, small_domains=1, small_ranks=2, canonical_case=1,
  phases=4, algorithm_unchanged=true. Timings in ms: COUNT=329, FIRST=337,
  LAST=8813, CANONICAL=13980, TOTAL=23463 (limit 180000).
- Stage6 job 136508604159: 18 checks, six phases, retained_sum_ac1=true;
  YEAR=130, CUTLETS=34, LENGTHS=11, WEAVE=12230, NAMES=3,
  PROJECTION=1, TOTAL=12416ms.
- Stage1 job 136508604322: global format 47/0, analyze clean, tests PASS.
- Production16 job 136508604638: checks=391, synthetic_cases=36,
  canonical_anchors=3, PRODUCTION16_CANONICAL_TIME_MS=42223.
- Discovery17 job 136508604566: checks=31072, raw_words=304920,
  valid_words=11002, rank_probes=268, projection_cases=3417,
  rejections=32, synthetic_time_ms=145; verify job 136508604133 PASS.
These are *native CI observations* for SOURCE_LOCK. No rerun is requested
for already accepted evidence. A documentation-only commit does not
constitute a new native acceptance on its own.

## Diagnosis and bounded first change

The two expensive Stage7 measurements are LAST and CANONICAL:
(8813 + 13980) / 23463 = 97.1% of observed total.
Stage6 independently attributes 12230/12416 = 98.5% to WEAVE.
These are single-run, noisy observations, not measured speedups.

Current lib/src/monster_month_weave_planner.dart has a mechanically
redundant exact count in the canonical path:
1. plan() calls MonsterMonthWeaveCounter.countWholeWeaves(lengths.lengths),
   required for bowl 4, seal 32 modulus.
2. plan() passes choice.result to unrankFull(), which computes
   countWholeWeaves(monthLengths) again before validating the rank.
The direct isolated COUNT time was 329ms; it does NOT imply a guaranteed
329ms savings or resolve the dominant per-day unrank cost.

Candidate A (smallest production-safe change, NOT implemented here):
- Extract a private _unrankWithKnownTotal(monthLengths, rank, total).
- Preserve public unrankFull(monthLengths, rank) and its exact count,
  rank validation, errors, immutable return and one-based lex semantics.
- Pass the already computed positive total from plan() into the private
  helper. Do not change the source of choice.result, bowl=4, seal=32,
  arithmetic of the active children, or the suffix oracle.
- This is a precisely bounded deduplication, not a new weave algorithm.
- Prove, by instrumenting a QA-only counting wrapper or equivalent,
  that the canonical path performs one whole-domain count instead of two;
  do not infer this from timing alone.

Candidate B (research only; NO implementation before measurement):
- Attribute calls and elapsed time inside
  _unopenedFactor -> countCompletions and _activeChildren, including
  call count, (opened, activeLength) histogram and expensive BigInt
  distributions, without altering semantics.
- If repeated expensive suffix states are measured, test a bounded exact
  memo keyed by all values on which countCompletions depends, not only
  opened or active length. Limit cache bytes/entries, quantify hit rate,
  and require identical exact BigInt counts. No unbounded cache.
- Otherwise use a mathematical recurrence with an independently proven
  invariant and test every child count exhaustively on small domains.
  Do not speculate that memoization will help within one full-year word.

## Independent correctness oracle and boundaries

QA outside Dart (2026-11-20): simple multiset enumeration, checking
ascending first and last occurrences ONLY at completed leaves, yielded:

  lengths    admissible count    lex first         lex last
  [2,2,1]    2                   11223             12123
  [2,2,2]    5                   112233            123123
  [3,2,2]    9                   1112233           1231123
  [2,3,2]    11                  1122233           1232123
  [1,2,2]    2                   12233             12323
  [3,3,2]    26                  11122233          12321123

These results are an independent *non-Native* oracle, not a Dart PASS.
Translate into tests that exhaustively compare count and EVERY one-based
rank (55 words total) against baseline and changed production code.
For each fixture, verify rank 0 and count+1 reject; preserve type and
unmodifiable output semantics. Verify input immutability and invalid
month-count/day-length limits explicitly.

Full-domain regression:
- Canonical foundation = -15055671, year 5000, zero transitions,
  45 months, 4244 days, preserved §U lengths and §V bowl4/seal32.
- Preserve bit-for-bit output of FIRST, LAST, CANONICAL and exact count
  from SOURCE_LOCK; capture a baseline SHA-256 of each full word
  *before* editing production code (not invented in this document).
- Independently validate exact multiplicities and strictly ascending
  first/last occurrence positions for each full word.
- Retain Production16's 3 normative AC.1 anchors, 36 synthetic dates,
  five immutable calendar fields and existing Hebrew public API.
  A hash match alone is insufficient as an independent oracle.

## Measurement and release gates

- No new dependencies, no main/merge/release, no changes to canonical
  sources or the accepted §V selection contract.
- A candidate may be committed only to Dart+עברית, after verifying
  current HEAD and exact baseline blobs. Do not revert newer HEAD to
  SOURCE_LOCK if the branch has advanced.
- For production changes, add focused tests and a natural CI job only
  if warranted. Gate: completed/success all jobs at candidate SHA,
  Dart 3.13.2 format 0 changed, analyze 0, accepted Stage1/3/4/5/6/7,
  P16, D17 and verify pass. Do not accept queued/in_progress as PASS.
- Full-domain canonical/first/last exactness and AC.1 invariants are
  mandatory; compare five paired baseline/candidate measurements on the
  same OS/SDK class, publish medians and raw timings. Performance targets
  are observations, not grounds to weaken correctness.
- Preserve Stage7 <=180000ms, Stage6 <=120000ms, P16 <=240000ms,
  D17 <=90000ms; report any regression rather than hiding it.
- If Candidate A yields only marginal improvement, stop and instrument
  Candidate B first; no speculative rewrite of the entire combinatorial
  engine.

NEXT: implement Candidate A with exhaustive oracle and baseline hashes,
then obtain evidence from the naturally triggered CI for its NEW SHA.
