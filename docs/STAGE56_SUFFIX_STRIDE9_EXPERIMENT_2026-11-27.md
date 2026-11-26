# Stage56 suffix stride-9 isolated experiment (2026-11-27)
Project PC-BRANCH-PHP-MALAY. Exact parent e8840ce832af2079ce46901cd15512eeda5c2958. No Stage56 acceptance.

## Completed evidence
Push run 45900520391 completed/failure, 29 of 30 jobs successful. B4 PHP 8.3.37 job 140184879360 succeeded including profiler schema. Artifact 15156651139 SHA256 b7b84df1967991768f869cf9effcb7b055203f9525d7d008f5697243c1e9284d, 18/18 CRC, source/project exact, ten core exits zero, three stderr files empty. 120 vectors, 3940 words/ranks/unranks, 83776 positions, 31419 fast words; profiler 259 positions/2 buckets. The decimal-width oracle is included in the successful profiler test.
External job 140184878950 failed steps 16 and 18; artifact 15157797537 SHA256 e33910c24db19d0168f51abda15f945c78e1688fd974b5d5cc0201353fdd0c17, 81/81 CRC, 80/80 manifest hashes, no unlisted files besides manifest. Pinned external tuples 271 PASS, raw Sauce MISMATCH, source JDN boundary adapter only PASS. Real-year exits 0/124/124, empty stderr. 4999 766.812s peak 224395264, 5000 timeout roundtrip_unrank, 5001 timeout month_weaving_unrank.

Timestamp joins: DP start/end paired by unique per-process id, interval bounded by first bucket timestamp minus cumulative unrank time and final emitted bucket timestamp. 
|year|profile|positions recorded|unrank s|DP s|rebuilds joined/reported|branch generation s|peak bytes|
|---|---|---:|---:|---:|---:|---:|---:|
|4999|1|4125|184.203|114.187|7/7|40.037|224395264|
|4999|2|4125|195.597|125.334|8/8|40.250|224395264|
|5000|1|4243|292.751|180.705|15/15|59.860|269484032|
|5001|1 partial|1792|531.973|418.171|16/16|53.827|388497408|

The previous profiler parent 08a2d844 had first-unrank 249.456/394.135s; repaired 184.203/292.751s. Against pre-profiler 590f05ac 184.138/296.654s, now comparable, not controlled benchmark. 4999 total 767.003 -> 766.812s; 5000/5001 still time out. 5001 partial bucket data not a full-year result.

## Single optimization and contract
DP dominates measured unrank (62%, 64%, 62%, 79% partial). For 45/46 months only, shift absolute stride 8 to 9: checkpoints 9,18,27,36 and four active rows instead of five checkpoints and three active. Retain at most eight cached/checkpoint rows, unchanged 512M and 900s harness limits; allocator peak is not guaranteed by row count. No recurrence, bounds, rank order or other shape change.
Predictive model, not measurement: enumerate monotonically increasing row requests, count a rebuild on missing active/checkpoint row, use nearest covering later checkpoint and replace active window; weight row work by initial full-rebuild row durations, ignore q shrink and cross-traversal effects. 45 months stride8 ->9: predicted rebuilds 15->10, row work 59->54, weighted 181.60->165.07s; 46 months 16->10, 62->56, 419.52->368.22s. This is why stride9 chosen over 11 (which predicts 446.86s for 46). Real memory and timings must be measured; revert if peak or correctness regresses.
Independent Python integer count for lengths [4]*m: initialize terminal row to ones; for i=m-2 down to 0, q=1..4+3*i, F_i(q)=sum_{k=1..q} comb(k+1,k-1)*F_{i+1}(k+3), F_i(0)=0. Existing 17-month constant reproduced. Added 45/46 counts, lexicographic endpoints twice and midpoint roundtrip; original regression assertions and CI marker preserved. New marker printed only after new checks. No Native result claimed for this commit.
NEXT: verify exact-SHA push B4 and new marker, then compare 3 year exits and joined DP cost, row counts and peak against above; no duplicate dispatch; no acceptance until all raw and production gates pass. No PATCH22/PATCH23/main/merge/publication.
