# Stage56 / Phase A — isolated PHP production combinatorics

PROJECT_ID: PC-BRANCH-PHP-MALAY
Branch: PHP+Bahasa-Melayu
Parent (required): 8f6cc5d48b7b77d2525c6e18be2f3017aaa82552
Stage55 Native acceptance is separately attached to source fe5511b6f294a005f3a287ec426635d89717d6e5, run 42188526067. Stage56 full acceptance is **not** claimed.

## Exact production component

`src/Patches/YearStructureSlices56.php` is an isolated, opt-in component, with no new `BootstrapKernel` route, no dependence on `tests/oracle` and no `DateTuplePatch23` injection. Its methods count, rank and unrank:

1. Positive gate-gap partitions into `k` parts, optionally with required **proper** prefix at gate offset `r`; count is `C(g-1,k-1)` or `Σ C(r-1,j-1) C(g-r-1,k-j-1)`.
2. Month-length compositions, lengths 4..123; coefficient of `(1+z+...+z^119)^m` from exact inclusion-exclusion. Counts outside the admissible length window are zero, while malformed input arguments are rejected.
3. Ordered distinct canonical name indices 1..pool, using falling-factorial block sizes and mixed-radix zero-based offset inside the public 1-based rank convention.

`Pastafari\Stage01\BigInt` handles all counts and ranks; no float, double conversion, GMP requirement or lossy int cast of BigInt is used. Binomial divisions enforce an exact remainder of zero. The only `toIntExact()` conversion concerns a validated single factoradic digit that is less than 47. Memoization is per-instance; the component has no long-lived global state. The input arguments and output arrays are not mutated. No weaving logic is attempted.

## Scope, complexity, proofs

- Gate `g` is bounded to `[1,5778]`, partition size `[1,17]`, required interior cut `[1,g-1]`. Each unranking candidate uses an exact completion count, and subtracts whole lexicographic blocks, so its output is the unique vector indexed by the input rank.
- Year-day total is bounded `[0,5778]`, months `[1,47]`. Each candidate prefix leaves a residual bounded-composition count; the resulting recurrence partitions the lexicographic suffixes disjointly. The coefficient formula counts those suffixes exactly by inclusion-exclusion. An impossible month total has count zero and no accepted rank.
- Names are selected without replacement. A candidate name owns `(pool-i-1)!/(pool-selected)!` suffixes at position `i`. Euclidean division chooses its lexicographic digit, proving the rank/unrank inverse.
- Complexity depends on input and memoized `C(n,k)` values. With `k<=17` and `m<=47`, runtime is polynomial in year length (at most 5778) and small fixed upper bounds, with no enumeration of all combinatorial outputs. There is no weaving performance claim, and no claim this partial component already generates complete normative years.

## Verification gates and boundaries

The independently authored test-only recursive DFS enumerates **all** small cutlet partitions, bounded month vectors, and partial ordered name selections; it does not use the production counting formulas. Each vector is compared against both rank and unrank, plus zero and upper+one rank rejection. There are malformed-input tests, numeric examples, and six huge-rank 1/N roundtrips that must run against the actual repository `BigInt` on GitHub PHP 8.3 64-bit.

Local PHP 8.4.24 syntax lint passed for both new files. A local **small-domain-only** execution with a temporary native-int stand-in for `BigInt` passed 12,039 assertions (1,299 cutlet vectors; 2,379 month vectors; 1,903 name vectors; 585 rejected ranks/inputs). This is an algorithmic small-domain check, **not** a test using the repository's BigInt and **not** Native acceptance. The CI workflow `php-malay-stage56-slices.yml` uses the actual production `BigInt`, PHP 8.3, `512M`, an explicit `900s` test bound, three lint gates, exact counters and SHA-bound evidence artifact. Only a completed successful run on the new implementation SHA can establish the Phase A Native gate.

## NEXT after Phase A

First verify the new CI completed result and SHA-bound artifact. If Phase A is accepted, proceed with Stage56 phase B: an independently derived exact month-weaving frontier algorithm, proving recurrence and resource upper bounds before integrating with PATCH22/PATCH23. The full Stage56 gate still requires 9 target dates over three actual years and all prior CI gates. Preserve main, historical Legacy behavior, normative source and trusted Year5000 dependency.
