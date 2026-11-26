# Stage56 profiler failure triage — 2026-11-26

Parent 08a2d844eb78b0408ab74b83ba17f8cc5202516d, branch PHP+Bahasa-Melayu, PROJECT_ID PC-BRANCH-PHP-MALAY.
Push run 45697840663 completed/failure. B4 job 139499813371 PHP 8.3.37: core rank/unrank step 4 success; profiler step 5 exit 255, artifact 15063522464 (18 CRC-valid entries, SHA256 b04bb839a4306d143577849502c10011858d945500391ef1c5140c4fda796664) contains RuntimeException STAGE56_UNRANK_PROFILE_METRICS line 98. Static diagnosis: rank width was recorded at setup or subtraction only, but reset at each bucket. Rank 1 may never subtract in the final bucket. Preserve the original fail-closed schema assertion; seed rank width at each bucket transition. No rank/unrank recurrence change.

External job 139499812485 failed, artifact 15064879756 (79 CRC-valid entries, 78/78 manifest hashes verified, SHA256 e10f8b3a3cad52b4685d168e51ced21d2d4c22c46465efaf0aa01d283a68961f; exact project/SHA). All three year exits 124; stderr empty. 4999 reached roundtrip_unrank, 5000 roundtrip_rank, 5001 month_weaving_unrank with no completed bucket. Raw sauce comparison exit 1; preserve FAIL. External semantic differential exit 0 only.

First unrank complete buckets:
year | positions | elapsed incl setup s | completed DP rebuild s | branch-base s | cache/checkpoint/rebuild | direct mul/compare/sub | max digits | peak bytes
4999 | 4125 | 249.456 | 136.788 | 48.158 | 116/100/7 | 31846/27915/3966 | 6196 | 224395264
5000 | 4243 | 394.135 | 218.461 | 72.222 | 262/21/15 | 34613/30575/4084 | 6765 | 269484032

DP times joined by monotonic timestamps within each profile's first setup-through-last-bucket interval. Remaining time is not direct BigInt timing; it includes instrumentation and other work. 5001 lacks bucket-level measurements, so no invented breakdown. Compared with parent unprofiled phase elapsed 184.138s and 296.654s, profiling is a plausible contributor, not a controlled overhead estimate. DP dominates measured complete buckets, but fix profiler first to restore trustworthy measurement before choosing a DP algorithm change.

Isolated diagnostic optimization: use exact normalized base-10^9 limb magnitude digit width = 9*(limb count-1)+decimal width of top limb (zero -> 1); O(1) instead of full toString. This does not alter arithmetic or oracle. Tests compare against decimal literals and full string representation including sign, zero, limb boundaries and 6800-digit magnitude. Existing output equality and bucket checks retained. Static review only at commit time; fresh PHP8.3 CI must prove native profiler and B4, and three real-year runs on new SHA. No duplicate run on parent, no stage acceptance, no PATCH22/PATCH23/main/merge/publication.
