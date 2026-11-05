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
