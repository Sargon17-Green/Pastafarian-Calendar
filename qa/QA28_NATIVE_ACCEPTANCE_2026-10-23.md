# QA28 — Finite signed Native directed frontier acceptance (2026-10-23)

**PASS, finite original witness-triad scope only. Stage 1 remains open.**

Original GitHub run [39985923985](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39985923985) completed SUCCESS at tested commit `7a2a9d64d2080153354d3ef200aece590a3ff997`. Original artifact `12517398861` had ZIP SHA-256 `ee77ee9d8af0957c76363d5cc9a806f484a8d26270f6a7433a15c85f6b709080`, independently downloaded, SHA-checked and ZIP CRC-checked.

The independent Python 3 auditor rechecked the two signed original QA20 Native trace files that contain the nearest input-origin witnesses, with the original QA27 aggregate SHA-256 `20caa24769f882e38c69eb8bb9a31567fdbd7bb52f3f885b95436c1ece2798f3`. Exactly **15/15 predecessor–anchor–successor triads** reproduced; **120/120 adversarially altered directed-edge records** were rejected. Two predecessor transitions begin with fetched `x`; four anchor exits differ from simple addition of the pre-instruction delta; none of the 15 witness exits change row. Original target cells remain unvisited in the accepted historical 136-case corpus.

This is a directed **finite witness** result, not an exhaustive control-flow proof. It does not establish global nonreachability, source byte ownership in all states, or dead code. Further work must address dynamic `x`/`j`/`k`/trampoline/stringmode/physical write semantics without forcing the instruction pointer.

Production Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c` remains unchanged. `CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`, `FULL_FUNCTIONAL_QA_PASS=NO`, `GEOMETRIC_SPAGHETTI_QA_PASS=NO`. Do not modify main, canonical Befunge+Кыргызча, accepted historical evidence, or merge PR #17 or open Stage 2.
