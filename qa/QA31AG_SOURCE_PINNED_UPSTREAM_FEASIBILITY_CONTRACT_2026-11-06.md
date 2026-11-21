# QA31AG — source-pinned upstream feasibility: row23/32 and EOF (2026-11-06)

Project `PC-BRANCH-BEFUNGE98-KYRGYZ`, branch `qa-befunge98-stage1-order-isolation-20261008`. Verified pre-change HEAD: `a932c59a4e6f9a1a4b23a5c4771df332e16ae757`. Historical source Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`. Stage 1 **OPEN**; no main, merge, Stage2 or production edit.

## Source facts and physical-prefix boundary

The already accepted QA31R original signed native case `digit` (`b'1'`, input `31`) records `m=(3,49)=1` at row29, then row32 `q=(1,49)=0`; row35 writes `q=1` and exits to row38. The `digit_space` case has `m=0` at row29 and does **not** enter row32. Both statements are supported by the pinned QA31R original-evidence report (Git blob `4cb764bdef1859a47a34e6e7b1280b1fc2fd13af`) and are not new STEP verifications.

The accepted QA31AF source/200-original-Native report (Git blob `8307d335d55d64bcf0006f5437a717edb317bb47`) records 680 row23 and 100 row32 source-j visits, all zero jump operands; each corresponding `x235` had zero physical visits. These are *finite non-observations*, not globally unreachable claims. At `(13,5)` `~` physical EOF reflects to `(12,5)` rather than returning a negative integer. Only a hypothetical `-1` return selects row5 `x(286,5)`. A real empty read must never be presented as `-1`.

## Independently testable QA31AG implementation contract

Inputs: exactly the pinned source file and the two pinned report files. The new forward model checks 18 source opcode coordinates and the Git blob identity, then evaluates seven `q` values (`0..6`) for each `m` in `{0,1}` independently on rows 23 and 32 (28 conditional source segments), plus two row29 entries and four row35 increment paths; five nonnegative row5 byte probes, one EOF reflection, and one explicit counterfactual `-1`. Each segment has a strict maximum 549 source instructions, and no real stdin is invented. The output marks every modeled route `counterfactual_segment`, captures `q+1` writer at row35 and its exit to row38, and preserves `UNKNOWN` for alternative row8 ingress because no prior incoming stack/input owner is proved.

The second program independently computes inverse predecessor sets for exits from row23 and row32, inspects nine original source opcodes without importing the first program, rejects 12 deliberate report mutations and enforces negative acceptance flags. Forward script additionally performs six synthetic/source-pin negative controls. No Native program is launched and no full 200-trace archive is reprocessed in this QA.

Acceptance requires completed exact-head CI execution on the repository checkout, full source Git SHA check, both Python scripts successfully executed, JSON audit with all 30 modeled gate states (28 row23/32 + 2 row29), four row35 states, 18 source-site pins, 12/12 independent hostile mutations, six forward negative tests, no unreconciled source opcode mismatch, no `UNKNOWN` converted to `PASS`, and uploaded stdout/JSON. The local Python syntax and independent synthetic smoke prove only script executability, **not source-bound QA31AG PASS**.

## Findings and NEXT

The source model permits `x(235,23)` and `x(235,32)` only in states with `q>3` at their respective gates. That condition must be joined with a physically feasible upstream route and the `m=1` ingress predicate. Row35's conditional write from `q=3` to `q=4` exits to row38; it does **not** establish an actual second visit to row32 with `q=4`. Row8 has a `g`/`j` dependence (sites `(57,8)`, `(151,8)`, `(185,8)`), but tracing alternative ingress without its prior physical stack state is not sound. Outcome: *no new natural-input witness*, and no basis yet to run a Native probe.

**NEXT**: after exact-source CI, inspect results; if green, perform narrowly bounded original-input prefix ownership investigation of row8/row20/row29 under signed STEP traces, with a source-grounded candidate only then justify a new Native test. If CI fails, correct the precise source-model mismatch; no fabricated `expected-red` without a witnessed failure.