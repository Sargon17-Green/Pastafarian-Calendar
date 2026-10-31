# MATLAB+Polski Stage55 — AFTER14 → AFTER15 bounded contract

Status: candidate. AFTER14 certified; AFTER15 Native and independent Python NOT YET verified. Stage55 full-year acceptance remains OPEN; LAST_COMPLETED_STAGE=54.

## Pinned input
- Branch MATLAB+Polski; parent SHA `1b3d4840e35694924e849d7b567fb6f25ead60d1`; no main/merge or full-year heavy DAG.
- AFTER14 from completed/success run 41238755388, artifact 13056567785, seven CRC-valid ZIP entries, 15461 bytes, ZIP SHA256 148edecd3dda021347666b0ceb4ae5e44f4017db1c29b289421e69ef17c6958d.
- Checkpoint `STAGE55_REAL_YEAR_INNER_CURSOR_AFTER_14.json` SHA256 `c93fd2c18e4af7f83cdccab789dc14a91a26807c7c9a3881032d0a4033d3bbb6`. Reject mismatch.
- Canonical fixture year 5000: 45 source months, 4244 days, first_day=-15057702, source month-name index #12=39, first cutlet-name index=15. Certified prefix: `1,2,3,4,5,6,7,4,8,9,10,9,11,6`.

## Exact one-day transition and independent oracle
- BEFORE: stepsComputed=14, openedUpTo=11, closedUpTo=0, remaining=4230, rank within [1,count], not done.
- Invoke native unrank for exactly one symbol, with the pinned AFTER14 state. Independent Python binomial-insertion interval oracle counts all 12 legal child branches, verifies sum(blocks)=parent count, selected block count=child count, and exact rank subtraction.
- Independent local preflight predicts selected symbol 12; this is an EXPECTATION only, not a claimed Native result. It opens source month #12, so AFTER openedUpTo=12, closedUpTo=0, stepsComputed=15, remaining=4229, not done. Projection expects `POSITION=15 YEAR=5000 CUTLET_INDEX=15 CUTLET_DAY=15 MONTH_INDEX=39 MONTH_DAY=1`.
- MATLAB R2026a: assert checkpoint shape/rank, count recount, serialization readback, PATCH_25 branch trace and exact 5 fields; two negative bounds positions 0 and 16.
- Python: 22 independent tiny brute-force controls; exactly 12 full-size child counts; strict UTF-8 single-row byte equality against MATLAB, child interval and rank invariants.
- Persist AFTER15 JSON with SHA256 plus both engines' logs and row files as a seven-member artifact.

## Acceptance, exclusions and next gate
- Dedicated 35-minute branch-only workflow pinned to run 41238755388 and checkpoint SHA; no duplicate dispatch.
- Only completed/success plus inspected Native+Python log markers, matching SHA/7 CRC-valid ZIP members, and strict row diff can certify AFTER15.
- Explicitly not certified: complete year-wide canonical five-field Oracle, cross-engine soak, or final Stage55. LAST_COMPLETED_STAGE stays 54.
