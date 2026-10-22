# QA21 — Natural-input Native source-opcode causal intervention (DISCOVERY)
 
**Status at creation: GitHub Native CI pending. Stage 1 remains OPEN.**
 
This QA-only experiment is restricted to the six original source glyphs proved input-reachable by QA20 from malformed input, with independent untouched source Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`.
 
Frozen candidate/input/first Native STEP witnesses:
- (10,44) `>`, `invalid18`, tick 1503
- (150,20) `x`, `invalid18`, tick 1185
- (175,38) `x`, `invalid18`, tick 1502
- (179,44) `@`, `invalid18`, tick 1672
- (235,11) `x`, `invalid14`, tick 9891
- (396,17) `x`, `invalid07`, tick 1065
 
Source: actual frozen QA20 Native corpus, GitHub Actions run 39761821210, tested SHA `d0a1c686c4f9244121246aa5b70266c072c3ddce`, 48/48 Native inputs (27 valid, 21 invalid). Three original input trace compressed SHA-256 pins are embedded in `qa/stage1_qa21_select_natural_witnesses.py`. Witness selector validates the exact raw Native STEP sequences at all six target ticks. No ordinary input is invented by the assistant.
 
Per candidate, run two fresh PyFunge-98 `Program` instances with the exact original malformed input; compare SHA-256 of the complete pre-target Native STEP prefix, the target coordinate, direction, runtime opcode, stack and IP state. **Baseline** runs the original source unmodified through the genuine target instruction and continues to the original seven `-1` rejection outputs in the exact original number of steps. **Counterfactual** modifies *only the disposable Program's live Funge-space at the naturally reached target* from its original opcode to `z` immediately before one actual Native opcode execution. The test compares the immediate post-instruction Native state and reports effects separately, including no-effects, without hiding them. No IP relocation. It makes no claim of full mutant numeric result; no Python calendar oracle.
 
The independent Python3 receipt auditor verifies all six witnesses and reports eight negative controls, while explicitly rejecting assertions of global dead-code absence, numeric necessity, Stage1 acceptance and mutation of the production source.
 
Caution: a changed post-step IP state is a finite causal effect on the interpreter, **not** proof that the code path is indispensable to the final invalid-input output or any valid Pastafarian computation. QA18's remaining 15 unobserved candidates remain unresolved; no final geometry certificate.
 
Governance: `CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`, no Stage2, no canonical `Befunge+Кыргызча` or `main` edit, no PR #17 merge.
