# Dart+עברית — Stage7 / DISCOVERY05 — §V hotpath attribution

PROJECT_ID: PC-BRANCH-DART-HEBREW
BRANCH: Dart+עברית
MODE: Branch-only profiling and independent QA; no production algorithm change.
STATUS: Candidate, NOT ACCEPTED until completed Native CI/log evidence.
PARENT: 1186284527f7a6b7142c44bf5ad7ee60a0acebf2

## Accepted prerequisite, not a claimed optimization

Stage6 natural push 44715408267 completed/success 25/25 at parent;
Stage6 job136217433151: 18 checks, canonical_anchors=1, phases=6,
retained_sum_ac1=true, formatter 1/0, analyzer clean, total 15386ms.
YEAR=173, CUTLETS=15, LENGTHS=14, WEAVE=15175, NAMES=4,
PROJECTION=1 ms. Weave is 98.6% of this one observed profile.
Stage1 46/0, Stage5 65 checks, Stage4 62, Stage3 16,
P16 391/36/3, D17 31072/raw304920/valid11002; verify success.
No speedup is claimed from a single run.

## Engineering question and independent oracle

Separate accepted §V production's full-domain count from its unrank work.
Input is immutable canonical foundation -15055671 (year 5000), zero
transitions, and the existing canonical §U month-length vector.

Time COUNT=exact countWholeWeaves once, FIRST=unrankFull(rank 1),
LAST=unrankFull(last rank), CANONICAL=planner.plan with real bowl4/seal32.
UnrankFull itself includes an initial exact count: the test explicitly
does NOT subtract it from FIRST/LAST. Timings are descriptive and not
a head-to-head performance claim. Output each nonnegative phase duration
and total in integer milliseconds, all measured in one process.
Bound the aggregate measurement to 180000ms.

Independent oracle for [2,2,1]: enumerate ordinary multiset words in
lexicographic order; filter first and last occurrence orders at leaves.
Compare count and every rank against production. For the full year,
independently validate each of the three resulting words by day,
multiplicities, and both occurrence orderings, verify literal lexicographic
first, exact >127-bit count, canonical rank/modulus and accepted year.

## Acceptance contract

One new Native job dart-hebrew-stage7-weave-hotpath on natural push;
Dart 3.13.2, no new dependencies, format test file 1/0 changed, analyzer
No issues, executable terminates zero. Require:
- STAGE7_PHASE_{COUNT,FIRST,LAST,CANONICAL}_MS integer >=0
- STAGE7_TOTAL_MS integer <=180000
- STAGE7_HOTPATH_PASS checks>=17000, full_year_words=3,
  small_domains=1, small_ranks>=1, canonical_case=1, phases=4,
  algorithm_unchanged=true
- Stage1 now formats 47/0 with clean analyzer/tests
- Stage6 retains 18/1/6 and total<=120000, Stage5/4/3, P16, D17,
  verify remain successful; exact natural run completed/success 26/26.

Any failure requires its own completed log and proven repair. No manual
duplicate dispatch, main, merge, release or production optimization before
Stage7 evidence differentiates the hotpath.
