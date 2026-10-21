# Canonical selection rejection — constant-step theorem

**Status:** mathematically established for an abstract circular domain;
test-only verification fixture prepared, *not* simulator-verified.
**Scope:** applies to Scroll §§M–N, both short and wide selection,
without altering the prescribed initial answer or digit construction.
**Lifecycle:** Stage-1 research artifact; do not introduce a production
selection implementation before its own historical DISCOVERY/PATCH stages.

Let the ordered answer domain be \(\{1,\ldots,S\}\), the number of
choices \(N\) satisfy \(1\le N\le S\), and let

\[
L=\left\lfloor S/N\right\rfloor N.
\]

A valid answer is any \(1\le A\le L\). The only rejected values form
the terminal interval \(L+1,\ldots,S\). The mandated progression is
\(A_{k+1}=1+((A_k-1+d)\bmod S)\), \(d\in\{+1,-1\}\).

If \(A_0\le L\), reject count is zero and accepted answer is \(A_0\).

If \(A_0>L\):

- **Forward:** \(A_0,A_0+1,\ldots,S\) are all rejected. The
  next value is 1, so the first accepted answer is 1 and the
  exact rejection count is \(S-A_0+1\).
- **Backward:** \(A_0,A_0-1,\ldots,L+1\) are all rejected. The
  next value is \(L\), so the first accepted answer is \(L\) and
  the exact rejection count is \(A_0-L\).

The selected ordinal remains \(1+((A_{accept}-1)\bmod N)\).
In particular, a rejected forward walk selects ordinal 1;
a rejected backward walk selects ordinal \(N\).

**Wide selection:** the Scroll first constructs \(W\) from successive
ring digits and uses \(S=M^k\). The above theorem applies to its
*post-construction* circular walk only. It does not authorize changing
the digit sequence, its correlation, lexicographic rank, the bias in
the wide selection, or any \(N\)/\(k\) derivation.

**Hardware implication:** avoid data-dependent repeated rejection
increments. Compute accepted answer and logical reject count with
comparators/subtractors in arbitrary-precision limbs. Complexity is
bounded by operand width and physical memory bandwidth rather than
by the potentially enormous number of rejected answers.

**Exact equivalence requirement:** where the 55-stage contract requires
a legacy method, it must remain physically present and observable.
Optimization cannot replace or erase a mandated DISCOVERY or PATCH,
and its own stage must prove it preserves *all observable semantics*.

## Evidence

A separate scratch executable compared loop and closed forms over
all domains \(S=2..150\), all \(N=1..S\), every \(A=1..S\),
both directions: **2,272,548 cases; 0 disagreements**. This is an
arithmetic comparison, not RTL execution or formal equivalence.

`tests/tb_selection_rejection_equivalence.sv` performs another
comparison for all \(S=2..64\) using SystemVerilog, plus 127-bit,
two-digit and three-digit arithmetic boundary checks. Its results
must remain `UNVERIFIED` until a real simulator runs the test.
