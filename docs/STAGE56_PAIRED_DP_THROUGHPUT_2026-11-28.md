# Stage56 paired censored throughput and next arithmetic contract (2026-11-28)
PC-BRANCH-PHP-MALAY. Source lock e492b03691e9a405882375f2d234278494819323, tree 3f78532ecab67f53176aa00847a1db3a65dbbec2. QA analysis only; no runtime, gates, or policy changes.

## Evidence
Rollback push 46071784338 completed/failure on exact SHA, B4 job 140750203283 success, external job 140750203233 failure (raw Sauce and real-year profile steps). B4 ZIP 15233252401 f11d494029badf064f92251891fa1c889186fe2f8cfe70742bf94e8f3d74973c, 24/24 CRC, exact identity, five empty stderr, log: 449 arithmetic, 3990 rank probes, 128 widths, 3940 rank and 3940 unrank. External ZIP 15235796341 6b656c89f965d15bb84e1e72199607030ad0f2ef6737edd16a21431f115982da, 79 CRC, manifest 78/78 exact, upload digest matches log, exits 124/124/124, empty stderr, no final year JSON; month count trace 3/3 PASS. Paired run 46059187531 external job 140709010048 artifact 15232361899 ba4765c83605c7b15128171aaa0ce051dfc6520cad0c596a0e408f2f266f4464, 103 CRC, manifest 102/102 exact, both mode identities source 921bbddeb70229197d9256a7dcf507e700e44733, six exits 124, empty stderr, no final JSON. Both artifacts independently parsed in Python.

Method: group DP start/row/end records by id, assign start to most recent stage start by monotonic timestamp; verify completed planned_cells = sum(row.cells) = end.cells; check active+checkpoint <=8. Repeated cells per process engine and row = min(emitted cells, prior maximum emitted width). Completed cell throughput = sum(cells in completed rebuilds)/sum(end.seconds), not average per-row rate. Censored stage rows count only emitted cells, exclude unfinished rebuild from throughput. Positions sum only emitted unrank buckets; no missing buckets interpreted as zero work. No claim of full-year speedup.

|year|mode|stage|rebuild complete/started|emitted cells|repeated same engine|completed cells|DP seconds|cells/s|stage seconds|
|---|---|---|---:|---:|---:|---:|---:|---:|---:|
|4999|default|count|1/1|67743|0|67743|119.541|566.69|119.541|
|4999|fused|count|1/1|67743|0|67743|115.373|587.16|115.373|
|4999|default|unrank|7/7|80988|80988|80988|138.218|585.94|222.731|
|4999|fused|unrank|7/7|80988|80988|80988|133.627|606.07|217.692|
|4999|default|roundtrip count|1/1|67743|0|67743|119.167|568.47|119.167|
|4999|fused|roundtrip count|1/1|67743|0|67743|115.693|585.54|115.694|
|4999|default|roundtrip rank|7/7|80988|80988|80988|138.158|586.20|181.893|
|4999|fused|roundtrip rank|7/7|80988|80988|80988|133.487|606.71|176.898|
|4999|default|roundtrip unrank|8/8|85352|85352|85352|151.719|562.57|censored|
|4999|fused|roundtrip unrank|8/8|85352|85352|85352|146.940|580.86|censored|
|5000|default|count|1/1|97394|0|97394|155.476|626.43|155.476|
|5000|fused|count|1/1|97394|0|97394|151.671|642.14|151.671|
|5000|default|unrank|15/15|137838|137838|137838|224.325|614.46|359.203|
|5000|fused|unrank|15/15|137838|137838|137838|216.431|636.87|351.914|
|5000|default|roundtrip count|1/1|97394|0|97394|151.784|641.66|151.785|
|5000|fused|roundtrip count|1/1|97394|0|97394|151.567|642.58|151.567|
|5000|default|roundtrip rank|8/9|60043|60043|48112|130.974|367.34|censored|
|5000|fused|roundtrip rank|8/9|65497|65497|48112|131.532|365.78|censored|
|5001|default|count|1/1|124263|0|124263|346.000|359.14|346.000|
|5001|fused|count|1/1|124263|0|124263|321.912|386.02|321.912|
|5001|default|unrank|11/12|126124|126124|99213|408.097|243.11|censored|
|5001|fused|unrank|14/15|163900|163900|153348|456.914|335.62|censored|

Position evidence: 4999 provider unrank 4125 positions in 222.728/217.689s default/fused, branch-base generation 48.333/48.027s. 5000 provider unrank 4243 in 359.200/351.910s, branch-base 72.075/72.420s. 4999 partial roundtrip unrank 1536/3072 positions, 194.785/212.112 bucket seconds, differing horizons not directly comparable. 5001 no emitted position bucket; no position-rate estimate. DP seconds account for 62.1%/62.5% of default completed provider unrank (4999/5000), so optimizing the row kernel alone cannot remove all cost. Initial rollback count 67743/97394/124263 cells in 135.807/171.030/385.684s, respectively; runner variability prevents direct attribution across runs. Repeated same-engine cells are invariant by row/q/vector; distinct fresh roundtrip engine intentionally repeats initial count. Preserve it.

## Alternative arithmetic qualification (not implemented)
Pinned kernel src/Patches/MonthWeavingInterleaving56.php blob 05a348188f1752c8f10699ea7b76ecd24ad44238, rebuildSuffix lines 501-576; BigInt blob 3ec9a816ed2c704998018abab36efa5a8e98d20c (base 10^9), roundtrip harness blob 020ee3cf81b4e7291bcb4b7ad4805eb385e08528 lines 276-310. Existing per-cell cumulative += weight * following[L+r] with weight update by exact small division. Reject same fused/scratch experiments and cache sharing. Candidate: explicitly opt-in standalone PHP GMP row arithmetic qualification, not production dependency approval. Keep full rows in one representation within kernel, avoid decimal conversion per operand per cell; separately measure canonical BigInt conversion and any memory cost. Extension presence/version must be recorded and missing GMP yields NOT_RUN, not fallback PASS. Local PHP 8.4.24 has neither GMP nor BCMath; no native GMP result. No new dependency installed.

Contract: input positive integer length vector, valid nonterminal row index and q in 0..initial width, terminal row all 1 and nonterminal F_i(0)=0. Independent Python int/math.comb F_i(q)=sum_{r=0}^{q-1} C(L_(i+1)+r-2,r)*F_(i+1)(L_(i+1)+r). Compare exact canonical decimal per cell on 39 exhaustive small vectors plus one fixed larger vector per 34/45/46 shape with independently derived lengths (from first full DP row widths), compare full-row streaming SHA256 and exact count, no giant fixture copied from another branch. Reject nonpositive lengths, invalid q, negative values, nonexact division; zero/one and max-length boundaries, verify same word/rank using independent exhaustive lexicographic enumeration on small vectors. Qualification: same ordered row workload and completed cell count, alternating mode order, 3 paired repeats, record separate conversion, arithmetic and allocation/RSS metrics, 512MiB process limit (including native allocation via OS measurement), 180s bounded synthetic per process, no more than eight live DP rows, no new real-year paired runs until semantic qualification and material >=20% kernel speedup including conversion on each large workload, with no peak regression. A later real-year trial, if qualified, must retain independently rebuilt roundtrip and 900s / 512MiB caps, require 3 final JSONs and all preexisting comparisons. Raw Sauce FAIL, Stage56 NOT ACCEPTED. No PATCH22/PATCH23/main/merge/publication.
