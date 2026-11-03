# MATLAB+Polski Stage55 — AFTER24 to AFTER25 bounded differential contract

This step extends a **certified AFTER24 predecessor**, not full Stage55 acceptance.

## Certified predecessor
- Git branch `MATLAB+Polski`, exact commit `d4b7158cd81ff368fa2eb728d7c98fe99787aad0`.
- MATLAB R2026a Native + independent Python completed/success run [41651304112](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41651304112), job 125969878741; Canonical Names Lock completed/success run [41651304002](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41651304002), job 125969878154.
- Native `STEPS=24 REMAINING=4220 LETTER=2 REJECTED=2`, Python `SMALL=22 BLOCKS=19`. Both strict byte-identical five-field row: `POSITION=24 YEAR=5000 CUTLET_INDEX=15 CUTLET_DAY=24 MONTH_INDEX=14 MONTH_DAY=2`.
- GitHub original artifact ID `13238941394`, ZIP SHA256 `3b5ed31527c63990929cd72320d7205d838c3baef825f1273c561d4ae64b7930`, seven valid CRC members, archived `/QA_Artifacts/PC-BRANCH-MATLAB-POLSKI/Stage55_AFTER24_41651304112_original.zip`. AFTER24 checkpoint SHA256 `7534b4b1bd2e038cd5e2864faa1e100931b004dab79055acf2dc746ac9883f3c`.

## Bounded AFTER25 requirements
Year5000 fixture has 45 months and 4244 days. Input prefix `[1,2,3,4,5,6,7,4,8,9,10,9,11,6,12,13,14,15,16,16,17,7,18,2]`, `stepsComputed=24,openedUpTo=18,closedUpTo=0,remaining=4220`, positive rank within count. Native MATLAB R2026a uses exact BigInt adjoint rank selection, independently recounts suffix, round-trips JSON checkpoint, and uses PATCH25 five fields; out-of-range positions 0 and 26 must reject.

Independent Python uses binomial insertion DP rather than MATLAB's adjoint selector. It exhaustively cross-checks 22 tiny cases, counts 19 eligible lexical child blocks and validates their sum against parent count and exact rank interval. Independent preflight on the original AFTER24 checkpoint selected **symbol 19** (new month opening); predicted `openedUpTo=19,remaining=4219` and month name index 27, month day 1. Strict expected row: `POSITION=25 YEAR=5000 CUTLET_INDEX=15 CUTLET_DAY=25 MONTH_INDEX=27 MONTH_DAY=1`. This prediction is NOT a MATLAB Native proof.

## Acceptance and prohibitions
On exact new SHA, require both completed Native/Python and canonical Names Lock jobs; inspect logs and steps; verify original artifact SHA256, CRC 7/7, pinned AFTER24 JSON and generated AFTER25 SHA256, Native+Python byte-identical five-field row, and two expected negative rejects. `queued`/`in_progress` is neither PASS nor blocker. Do not duplicate dispatch. Full-year canonical Oracle, cross-engine soak, and Stage55 final PASS remain **NOT VERIFIED**; LAST_COMPLETED_STAGE=54. No main/merge/publish or heavy unbounded run.
