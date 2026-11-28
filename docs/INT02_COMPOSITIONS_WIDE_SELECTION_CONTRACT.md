# INT-02 composition and wide-selection contract

**Project:** `PC-BRANCH-COBOL-SIMPLIFIED-CHINESE`  
**Source:** `Pasted text(20261127-150032).txt`, SHA-256 `0add0726ef80f160f73594eba50c246c0bdeb0a5f613e14b6baa23e2f5321aae`  
**Repository HEAD used for the analysis:** `148776590c7d304666a9e4e65fa61c601bdc181d`

This document fixes the measurable contracts for the missing composition and wide-selection units. It is a design/independent-model artifact, not a Native acceptance record.

## 1. Shared arithmetic and ordering

- The answer modulus is `M = 2^127 - 1 = 170141183460469231731687303715884105727`.
- All ranks are one-based.
- All composition vectors are ordered lexicographically by ascending component values.
- `BIG-INTEGER-SERVICE` handles are caller-owned at module boundaries. Inputs are never mutated. Returned handles are detached from the module's arena and become caller-owned; the caller must free them.
- Scratch handles are allocated inside a service scope and released before return. No module may return a handle still registered to its local scope.
- Do not serialize a handle to `SVC-TEXT` if its value can exceed 8,192 decimal digits. In particular, the weaving count and wide-selection rank stay as handles from count through selection and unranking. The 8,192-character text limit is an I/O limit, not a valid maximum for internally generated handles.

## 2. Tablet XX — positive gap compositions with a mandatory interior gate

### Inputs and domain

- `R`: number of gate intervals in the year, `6 <= R <= 137`.
- `K`: number of meatballs, `6 <= K <= 17`, `K <= R`.
- `G`: mandatory prefix in gate-interval units. `G=0` means no mandatory interior cut; `1 <= G < R` means the action gate is interior and a composition prefix must equal `G`; `G=R` is the year-end and imposes no additional cut.
- Output is a positive vector `(g1,...,gK)`, each `gi >= 1`, with sum `R`.

### Count oracle

Without an interior gate:

\[
N(R,K)=\binom{R-1}{K-1}.
\]

With an interior mandatory cut `G`:

\[
N(R,K,G)=\sum_{j=1}^{K-1}
  \binom{G-1}{j-1}\binom{R-G-1}{K-j-1}.
\]

A binomial coefficient with an invalid lower index is zero. The formula partitions the `K` positive parts into `j` parts before the mandatory cut and `K-j` parts after it.

### Lexicographic rank/unrank

For a selected prefix sum `s`, `p` remaining parts, and an unsatisfied interior gate `G`, the number of completions is:

\[
W(R-s,p,G-s)=\sum_{j=1}^{p-1}
  \binom{G-s-1}{j-1}\binom{R-G-1}{p-j-1}.
\]

Once the prefix reaches `G`, the remaining count is the ordinary positive-composition count `C(R-G-1,p-1)`. A candidate that crosses `G` before reaching it has zero completions. Rank/unrank scans each candidate part in ascending order and subtracts the corresponding completion count.

### Bound

The maximum unconstrained count in the supported domain is:

`C(136,16) = 261429178502421685800` (21 decimal digits).

It is below `M`, so the gap-composition choice needs only one answer digit (`d=1`). The mandatory-gate subset cannot exceed this bound.

## 3. Tablet XXI — bounded month compositions

### Inputs and domain

- Year length `Y`: `252 <= Y <= 5778` days.
- Month count `m`: `ceil(Y/123) <= m <= min(47, floor(Y/4))`.
- Each month length `li` is an integer in `[4,123]` and `sum(li)=Y`.
- Output is the lexicographically ordered vector `(l1,...,lm)`.

### Count DP

Let `D[p,s]` be the number of ways to compose `s` days into `p` months, each in `[4,123]`.

- `D[0,0]=1`; all other `D[0,s]=0`.
- Direct recurrence: `D[p,s] = sum(D[p-1,s-d], d=4..123)`.
- Sliding-window recurrence, with out-of-range cells treated as zero:

