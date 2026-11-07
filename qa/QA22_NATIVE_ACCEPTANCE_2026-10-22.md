# QA22 — finite Native output continuation accepted

GitHub Actions run 39774061424 PASS on exact commit 72b1be429d6e55523692659fff49627d7e06e27a. Artifact 12423374573; original ZIP SHA256 1867b6648b4696ff53ca999e340cb6051e988220876c9bea86f483f4318823e7. Independent audit SHA256 2e7ae84eee55b8470b84cd9763bb243d5eddb2190d46e4d4853853491a3f1b67.

Six test-only, naturally input-origin Native source opcode mutants independently replayed. Two mutants at (150,20) and (175,38) terminated with the seven original -1 tokens after 1,060 and 12,223 steps respectively. The (179,44) mutant was unresolved at a 125,000-step cap but emitted 5,154 tokens, already violating the original seven-token stdout contract. The other three cases (10,44), (235,11), (396,17) were unresolved with zero stdout tokens at 125,000 steps. No case was silently skipped. Eight forged reports were rejected.

This is an exact finite result. Nontermination and universal dead-code/necessity are not proven. Original source Git blob 560d6aa5807a7f766213a33835cce85eab0fa40c remains unchanged; main, canonical branch and Stage 2 untouched. LAST_COMPLETED_STAGE=0.
