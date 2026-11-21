# Exact month-composition counting: independent Lua QA

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Date: 2026-11-21
Authorized branch: Lua+Kreyòl-ayisyen
Parent: 065959a5d61336e18682f8f1e017cf8bae4d22b6

Scope: QA-only arbitrary-precision counting and unranking for ordered month-length compositions; never overrides test/normative_oracle.lua, month weaving, production or Stage55 state. No Stage56.

Input: integers total 0..5778, m 1..47, 1<=lo<=hi<=123, and BigInt rank1 in [1,count]. Output: exact BigInt count, or one-based lexicographic ranked sequence of m values summing to total with each in [lo,hi], or domain/rank rejection. For the normative domain lo=4 and hi=123. A QA execution cap of 16 months is NOT a validity rule.

Independent formula: set r=total-m*lo, d=min(r,m*(hi-lo)-r), w=hi-lo+1. When 0<=r<=m*(hi-lo), count=sum_j (-1)^j C(m,j) C(d-j*w+m-1,m-1) for j=0..floor(d/w); otherwise count=0. Symmetry in free/occupied capacity narrows terms. Binomial arithmetic uses BigInt multiplication and exact division with zero-remainder assertion. Lexicographic unranking subtracts prefix blocks via the suffix count. This differs algorithmically from the recursive DP of the normative source.

Checks: 132 exhaustive small-domain count probes, 340 independent brute-force ranked tuples, 4 exact large year5000 counts at L=5294 for m=44..47, plus infeasible m43, normative bounds, first and last rank, and domain rejection. Expected marker: LUA_HAITIAN_EXACT_MONTHS_PASS: 486/486. Compare with independent Python math.comb receipts and exact source SHA.

The existing reusable resource-boundary workflow will run this with genuine Lua 5.3 and frozen src/bigint.lua. Store stdout, stderr, exit, and SHA256 for the new files in the existing artifact. No duplicate workflow dispatch. Before verified CI, this is implemented and parser-checked only, not Native PASS.

Nonclaims: no real year selection or weaving in this new test, no fullDate, no production integration or Stage56. Resource budget exhaustion must not be interpreted as calendar invalidity.
