# SQL+தமிழ் — Stage 2 Slice22 independent weaving feasibility

**2026-11-05 | PROJECT_ID:** `PC-BRANCH-SQL-TAMIL`  
**Branch preflight:** `SQL+தமிழ்` at `a37c893264ed50c6e9054b8f963af6fe37b869d2` (live branch/ref read); contract blob `f4a447ffee650812b8bb3bf20c9f70296203d12f`, normative reference blob `ce17bf6fd166451b6904411c5e29d1b26d92e278`.  
**Classification:** PREPRODUCTION MATHEMATICAL FEASIBILITY ONLY. No SQL/Native implementation, no PostgreSQL 17 test, no Slice22 acceptance, no merge/main/publish.

## Exact combinatorial model

For lengths `L=(L_1,...,L_k)` with each `L_i>=2`, admissible words contain exactly `L_i` copies of symbol `i`. Their first-occurrence *and* last-occurrence orders are `1,2,...,k`. A state consists of `a` opened types, `c` fully closed types, and residual `r_i>0` for each active type `c<i<=a`. Let `T=sum_{c<i<=a} r_i`. The active-only completion count is

```
A(r;c,a) = product_{i=c+1}^a C((sum_{j=c+1}^i r_j)-1, r_i-1).
```

Proof: insert each successively higher active type into a word of lower active types. Its last token must occur after the prior active type's last token. The number of ways to place its other `r_i-1` indistinguishable tokens among the first `S_i-1` positions is `C(S_i-1,r_i-1)`. The insertions are bijective, so their counts multiply.

For the unopened future types, define `F_a(T)` as the normalized number of admissible suffixes per active-only completion, with `a` types already opened and `T` residual active tokens. At `a=k`, `F_k(T)=1`. Peeling the next type of multiplicity `h=L_a` back from the opening frontier gives, for `a=k,...,1`:

```
F_(a-1)(T) = sum_{x=0}^T F_a(x+h-1) * C(x+h-2, h-2)
count(state) = A(r;c,a) * F_a(T)
root = F_0(0)
```

The summands partition at the frontier between the next first occurrence and the last-token ordering of the lower types: `x` is the number of residual old-frontier tokens in the distinguished suffix. The other `h-2` nondistinguished copies of the newly introduced type have `C(x+h-2,h-2)` legal slots; deleting/inserting those copies is reversible. Different `x` describe disjoint suffix classes. Every term is a nonnegative integer. For fixed `a`, calculating successive `T` by prefix sums yields `O(kD)` arithmetic operations and `O(kD)` stored exact integers. Compute the binomial multiplier incrementally using `C(x+h-1,h-2)=C(x+h-2,h-2)*(x+h-1)/(x+1)`, with exact division. The valid table bound for each row is `T<=sum_{i=1}^a (L_i-1)`, so impossible tails are never stored.

For lexicographic 1-based unranking, each next-symbol candidate partitions the valid suffix set into disjoint ordered blocks whose sizes are `count(next_state)`. Subtract preceding blocks and continue inside the first block containing the residual rank. Positive rank within `1..root` maps bijectively to exactly one admissible word; no floating-point or modulo reduction is needed by the counting algorithm.

## Independent verification (CPython, not PostgreSQL)

`sql/test/130_stage02_month_weaving_feasibility.py` constructs **all distinct multiset words** in 9 small vectors, filters the actual first/last constraints, and independently records every prefix count and sorted word. The enumerator neither uses the DP nor copies output from the SQL reference. Tests compare this literal enumeration to exact DP state counts and check all lexicographic ranks:

```
PASS small-vectors=9 exact-words=150 exact-prefixes=660 rank-roundtrips=150
```

Boundary profiling using the same script (`--bench`) was bounded and used `tracemalloc` to measure Python allocations:

| Shape | k | D | Stored cells | Exact root decimal digits | Elapsed s | Peak Python traced MiB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `(120,123×46)` | 47 | 5778 | 137523 | 9478 | 2.5542 | 192.437 |
| `(4×46,68)` | 47 | 252 | 3496 | 209 | 0.0114 | 0.258 |
| `(123×20)` | 20 | 2460 | 25641 | 3138 | 0.2312 | 12.245 |
| `(52×47)` | 47 | 2444 | 57576 | 3912 | 0.4423 | 34.499 |

The all-123 47-month vector sums to 5781 and is **outside** the reachable `D<=5778` domain; it was deliberately excluded. The smaller 48-month vector is likewise excluded by `k<=47`. All four reported shapes obey `4<=L_i<=123`, `252<=D<=5778` and `k<=47`.

**Limitations:** This local proof and benchmark do not establish PostgreSQL execution time, planner behavior, storage or the 15-minute CI gate. The largest Python `tracemalloc` peak is about 192 MiB, so a PostgreSQL implementation should avoid repeated copying of giant arrays or unbounded per-prefix recursion; prefer per-call set-based or well-profiled bounded storage with exact numeric operations. None of the 40 Native goldens, isolation gates or 8 differential jobs has run for Slice22.

## Next authorized engineering action

Implement `sql/24_stage02_month_weaving.sql` using this checked state-count factorization and per-call bounded suffix factors, with exact numeric candidate-block unranking and no persistent memo. Add an independent realistic-vector oracle with >=40 fixed cases, >=40 named PG17 Native gates, >=5 isolation tests, >=8 actual-array differential comparisons, and a branch-only hard-15-minute workflow. Before accepting Slice22, inspect completed job logs and original ZIP hashes and CRC as the contract requires. Do not change the normative reference, `main`, or merge/publish.
