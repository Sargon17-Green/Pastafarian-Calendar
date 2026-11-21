# Stage21 — independent mixed-radix index bound QA (2026-11-21)

Project: `PC-BRANCH-PERL-GUOYU`; branch: `Perl+國語`.  
Inspected HEAD: `7355ec8e1f69bd5732c70c007dfdead613f3d050`.  
Inspected production blob: `lib/Pastafari/Monster/WeavingPrimitive.pm` = `2a87cdca21914a2fd0d1704a0fc6b669c5674955`.

**Scope:** independent, bounded *static/numeric* QA of Stage21's existing 12-month/48-day mixed-radix index representation. It does not add a stage, modify executable Perl code, reproduce the Native suite, or assert full-year acceptance. Previous Stage21 Native acceptance and same-HEAD regression evidence remain separate.

## Invariants, independent derivation

In the active interval `(closed, opened]`, only labels with remaining length >=2 are active. Each active label of original length `l` contributes radix `l-1`; singleton labels never contribute an active digit. Therefore an interval's state-space size is the product of `(l-1)` over its active labels. All original profile lengths are positive, at most 12 labels and at most 48 days in total.

A separate, integer-only optimization (not using the production recurrence, memo representation, or ranking code) defines:

- `F(0,0)=1`; infeasible states have no value.
- `F(k,n) = max((l-1) * F(k-1,n-l))` over integer `l >= 2` and feasible remainder.
- Evaluate all `1 <= k <= 12`, `2*k <= n <= 48`.

The exact global maximum is **589,824**, attained for ten active lengths `[4,4,5,5,5,5,5,5,5,5]`, whose total is 48 and whose digit product is `3^2 * 4^8`. Sixty small `(k,n)` cases were additionally cross-checked using a separate exhaustive enumeration of every composition, with no discrepancies.

For any profile there are at most `(12+1)*(12+2)/2 = 91` distinct `(opened,closed)` interval buckets. Each contributes at most 589,824 entries, so **every mixed-radix memo index is strictly below 91 * 589,824 = 53,673,984**, itself below `2^26`. Every digit code and weight is below `2^20`. Thus integer indices and weights have ample exactness margin on the verified 64-bit Perl environment. When `int(code/weight)` uses IEEE-754 binary64, an exact noninteger ratio with divisor below `2^20` differs from an integer by at least `2^-20`, while a conservative rounding error for quotients below `2^20` is less than `2^-33`; flooring cannot change the quotient. Integer ratios are exactly representable.

Separately, even ignoring all weaving-order constraints, the maximum multinomial word count over positive lengths, at most 12 labels and at most 48 days, is bounded by the balanced profile:

`48! / (4!)^12 = 339917784579447928182134345929899510000000000`

This is a **45-digit** bound, below `10^48`, so the existing four decimal-base-`10^12` limbs are sufficient. This is a capacity argument, not a complete end-to-end proof of rank/unrank correctness.

## Reproduction (Python 3, no third-party dependencies)

```python
from functools import lru_cache
from math import factorial, prod

@lru_cache(None)
def f(k, n):
    if k == 0:
        return (1, ()) if n == 0 else None
    options = []
    for l in range(2, n - 2*(k-1) + 1):
        t = f(k-1, n-l)
        if t is not None:
            options.append(((l-1)*t[0], (l,)+t[1]))
    return max(options, default=None, key=lambda x: x[0])

def compositions(n, k):
    if k == 0:
        if n == 0:
            yield ()
        return
    for l in range(2, n-2*(k-1)+1):
        for t in compositions(n-l, k-1):
            yield (l,)+t

checks = 0
for k in range(1, 6):
    for n in range(2*k, 18):
        exhaustive = [prod(l-1 for l in c) for c in compositions(n,k)]
        if exhaustive:
            assert f(k,n)[0] == max(exhaustive)
            checks += 1
assert checks == 60, checks
best = max((f(k,n)[0],k,n,f(k,n)[1])
           for k in range(1,13) for n in range(2*k,49))
assert best[0:3] == (589824,10,48), best
assert sum(best[3]) == 48 and prod(l-1 for l in best[3]) == best[0]
assert 91*best[0] == 53673984 < 2**26
assert best[0] < 2**20
assert 48 // 4 == 12
upper = factorial(48)//(factorial(4)**12)
assert len(str(upper)) == 45 and upper < 10**48
print("STATIC_BOUND_PASS; oracle cases=", checks)
print("maximum radix product:", best)
print("exclusive index capacity bound:", 91*best[0])
print("unconstrained count bound:", upper)
```

## Gate disposition

**STATIC_BOUND_PASS only** for the explicit numeric capacity assumptions above. No new Perl source change; no new Native, differential, or full-stage acceptance. Stage21 remains the last accepted stage; full-year functionality remains unverified. Stage22 or expanded scope remains subject to the existing owner's explicit authorization. The existing exact-HEAD run `44876323468` and Stage21 artifact `14696880191` are not rerun.
