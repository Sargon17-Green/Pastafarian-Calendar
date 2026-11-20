# Research-only Native Chapel prefix-rank baseline (pre–Stage 6)

**Source lock:** parent f38abd1f3e0fc8a7f90595c57ed27271d862a3e6 (native polynomial root passed in CI 44716482398). The legacy year-boundary GateOracle 180-second exit 124 is independent and inconclusive.

## Testable finite contract

Input: an ordered tuple of 1–4 month lengths, each in 1..3, with total days <=8. There are precisely 88 tuples. A legal word uses each month identifier its specified number of times, with first and last occurrences of identifiers both strictly ascending.

Output: exact bigint count for a prefix; zero-based lexicographic rank for each legal complete word; and a complete legal word for each rank 0..count-1. Prefix blocks partition the number of completions. Out-of-range and invalid-first-symbol cases return zero or reject. The algorithm is exact integer arithmetic: it applies the same-branch one-dimensional insertion transfer to each candidate prefix, *recomputing* DP states; no floating-point estimates or text translations.

Independent oracle: Python standard-library **direct multiset permutations**, ordered lexicographically by symbol; no imports from Chapel, Python insertion transfer, sparse DP, or GMP. Acceptance requires exactly 88 families, 42,221 distinct permutations inspected, 331 legal words, 662 Native rank/unrank roundtrips, 2,698 prefix-count cross-check observations (including duplicate prefixes reached along different words), and invalid-first-month checks for every multi-month family. Native Chapel 2.10.0 build must compile, finish in <90 seconds and <=512 MiB RSS. A mismatched rank, word, count, fixture identity, output cardinality or limit is FAIL, not inconclusive.

## Explicit boundaries and next step

This is a finite **polynomial prefix-count baseline**, not an optimized incremental retained-state implementation. Rank/unrank currently recomputes prefix counts and has no bounded full-year median runtime evidence. Its 4244-symbol rank and reverse-rank status is **NOT_TESTED**; Stage 6 and Legacy witness #3 are NOT_CLAIMED. No edits to `src/`, main, releases or protected branches.

Once exact Native CI passes, implement and verify reusable incremental prefix DP/state updates and reverse-adjoint block computation on bounded finite cases with the independent oracle; then two separate 4244-symbol Native median rank/unrank runs each <=180 s and <=512 MiB with dense checkpoints, FIFO witness, and SHA-256 before considering a Stage 6 contract.
