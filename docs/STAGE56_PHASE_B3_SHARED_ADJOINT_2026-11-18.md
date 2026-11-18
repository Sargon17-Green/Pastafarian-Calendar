# Stage56 Phase B3 — shared shifted-suffix adjoint for exact next-ID block counts

PROJECT_ID: PC-BRANCH-PHP-MALAY  
Branch: PHP+Bahasa-Melayu  
Parent: 715eee6d0cd92631669cbf49dab2d6e91a4c151c

## Verified predecessor (B2), not full Stage56

Canonical push Actions run 44364896209 completed/success **29/29** on the exact parent SHA. The B2 job 135015895270 ran PHP 8.3.36/64-bit, four PHP syntax lints and exact DFS rank/unrank differential: vectors=120, words=3940, out_of_range=360, invalid=5, huge=2; exit=0, empty stderr. Its SHA-bound ZIP artifact 14457299187 has matching PROJECT_ID/SHA, ZIP CRC PASS and SHA256 `b5e594cab2b00a5e0ed5418aa6f9397e4a1af7bd74872cff032ba2d4da311809`. No production provider integration was accepted by this evidence.

## Objective, API, state and boundaries

`MonthWeavingAdjoint56::candidateBlocks(remaining,opened)` returns an ascending map from each legal **1-based next month ID** to an exact `BigInt` count of legal completions after consuming it. All counts are 0..123, at most 47 families and 5778 remaining symbols. Zeros must be a prefix; `opened` is the largest ID seen previously; no previous family may remain unopened before the first positive residual. The input is never mutated, malformed states throw `InvalidArgumentException`, and the terminal state returns an empty map. It is not yet wired into `PATCH22/PATCH23`.

A next ID `i` may be chosen only when `i <= opened+1`, the residual is positive, and if its residual is 1 then every earlier residual is 0 (last occurrences must remain ordered). Let `L` be the number of previously inserted symbols, `n` the next family's residual and `x_h` the old first-position distribution. `T(n,L,o)` is the *linear* first-position insertion transform, using `p=1..L+1`, `t=L-p+1` and exact coefficient `w=C(n-2+t,t)`:

- For `n>=2`, `y_p = w * sum_{h=0..p-1}(x_h)` when the next first occurrence must be later than the previous first; otherwise `y_p = w * sum_h(x_h)`.
- For `n=1`, `y_{L+1}=sum_h(x_h)` and all other positions have zero mass.
- For each family with original `opened`, ordered-first is true iff its ID is strictly greater than `opened+1`.

The adjoint of the same operator, applied to a suffix functional `a_p`, is **exactly**:

- Ordered first: `b_h = sum_{p=h+1..L+1} w(p) a_p`.
- Already allowed to open: `b_h = sum_{p=1..L+1} w(p) a_p`.
- `n=1`: `b_h=a_{L+1}`.

These formulas use only additions, multiplications and exact binomial-ratio divisions; no floats, estimates, GMP-only dependency, or oracle data is used in the implementation.

## Reusable shortened suffix and one exceptional seam

For any legal next choice, exactly one symbol is consumed. Every subsequent family `j` therefore sees the same shortened cumulative old length `cum[j]-1`, independent of the selected ID. A single reverse sweep builds adjoints for these shortened lengths. It starts with the all-ones terminal sum functional, then applies the exact transposed insertion operators in descending family order. Rows are stored as losslessly compressed decimal strings instead of retaining all `BigInt` instances.

For candidate `i`, forward-transform the **original, reused** prefix distribution through family `i` with `n_i-1`, and dot it with the shortened suffix adjoint after `i`. The only opening-state exception is when `i=opened+1`: now family `opened+2` is no longer subject to the ordered-first restriction. Recalculate **one** transposed operator with the changed flag, then reuse the common suffix beyond it. If `n_i=1`, legality guarantees this is the earliest active family, which closes; the branch count is the zero-index component of the succeeding adjoint, without applying a deleted family operator.

Induction on inserted families establishes the forward transform; the defining dot-product identity for the transpose establishes the reverse sweep. Together with independent DFS enumeration, this proves every sibling block count, not merely their sum. This is not copied from the historical test-oracle's recursion or compression mechanics; it is derived from the independent B1 linear insertion operator.

## Scope and performance caveat

A *single prefix state's full sibling set* now needs one backward sweep and one forward prefix sweep, rather than independently recomputing every candidate. The arithmetic-operation bound is `O(m L)` per prefix state plus `O(m L)` row serialization; temporary `BigInt` rows are bounded by `O(L)`, compressed storage is proportional to the exact decimal values. Evaluating all `L` positions of a word still has an `O(m L^2)` arithmetic-operation worst-case bound. **This is not yet a demonstrated <=512MiB / <=900s rank/unrank solution for real years.** Actual BigInt digit growth, gzip throughput, and use of all 5778 symbols must be profiled before provider integration.

## Tests and acceptance discipline

A separate DFS oracle enumerates every legal word on all 120 count vectors (1..4 families, 1..3 copies), which induces **18,302 distinct prefixes** and **18,182 nonterminal sibling block checks**, covering 3,940 legal words. Check every per-ID count, candidate order, input nonmutation and, for nonterminal states, the exact partition sum against B1. Also test eight invalid states and an 8x6 genuine `BigInt` total/partition (more than 19 decimal digits). A small-int local stand-in passed all 120 vectors / 18,302 prefixes / 18,182 branches, and local PHP 8.4 lint passed; this **is not Native BigInt acceptance**. Native PHP 8.3/64-bit with exact counters, empty stderr, zero exit and SHA-bound evidence is required on this new SHA.

## NEXT

1. Verify the new exact-SHA B3 Native job and artifact. Fix only demonstrated failures, without rerunning completed PASS on the old SHA.
2. Measure realistic month vectors for actual years 4999, 5000, 5001 using a reproducible trusted year source, under 512MiB and 900s. Record rank/unrank timing and peak RSS; do not extrapolate from synthetic data.
3. If the full-word path fails the gate, derive a *state-updatable* adjoint across consecutive prefixes or a proven equivalent faster production method, with independent differential and bounded performance evidence. Only then consider PATCH22/PATCH23 provider integration.

No merge/main changes or Stage56 overall PASS is authorized by this B3 subphase alone.
