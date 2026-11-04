# DISCOVERY03 — Sparse forward and algebraic-transpose research (2026-11-04)

## Exact contract
Only legal words with increasing first and last occurrences are counted. Keep prior Python baseline and Chapel production unchanged. For month j, an already fixed interior prefix or a positive trailing month-j prefix leaves at most one admissible first-insertion gap; otherwise possible gaps form a suffix i>=q. Store a forward state as (offset, tuple(values)) rather than a length-N dense array.

For the general suffix case with i<n, insertion weight w(i)=binomial(k+n-i-2,n-i), while w(n)=1. Compute adjacent coefficients by the exact recurrence w(t-1)=w(t)*t/(k+t-2) for t=n-i; reverse transpose uses w(t)=w(t-1)*(k+t-2)/t, starting w(1)=k-1. Integers divide exactly. Single-gap transpose equals one weighted after-value repeated through the admissible predecessor positions. The legal-candidate blocks must sum to the current continuation count.

## Reproducible correctness gates
The new script test/weaving_sparse_dual.py contains a separate implementation of sparse transfer and transpose, preserving the prior dual-adjoint script as a comparison reference. It invokes existing independently built complete-word enumeration and occurrence-poset oracle: 137 families, 1,982 rank/unrank assertions, 8,361 partition checks. Full 45-month / 4,244-symbol total must have bit length 22,470 and SHA-256 (big-endian) 925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da. The bounded median test performs exactly six choices, compares the resulting prefix count against the independent dense transfer, with a 25 s internal and 30 s OS gate, maximum RSS 512 MiB. The old Chapel year-weaving timeout remains INCONCLUSIVE_TIMEOUT_180S.

## Local bounded evidence; no full claim
The separately tested prototype passed 137 families / 1,982 roundtrips / 8,361 partition checks and the six-symbol median prefix. On the same local environment, sparse-before-recurrence took 9.799 s (310,040 KiB measured after recurrence; earlier sparse-only RSS 309,944 KiB), versus sparse-with-recurrence 6.696 s / 310,040 KiB; these local figures are not comparable to GitHub runner timing. An independent bounded 38 s diagnostic reached 48 real median symbols at 35.465 s, then was terminated; 4,244-symbol general median rank+reverse-rank is **NOT TESTED**. No Chapel production, Stage6, main, merge or publication change.

## Next gate
Inspect completed CI for exact markers WEAVING_SPARSE_FINITE_RESULT=PASS and WEAVING_SPARSE_MEDIAN_PREFIX_RESULT=PASS; keep general median NOT_TESTED. Then profile longer *real* median prefix and reduce per-symbol transfer work or design a different exact structural algorithm. Only claim full 4,244-symbol median rank/unrank when both operations complete within 180 s per trial and <512 MiB, and independent finite tests remain valid.
