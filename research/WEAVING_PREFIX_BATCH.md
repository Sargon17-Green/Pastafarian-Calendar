# DISCOVERY03 — shared-prefix batched next-symbol counts (research only)

## Scope and result

This is an incremental research step after WEAVING_PREFIX_TRANSFER.md, not a production fix or Stage6. The 2026-11-02 run 41537988785 on commit 4b8d90867ba8e040006b8da876aee9451db98c4a ended with verify=success, small independent oracle 137 cases/1982 rank checks PASS, transfer oracle 137/4983 prefix/1982 rank PASS, 45-month total 4244-day transfer count PASS (22470 bits, SHA256 BE 925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da). Chapel Native year-boundary probe still timed out at STRUCTURE_MONTH_WEAVING_BEGIN after 180s (exit=124, INCONCLUSIVE). This is not a historical third defect.

## Algorithm and contract

Input: positive integer month lengths L=(L1..Lm) and already emitted prefix P; output block[c]=count_prefix(L,P+[c]) for every candidate c in 1..m. If the prefix exceeds multiplicity or is full length, all blocks are zero. Invalid symbols and empty lengths are rejected. Production calendar code is untouched.

For each month j, project P onto months <=j. Encode the constrained insertion gaps as (q,fixed_sum,first_fixed,tail). Cache baseline 1D transfer arrays D_j computed for P, keyed by the month count. For candidate c, all stages j<c are unchanged and can reuse D_(c-1). At j=c increase the new-month trailing minimum by one. At all j>c the appended old letter freezes the former trailing gap and creates an empty new tail. Transfer as in the exact 1D theorem. Cheap necessary conditions reject first appearances that skip earlier unseen months and closing a month while an earlier month remains unfinished. No production remaining-vector recursion or NormativeOracle is imported; finite differential data come from a separately written direct word enumerator.

Worst-case time per candidate_counts query: O(m^2*N) bigint arithmetic; stored baseline arrays O(m*N) bigint objects (not O(N)). Rank/unrank call the batch once per prefix and hence still scale as O(m^2*N^2) bigint arithmetic; no full-year 180-second claim follows from this research.

## Acceptance and measurements

The new self-test covers 137 finite length families, 17,672 next-symbol count comparisons against direct enumeration, 1,982 complete rank/unrank round-trips, plus invalid prefixes and multiplicity boundaries. On the exact logged 45-month/4244-day lengths, it checks the first-letter-prefix (1,) with only candidates 1/2, and a prefix of all 45 first appearances (all 45 candidates nonzero); sum of candidate blocks must independently equal existing exact count_prefix for each prefix. The bounded profile gate is cumulative under 25 seconds and peak RSS under 512 MiB on Linux; these bounds apply to exactly TWO calls, not full-year unranking. A local Python prototype on Linux measured 5.101s for the two profiles and max RSS 305616 KiB (~298.5 MiB); this is not GitHub CI or Chapel Native evidence. New exact GitHub blob requires CI validation before PASS.

## NEXT

Use the profile to derive a per-symbol incremental update that eliminates rebuilding all month-stage arrays at every of 4244 positions, then demonstrate reproducible full-year rank/unrank under 180 seconds and bounded memory with a second independent rank oracle or metamorphic round-trip. Only then consider a separate scoped Chapel research port. Do not extend the timeout, modify production, merge main, or equate this to Stage6 acceptance.
