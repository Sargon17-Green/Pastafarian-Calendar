# DISCOVERY03: independent finite exact count/rank oracle

## Pre-change evidence

GitHub Actions run 41504311343 on source c3a9dbb399b6c39fa60bffe47afdcff9a1301d62 completed. Job verify succeeded. Native Stage 1 through 5 checks succeeded (historical total 318/318). DISCOVERY03: 2518 checks / 0 failures. Cache diagnostics passed, including 6+3 unrank checks. Reachability oracle: 66/66 witnesses passed, exact bound logs agree. The year-boundary Native probe still exited 124 after 180 seconds at STRUCTURE_MONTH_WEAVING_BEGIN. This is INCONCLUSIVE, not a numerical mismatch, not Stage6 PASS and not a newly proven historical Legacy defect.

## Independent model and proof

Month i has L_i > 0 occurrences. Define distinct nodes (i,j), 1 <= j <= L_i. Define the following precedence edges:

- within month: (i,j) precedes (i,j+1);
- first-occurrence order: (i,1) precedes (i+1,1);
- last-occurrence order: (i,L_i) precedes (i+1,L_(i+1)).

Every word satisfying the ordered first and last month appearances specifies exactly one linear extension of this poset. Conversely, any linear extension yields one legal month word. The within-month occurrence number is forced, so this is a bijection, also when a month has only one occurrence. Consequently lexical ranking of legal words is equivalent to choosing available poset nodes in increasing month label order.

## Test-only implementation

New standalone stdlib Python script: test/weaving_small_exact_oracle.py. Method A brute-force enumerates every small multiset word and directly filters the first/last positions. Independent Method B constructs explicit occurrence-poset precedence masks, counts linear extensions with exact-integer subset DP, and performs zero-based lexical rank/unrank. These methods do not import each other or Chapel production code.

The deterministic corpus has 137 distinct length tuples, all with at most 10 total occurrences, including singletons, unequal lengths, zero-based first and last legal ranks, and invalid boundary ranks (-1 and count). Full enumeration predicts 1,982 successful rank/unrank assertions, plus 137 exact count comparisons. Extra identities checked: for two months, choose(L1+L2-2,L1-1); for all lengths equal to 2, Catalan(m) = choose(2m,m)/(m+1). The full 45-month fixture is deliberately excluded.

The exact oracle is invoked before Chapel compilation in test/run_year_boundary_probe.sh. Neither the public date algorithm nor acceptance is modified. An automatic new GitHub run (if triggered by the commit) must be independently assessed at its exact SOURCE_HEAD. Do not treat local Python success as native Chapel success.

## Feasibility boundary and next step

The subset-DP method is an independent finite oracle, NOT the scalable replacement. Its theoretical state bound is 2^N with N=4244 for the actual fixture. The existing Chapel remaining-vector memoizer has a constructive reachable-state lower bound approximately 3.991035906815e87 for that fixture. Neither is a viable big-input implementation. The special all-length-2 family has a Catalan closed form, but this special identity does not establish a solution for arbitrary heterogeneous month lengths or arbitrary prefix rank/unrank.

Next derive an exact compressed counting recurrence or algebraic technique for all relevant prefixes, with a rigorous resource bound for m=45 and N=4244, exact bigints and five-output preservation. Validate every prefix/rank on the committed independent finite oracle, then design bounded native/differential gates before production changes. Do not raise the 180-second timeout as a purported fix or classify it as historical defect #3.
