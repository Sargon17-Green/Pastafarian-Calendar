# Stage 55 — bounded AFTER11 → AFTER12 differential contract

Project: PC-BRANCH-MATLAB-POLSKI. Branch: `MATLAB+Polski`. This is one bounded continuation of the real-year cursor, not acceptance of Stage55.

## Input gate
- Immutable predecessor: GitHub Actions run 41210864467, completed success on exact SHA `5bb2c56e602e67c8fb006cab0fcf897affcbe068`, artifact 13046348187, 15,423 bytes, ZIP SHA256 `c484fc7f6f701f844b3cc54cf2d9ccb885485c210f7ba7793ca239879fb499d5`.
- Original artifact has seven intact members. AFTER11 checkpoint SHA256: `e506397ddbd7bb170282db681689af626d6a72eef7a0de255a4bf839fedb65cc`.
- Year 5000: 45 source months, 4244 source days, first_day -15057702. Prefix after eleven days is `[1,2,3,4,5,6,7,4,8,9,10]`; openedUpTo=10, closedUpTo=0, steps=11, remaining=4233.
- AFTER11 was checked against ten independent child intervals, 22 tiny brute controls and strict five-field Native/Python equality. It is the only permitted input.

## Outputs / independent oracle
1. MATLAB R2026a extends the exact cursor by one step using the production adjoint unranker, independently recounts the resulting suffix through the first-endpoint counter, writes AFTER12 UTF-8 JSON, and verifies exact readback.
2. Python independently counts legal child intervals for symbols 1..11 using the binomial insertion DP (not the MATLAB rank selector); verifies the 11-block partition, chosen child count, exact rank-offset identity, predecessor digest, checkpoint shape and 22 brute-force tiny controls.
3. AFTER12 must have steps=12, remaining=4232, exactly one additional month decremented, openedUpTo=10 or 11 (11 only when the newly opened symbol 11 is selected), closedUpTo=0, done=false, and 1<=rank<=count.
4. Independent rank-interval preflight predicts selected symbol 9. Expected five-field row: position=12, year=5000, cutlet index=15 (Akad), cutlet day=12, month index=19, month day=2. Native/Python rows must be byte-identical and the PATCH25 occurrence-count trace must be present.
5. Native must reject positions 0 and 13. CI timeout 35 minutes; MATLAB through matlab-actions/run-command@v3; predecessor artifact/run ID and checkpoint SHA pinned; preserve all seven checkpoint/log members on PASS or FAIL. No heavy DAG.

## Acceptance
Only a completed workflow on the exact branch SHA, Native and independent Python pass markers, original ZIP SHA256, AFTER11 and AFTER12 checkpoint digests, 11 positive child blocks, 22 brute controls, exact rank partition/offset, five-field byte equality and two negative rejections can certify AFTER12.

This does not certify the full-year canonical Oracle, cross-engine Soak, or final Stage55. LAST_COMPLETED_STAGE remains 54 until those distinct gates pass.