\[
D[p,s]=D[p,s-1]+D[p-1,s-4]-D[p-1,s-124].
\]

Lexicographic unranking tries candidate month lengths `d=4..min(123, remaining-4*(p-1))` and uses `D[p-1,remaining-d]` as the completion block size.

### Bound and memory

An exhaustive DP over the full declared `(p,s)` domain found the maximum count at `(m,Y)=(47,2984)`:

`88188610661218998730479348148499174290556866510515790050322945205040359156522439817076486280000`

This is 95 digits: greater than `M^2` (77 digits), smaller than `M^3` (115 digits). Therefore the month-composition selector needs at most `d=3` answer digits.

A fixed 96-byte decimal cell table for `(48 x 5779)` entries occupies `26,629,632` bytes (about 25.4 MiB). A rolling two-row BigInt calculation can generate the table; rank/unrank then performs at most `47 x 120 = 5,640` candidate lookups/subtractions.

The maximum was cross-checked independently by inclusion-exclusion:

\[
D[m,Y]=\sum_{j=0}^{\lfloor(Y-4m)/120\rfloor}
 (-1)^j\binom mj\binom{Y-4m-120j+m-1}{m-1}.
\]

## 4. Tablet XVI — deterministic wide selection on caller-owned handles

### Inputs and outputs

- Input handle `N`: positive number of choices.
- Input handle `a1`: first answer, `1 <= a1 <= M`.
- Direction `dir`: `+1` for forward or `-1` for backward.
- Output handle `rank`, plus `d`.
- No input handle is modified. Output is detached from the local BigInt scope.

### Algorithm

Choose the least `d >= 1` such that `M^d >= N`. Generate `d` answer digits by cyclic successor/predecessor modulo `M`:

- `a1` is the supplied first answer.
- `a(i+1)=a(i)+1`, with `M -> 1`, for forward selection.
- `a(i+1)=a(i)-1`, with `1 -> M`, for backward selection.

Construct:

\[
X=1+\sum_{i=1}^{d}(a_i-1)M^{i-1},\qquad S=M^d,
\]

\[
L=\left\lfloor\frac{S}{N}\right\rfloor N.
\]

If `X <= L`, use `C=X`. If `X > L`, the rejected suffix is contiguous; the first accepted value in the prescribed cyclic direction is therefore `C=1` for forward selection or `C=L` for backward selection. This jump is exactly equivalent to walking one value at a time through the rejected suffix, without an unbounded loop.

Return:

\[
rank=((C-1)\bmod N)+1.
\]

This procedure is deterministic. It is **not** a uniform random sampler; the primary source's footnote 12 explicitly disclaims uniformity. Do not describe it as uniform.

### Wide-domain bound

The maximum legal weaving count is bounded above by the number of all words over 47 symbols of length 5,778:

`47^5778` has 9,662 decimal digits.

`M^252` is smaller than this bound, while `M^253` has 9,673 digits and is larger. Thus `d <= 253` for the declared weaving domain. A legal maximum-year stress vector `(44 x 123, 3 x 122)` has a 9,478-digit count and needs `d=248`.

The wide selector must therefore support at least 253 base-`M` digits. It must use BigInt handles throughout; neither the count nor the rank may pass through the 8,192-character text interface.

## 5. Tablet XXI — ordered-first / ordered-last weaving

Let `li` be the month lengths. A valid word contains exactly `li` occurrences of symbol `i`, with both first-occurrence positions and last-occurrence positions strictly increasing in month order.

A state has:

- `o`: number of months already opened (their first occurrence has been emitted); opened months are the prefix `1..o`.
- `c`: number of months already closed (their last occurrence has been emitted); closed months are the prefix `1..c`.
- `ri`: remaining occurrences for active months `c+1..o`.
- `S = sum(ri)`.

A legal next symbol is either the next unopened month `o+1`, or an active month. An active month may consume its final occurrence only when it is the next month to close (`i=c+1`); otherwise that choice is forbidden. This is the exact state transition for the two ordered-endpoint constraints. Lexicographic unranking tries legal symbols in ascending order and subtracts child completion counts.

