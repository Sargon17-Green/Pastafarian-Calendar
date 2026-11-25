# Stage56 suffix-cache checkpoint triage — 2026-11-25

PROJECT_ID=PC-BRANCH-PHP-MALAY. Parent 173171eb64d48b3fc1c2b80841fa223e6fa51772. Stage56 NOT ACCEPTED.

## Completed exact-SHA evidence

Push run 45505359711: 33/34 jobs success; B4 138839040807, B5 external 138839040910 failure. B4 ZIP 14972971676 SHA256 ccd24259eda591e73f675e83834ebd8c06917e7118680a91c2409b1ef18ff9a2, 16/16 CRC, exact project/SHA, ten exits zero, empty stderr, PHP 8.3.37; 31,419 fast words and 3,940 rank/unrank checks each, 83,776 positions. External ZIP 14975462524 SHA256 e3cd6cd261141428c1a7a4f201994533c1f352371f5d98c1aab115e14dc118d6, 74/74 CRC and 73/73 manifest hashes, exact project/SHA, canonical cc2cf0b422757a5e7c33218ce30cffa8f99c6786 and empty source status. All 4999/5000/5001 exit124, empty stderr, no final profile JSON. Last open stages roundtrip_unrank, roundtrip_count, month_weaving_unrank respectively. Month-count stream PASS 34/45/46 only; raw sauce mismatch 3/3; external 271 tuples not PHP parity.

Predecessor 0cbec45f635a6f7d15d331aa6a8a6b1d94b60cf3 run 45272320350, 33/34, external ZIP 14869964346 SHA256 a245bef01e292dbf42c725f1c853b3aae036b45b654800131701e74dcb5582eb, 74/74 CRC and 73/73 manifest. All three exit124; final open stages roundtrip_unrank, roundtrip_rank, month_weaving_unrank. Wall-time comparison is confounded: month_weaving_count 92.14/118.76/267.74s old vs 127.33/163.63/369.74s new (count code unchanged); sibling optimization speedup NOT established. dad072d2 push 45272200395 also 33/34 failure by metadata, not artifact-audited.

## Structural model (not PHP Native)

Simulate exact cache lookup/rebuild request schedule on the pinned external reference month lengths and complete weave from ZIP; count DP loop iterations only, not wall time. Old eight consecutive rows vs five-or-fewer absolute stride-8 checkpoints plus remaining active slots (maximum eight retained rows):
- 4999: 217409 -> 148731 cells (5 -> 8 rebuilds)
- 5000: 399134 -> 235232 cells (6 -> 16 rebuilds)
- 5001: 526279 -> 303516 cells (6 -> 17 rebuilds)

Independent Python integer recurrence model compared old/new values on 60 seeded 9..25-month vectors and 46 queries each, including arbitrary out-of-order and wider requests: 2760/2760 exact matches. These are model results only. Row count bound is not a byte/RSS guarantee; existing 512 MiB and 900s limits unchanged.

## Change and contract

For immutable month-length vector, a cached DP row at index i can supply F_i(q) iff stored extent >= q. For rebuild from start, select nearest later checkpoint covering propagated required extent. Otherwise use terminal row. Exact recurrence, BigInt operations, branch order and source binding unchanged. Checkpoints at absolute indices 8,16,24,32,40 only when nonterminal. At most eight retained rows across checkpoint and active caches; wider requests replace shorter rows, never use insufficient extent. No file cache. Existing B4 oracle remains; add two 17/25-month count constants independently derived using Python exact integers and endpoint/repeated/midpoint cases. No actual PHP execution of this patch established at commit preparation.

NEXT: inspect automatically triggered exact-SHA B4 and B5, logs and ZIP checksums/CRC/source pins/exits/stderr. Require unchanged exhaustive B4 + checkpoint regression; all 3 real PHP profiles under 512MiB/900s with exact differential. Compare timings cautiously. If memory/time still fail, instrument per-rebuild cell and peak metrics; do not relax limits. Raw sauce remains open. No PATCH22/PATCH23 integration, main/merge/publication.
