# DISCOVERY03 — bounded genuine median-prefix performance profile (2026-11-05)

This is research on the existing Chapel+Українська-мова branch, NOT Stage6 or production. The immediate upstream CI 41871934829 verified the independent sparse finite oracle (137 families / 1982 rank checks / 8361 partitions), the kernel differential (137 / 1988 prefixes / 4901 forward / 9802 transpose comparisons), and six genuine median symbols (7.926 s, 231016 KiB). Its overall workflow failed ONLY at the old Chapel year-boundary 180s timeout; that failure is inconclusive rather than a third Legacy witness.

## Measurable diagnostic contract

Input: the existing 45 positive month lengths totaling 4244 and the fixed median rank floor(total/2). Independently pin the 22470-bit root SHA-256; do not generate an arbitrary small prefix or reuse the previous rank result as a fake measurement.

For up to 64 actual median decisions, independently time candidate partition computation `state.blocks()` and committed transition `state.take(c)`. For each decision, require `sum(blocks)==state.total`, a legal selected candidate, `0<=rank<state.total` after the transition; pin the known first six symbols `(1,2,3,4,5,6)`. Report cumulative times at symbols 6/16/32/48/64 and final maximum single-step durations, process maximum RSS, prefix SHA-256, stop reason, and completed symbol count.

Bound by 50s soft budget checked between *complete* symbol transitions, 512MiB RSS guard at each transition, and 65s OS hard timeout with 5s grace. A partial diagnostic prints `WEAVING_SPARSE_PROFILE_RESULT=BOUNDED_PARTIAL`; 64 symbols prints `PROFILED_64_ONLY`. Neither means full rank/unrank, Stage6 PASS, or an independent performance acceptance. OS timeout (exit124) is failure/inconclusive, not PASS. The full 4244-symbol median and reverse-rank remain NOT_TESTED.

## Decision after the measured run

Use completed logs and the separated blocks/take timings to prioritize one operator cost; optimize only research code, then repeat finite independent differential gates. Claim full-year performance only after genuine full median rank AND reverse rank finish <=180s each and under 512MiB, with the old Chapel timeout still separately classified.
