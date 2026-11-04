# MATLAB+Polski Stage55 — AFTER27 to AFTER28 bounded differential

## Certified predecessor
- Branch `MATLAB+Polski`, exact HEAD `ecefd7a4d441f7ffc4a42bea927bd22571bfe698` before the change.
- Native/Python [run 41712181217](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41712181217), job 126182782116 completed/success. Canonical Names Lock [run 41712181111](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41712181111), job 126182780392 completed/success.
- Native: `STEPS=27 REMAINING=4217 LETTER=19 REJECTED=2`. Independent Python: `SMALL=22 BLOCKS=21`, byte-identical strict row `POSITION=27 YEAR=5000 CUTLET_INDEX=15 CUTLET_DAY=27 MONTH_INDEX=27 MONTH_DAY=2`, plus two invalid position rejects.
- Original artifact 13268373088: ZIP size 15517 bytes; SHA256 `03be57ea276ce8a4855f7265fdaf7c82baa088ab3aeaf6c178c1bc6ebf496b89`; all seven members CRC valid; archived unchanged at `/QA_Artifacts/PC-BRANCH-MATLAB-POLSKI/Stage55_AFTER27_41712181217_original.zip`.
- Pinned AFTER27 JSON SHA256 `82765dd2c1e403cfc2ea8b5ec933a4aeac9ef898b3145d09dbd9f77e8bddca72`.

## Independent bounded oracle and expected AFTER28 transition
- Fixture: year 5000, 45 month lengths summing 4244; `first_day=-15057702`.
- Input prefix `[1,2,3,4,5,6,7,4,8,9,10,9,11,6,12,13,14,15,16,16,17,7,18,2,19,20,19]` (27 elements); `openedUpTo=20`, `closedUpTo=0`, `remaining=4217`; exact predecessor rank/count in pinned checkpoint.
- Independent insertion-count Python DP partitions the parent into 21 lexical child blocks (21/21, exact integer sum), selects symbol `5`, keeps `openedUpTo=20`, predicts `remaining=4216`, month name index `24`, second occurrence/day `2`. This is a prediction, not Native evidence.
- Strict expected row: `POSITION=28 YEAR=5000 CUTLET_INDEX=15 CUTLET_DAY=28 MONTH_INDEX=24 MONTH_DAY=2`.
- Native MATLAB must select one lexical child with the production exact BigInt adjoint algorithm, recount with production suffix API, JSON round-trip, verify five fields via `MonthDayCompatibilityRoute`, and reject positions `0` and `29`.
- Independent Python recomputes exact child partitions by binomial insertion DP (not production adjoint), verifies rank interval, output count, 22 exhaustive tiny controls, and exact byte equality of the 5-field row.

## Acceptance and scope
- Require completed/success on the exact new SHA for Native/Python and Canonical Names Lock, inspect logs, assert Native `STEPS=28 REMAINING=4216 LETTER=5 REJECTED=2`, independent `SMALL=22 BLOCKS=21`, 2 negative rejects and byte-identical expected row. Verify predecessor pin, next JSON SHA256, original ZIP digest/CRC7/7, and archive unchanged.
- This proves only one additional bounded transition. Full-year canonical oracle, cross-engine soak and final Stage55 PASS are NOT VERIFIED; `LAST_COMPLETED_STAGE=54`.
- Do not run historical PASS, heavy DAG, unbounded full-year jobs or merge/main.
