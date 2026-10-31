# Stage 55 — bounded AFTER9 → AFTER10 differential contract

Project: PC-BRANCH-MATLAB-POLSKI. Branch: `MATLAB+Polski`. This is a bounded incremental probe, not final Stage55 acceptance.

## Input / identity
- Immutable predecessor: GitHub Actions run 41203174443, completed success, head SHA 21b137dc4626a3c61a4e6f4651f653b7d48f05dd, original artifact 13043806457.
- SHA256 of `STAGE55_REAL_YEAR_INNER_CURSOR_AFTER_9.json`: `d1f9baea5802f7429d0ac0eddcd55cb9a3a3d0d74bc05be95abc14956ad69005`.
- Year 5000: 45 source months, 4244 source days, first_day -15057702. Rank/count remain exact decimal integers.
- Verified prefix [1,2,3,4,5,6,7,4,8], openedUpTo=8, closedUpTo=0, steps=9, remaining=4235; first eight months reduced once and fourth reduced a second time.

## Outputs and independent acceptance oracle
1. MATLAB R2026a unrank one production suffix step, independent native recount, writes AFTER_10 UTF-8 JSON with readback, and Native five-field row.
2. Python oracle independently computes insertion-count child blocks for legal symbols j=1..9, checks sum(children)=parent count, selected count=child count, and prefix interval/rank-offset identity; separately checks 22 brute-force tiny controls.
3. Checkpoint must have steps=10, remaining=4234, exactly one decremented month, openedUpTo either 8 or 9 depending on new symbol 9, closedUpTo=0, valid integer rank in [1,count].
4. Five-field projection must match Native/Python bytes: year 5000; cutlet name Akad (index 15); cutlet day 10; fixture month name (by index); occurrence-count month day. Reject out-of-prefix target positions 0 and 11.
5. Workflow limited to 30 minutes; uses matlab-actions/run-command@v3, pins predecessor run and SHA256, avoids heavyweight audit, always uploads 7 original files in both PASS/FAIL.

## Gate
Accept only on completed correct-SHA CI and artifact: SHA256 ZIP/checkpoint, 7 members, 9 independent blocks, 22 tiny controls, strict byte-equal five-field row and 2 negative rejections. Do not mark full-year canonical Oracle, cross-engine Soak or overall Stage55 PASS on this bounded evidence. Last completed stage remains 54.
