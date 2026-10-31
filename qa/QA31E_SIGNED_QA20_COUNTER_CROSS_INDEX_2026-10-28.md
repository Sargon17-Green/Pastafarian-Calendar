# QA31E — bounded QA20 / QA31A upstream counter cross-index (2026-10-28)

Project: PC-BRANCH-BEFUNGE98-KYRGYZ. Stage 1 ONLY. This is a read-only offline audit of **previously executed original Native STEP traces**, not a new native execution, not Stage 1 PASS and not a proof over all valid inputs.

## Pinned original evidence

- Source blob: `560d6aa5807a7f766213a33835cce85eab0fa40c`; same source in original QA20 shard manifests and QA31A.
- QA20 [run 39761821210](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39761821210), four original artifacts: shard 0 [12417714729](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39761821210/artifacts/12417714729), ZIP SHA256 `0487e7b6c65134a69d6ac7b313d332e6cb5c966b9fea0124ae60a28d45f11076`; shard 1 [12418676466](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39761821210/artifacts/12418676466), `0d39bebd0e2b28976f77a38f8f1c0113ec8ad5d2de08f53415179277135bf5ea`; shard 2 [12418536785](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39761821210/artifacts/12418536785), `d511c5cbde86b850224851d27ddc994e5689019c0af93aea9d5c5df92f33f16c`; shard 3 [12417633980](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39761821210/artifacts/12417633980), `d792e4ce459769124d9055f47dc2773a44a487f260ff2302ada8371ed4450c07`.
- QA31A artifact ID `12634011438` (verified via GitHub connector), ZIP SHA256 `235be0d04cc2f6ab113b3a809c3a2ef93513c07cb2233b2b8b457722d409a4cd`, summary JSON SHA256 `39f017ea8cb4b6865df031639763f8546fb87427ca94b487e18493fc475a189c`. QA31A records 136 original programs across QA20/QA24/QA26; **this audit inspected full STEP bytes for QA20's 48 cases only**.
- ZIP CRC, all 48 compressed STEP SHA-256 hashes against their manifests, physical STEP numbering, STEP counts, source byte blob and unmodified route flags passed. The accompanying `stage1_qa31e_signed_counter_audit.py` reproduces these checks and prints per-case data.

## Evidence-bound results

| QA20 category | Cases in QA20 | Cases reaching target `j=(114,38)` | Increments at `p=(248,26)` before `j` | Observed successor x |
| --- | ---: | ---: | --- | --- |
| Valid | 27 | **27** | **4 in every case** | **176 in every case** |
| Invalid, counter 4 | 6 | 6 | 4 | 176 |
| Invalid, counter 3 | 1 | 1 | 3 (invalid15) | 115 |
| Invalid, counter 0 | 2 | 2 | 0 (invalid18, invalid19) | 115 |
| Other invalid | 12 | 0 | not evaluated at target `j` | not applicable |

All observed QA20 routes that reached target `j` executed initialization `p=(106,2)` at tick 146; all such routes executed `g=(57,38)` fifty ticks before `j`. The valid routes showed no `{`, `}`, `u`, or `k` before `j`. The source-level QA31D reconstruction explains the gate as `61 * [FungeSpace(1,49)==4]`; QA20's observed next positions agree with that equation. In the 27 valid QA20 routes, the four increment ticks may vary substantially across inputs, but their **count** is invariant.

**Important distinction:** some *invalid* QA20 routes do reach the same `j` with a counter different from four. Thus an unqualified claim that the gate is input-invariant or is always taken with operand 61 is **false**. The supported narrower statement is: **no valid counterexample exists among the 27 QA20 valid paths audited.** There is no reason to repeat another fourth-field-only Native perturbation without a new candidate. Manifest hashes and observed source opcode coordinates do not by themselves prove global FungeSpace write ownership or input-to-stack causality across all 136 QA31A cases, let alone all possible inputs.

## Next authorized action and limitations

**NEXT (one action):** inspect QA31A's original near-reachability witnesses and immutable source-plane control geometry for target `(10,32)` (one of the **15 unobserved source cells**). Establish whether a reachable original input/path candidate exists without inventing a path or editing source; only if supported, specify an exact new original-Native test with full physical STEP capture and independent audit. Otherwise mark the finite search boundary and continue the 15-cell ownership frontier in Stage 1.

Blocker classification: **מקור קנוני חסר** is *not* the issue—the source exists. The remaining blocker is an **unproven Stage 1 acceptance condition** (global source ownership / full functional and geometric QA), and **סביבת Native חסרה** only for any *new locally executed* Native experiment. No new Native run was needed or executed for QA31E. No main change, Stage 2, or merge.
