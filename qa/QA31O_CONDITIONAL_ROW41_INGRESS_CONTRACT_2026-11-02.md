# QA31O — conditional row41 ingress and stack retention (2026-11-02)

Project: `PC-BRANCH-BEFUNGE98-KYRGYZ`. Existing QA branch: `qa-befunge98-stage1-order-isolation-20261008`. Stage1 OPEN.

## Input
Git-blob-pinned original `src/interleaved_work_counts.b98` = `560d6aa5807a7f766213a33835cce85eab0fa40c`. Examine only source rows 38 and 41 (zero-indexed) under **explicit hypothetical FungeSpace memory assignments**. No original stdin witness has been shown to reach row41. No new Native or existing signed STEP is fabricated.

## Independent bounded oracle
`qa/stage1_qa31o_conditional_row41.py` models only one right-moving instruction segment per row (max 300 source instructions), the original `g`, `j`, `x`, and arithmetic opcodes. It verifies row lengths (237, 246) and exact opcode coordinates:

- Row38: g=(57,38), j=(114,38), x=(175,38) and (236,38).
- Row41: g=(57,41), (104,41), (151,41), (198,41); x=(245,41).
- Under explicit `FungeSpace(1,49) = 4` row38's `j` operand is 61 and `x(236,38)` transfers to (10,41). For 0/1/3/5, operand 0 takes `x(175,38)` to (10,44).
- On conditional entry at (10,41), four `g` instructions read `FungeSpace(10,49)` through `(13,49)`; `x(245,41)` returns to (4,0), **leaving all four values on the stack in read order**. This is a necessary possible route for further investigation, not a known reachable natural path.

## Acceptance scope and counts
8 bounded source-model cases: 5 conditional row38 assignments and 3 independent row41 four-value vectors, including negative and large values. Ten hostile source-opcode mutations are rejected. Verify the actual original Git blob, original row bytes, original source geometry and the exact stdout markers in CI. Persist JSON plus log artifact. The checker may also be run in fixture-only mode, clearly labeled as such.

This is not Native, differential testing or Stage1 PASS. Unproven: genuine stdin path to the row38 gate with memory(1,49)=4, global source/owner reachability, full functional QA and geometric spaghetti QA.

## NEXT
Verify QA31O exact-head CI, inspect artifact SHA/CRC/JSON 8 cases + 10 hostile controls. Then trace the **last source-backed writer(s)** of FungeSpace(1,49)=4 prior to row38, and whether those source conditions can be simultaneously satisfied by actual input. Do not infer reachability merely from modeled state assignment. No main/merge/Stage2.
