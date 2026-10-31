# Stage13 PATCH02 — bounded ticket-directed canonical weaving

## Demonstrated failure
On [run 41213730086](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41213730086), HEAD `3e8c69c1acf78e74d3b6630923a865b5e18009ff`, 13 jobs including verify succeeded; Stage13 job 124573824455 compiled/bound/linked with GNAT 13 but raised `STORAGE_ERROR: Bignums.Normalize: big integer limit exceeded` in the 45-month weave test. The final multinomial for 45 months of 94 days is already beyond GNAT's bounded Big_Integer; removing intermediate factorials alone is insufficient.

## Semantics and algorithm
Preserve exact month multiplicities and the canonical opening and closing rails (month IDs 1..M). Replace global lexicographic rank for full-year weaving by a bounded *ticket at each interior slot*: at position i (1-based), with r remaining slots, use a shifted sealed stream with `First=Answer_At(stream,i-1)` and unchanged direction, then `Choose_Rank(shifted,r)`. Consume one occurrence of the month containing that ticket among ascending cumulative counts. Each ticket lies in [1,r], r <= 5778; no factorial or gigantic count is constructed.

**This deliberately changes the mapping and potential distribution; it is not mathematically equivalent to the earlier global lexicographic rank.** The numerical values of final five fields may differ from the abandoned algorithm. Exact multinomial count and one-based lexicographic unrank remain available only for small representable fixtures; 45-month stress checks use ticket extremes instead. This is reference-branch work only, not a claim of production or cross-branch correctness.

## Bounded verification contract
Keep all 6 two-month and 210 three-month exact lexicographic rank tests, and shape/rail/multiplicity checks on the 45×94 extreme-ticket cases; expected marker `STAGE13_PATCH01_WEAVE_ASSERTIONS= 2595` (unchanged name). Retain four Calendar_Date invocations and 25 postconditions: `STAGE13_DISCOVERY10_ASSERTIONS= 25`. Stage13 acceptance requires completed/success verify and native-stage13-discovery10 on the same HEAD, both markers and GNAT 13 compile/bind/link; check all other jobs. Pending or failed CI is not PASS. No main/merge/publication.
