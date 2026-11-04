# Dart+עברית — Stage 2 / DISCOVERY13 — §V count of ordered month weaves

PROJECT_ID: PC-BRANCH-DART-HEBREW
BRANCH: Dart+עברית only; no main/merge/publication.
PRECONDITION: Production12 §U accepted. GitHub Actions run 41786715714 on commit 4af951d0161697aab150e453ceffb1217e3ebbea completed/success, all 16 jobs success; P12 job 126430421902: PRODUCTION12_MONTH_LENGTHS_PASS checks=448, brute_domains=30, boundary_cases=4, canonical_anchors=3; Dart 3.13.2 format 0 changed, analyzer no issues.
NORMATIVE_SOURCE: main README §V: fixed ordered length vector, first occurrences of months in ascending ID order, last occurrences also in ascending ID order, lexicographic full weave choice from bowl4 seal32. §W names and §X final date explicitly remain closed.
MODE: Discovery count-only plus bounded rank exploration. Does not claim full-year weave selection.

## Independent algorithm / proof

Let r_i be remaining occurrences in a legal prefix, a the highest opened month, and b the highest closed month, with 0<=b<=a<=m. Months <=b have zero remaining; all later months have positive remaining. The active colors b+1..a had their first occurrences in the prefix, so only their *last* occurrences remain constrained. The unopened colors a+1..m must satisfy both ascending first and ascending last occurrences within the suffix.

To count suffixes, start with active colors only, inserting each next color into gaps of the previous word while forcing at least one copy into its final gap. The multiplicative factor for k new copies and N old tokens is C(N+k-1,N), exact BigInt. If there is no active color, start from a single monochromatic word of length r_{b+1} with first position 1.

Insert the first unopened color with no first-occurrence restriction relative to active colors (their first occurrences are already in the consumed prefix). For every later unopened color, require the first new occurrence strictly after the first occurrence of the previous unopened color. Track only the first position p of the greatest new color: for an insertion after r old tokens, its new first position is r+1. The number of distributions forcing the new color's final occurrence after all old colors, and choosing its first occurrence after r old tokens, is W(N-r)=C(k+N-r-2,N-r) for k>=2 (when k=1 only r=N is allowed). Use prefix sums of existing p-distribution to enforce first-occurrence order. Each insertion requires O(N) BigInt arithmetic, with O(N) live memory. No recursion on the multidimensional count vector, no exponential materialization, no borrowed production code.

A bounded discovery unrank applies lexicographic prefix-block counting by calling the exact suffix counter after each legal next color; it refuses input longer than 24 days. Canonical length vectors of 252..5778 days are **not** unranked by this discovery API. It is not full §V implementation.

## Independent oracle / acceptance

- Native Oracle A: recursive next-letter enumeration of all legal suffixes for m=1..5, synthetic remaining counts 1..3, 0<=b<=a<=m, suffix length <=11, excluding the vacuous already-completed state. Exactly 5,962 distinct state comparisons. Oracle does not use insertion combinatorics.
- Native Oracle B: complete independent lexicographic recursive enumeration of eight small count vectors and comparison against every bounded discovery rank. At least 30 exact rank checks.
- Validation: reject invalid state, invalid/zero rank and rank scope above 24 days; count completed suffix as 1; count 47 months of 4 days each exactly as BigInt >2^127.
- Canonical count-only: three calculation-day anchors Foundation±1 and Foundation. Use proven §R years and independently accepted §U lengths; verify that each has at least one full eligible weave. No global unrank or seal32 applied.
- Acceptance only if new CI at the exact Git SHA finishes all 17 jobs completed/success, Dart 3.13.2 format 0 changed, analyze zero issues, and DISCOVERY13_WEAVE_COUNT_PASS checks>=6000 suffix_states=5962 rank_cases>=30 canonical_anchors=3 count_only_ready=true full_weave_ready=false. queued/in_progress is not PASS.

NEXT after accepted discovery: design and implement scalable full-year lexicographic unranking with bowl4 seal32, using prefix-count caching or a more efficient proven method and independent small exhaustive oracle plus bounded large-case runtime; no claim of completed §V until Native CI confirms. Then §W select 47 distinct names by canonical index with bowl5 seal33; §X final five fields vs independent OracleEngine.
