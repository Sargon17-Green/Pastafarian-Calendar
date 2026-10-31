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

## QA21 exact finite Native acceptance — 22 October 2026

**PASS only for the local causal claim.** Successful [Native CI run 39764495612](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39764495612), tested QA commit `61de02da97fff5d480e266ffe97ce4981d419ff7`, original downloadable artifact `12420333716`. Independent ZIP CRC test and SHA256 file digests verified; archive SHA256 `7fea9d8cd6e392275e6d0af33f719b7d272f70b242aaa90d4ce0f8f1a9fc5c08`. Witness JSON SHA256 `aef9d33debba740f5ad24f1d272d016725aed0ee78100a55b65769ce5a68a681`, actual Native intervention report SHA256 `b77427385d7f4012b8a601974fe8b1d293366be7dd0e2f4c07b4e6020f2f9ced`, independent receipt audit SHA256 `610ac6b5df77a8cb9550f33f8fdd168e63b745a0c165bccd082069e68f3c24da`.

**Native result 6/6 immediate effects.** Each of six exact input-driven, source-anchored instruction prefixes was reproduced for a fresh baseline program and a fresh disposable mutant program. The full normal rejection continued and produced seven `-1` fields, with normal step counts: invalid18 1,672, invalid14 10,061, invalid07 1,235. The disposable mutant changed only the live Funge-space opcode to `z`, then executed one genuine Native interpreter instruction at the same naturally reached position; no IP relocation. After one step the states differed in **all six cases**: `>` at (10,44) sets delta (1,0) vs z delta (-165,6); `x` at (150,20) jumps by (-140,-15) vs z goes right while preserving the two stack arguments; `x` at (175,38) jumps by (-165,6); `@` at (179,44) halts vs z remains alive; `x` at (235,11) jumps by (-225,33); `x` at (396,17) jumps by (-386,27). Independent receipt auditor confirmed six differences and rejected eight report forgeries.

**NOT yet demonstrated:** Effect on final seven-field rejection output for any of the six altered copies, natural reachability or deadness of the remaining 15 candidates, necessity for a valid calendar computation, unrestricted correctness, complete Stage 1 geometric ownership. Those questions remain explicitly open. Keep `LAST_COMPLETED_STAGE=0`, no Stage 2, production, main, canonical language or signed historical changes.
