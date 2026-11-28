# QA18 — Bounded Native source-glyph contact PASS (2026-10-20)

GitHub Actions run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39423789058
Tested head: 6fbc0828c4ef78affb3899f5924e57e0a0025ed5
Original CI receipt artifact: 12265002965
Receipt file SHA-256: 263a73a40afa17a8a9b1c831a01239be671d9ea0a9c331fd3f725f83cf1cfea7
Source blob: 560d6aa5807a7f766213a33835cce85eab0fa40c (unchanged).

Exactly 49 prior real Native QA13/QA14 traces were reaudited, not reexecuted. Across 13,442 non-space source characters: 12,460 were physically fetched before writes, zero were first fetched only after writes, zero were exclusively g-read or p-written, 982 received no observed STEP/g/p contact. No dead-code conclusion follows. The 982 appear in 11 source rows; 21 look like Befunge control opcode glyphs (10 x, 4 g, 3 >, 2 p, 1 j, 1 @) and require targeted future Native mutation/counterfactual experiments. All nine synthetic forged ledgers failed closed.

QA18 is finite observational acceptance only. Stage 1 remains OPEN; LAST_COMPLETED_STAGE=0. No production, canonical branch, main, PR #17 or Stage 2 changes.
