# Stage10 DISCOVERY05 — HIDDEN_DROP_ORDER preflight

User authorized Stage10 on 2026-11-28. Source base a2302e31d5ac48aff65b2df4bfd9fbdec6010443, tree 0d5dd04929f2e25fed57acce9fee0f3a165a8cd0. Frozen plan 0c2bad7393f4d66b77f884520f8ab6f5025feedd, README 56bc4173aae4975ded019ef5ab5a36249f1424df sections A, D, E, F, G and canonical c=t=F checkpoint.

## Contract
Input: ordered arbitrary-precision integer days c,t. Derive A=N(c), B=N(t), D=|t-c|+1, S=A+B, Q=1/2/3. Use immutable stone row k for k=1..7. Initial x=SAVE(A+(2k+1)B+(3k+1)D+(4k+2)S+(4k+4)Q+sum(stones[k])); seven sequential grinding steps x=SAVE(x²+3x+stone+r), fixed stone order 1,2,3,4,5,1,2. SAVE maps to 1..2^127-1. Output seven labeled values h[k] plus chronological positions -6..0: h[7],h[6],...,h[1]. Position p holds h[1-p]. Position 0 holds h[1].

## Evidence
Independent JS BigInt oracle (no foreign branch code/fixtures) compares direct recurrence with equivalent residue/table formulation; includes canonical seven hidden values and first-visible consumer anchor from README. Executed in JS evaluation: {"pairs":100,"traceChecks":5600,"slotChecks":700,"canonicalAnchors":8,"hypotheticalOrderSensitivity":100,"failures":0}. Ten days include F±1, 0, 1, anchor -278522, F±M and ±2^255 relative to F. Reversed order comparison is hypothetical sensitivity only, not observed legacy RED. No Pascal compiled, no CI acceptance, no Native differential.

## Live-path audit
Current src tree has BigInt, MonsterBootstrap, PastafariCalendar, SourceLanguageCatalog, Stage02WorkCounts. No hidden/drop primitive exists in these files; PastafariCalendar exposes only BootstrapProbe, WorkCountsForContext, StoneSnapshot. File history on this branch: 52d36b0079b3b48c1bd297abae1c7ad04347d8c0 (bootstrap), 18f9650c27593ccd99b4a2b9b22ca9df8477b918 (WorkCounts), b2d1cc1272902471ef6a78c037cf46c37eb24b2a (StoneSnapshot seeded), 523565c08a5f319549b71566155cb404b7723f7a (StoneSnapshot patch). This is a bounded lineage audit, not proof no historical source exists elsewhere. Missing functionality is not a measured defective legacy implementation. Gate EXPECTED_RED_AND_LIVE_LEGACY_PATH remains open. NEXT: supply genuine legacy source/discrepancy or separately authorize a documented Stage10-only seeded chronological-order defect. No Stage11, main or merge. LAST_COMPLETED_STAGE=9.
