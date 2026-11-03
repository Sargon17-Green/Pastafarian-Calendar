# MATLAB+Polski Stage55 — AFTER25 to AFTER26 bounded differential

## Verified predecessor
- Existing branch `MATLAB+Polski`, commit `a2e91bee5bf14b83bf7dbe82d375cef1d0b93aca`.
- MATLAB R2026a Native/Python run [41654601059](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41654601059), job 125981441032, completed/success; Canonical Names Lock [41654600767](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41654600767), job 125981439946, completed/success.
- Native `STEPS=25 REMAINING=4219 LETTER=19 REJECTED=2`; Python `SMALL=22 BLOCKS=19`; byte-identical five-field row `POSITION=25 YEAR=5000 CUTLET_INDEX=15 CUTLET_DAY=25 MONTH_INDEX=27 MONTH_DAY=1`.
- Original artifact 13240935740 ZIP SHA256 `3dc3b0cd57b6f10144001fc133d22a2ac0a06d7d8bf8f898b3f5e3d56e6cf46e` (15490 bytes, CRC7/7), archived at `/QA_Artifacts/PC-BRANCH-MATLAB-POLSKI/Stage55_AFTER25_41654601059_original.zip`.
- Pinned AFTER25 JSON SHA256 `7d589bd5333aea10ee16e368364862caa3a081ee37f6016e459f8f42297baa40`.

## Independent bounded oracle and expected transition
Year 5000, 45 month lengths summing to 4244. Input prefix `[1,2,3,4,5,6,7,4,8,9,10,9,11,6,12,13,14,15,16,16,17,7,18,2,19]`. Input cursor `stepsComputed=25,openedUpTo=19,closedUpTo=0,remaining=4219`, nonzero rank within count. MATLAB Native R2026a selects exactly one lexical child using its exact BigInt adjoint rank selector; independently recounts the child, round-trips JSON, checks PATCH25 five fields and two invalid positions 0 and 27.

Independent Python witness counts 20 eligible child blocks by binomial insertion DP, independently of the MATLAB algorithm, and checks exact count partition, selected child rank interval, 22 exhaustive tiny controls, both outputs' five-field row bytes. Local analysis of pinned native AFTER25 selected symbol 20, new openedUpTo20, remaining4218, name index40, occurrence 1. Expected strict row `POSITION=26 YEAR=5000 CUTLET_INDEX=15 CUTLET_DAY=26 MONTH_INDEX=40 MONTH_DAY=1`. This expectation is a Python preflight, NOT completed native evidence.

## Acceptance boundary
Require completed/success on **exact new SHA** for the Native/Python differential and Canonical Names Lock; inspect logs/steps, independent SMALL22 BLOCKS20 and Native STEPS26 REMAINING4218 LETTER20 REJECTED2, byte-identical five fields, ZIP SHA256 and CRC7/7, pinned predecessor and new AFTER26 JSON digest. Only archive the original completed PASS artifact. Do not rerun duplicate workflow or treat queued/in_progress as PASS or blockage. Full-year canonical Oracle, cross-engine soak and final Stage55 PASS remain **NOT VERIFIED**; LAST_COMPLETED_STAGE=54. No main/merge/publish or unbounded heavy DAG.
