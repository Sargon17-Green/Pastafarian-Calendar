# Stage56 B5 DP profiling — 2026-11-25

PROJECT_ID=PC-BRANCH-PHP-MALAY; parent f485b5f6e9882f28287f317f3c11d16345a44684. Stage56 NOT ACCEPTED.

Exact push 45551439460: B4 job 138993295966 success; artifact 14994550534 SHA256 3bd40d950960ed63834e79f9b5d6e26335da9ebd96db9cd5f76c2acf77eccea3, CRC 16/16; ten exits zero, empty stderr; 31419 fast words, checkpoint vectors=2 endpoints=6 midpoints=2. External job 138993296012 failure; artifact 14995004641 SHA256 2f337603965d5acc0ea89e6bfe7aee1641f44b647104917becd72aeb07563855, CRC 75/75, manifest 74/74; project/branch SHA and clean canonical source cc2cf0b422757a5e7c33218ce30cffa8f99c6786 verified. PHP8.3.37: 4999 exit0, 785.941s, peak 224395264 bytes, month differential PASS, rank roundtrip PASS, cutlet oracle PASS, status PHP_REAL_YEAR_QA_PASS_NOT_STAGE56_ACCEPTANCE. 5000 exit124, last stage roundtrip_unrank, observed peak 270532608 bytes. 5001 exit124, last stage month_weaving_unrank. Empty stderr all three. Raw sauce 3/3 mismatch; independent 271 external tuples PASS only.

Instrumentation contract: opt-in only in source-bound QA, separate per-year .dp.jsonl in existing artifact directory. Each rebuild emits a start (unique process-local ID, engine, month count, index range, q extent, exact planned nonterminal DP iterations, covering checkpoint flag), each completed row (actual iterations, cache rows, monotonic time, allocated bytes and process peak), and end (total completed cells, elapsed seconds). Terminal row has zero recurrence iterations. A timeout can leave a start/partial rows without end, never a fabricated end. Compare completed row sum to planned/end count and active+checkpoint rows <=8; distinguish process allocator peak from per-rebuild RSS; no per-cell logging or arithmetic changes. Retain existing 512MiB/900s, raw sauce gate and independent external checks. Require B4 unchanged and all genuine years, not just 4999; isolate next bounded optimization using the new evidence. No integration PATCH22/PATCH23, main/merge/publication. Instrumentation not yet Native-tested.


## Opt-in MonthWeavingInterleaving56::unrank profile (schema v1)

The follow-up profiler is deliberately separate from the existing suffix-DP rebuild profiler. It is enabled only when STAGE56_UNRANK_PROFILE_PATH is a non-empty path. With the variable unset, unrank() emits no file and retains its normal return value and arithmetic path.

- Output is JSONL: one event=bucket record after each 256 completed unrank positions, plus one final partial bucket when needed. There is no per-candidate or per-cell I/O.
- bucket_elapsed_ns measures the current bucket; unrank_elapsed_ns is cumulative. setup_elapsed_ns (first bucket only) includes total-count construction and rank validation before position 1.
- candidate_count, first/next sibling candidate counts, skipped candidates, and new-month branches distinguish the paths explored.
- branch_base_generation_ns measures firstBranchBaseCount, nextBranchBaseCount, and new-month multiplyByBinomial generation. Suffix-DP rebuild work remains accounted for by the separate .dp.jsonl profile.
- direct_bigint_mul_calls, direct_bigint_compare_calls, and direct_bigint_sub_calls count public BigInt::mul/compare/sub call sites in unrank; the final equals() is counted as a comparison. They do not count mulSmall/divSmallExact internals or operations performed inside rebuildSuffix.
- suffix_cache_hits, suffix_checkpoint_hits, suffix_rebuilds, and terminal shortcuts count calls made by this unrank invocation, including its initial total-count lookup.
- max_decimal_digits and max_decimal_digits_by_role track the decimal widths of rank, total, suffix, candidate-base, cumulative-base, and scaled-block values observed at the unrank call sites. They do not claim to measure every private intermediate inside BigInt.
- allocated_bytes and process_peak_bytes use PHP allocator counters (memory_get_usage(true) and memory_get_peak_usage(true)); they are not operating-system RSS.

The bounded schema/output-neutrality test uses five 52-element month lengths (260 positions), checks identical profiled and unprofiled output, and requires exactly two buckets (256 + 3). It runs as a separate PHP 8.3 Native step; the existing B4 oracle file and its 120 vectors / 3,940 words / 83,776 positions are unchanged. The source-bound real-year harness also writes <year-output>.unrank.jsonl, which is included automatically in the existing artifact hash manifest.

This instrumentation is diagnostic only. It changes no recurrence, candidate order, rank/unrank arithmetic, output, time limit, memory limit, or acceptance policy. A profiler-schema PASS is not a real-year PASS and does not accept Stage56. The raw Sauce differential remains an independent failing gate.
