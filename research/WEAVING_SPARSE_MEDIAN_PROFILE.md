# DISCOVERY03 — bounded genuine median-prefix performance profile (2026-11-05)

This is research on the existing Chapel+Українська-мова branch, NOT Stage6 or production. The immediate upstream CI 41871934829 verified the independent sparse finite oracle (137 families / 1982 rank checks / 8361 partitions), the kernel differential (137 / 1988 prefixes / 4901 forward / 9802 transpose comparisons), and six genuine median symbols (7.926 s, 231016 KiB). Its overall workflow failed ONLY at the old Chapel year-boundary 180s timeout; that failure is inconclusive rather than a third Legacy witness.

## Measurable diagnostic contract

Input: the existing 45 positive month lengths totaling 4244 and the fixed median rank floor(total/2). Independently pin the 22470-bit root SHA-256; do not generate an arbitrary small prefix or reuse the previous rank result as a fake measurement.

For up to 64 actual median decisions, independently time candidate partition computation `state.blocks()` and committed transition `state.take(c)`. For each decision, require `sum(blocks)==state.total`, a legal selected candidate, `0<=rank<state.total` after the transition; pin the known first six symbols `(1,2,3,4,5,6)`. Report cumulative times at symbols 6/16/32/48/64 and final maximum single-step durations, process maximum RSS, prefix SHA-256, stop reason, and completed symbol count.

Bound by 50s soft budget checked between *complete* symbol transitions, 512MiB RSS guard at each transition, and 65s OS hard timeout with 5s grace. A partial diagnostic prints `WEAVING_SPARSE_PROFILE_RESULT=BOUNDED_PARTIAL`; 64 symbols prints `PROFILED_64_ONLY`. Neither means full rank/unrank, Stage6 PASS, or an independent performance acceptance. OS timeout (exit124) is failure/inconclusive, not PASS. The full 4244-symbol median and reverse-rank remain NOT_TESTED.

## Decision after the measured run

Use completed logs and the separated blocks/take timings to prioritize one operator cost; optimize only research code, then repeat finite independent differential gates. Claim full-year performance only after genuine full median rank AND reverse rank finish <=180s each and under 512MiB, with the old Chapel timeout still separately classified.


## 2026-11-06 — measured take bottleneck and exact-coefficient cache candidate

Run 41978850054 on `1e27317860dc31d886458acd48c4c2a737a5c25a` completed: verify success, Native Stages 1–5 and independent sparse finite/kernel QA success. The separate historical Chapel year-boundary probe timed out (exit 124 at 180 s; inconclusive). Genuine median-prefix profiler verified root and completed 59/64 decisions before the 50s soft guard, with blocks=13.977 s, take=35.889 s, elapsed=50.618 s, max RSS=220776 KiB, result BOUNDED_PARTIAL; full-year median rank/unrank NOT_TESTED.

Research-only hypothesis: a major part of `take` is repeatedly recomputing identical exact binomial coefficients for each fixed month length and cumulative state size. The sparse forward kernel now caches its full recurrence row `C(k+d-2,d)` (d=0 uses 1; k=1 uses zero for positive d) with a bounded 96-entry LRU, then indexes it instead of repeating exact `comb` and division on each forward transfer. This does not modify the Chapel production algorithm or its normative gate.

Independent arithmetic preflight compared 16,347,630 row entries across n=0..500 and k=1..130 against `math.comb` exactly, all equal. Actual new-code acceptance still REQUIRES GitHub CI independent dense-transfer differential 137/1988/4901/9802, finite rank/unrank 137/1982/8361, verify and Native Stage1–5; the same bounded genuine median-prefix profile must be remeasured. No performance improvement is claimed until those post-change measurements. A full 4244-symbol median rank and reverse rank, each <=180 s and RSS <=512MiB, remain separate unpassed gates.


## 2026-11-06 — measured cache regression and candidate-state reuse experiment

GitHub Actions 42125590371 completed/failure on the exact branch SHA `fcbb26e440fb1d1411d6755cf3de8e8cbdc65ae7`. Verify, Native Stage1–5, DISCOVERY03 (2518/0), independent finite 137/1982/8361 and sparse kernel 137/1988/4901/9802 passed. The historical Chapel 180s month-weaving probe again exited 124 (INCONCLUSIVE, not a third Legacy witness). The new actual median profile root was verified and reached 61 symbols; blocks=13.997s, take=35.688s, elapsed=50.439s, peak RSS=230108KiB, STOP=SOFT_TIME_BUDGET, RESULT=BOUNDED_PARTIAL. Previous baseline was 59 symbols; blocks=13.977s, take=35.889s, elapsed=50.618s, RSS=220776KiB. The coefficient-row LRU did not provide material acceleration; full 4244-symbol median rank/unrank remains NOT_TESTED.

The next isolated research-only experiment reuses exactly one already-computed forward state. For eligible candidate c>1, `blocks()` has already computed `sparse_transfer(states[c-1], sizes[c-1], lengths[c-1], extend_spec(specs[c],c,c))` in its reverse-adjoint candidate partition. When `take(c)` commits that same candidate, it now adopts this identical immutable `SparseVector` rather than recomputing the c-th transfer. Candidate 1 and downstream c+1..m transitions still take the original route. The prepared states are invalidated after each committed symbol; no production or normative source is changed.

**Validation contract:** finite brute-force/occurrence-poset independently checks 137 families, 1982 rank/unrank roundtrips and 8361 partitions; every chosen c>1 must yield exactly one reuse and must equal an independently recomputed full c-th transfer. The existing independent dense transfer/transpose differential must still prove 137/1988/4901/9802. The CI 50-second bounded profiler reports actual reused transfers and genuine median-prefix timings/verified root. Do NOT claim performance improvement, full rank/unrank acceptance, Stage6 PASS or Legacy #3 until new completed logs and the full 4244-symbol median and reverse-rank gates (each <=180s and <=512MiB).


## 2026-11-06 — completed candidate reuse CI; next bounded per-month transfer instrumentation

Run 42174777254 completed/failure at exact e9377f15fc91207266118093ce89277fa32a53b3: verify and Chapel native Stages 1–5 PASS; DISCOVERY03 2518/0; independent finite 137/1982/8361 PASS with 5969 reused transfers; independent sparse kernel 137/1988/4901/9802 PASS. The old Chapel 180s month-weaving probe exit124 is INCONCLUSIVE, not Legacy witness #3. Genuine median root VERIFIED, 61 symbols, 59 reused transfers, blocks=14.045s, take=35.776s, elapsed=50.576s, RSS=230196KiB, result BOUNDED_PARTIAL; full 4244-symbol median rank/unrank NOT_TESTED. Candidate reuse does not materially improve the previous 61-symbol 13.997/35.688/50.439-second profile.

Next hypothesis measurement: separate time and total forward transfer work by blocks/take and month, before proposing further optimization. The opt-in wrapper calls the exact unchanged sparse_transfer; captures elapsed seconds, calls, visited free output slots (not multiplications), fixed-spec calls, output lengths, and five highest-cost months. Constructor transfers excluded. A finite differential smoke compares all states and partitions with and without telemetry. Profiling overhead forbids inferring a speedup from elapsed time alone. CI acceptance requires verify, Native Stage1–5, DISCOVERY03 2518/0, independent finite 137/1982/8361 and kernel 137/1988/4901/9802, observability smoke, 50s root-verified bounded profile. The full rank/unrank time and RSS gates remain unpassed.
