# MATLAB+Polski Stage55 — AFTER26 to AFTER27 bounded differential

## Certified predecessor
- Existing branch `MATLAB+Polski`, exact commit `066845e29a457fa32c4d9ed447257974304213bd`, verified HEAD before changes.
- AFTER26 Native/Python run [41689067239](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689067239), job 126102510744, completed/success; Canonical Names Lock [41689067060](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689067060), job 126102509898, completed/success.
- Native `STEPS=26 REMAINING=4218 LETTER=20 REJECTED=2`; Python `SMALL=22 BLOCKS=20`; strict five-field row `POSITION=26 YEAR=5000 CUTLET_INDEX=15 CUTLET_DAY=26 MONTH_INDEX=40 MONTH_DAY=1`.
- Original GitHub artifact 13256868995, SHA256 `a8b9f7471bb9729cac4d287004f566470acb2ed4034d0580f6449362337b7cb7`, 15498 bytes, 7 CRC-valid members; archived unchanged at `/QA_Artifacts/PC-BRANCH-MATLAB-POLSKI/Stage55_AFTER26_41689067239_original.zip`.
- Pinned AFTER26 checkpoint JSON SHA256 `feedebd207dc22e1531f8849073a28e1f2c4b2fed37ee6490fff2cb238cb0cf6`.

## Independent bounded oracle and expected next transition
Year 5000, 45 month lengths totaling 4244, first day -15057702; input exact prefix `[1,2,3,4,5,6,7,4,8,9,10,9,11,6,12,13,14,15,16,16,17,7,18,2,19,20]`.
Input cursor `stepsComputed=26, openedUpTo=20, closedUpTo=0, remaining=4218`, positive rank within count.
MATLAB R2026a shall select exactly one lexical child using the production exact BigInt adjoint algorithm, recount independently through the production suffix API, round-trip JSON, check PATCH25 five fields and reject invalid positions 0 and 28.

Independent Python shall compute 21 lexical child blocks via binomial insertion DP, independent of MATLAB's adjoint algorithm; verify all counts sum exactly to parent, child count and rank interval agree, and 22 exhaustive tiny controls. Local Python preflight of the exact archived AFTER26 JSON showed `21/21` block partition, selecting symbol `19`, leaving `openedUpTo=20`, `remaining=4217`. Month name index is `27`; second occurrence gives day `2`; strict expected row `POSITION=27 YEAR=5000 CUTLET_INDEX=15 CUTLET_DAY=27 MONTH_INDEX=27 MONTH_DAY=2`. **This is predicted, not Native result.**

## Acceptance boundary
Require completed/success on exact new SHA for both Native/Python and Canonical Names Lock; inspect job steps and logs, Native `STEPS=27 REMAINING=4217 LETTER=19 REJECTED=2`, Python `SMALL=22 BLOCKS=21`, exact byte-identical five-field row, two invalid-position rejects, SHA256 and CRC of all 7 ZIP members, exact pin predecessor and SHA256 of AFTER27 checkpoint. Archive original on completed verified PASS only; never claim Native PASS from local preflight.
The full-year canonical oracle, cross-engine soak and final Stage55 PASS remain **NOT VERIFIED**; `LAST_COMPLETED_STAGE=54`. Avoid duplicate dispatch, main/merge, publication and unbounded heavy DAG.
