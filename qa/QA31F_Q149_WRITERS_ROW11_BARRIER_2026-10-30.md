# QA31F: source-pinned q(1,49) writers and row11 barrier — 2026-10-30

Project PC-BRANCH-BEFUNGE98-KYRGYZ. QA branch qa-befunge98-stage1-order-isolation-20261008, previous HEAD 94ccd8f100c30238891f171437c64a95aa8fe817; original immutable source blob 560d6aa5807a7f766213a33835cce85eab0fa40c.

New targeted, original-source segment model: row 2 initializes counters 0..3 at y=49 to zero; p(248,14) sets m=(3,49) to 1 without incrementing q=(1,49); p(248,26) increments q and p(344,26) resets m to 0; p(248,35) increments q while leaving m unchanged. At g(57,11)/j(113,11), q<=3 takes x(174,11) to (10,14); q>3 takes x(235,11) to (10,44). This upstream diversion is a concrete barrier to using simple q accumulation as the missing simultaneous m=1,q>3 witness at row 23.

The executable qa/stage1_qa31f_q149_writer_gate.py checks source Git blob identity, physical bytes, 1 row-2 initialization, 10 q-gate cases, 252 writer-model cases, and rejects 3 hostile opcode mutations. These are 263 bounded source cases and 3 deliberate negative controls, not newly executed Native or signed STEP replays. CI status must be separately verified on the exact new SHA. No QA20 48-case rerun, no 136-case Native rescan, no production changes.

Assumptions: each original segment begins at (10,row) with an empty stack, zero storage offset and unchanged source; hypothetical segment compositions are not proven globally reachable under natural stdin. This audit does not prove other entry paths absent, prevent source self-modification, prove global cell ownership, or close Stage 1.

NEXT: inspect source-backed incoming edges or original signed Native predecessor chains for an alternative entry to row14/23 bypassing row11 q>3, or a path incrementing q while retaining m=1; only a grounded natural input candidate warrants bounded new Native and independent receipt verification. Stage1 OPEN. No Stage2 or main merge.