### Future-factor recurrence

Let `F_k[s]` count future completions from unopened month `k` onward when `s` active occurrences remain. The base is `F_(m+1)[s]=1`. For month length `n=lk`:

\[
F_k[s]=\sum_{j=0}^{s}\binom{n+j-2}{j}F_{k+1}[n-1+j].
\]

For a state with active months `c+1..o`, define cumulative active counts `P_i=sum(r_h, h=c+1..i)`. The active interleaving factor is:

\[
A=\prod_{i=c+1}^{o}\binom{P_i-1}{r_i-1}.
\]

The state count is `A * F_(o+1)[S]`. The product telescopes to the number of active-symbol words whose last occurrences retain the required order.

### One-vector in-place cache

For each `k` descending from `m` to `1`, compute `F_k[s]` in ascending `s`. The source cell is `F_(k+1)[lk-1+s]`. Since every `lk >= 4`, its index is strictly greater than `s`. Therefore the current vector can be overwritten in place: read the higher-index source before replacing the lower-index destination. No future iteration reads an already overwritten cell.

This retains one vector of at most 5,779 handles rather than two full vectors. The independent model cross-checks this recurrence against direct legal-word recursion on small cases and against the source's three-month stress case `[123,123,6]`.

### Resource envelope

For a monotone upper envelope, use 47 months of 123 days (5,781 days; this is a resource bound, not a legal year). Increasing a month length by one has an injection: insert one additional occurrence of that symbol immediately before its existing last occurrence. This preserves both first- and last-occurrence order. Padding to 47 months of 123 therefore bounds every legal vector's future-factor entries and prefix indices.

The one-vector in-place model measured the envelope's peak at **1,677,995 base-10^9 chunks**, below the existing 2,000,000 live-chunk guard by 322,005. The envelope requires 133,010 DP cells. At the same layer, retaining both complete vectors would require **3,206,153 chunks**. The legal maximum-year vector `(44 x 123, 3 x 122)` has 9,478 count digits; its decimal SHA-256 is `c753a38d7b6df8d65d41ef6ba02d8cd61c43d9221903d27c0d742c45dcf81cc2`.

The existing two-vector oracle cache is therefore not an acceptable production memory layout under the 2M guard. The in-place transformation is the required production layout.

## 6. Independent model evidence and remaining gates

The following local model programs are independent of the COBOL production implementation:

- `test/int02_composition_selection_model.mjs`: exhaustive small positive-composition count/rank/unrank checks, bounded-month DP vs brute force, inclusion-exclusion cross-check, and wide-selection shortcut vs literal cyclic walk for toy moduli.
- `test/int02_weaving_inplace_model.mjs`: direct legal-word brute-force checks, source footnote case `[123,123,6]`, one-vector in-place recurrence, full-domain monotone resource envelope, and wide selection up to the 253-digit bound.

These are model/QA results only. They do not establish COBOL compilation, Native execution, CI completion, differential acceptance of a production module, or acceptance of a complete stage. The next production work is to implement the caller-owned-handle COBOL modules and drivers against these contracts, then run only the new targeted gates. The six previously accepted INT-02 gates must not be rerun.

## 7. Model run summary (not Native)

- Gap model: 308 `(R,K,G)` configurations, 20,342 explicitly enumerated vectors, and 15 large-rank inverse probes passed.
- Month model: 90 small `(m,Y)` configurations and 190,566 explicitly enumerated vectors passed; three large-rank inverse probes passed; the maximum was independently cross-checked by inclusion-exclusion.
- Wide-selector model: 30,664 toy-modulus cases matched a literal cyclic walk; 48 real-modulus boundary cases passed.
- Weaving model: six small legal-word brute-force cases matched both future-factor implementations; the `[123,123,6]` source example matched exactly; the 47-month maximum-year stress case and the 47x123 monotone resource envelope passed.

The two model programs print machine-readable JSON. Their verdict strings deliberately include `NOT_NATIVE`.
