# QA31Y — source-pinned finite original-Native last writer / reader review (2026-11-04)

PROJECT_ID: `PC-BRANCH-BEFUNGE98-KYRGYZ`
Working branch: `qa-befunge98-stage1-order-isolation-20261008`
Verified parent HEAD: `b3542a3acb3d81df6ccf3fc13b0604f12322172a`
Original production source blob: `560d6aa5807a7f766213a33835cce85eab0fa40c` (unchanged).
Prior source and signed Native: [QA31V 200-case run](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689861481).
Prior selected pairwise witness contract: [QA31X](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/b3542a3acb3d81df6ccf3fc13b0604f12322172a/qa/QA31X_BOUNDED_PAIRWISE_FIRST_DIVERGENCE_2026-11-04.md).

## Executed, bounded QA31Y

Original 8/8 QA31V ZIPs passed pinned SHA256 and CRC; 29/29 QA31X-selected signed traces passed independent receipt/CSV, gzipped SHA256, 510,835 STEP ordinal and IP continuity checks. No new Native.
Source pinned through the original Git blob endpoint at SHA above. Independently verified 19 source opcode coordinates including j=(185,8),(335,17), their 4-step tails, observed p/g sites and ~=(13,5); 3,557 physical opcode-event checks passed.

364 original physically witnessed jumps passed four-step tail arithmetic, stack pop and next-IP checks, all with operands 0 or 61:
* j(185,8): operand 61 in 158 events, 0 in 103.
* j(335,17): operand 61 in 100 events, 0 in 3.

A bounded 384-STEP upstream window per jump recorded previously observed p/g events and prior physical stdin reads: 1,195 **distinct observed p-to-g matching-value pairs**, 53 physical stdin read events across selected traces. These are matches between recorded p writer and g read, **not proof of full causal byte ownership or exhaustive Funge-space writer coverage**. All byte-owner fields are `unknown`. 14/14 independent synthetic positive/hostile checks passed locally; these are not additional Native tests.

Concrete pair: `pair_34_00` vs `pair_34_09`. Physical stdin differs at STEP 292. At STEP 8805 the original p(60,5) writes 0 vs 9 to cell (0,49); at STEP 9213 g(57,17) yields 0 vs 9; at STEP 9484 j(335,17) operand is 0 vs 61, with next IP (336,17) vs (397,17). Observed sequence, not universal input-byte ownership theorem.

## Reproducible artifact

Complete 17-entry original-source-preserving QA31Y ZIP prepared: `QA31Y_BEFUNGE98_KYRGYZ_FULL_EVIDENCE_20261104.zip`, 46,421,841 bytes, SHA256 `1c97b51823ed98b3d333fcb2d0b35d72f7546b04ed8e86c5adebe3aca5703e8a`; ZIP CRC and all 16 manifest entries independently rechecked. Includes all eight original signed QA31V shard ZIPs, QA31X Python loader, QA31Y Python analyzer, frozen QA31W CSV, complete 364 jump witnesses, summary, self-test log, per-file SHA manifest and QA31Y full review. Python 3 standard library only; run `python stage1_qa31y_source_pinned_last_writer_reader.py --zip-dir . --qa31w-csv QA31W_200_PHYSICAL_TRACE_CLASSIFICATION.csv --out REPRODUCED`. The ZIP is currently available as a conversation artifact; no permanent Drive copy is asserted here.

Stage1 remains **OPEN**: global input ownership, source reachability, full functional and geometric acceptance are not proven. No production edit, main/merge, Stage2, or Stage1 PASS.

## NEXT QA31Z
Perform bounded dynamic stack-dependency transfer from the physically observed g sites at (151,8),(57,17),(129,17),(202,17),(275,17) through local Boolean/arithmetic operators to the two j operands. Check each pre/post transfer against the signed original trace, add independent hostile synthetic controls, and report `unknown` whenever an unsupported stack mutation or alternate Funge-space writer prevents sound provenance. No Native rerun; no global PASS.
