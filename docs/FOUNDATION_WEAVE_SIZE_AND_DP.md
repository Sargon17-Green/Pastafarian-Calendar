# Woven month calendar: Stage-1 exact lower/upper size bounds

**Provenance:** `docs/FOUNDATION_MONTH45_LENGTHS_REFERENCE.csv`,
45 canonical **length-vector candidates**, each at least 25 and
at most 122 days, total `L=4244`. The month-day weaving itself
has not been selected or computed. This is a width/feasibility
proof independent of the canonical weave rank.

## What constitutes a legal weave

A word of length 4244 on canonical month ordinals 1..45 must
contain precisely `l_j` copies of each ordinal `j`.
The first occurrences must appear in ascending order 1..45,
and the last occurrences must *also* appear in ascending order.

## Upper bound (all multiset words)

For unrestricted multiset permutations,
```
U = 4244! / (l_1! · l_2! · ... · l_45!)
```
Every valid weave is one of those words, so `W ≤ U`.
By exact arbitrary-precision factorial and successive-binomial
product, **both** paths yield `bit_length(U)=22851`.

## Constructive lower bound (a certified legal subset)

Place one occurrence of each month in ascending order at the
very beginning of the word, and one occurrence of each month
in ascending order at the very end. Between these two
45-symbol blocks, interleave the remaining `l_j - 2` copies
of each month in *any* order.

Because every `l_j≥2`, these words necessarily satisfy both
first- and last-occurrence constraints, and distinct middle
multiset permutations give distinct legal weaves. Hence
```
D = (4244 - 2·45)! / ((l_1-2)! · ... · (l_45-2)!)
  = 4154! / Π (l_j-2)!
D ≤ W ≤ U
```
Two independent exact arithmetic implementations
(factorials and successive binomial selections) agree:
`bit_length(D)=22350`.

It follows **rigorously**, without computing the exact weave count,
that:
- `22350 ≤ bit_length(W) ≤ 22851`.
- Any exact unsigned binary representation of the root count
  requires at least **699** 32-bit limbs; **715** limbs suffice
  for this root count and for all its nonnegative suffix counts.
- With `M=2^127-1`, the wide-selection initial digit count
  `k=min{d:M^d≥W}` satisfies **176 ≤ k ≤ 180**.
  In particular `M^175 < D ≤ W ≤ U < M^180`.
- The existing 384-bit test-only arithmetic tools handle
  the *month-length choice* (274 bits) but fundamentally
  cannot represent a **full 45-month weave rank**.

## Exact suffix recurrence and its limitation

Let `u_j` be copies of month j already consumed.
A legal next month j must satisfy:
1. `u_j < l_j`;
2. if `u_j=0`, each i<j already has `u_i>0`;
3. if `u_j+1=l_j`, each i<j has `u_i=l_i`.

The exact completion count `C(u)` is the sum of `C(u+e_j)`
over those allowed next symbols, with `C(l_1,..,l_m)=1`.
These are the exact lexical block sizes for `unrank`.

This naive memoization has
`Π(l_j+1)` possible count vectors. For the Foundation
candidate lengths, `log2(Π(l_j+1)) ≈ 292.57`.
Allocating one DP cell per vector would therefore be
catastrophically infeasible. An exact compressed/state-factored
algorithm with explicit time/memory bounds is mandatory before
the 4244-day weave can be accepted.

## Implemented independent validation

`tests/tb_weave_small_exhaustive.sv` exhausts eight toy
instances, including lengths [2,2], [2,2,2],
[3,2,2], [2,2,2,2], [4,2,1], [1,1,1,1],
[1,2,1] and [4,4]. It compares brute-force enumeration
against the recurrence above and checks **every legal lexical rank**.
Their independent exhaustive counts are
`[2,5,9,14,4,1,1,20]`.

The toy cases exercise the semantics, but are **not** a
substitute for a 45-month weaving engine or a fully qualified
hardware implementation. No full woven date or canonical
month-name/day-in-month acceptance is claimed.
