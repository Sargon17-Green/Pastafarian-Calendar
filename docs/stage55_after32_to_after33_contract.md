# Stage55 AFTER32 → AFTER33: bounded evidence contract

PROJECT_ID: PC-BRANCH-MATLAB-POLSKI. Work only on `MATLAB+Polski`. LAST_COMPLETED_STAGE=54. Stage55 OPEN; no full-year verification.

## Pinned input and provenance
- AFTER32 predecessor run https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41979140995 (MATLAB Native + independent Python completed/success).
- Names Lock https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41979141014 (completed/success).
- Exact artifact name `stage55-thirty-second-day-differential`, run 41979140995, id 13393398276; original 7-member ZIP digest `sha256:1ed3a9dec457af233cbf64859dd6e40175c33c26172d74b5a4b43789dee17e0c`, verified CRC 7/7 and archived.
- Input `logs/STAGE55_REAL_YEAR_INNER_CURSOR_AFTER_32.json` SHA256 `6bdba0c1d5d7e786ee3eaa25ef0a6b939655ea2d134efe5bd534f0e02cd88265`.
- Metadata fixture: `tests/fixtures/stage55_year5000_appendix_a_metadata.json`. 45 months, 4244 days, first_day=-15057702.

## Measurable contract
On the exact 32-step predecessor, native MATLAB advances the adjoint rank cursor by one day and recomputes its exact count. Require `LETTER=7 STEPS=33 REMAINING=4211`; openedUpTo=22, closedUpTo=0, done=false. Output one AFTER33 JSON with SHA256.

An independent Python binomial-insertion witness, algorithmically different from MATLAB adjoint unranking, checks: 22/22 small brute cases; SHA-pinned BEFORE input; 23 positive child blocks partitioning the exact parent count; selected block 7, exact matching child count and rank offset; two out-of-year rejections for positions 0 and 34; strict UTF-8 byte equality of exactly one five-field row `STAGE55_THIRTY_THIRD_ROW POSITION=33 YEAR=5000 CUTLET_INDEX=15 CUTLET_DAY=33 MONTH_INDEX=6 MONTH_DAY=3`; AFTER33 JSON digest and all output artifacts.

Preflight on original pinned AFTER32 JSON independently enumerated all 23 child blocks (sum = parent), selected symbol 7, and predicted month-name index 6, occurrence 3. This is NOT MATLAB AFTER33 proof.

## Completion and guardrails
AFTER33 bounded gate requires both native/Python and Canonical Names Lock jobs completed/success on the exact SHA with complete logs, artifact original ZIP verified CRC 7/7 and digest, and recorded AFTER33 checkpoint hash. queued/in_progress never pass, do not redrive a completed PASS on same SHA. Do not claim full-year canonical oracle, cross-engine soak or overall Stage55 PASS from this transition. Only after AFTER33 bounded gate, plan AFTER34 by an independent justified contract.
