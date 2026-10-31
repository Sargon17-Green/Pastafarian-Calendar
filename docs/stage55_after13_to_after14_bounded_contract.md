# MATLAB+Polski Stage55 — AFTER13 → AFTER14 bounded contract

Status: candidate pending Native and independent Python completion; Stage55 full-year acceptance NOT established.

## Pinned input
- Branch: `MATLAB+Polski`, parent HEAD `f09451ceafebc13b7bba684ce5736d590028fc57`; never change main.
- Predecessor AFTER13 from completed/success run 41222110025, original 7-member CRC-valid ZIP (15451 bytes, SHA256 810812020c90dd9532092983eeb70a859caeff3743a9acba263591ada8db426c), artifact 13050324695.
- `STAGE55_REAL_YEAR_INNER_CURSOR_AFTER_13.json` SHA256 `30c539f342182b1c6274b2c33943d2b351caa3490d885abf9a5a361733ffde18`; verify in CI before using.
- Year 5000 fixture, 45 source months/4244 days, first_day -15057702; certified 13-symbol prefix `1,2,3,4,5,6,7,4,8,9,10,9,11`.

## One-symbol exact transition
- BEFORE: stepsComputed=13, openedUpTo=11, closedUpTo=0, remaining=4231, rank in [1,count].
- Execute precisely one exact lexicographic unrank step with closedUpTo=0, preserve source original lengths.
- Independently enumerate 12 legal child intervals (symbols 1..12) via Python binomial insertion, verify sum equals parent count, selected interval count equals child count, rank subtraction equals preceding blocks and residual rank.
- Local independent numerical preflight from the exact checkpoint predicts symbol 6 (previously opened), openedUpTo remains 11, MONTH_INDEX=42, MONTH_DAY=2, CUTLET_INDEX=15 and CUTLET_DAY=14. This is a test expectation, NOT a Native result.
- AFTER: stepsComputed=14, remaining=4230, no completion, rank bounds hold. Store and hash the exact `AFTER_14.json`.
- Independent Python: 22 tiny brute-force cases + 12 entire-scale child block counts, one full five-field row. MATLAB R2026a Native: PATCH_25 trace and 2 out-of-prefix negative tests (positions 0 and 15).
- Require byte-identical single UTF-8 rows `STAGE55_FOURTEENTH_ROW POSITION=14 YEAR=5000 CUTLET_INDEX=15 CUTLET_DAY=14 MONTH_INDEX=42 MONTH_DAY=2`.

## Acceptance
- Dedicated 35-minute branch-scoped GitHub workflow, predecessor download pinned to run 41222110025 + exact SHA256; fail closed on mismatch.
- completed/success with MATLAB Native, Python independent and strict row diff, seven-file original ZIP with all CRCs, digests and preserved logs. No duplicate or heavy full-year DAG.
- This does not certify the canonical year-wide Oracle, cross-engine Soak or final Stage55; LAST_COMPLETED_STAGE=54.
