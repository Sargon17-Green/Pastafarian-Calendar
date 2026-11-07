# QA22 — Input-origin native opcode mutation output follow-through

**Status: new Native CI pending; no claim of output causality until checked.**

QA21 is accepted for six *immediate* effects after substituting exactly one original source opcode with neutral `z` in a disposable, naturally input-reached PyFunge-98 program. It does not show whether full rejection output changes. QA22 extends only that scope by continuing each mutated interpreter instance to termination or a strict **125,000 extra Native opcode steps**, with no relocation of instruction pointer, no repository source mutation and no artificial candidate input.

Six original witness tuples: (10,44) `>` / invalid18; (150,20) `x` / invalid18; (175,38) `x` / invalid18; (179,44) `@` / invalid18; (235,11) `x` / invalid14; (396,17) `x` / invalid07. The witness JSON from QA21 run 39764495612 is SHA-256 pinned (`aef9d33debba740f5ad24f1d272d016725aed0ee78100a55b65769ce5a68a681`) and full original QA21 Native receipt similarly pinned (`b77427385d7f4012b8a601974fe8b1d293366be7dd0e2f4c07b4e6020f2f9ced`).

Per candidate, new complete unmodified Native baseline must still output seven -1 values, the exact original prefix and immediate intervention state must match QA21, and the isolated mutable Native Funge-space is continued. The report records whether the altered program terminated, its actual seven-field or nonstandard stdout if terminated, and capped-but-unresolved otherwise. **Cap exhaustion is NOT proof of an infinite loop or a changed final result.** No arithmetic oracle for mutated code is used. No case is silently skipped; unresolved runs require additional attention.

An independent verifier checks exact six original-input witness identities, immediate Native states against QA21, step budgets, termination/output status and eight synthetic forged report variants. Global necessity, all source glyph reachability, Stage 1 geometric ownership, production release and Stage 2 remain OPEN. Keep original source Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c` unchanged, main and canonical Befunge+Кыргызча untouched, no PR #17 merge. `LAST_COMPLETED_STAGE=0`.
