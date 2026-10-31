# MATLAB+Polski Stage55 — AFTER12 → AFTER13 bounded contract

Status: implementation candidate; no Native PASS or Stage55 full PASS is implied by this document.

## Inputs
- Branch: `MATLAB+Polski`; source parent HEAD `d82b3f776c14467065298600fbd28a94c2067112`.
- Native MATLAB R2026a via `matlab-actions/run-command@v3`, plus independent Python integers.
- Original verified AFTER12 checkpoint, SHA-256 `b63255d43acd4607652555b420f4e18729b0c871754b969d4c1cee7a0857fe07`, from completed SUCCESS run 41215080520, artifact 13048776523.
- Year-5000 fixture: 45 months, 4,244 days, first_day -15057702. Prior 12-symbol prefix: 1,2,3,4,5,6,7,4,8,9,10,9.

## Transition and exact bounds
- AFTER12: stepsComputed=12, openedUpTo=10, closedUpTo=0, remaining 4232, rank in 1..count.
- Exactly one one-symbol unrank step; output AFTER13 with stepsComputed=13, remaining 4231.
- Independent binomial-insertion count enumerates exactly 11 possible child blocks (symbols 1..11), partitions the parent count and verifies the chosen rank interval / child count / residual rank.
- Bounded local preflight on the SHA-pinned AFTER12 checkpoint predicts symbol 11, openedUpTo 11, month name index 16, occurrence day 1; the cutlet is 15 and day 13.
- Native/Python must each output exactly one identical UTF-8 row: `STAGE55_THIRTEENTH_ROW POSITION=13 YEAR=5000 CUTLET_INDEX=15 CUTLET_DAY=13 MONTH_INDEX=16 MONTH_DAY=1`.
- Independent Python validates 22 tiny brute-force controls, 11 child blocks, entire rank partition, and computed output checkpoint; Native validates two out-of-year rejects (positions 0 and 14) and PATCH_25 occurrence-count trace.
- Compare the full five-field row byte-for-byte and print SHA-256 of the AFTER13 checkpoint. Preserve both checkpoint files, Native/Python logs, two row files and digest in one original 7-member artifact.

## CI acceptance and exclusions
- GitHub Actions only on the branch via dedicated 35-minute workflow, fixed prior run 41215080520; require completed/success, job logs, ZIP integrity, verified SHA-256 and rows before recording AFTER13 PASS.
- In-progress/queued is neither blocker nor PASS; no duplicate dispatch. Failed checks require actual defect reproduction before a fix.
- This does NOT certify the full-year canonical Oracle, cross-engine Soak or final Stage55. LAST_COMPLETED_STAGE remains 54.
