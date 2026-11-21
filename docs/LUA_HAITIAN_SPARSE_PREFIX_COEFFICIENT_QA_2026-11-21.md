# Bounded endpoint-path sparse coefficients and lexicographic unranking (QA research)

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Date: 2026-11-21
Source base: 14e4a60abb9f3f6da61dd7f7156f88dff77a0569
Scope: QA-only algorithm research. No new Stage, production wiring, protected branch, merge or release.

## Trigger and frozen evidence

The exact-SHA run 44948262844 has a focused completed/success job 136980280634. Its log shows independent Python source locks 4/4, endpoint-polynomial small-domain identity 55/55, resource QA 26/26, Lua 5.3 strategy 65/65 and independent exact month composition 486/486. Native selected month vector: m=47, L=5294. Existing memo DP lower bound is product_i(n_i-1), so it remains resource-unsupported. This is not a calendar-invalidity result. At the design checkpoint the overall run was not yet accepted.

## New executable QA implementation

test/lua_haitian_sparse_path_qa.py counts *prefix-constrained* weavings by a different algorithm from the normative remaining-vector recursion:

1. Parse prefix, validate that first and last occurrences have monotonically increasing labels, and compute the endpoint state (a,b) and residual length r.
2. Enumerate paths of remaining O_i/C_i endpoint events with O and C each internally ordered, never closing unopened months. Every gap has active interval A_g=[b,a) in zero-based indexing.
3. Reserve one occurrence per future opening and one per future closing; the remaining interior counts t_i are exact nonnegative integers.
4. Truncate the rational gap factors 1/(1-sum_{i in A_g}x_i) to t; expand sparse multinomial terms using Python integers. The coefficient of x^t summed over endpoint paths is the exact suffix count.
5. For one-based lexicographic rank R, subtract successive candidate-next-label suffix counts until the block containing R is reached; repeat until the word is complete. No modulo reduction, floating-point counts, approximate sampling or silent fallback.

This generalizes the earlier complete-word endpoint identity to conditional prefix counts and an explicit exact lexicographic unranking contract.

## Independent oracle and measured local result

The oracle enumerates distinct multiset words and independently checks increasing order of first and last positions. It does not import the normative Lua, endpoint-path implementation or any cross-branch fixture.

Command: python3 test/lua_haitian_sparse_path_qa.py
Local Python result:
- SPARSE_PATH_QA_CASES: 43
- SPARSE_PATH_PREFIX_ORACLE: 290
- SPARSE_PATH_LEX_UNRANK: 122

Negative checks reject impossible first-open prefix and out-of-range ranks. Boundaries are m<=4, total days<=12, each count>=2, and a maximum 150000 intermediate monomials. Outside the bounded QA envelope, ResourceBound means NOT_EVALUATED_QA_DOMAIN or POLYNOMIAL_STATE_BUDGET, never normative invalidity. The real m=47 vector is intentionally NOT_EVALUATED_QA_DOMAIN; real weaving, fullDate and Stage56 remain NOT_RUN. These are local static/QA results, not Native or CI acceptance of the new script.

## Next gate

Obtain an independent second implementation of prefix-conditioned coefficient extraction (not the same polynomial implementation), with exhaustive and adversarial mutation tests. Profile state count and runtime against increasing bounded m and compare to the existing memo DP. Identify a mathematically proven polynomial or fixed-parameter reduction before any attempt to count or unrank the frozen 47-month vector. Do not feed an approximate count into chooseRankWide; exact uniform selection requires exact suffix counts for every lexicographic block.
