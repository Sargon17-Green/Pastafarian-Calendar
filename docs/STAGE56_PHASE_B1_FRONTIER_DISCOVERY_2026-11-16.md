# Stage56 Phase B1 — independent exact weaving frontier count (discovery, NOT Phase B acceptance)

PROJECT_ID: PC-BRANCH-PHP-MALAY
Branch: `PHP+Bahasa-Melayu`
Predecessor source: `5bc9d623bb6ce1dc4c5b7c3edbae60cf74b4d459`
Phase A evidence: canonical run 43766830805 completed/success 27/27, dedicated job 132973752715 completed/success, artifact 14182444779 ZIP SHA256 `7e988af75f8b11f750d3edd557f0d49aef8d6110f14f249ea2183cadf5682bb2`, CRC verified, 12,048 assertions using real PHP 8.3.36 BigInt, 6 huge-rank roundtrips, three lint successes, exit 0 and empty stderr under 512MiB/900s.

## Mathematical state and recurrence

Allowed words of multiplicities `n_1,...,n_m` satisfy that their first occurrence indices are ordered and their last occurrence indices are ordered, each strictly `1,...,m`. When a prefix has been consumed, `opened` is the highest symbol ever encountered. All zero residual counts form an initial prefix of the alphabet, because last occurrences are ordered. The unconsumed alphabet has ordered *lasts*; first occurrence is unconstrained for labels `<= opened+1`, and remains ordered for later labels. This reduces a suffix to `(remaining[1..m],opened)`; no previous full word is needed.

Construct valid residual words by adding symbols in increasing symbol order. Let `F_{i-1}(p)` count words using labels up through `i-1` where the first occurrence of label `i-1` appears at position `p`, with previous total length `N`. Any placement of `n_i` copies of new label `i` that preserves the previous word's order must put a final `i` after all old symbols (ordered last occurrences). Let `g` be the number of old symbols preceding the *first* `i`, so its new first position is `q=g+1`. For `n_i >= 2`, the remaining `n_i-2` indistinguishable symbols may be placed among `N-g+1` gaps following that first occurrence, giving the exact binomial weight

`W(N,g,n_i) = C(N-g+n_i-2, n_i-2)`.

For `i <= opened+1`, the old first-occurrence order constraint was already fulfilled in the consumed prefix (or `i` is the first newly opened label), so the available mass is `T = sum_p F_{i-1}(p)`. For `i > opened+1`, the new first `i` must follow the old first `i-1`, so the mass is `P(g) = sum_{p<=g} F_{i-1}(p)`.

Hence `F_i(g+1) = W(N,g,n_i) * (T if i <= opened+1 else P(g))` for `g=0,...,N`, and when `n_i=1`, the final symbol must be the only `i`: `F_i(N+1)=T`. Initialize with one empty word `F_0(0)=1`. Sum the last layer for the count. The gap cases partition all valid words uniquely, proving exactness of the recurrence. Binomial weights are advanced from right to left using the exact ratio `W_t/W_{t-1}=(t+n_i-2)/t` for `t=1,...,N`, checking division remainders are zero. All products and sums in the PHP implementation use the actual `BigInt` class, not floats/GMP or fixture counts.

## Cost and remaining proof obligations

Counting a single suffix requires `O(m * L)` BigInt operations and `O(L)` simultaneously live BigInt values, with `m<=47`, `L<=5778` and positive residual multiplicities at most 123. Bit complexity and PHP allocation overhead remain material; these operation bounds are **not** a verified 512MiB/900s upper bound for rank/unrank. Naively recomputing a complete suffix count for every candidate at every one of `L` lexicographic positions can be `O(m^2 * L^2)` BigInt operations in the worst case, so B1 expressly **does not** introduce a production ranker or integrate with PATCH22/PATCH23. A reusable incremental suffix frontier or another proven optimization is the next engineering requirement.

## Independently checked local evidence

1. A separately written recursive DFS in `tests/stage56_weaving_frontier.php` enumerates word prefixes by legal next symbols and does not use the production insertion recurrence. Local PHP 8.4.24 syntax lints: 2/2. With a **temporary test-only integer BigInt stand-in** (not included in GitHub source), exact small-domain gate: 120 multiplicity vectors, 18,302 distinct valid prefixes, 3,940 complete valid words, six malformed-input rejections — all PASS. This is not PHP 8.3 Native or genuine production BigInt evidence.
2. Independent `tools/stage56_phase_b1_frontier_discovery.py` uses Python integers and a separate DFS to enumerate the same 120 vectors, 18,302 prefix checks and 3,940 words: PASS. Stress *count-only* profiles on local Python: 47 months totalling 5,778 days (`44*123 + 3*122`) generated a 9,478-digit integer in about 2.32 seconds; 47 months totalling 4,700 days generated about 7,677 digits in about 1.07 seconds; 47 months totalling 188 days produced about 168 digits in under 0.01 seconds. These are synthetic admissible multiplicity arrays, not real year 4999/5000/5001 input and not PHP performance evidence.
3. New isolated PHP 8.3 Native discovery job uses `512M`, `timeout 900s`, two lint checks, exact stdout counters, exit=0, empty stderr and SHA-bound ZIP artifact. Native acceptance is contingent on its completed logs and artifact (not on creating this commit).

## Exact NEXT

Check the new B1 Native job on the exact commit SHA and verify real BigInt/counters/artifact SHA/CRC. Then implement and prove efficient exact 1-based lexicographic rank/unrank using this independent frontier, including `0`, `1`, `N`, `N+1`, exhaustive small-domain differential tests, real PHP 8.3/64-bit profiles for generated year records 4999, 5000, 5001 under 512MiB/900s and provider exception/nonmutation gates. Phase B and full Stage56 remain **NOT ACCEPTED** until these gates pass. Do not modify `main`, merge, or silently substitute the test oracle for the independent production source.
