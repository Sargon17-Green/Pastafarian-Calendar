# MATLAB+Polski Stage55 — AFTER15 → AFTER16 bounded contract

Status: candidate; AFTER15 CERTIFIED, AFTER16 Native and independent Python NOT YET verified. Stage55 full-year acceptance OPEN; LAST_COMPLETED_STAGE=54.

## Pinned source and evidence
- Branch `MATLAB+Polski`, exact parent HEAD `e1646c2617eb18ceb52a143eba01fcd5152a2c9c`; no main, merge or full-year heavy DAG.
- AFTER15 run 41244335493 completed/success, job 124664512387, artifact 13059377535. MATLAB R2026a STEPS=15 REMAINING=4229 LETTER=12 REJECTED=2; independent Python SMALL=22 BLOCKS=12; strict byte-equal five-field row.
- Original seven-member ZIP 15445 bytes; SHA256 `709977ec9a58032adfab74480e004614c66508b9a42e77f2c6eaebba7b288752`; CRC PASS. Archived `/QA_Artifacts/PC-BRANCH-MATLAB-POLSKI/Stage55_AFTER15_41244335493_original.zip`.
- Input `STAGE55_REAL_YEAR_INNER_CURSOR_AFTER_15.json` SHA256 `3131328fcf9716b681a8c3cec9207dc6247b292485fe8caf01e15cb2bea204b5`; reject mismatch.
- Canonical fixture: year=5000, first_day=-15057702, 45 months, 4244 days; source month13 name index25, first cutlet name index15. Prefix `1,2,3,4,5,6,7,4,8,9,10,9,11,6,12`.

## Exactly one-day transition, independent oracle
- BEFORE: stepsComputed=15, openedUpTo=12, closedUpTo=0, remaining=4229, rank in [1,count], done=false.
- Native MATLAB one-symbol unrank; Python independent binomial insertion DP for all 13 child intervals, exact count partition, child count and rank subtraction; no native algorithm copied into the independent oracle.
- Local preflight of pinned JSON predicts selected symbol13 and AFTER stepsComputed=16, openedUpTo=13, closedUpTo=0, remaining=4228, done=false. This is EXPECTATION only, NOT Native proof.
- PATCH25 expected five-field row `POSITION=16 YEAR=5000 CUTLET_INDEX=15 CUTLET_DAY=16 MONTH_INDEX=25 MONTH_DAY=1`.
- Native: assert state shape, recount, serialization readback, PATCH_25 trace; reject out-of-range positions 0 and 17.
- Python: 22 tiny brute controls, 13 full-sized child blocks, one strict UTF-8 row diff against MATLAB, two negative bounds. Preserve 7 artifact members: two checkpoint JSONs, Native/Python logs, two row files, digest.

## Acceptance
- Dedicated 35-minute branch-only workflow; certified AFTER15 run 41244335493 and exact digest pinned; no duplicate dispatch.
- Only new SHA completed/success plus inspected logs, CRC-valid seven-member ZIP and exact byte-equal five-field row can certify AFTER16.
- Full-year canonical oracle, cross-engine Soak and final Stage55 PASS not verified. LAST_COMPLETED_STAGE=54.
