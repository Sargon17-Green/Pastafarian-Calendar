# Stage56 paired fused real-year result — 2026-11-27

PROJECT_ID: PC-BRANCH-PHP-MALAY
Exact source: 921bbddeb70229197d9256a7dcf507e700e44733; automatic push 46059187531 completed failure, 33/34 jobs success. External job 140709010048 failed raw Sauce, real-year profiling and paired comparator. B4 job 140709010415 success: 449 arithmetic, 39 small/3 large, 3990 probes, 128 width benchmarks, 3940 rank and 3940 unrank; ZIP 15227951895 SHA256 95cdce4e1f969e48ade5ef7f583e5979e5c37500239da91163f6ba87791a32d6, 24/24 CRC, exact identity, ten core exits and fused/scratch zero, five stderr empty. External ZIP 15232361899 SHA256 ba4765c83605c7b15128171aaa0ce051dfc6520cad0c596a0e408f2f266f4464, 103/103 CRC, 102/102 manifest hashes, no unlisted members except manifest; exact project and SHA in both modes, canonical source cc2cf0b422757a5e7c33218ce30cffa8f99c6786. Job upload digest matches. External 271 tuples PASS only; both independent month-count trace reports PASS (3 years each), raw Sauce exit1.

|Year|Default exit|Fused exit|Last started stage both|Observed peak bytes both|Max observed rows both|Completed count seconds default/fused|
|---|---|---|---|---|---|---|
|4999|124|124|roundtrip_unrank|224395264|8|119.541 / 115.373|
|5000|124|124|roundtrip_rank|269484032|8|155.476 / 151.671|
|5001|124|124|month_weaving_unrank|388497408|8|346.000 / 321.912|

All six stderr empty, completed DP rebuild row-cell sums match planned and end values. Month-weaving choice count and selected rank match in start records for each pair (partial evidence, not full semantic output). Four cutlet oracle messages (4999/5000 both modes); no 5001 cutlet completion. No final year JSON for any mode. All six hit 900s timeout; exact paired report PAIRED_QA_REJECT, each nonzero exit. No whole-year speedup or final semantic digest comparison possible. Do not infer a regression across different runners from historical wall times. Observed peaks do not regress within pairs, but missing completed profiles fail the contract, and 5001 exceeds 810s. No relaxation or repeat of the failed experiment. Restore four opt-in wiring files to exact parent 76261c95683d331bb890a739dd5ba72494d1107b blobs; preserve synthetic fused test and arithmetic guard, historical comparator and evidence. Fast-forward, not reset. Stage56 NOT ACCEPTED; raw Sauce FAIL. No PATCH22/PATCH23/main/merge/publication.

NEXT: independently quantify completed DP stage/cell/position throughput from paired censored traces; investigate repeat recomputation or alternative arithmetic not already rejected, with bounded source-specific contract. Preserve independent roundtrip checks, do not claim actual-year improvement from partial timings.
