# Dart+עברית — Stage 2 / PRODUCTION14 — §V full-year ordered weave

PROJECT_ID: PC-BRANCH-DART-HEBREW
BRANCH: Dart+עברית only. No main, merge, release or publication.
PRECONDITION: Discovery13 accepted only with exact source SHA cf70f3c09f10245ec35bc361141bc28ec1051df1, GitHub run 42125147383 completed/success 17/17; Discovery13 job 127587299557 marker checks=6031, suffix_states=5962, rank_cases=37, canonical_anchors=3, format 0 changes, analyze 0 issues.
NORMATIVE SOURCE: main README §V (first/last month occurrences in ID order; all eligible words lexicographic; bowl 4, seal 32). §§W–X remain outside this stage.
STATUS: candidate, NOT ACCEPTED until a completed exact-SHA GitHub Actions Native PASS.

## Exact algorithm and invariant

For a legal prefix, let b=closedUpTo, a=openedUpTo, A the number of remaining occurrences in the active colors b+1..a, and U the untouched counts of colors a+1..m. Let B(c) be the number of active-only words with ordered last occurrences for active count vector c.

For active colors c_1..c_k, prefix sums S_j, B(c)=product over j=2..k of binom(S_j-1,c_j-1). Empty or singleton active group has B=1. For active candidate j, the new base B_j is:
- j=1: B*product over i=2..k of S_(i-1)/(S_i-1), valid even when c_1=1 and it closes.
- j>=2 and c_j>1: B*(c_j-1)/(S_j-1)*product over i=j+1..k of S_(i-1)/(S_i-1).
- j>=2 and c_j=1: invalid, because it would close out of ascending last-occurrence order.

These rational expressions are evaluated with exact BigInt products and integer division. The quotient is an integer because it equals the count of combinatorial words after one legal token. Prefix sums and backward numerator/denominator products give all active B_j in O(k) arithmetic operations.

For any fixed legal active-only suffix word with A tokens, there are exactly H(A,U) ways to insert the unopened colors, independent of the internal word order. The insertion recurrence accepted in Discovery13 computes H by treating the A-token active word as one synthetic already-opened color. Hence every active child has one and the same factor H(A-1,U), and its lexicographic block size is B_j*H(A-1,U). The factor is computed at most once per day, and is 1 after all colors have been opened. If a new month is opened, it is always the highest next eligible ID; its block is the remaining rank after subtracting all active blocks, so no extra H query is required. The new active-only base is B*binom(A+k-1,A) when k occurrences remain after its first token (with explicit k=0 handling). A zero-active prefix takes its one legal next opener directly.

This method stores one O(m) active vector plus the bounded Discovery13 insertion DP of O(L) memory, with m<=47 and L<=5778. It does not enumerate all words, allocate a multidimensional state cache or cap the unrank at 24 days. The first or only lexicographic option when rank=1 avoids an unnecessary expensive H query.

## Inputs and outputs

- Static input: positive month lengths, 1<=m<=47, total<=5778; one-based rank in [1,countWholeWeaves(lengths)]. Output immutable list of exactly L month IDs in [1,m], with exact multiplicities and strictly increasing first and last occurrence positions.
- Canonical input: accepted §R year, §U month length plan and calculation day c. Compute the same (c,firstDayOfYear) work and bowls already specified by §§C–N; use bowl 4 seal 32, modulus countWholeWeaves(lengths), and static unrank to choose the complete §V weave. Output exact domain count, MonsterEqualChoice and immutable month ID list.
- No implicit §W naming or §X five-component results.

## Independent tests and acceptance

1. Independent oracle enumerates all ordinary multiset permutations of eight small inputs, checks first/last appearance order only at the leaves, and compares every accepted lexicographic rank against production. At least 20 independent exact ranks.
2. Boundary refusals for rank=0, rank>domain and zero-length month.
3. Two full 5778-day synthetic cases (47 months, lengths [120,123*46]) at first and last rank; verify exact length, every multiplicity, first/last ID order and one independently constructed contiguous first word. The combined two-case runtime must be <=240 seconds, measured using Native Stopwatch.
4. Canonical foundation-day §R + §U anchor through bowl 4/seal32, check exact selection modulus and valid full weave.
5. Complete branch regression CI. Only accept when all 18 jobs on one exact SHA are completed/success, Dart 3.13.2 formatter 0 changed, analyzer reports no issues, and job prints PRODUCTION14_WEAVE_PASS with independent_ranks>=20, full_year_cases=2, canonical_anchors=1, full_weave_ready=true.

If CI fails, inspect the precise job and reproduce a demonstrated defect. queued/in_progress are neither a blocker nor PASS. NEXT after acceptance: §W canonical month-name sequence via bowl 5 seal33; then §X final five-component calendar output.
