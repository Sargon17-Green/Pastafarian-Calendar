# QA31I — Signed paired-native differential (2026-10-31)

PROJECT_ID: PC-BRANCH-BEFUNGE98-KYRGYZ
Branch: qa-befunge98-stage1-order-isolation-20261008. Stage 1 remains OPEN.

## Scope and engineering decision

QA31G has already run original PyFunge-98 Native for the controlled pair stdin b'1' and b'1 ' (single appended ASCII space). Re-running identical natural inputs with no new treatment is unnecessary. QA31I uses the original independently signed Native receipts, introduces a physical-step pair comparison and a *separate* adversarial ten-mutation auditor. This is new QA evidence, not a new Native execution or a Stage 1 verdict.

Original source Git blob: 560d6aa5807a7f766213a33835cce85eab0fa40c.
Original completed QA31G Native: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41190694847/artifacts/13037899716
ZIP SHA256: e74e4ad35d5653ffd1610827e1351fce62552b0912dc78430908cc288f4e1161.
Inputs: two original Native cases, 2046 and 3038 complete physical STEPs, total 5084. Individual compressed trace hashes are pinned in the verifier. No new Native, source edits, input substitution, IP relocation, sweep or Stage 2.

## Measurable paired oracle

1. Validate the original ZIP SHA256, ZIP CRC, immutable original receipt, exact raw stdin and per-trace gzip hashes.
2. Independently validate all 5084 original physical p/g/j STEP events against the exact original source, via QA31H.
3. Compare the complete physical state fields of the first 1131 paired STEPs, requiring equality except for the input-read transcript at STEP 292. The first read of b'1' returns hex 31; b'1 ' returns hex 3120. Both yield immediate stack [49]. Thus the first *read transcript* differs at STEP 292, not merely at EOF.
4. At STEP 1132 confirm the first physical state divergence: digit-only EOF reflects to (12,5), delta (-1,0); the space-buffered case pushes 32 and advances to (14,5), delta (1,0).
5. Check original row29 j operands: digit at STEP 1254 gives 61; digit-space at STEP 2676 gives 0. Both HALT with seven identical -1 tokens, showing why output comparison alone is insufficient.
6. Reject ten independently mutated receipt pairs, including altered first reads, early stack states, EOF branch, buffered value, deleted STEP and both row29 gates.

Two separate QA-only Python 3 scripts and a tightly bounded GitHub Actions workflow constitute the implementation. CI acceptance requires completed/success on the exact source SHA and separate artifact hash/CRC verification. Local trace-pair checks: 5084 physical original signed records, 1131 common state steps, and 10/10 mutations rejected; the stronger source-pinned CI is not presumed PASS.

## Limits and NEXT

The observed distinction is a *finite, controlled* native input-byte effect on internal execution. It is not global ownership of memory/source or a general input-to-stack theorem. FULL_FUNCTIONAL_QA_PASS, GEOMETRIC_SPAGHETTI_QA_PASS and Stage 1 acceptance remain open. No protected branch, merge, main or Stage 2 change.

After exact-head CI completes: review steps and downloaded result artifact; if accepted, examine interpreter buffering / original source semantics and design an independently verified unseen-input bound or source-ownership frontier. Do not re-run the same QA31G pair.
