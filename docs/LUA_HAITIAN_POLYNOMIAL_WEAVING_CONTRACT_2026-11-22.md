# Exact polynomial-state weaving counter and conditional unrank (QA only)

PROJECT_ID: PC-BRANCH-LUA-HAITIAN  
Branch: Lua+Kreyòl-ayisyen  
Date: 2026-11-22  
Source witness: completed Native job 136980280634 in run 44948262844; frozen selected vector has 47 months and 5294 days.  
Scope: independent mathematical/algorithmic QA, not a production or normative Lua replacement.

## 1. Prior accepted evidence and obstruction

Run 44996963044 / focused job 137130036980 finished successfully at 6681e26dce282d0ac46b20baa67b8f619b6d228c. The independent sparse residual-state differential verifies 43 counts, 290 prefixes, 122 lexicographic ranks, two rejected mutants and five boundary guards; artifact 14744243018. It does not solve actual 5294-day weaving. The old remaining-vector memoization has at least product_i(n_i-1) states on its all-open/no-close slice, hence is infeasible for the attested 47-month vector.

## 2. New exact reduced-state identity

A valid multiset word has first occurrences of labels 0,...,m-1 in increasing order and last occurrences in increasing order. After any valid prefix, labels [0,b) are exhausted, [b,a) are active (each has remaining r_i >= 1), and labels [a,m) are unopened with original lengths n_i. Let Q=sum_{b<=i<a}r_i.

For every fixed interleaving of events involving active/unopened labels, the remaining active labels can be filled in exactly A ways while their last occurrences stay ordered, where

A = product_{i=b}^{a-1} binom( (sum_{j=b}^i r_j)-1, r_i-1).

This follows by positioning the occurrences of the largest active label relative to earlier active labels: its final occurrence must be the final active-label occurrence; choose the locations of its preceding r_i-1 copies among the Q_i-1 preceding positions. Multiplying the independent interleavings yields A. Hence active labels can be collapsed to a single virtual label V with multiplicity Q, with no loss of exact counts.

Define T(a,q) to count valid completions of q copies of V and as-yet-unopened labels a,...,m-1, with first occurrences of new labels in order and last(V) before last(a), before last(a+1), etc. With no unopened labels, T(m,q)=1 for every q. For a<m:

T(a,0)=T(a+1,n_a-1).

For q>=1, split on the first event:
- Consume V: T(a,q-1).
- Open label a: its first occurrence is forced, then its last occurrence must follow the last V; before that last V place n_a-2 remaining non-final copies of a among the previous q copies of V. Their positions can be chosen in binom(q+n_a-2,n_a-2) ways. Treat these copies as part of the enlarged virtual label: T(a+1,q+n_a-1).

Thus exactly

T(a,q)=T(a,q-1)+binom(q+n_a-2,n_a-2)*T(a+1,q+n_a-1).

The number of suffixes after any legal prefix is A*T(a,Q). An impossible prefix has count zero. The initial count is T(0,0). Rank is one-based; lexicographic unrank subtracts exact suffix-block counts over possible next labels, preserving this invariant. Counts are arbitrary-precision integers, never floating point or modular. The DP computes O(m*L) cells, not an exhaustive set of remaining-count vectors. Big-integer arithmetic still incurs nonconstant cost and substantial memory; the stated polynomial bound is for the number of DP cells, not bit complexity or a universal resource guarantee.

## 3. Independently measurable tests

Executable: test/lua_haitian_polynomial_weaving_qa.py.

Small-domain oracle exhaustively enumerates distinct multiset words and accepts only those with ordered first and last positions, independently of the reduced recurrence. Acceptance: 43/43 count, 290/290 prefix, 122/122 lexicographic ranks; 12/12 Catalan checks for n_i=2; 10/10 input/rank/budget guards.

Large-domain QA:
- Synthetic 47-month, 5294-day vector with 30 months of 113 and 17 of 112 days: exact count, and complete lexicographic unrank at first, middle and last ranks; independently check length, multiplicities by construction and ordering of first/last occurrences.
- Actual 47-month, 5294-day vector from the locked completed Native transcript: exact count; 8654 decimal digits; hash SHA-256 of decimal count e3d498d39d6b4dfc401a85b8d9135ff1089a81ace85565ac5dcb123870c09f34; three selected 96-label prefixes from first, middle and last *QA ranks*, verifying residual rank within exact suffix block. These are not normative chooseRankWide outputs.
- Explicit caps m<=47, L<=6000, DP cells<=180000; exceeding a QA cap means RESOURCE_UNSUPPORTED or NOT_EVALUATED, never a claim of invalid calendar data. The Python CI process has a separate 768 MiB VM limit and a 110-second wall limit; these are not changes to Lua Native production policy.

The script is QA research only. Passing Python QA does not constitute a Lua 5.3 Native differential or production acceptance. No call to normative chooseRankWide, makeWeavingCounter, buildYearStructure, calendarDate, fullDate, or Stage56. The next gate after exact-SHA CI is independent proof review and a separate resource-bounded Lua 5.3 differential adapter for the real vector, with verified source SHA, integer count, lex order, rank and output evidence. Do not merge, change main or release on these results.

## 4. Run and evidence contract

The existing canonical push workflow calls the scoped QA workflow once. That workflow locks HEAD and this script's exact blob, records per-file hashes, runs with explicit exit/stdout/stderr, checks exact markers and the frozen real count digest, and uploads a ZIP even on failure. New CI result must be evaluated from completed run, focused job logs and artifact before acceptance. A queued or in-progress run is not PASS and not a blocker.
