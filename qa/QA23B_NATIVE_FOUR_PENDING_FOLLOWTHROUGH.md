# QA23B — Followthrough of four unfinished natural-input Native opcode mutants

**At creation: pending original GitHub Actions run 39838384673; no Native result or PASS yet.**
QA23B extends accepted QA22 without replacing, rewriting, or truncating any QA10–QA23A evidence.

The four pending cases retain original real input and original first opcode-contact tick:
- (10,44) `>` on `invalid18`, first tick 1503.
- (179,44) `@` on `invalid18`, first tick 1672.
- (235,11) `x` on `invalid14`, first tick 9891.
- (396,17) `x` on `invalid07`, first tick 1065.

The immutable source Git blob is `560d6aa5807a7f766213a33835cce85eab0fa40c`. Immutable QA22 raw Native receipt is SHA-256 `ff85b07dab957de7a97ac32d917ed72f458a0a1ef1827b2744be176debf9d554` from successful run `39774061424`. All Native input/prefix records and the previous one-step mutated state must match the original receipt. Each of four *fresh* Python2 PyFunge 0.5-rc2 native Program instances receives a single `opcode -> z` mutation only in live disposable Funge-space at the naturally visited opcode. There is no forced IP relocation.

QA23B **must replay** exactly 125,000 post-intervention Native opcodes for every one of these four cases, with source-anchored prefix and exact original QA22 stdout-token agreement at that boundary. Only then may it continue, in 50,000-step recording increments, to an **absolute 500,000 post-intervention instruction cap** or actual normal termination. Four complete rows and independent checks including 11 adversarial forged reports are required. On failed Native execution, save all available prefix records and explicit RED; never silently skip a case or declare a missing receipt PASS.

A finite stdout prefix incompatible with the seven expected `-1` tokens establishes a causally divergent observable output even without termination. A live program remaining after 500,000 steps is **unresolved**, never an infinite-loop theorem. No valid calendar-input necessity, global 15-candidate natural reachability, unrestricted ownership or Stage 1 acceptance can follow from this bounded counterfactual alone.

The two already finished QA22 controls at (150,20) and (175,38) retain their native-equivalent seven-field results; QA23B does not run them again. At this checkpoint, `CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`, `FULL_FUNCTIONAL_QA_PASS=NO`, `GEOMETRIC_SPAGHETTI_QA_PASS=NO`. Production source, original signed evidence, `main`, `Befunge+Кыргызча`, PR #17 and Stage 2 remain unchanged.
