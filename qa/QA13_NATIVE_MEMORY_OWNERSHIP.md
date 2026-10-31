# QA13 — actual Native 2D physical-memory provenance (not Stage 1 completion)

**Status: Native CI pending.** Pin previous successful real PyFunge execution run 39108506703, original artifact 12129457903, tested SHA 76e09db067c1a044763d23e5f219b3fe8bac32cc. Full archive contains 17 original raw STEP/p/g traces and independent fresh-process Native replay. Production Git blob 560d6aa5807a7f766213a33835cce85eab0fa40c must never change.

This independent forensic auditor fixes all 17 raw trace SHA-256 digests, binds memory events to actual executed `p`/`g` instructions, verifies ordered before/after values, and confirms execution of the current written instruction bytes. The runtime-written gate at (1500,1860) must actually execute as 118 for 14 valid cases, or 62 for three invalid cases. The previously observed corpus has 2,919 physical writes, 5,585 reads, 136 executions of prior written cells, and 17 distinct arithmetic write histories. The pinned CI must independently verify all numbers.

**Important limitations:** QA13 does not start 17 *new* Native runs: it independently checks original preserved Native traces. Its finite evidence is not a universal ownership proof, nor proof of unrestricted object reuse, global spaghetti geometry, full functional Stage 1, or final release. Preserve historical red evidence and prior QA11B/QA12 accepted specimens. No production merge or Stage2.

## QA13 actual CI verification — 20 October 2026

**QA13 FINITE EVIDENCE AUDIT PASS.** The earlier "Native CI pending" status above is historical and superseded **only for this bounded auditor**.

- CI workflow: [run 39373183826](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39373183826), job `qa13-independent-native-physical-memory`: completed **SUCCESS** at code commit `f7ebf6fd264739bf230b2cbf1cf0eaed35d9a817`.
- Original source of actual PyFunge execution, not a new trace run: [run 39108506703](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39108506703), original Native artifact `12129457903`, tested QA HEAD `76e09db067c1a044763d23e5f219b3fe8bac32cc`.
- Original production QA source pinned at Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`, unchanged.
- QA13 receipt artifact `12242303340` (one JSON file `qa13_native_memory_receipt.json`); receipt SHA-256 `f1859f863d7cfe5bde70479215134e772deb5f839922f0319a6a9864089c4499`.
- Verified 17 different ordered history digests, **2,919** original `p` writes, **5,585** `g` reads, and **136** execution events of previously written Funge-space cells.
- Each of the 17 input histories has a physically written and subsequently executed gate at `(1500,1860)`. Opcode 118 (`v`) executed in 14 valid cases; opcode 62 (`>`) executed in three invalid cases.
- Parser temporal binding: executed `p/g`, matching tick/coordinate/value before-and-after, latest previously written byte at a visited coordinate.
- Seven purpose-built synthetic event forgeries failed closed; independent manifest corruption tests rejected 16 adversarial variants; replay receipt rejected four forged variants.
- First CI attempt [39372848714](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39372848714) was **RED** because its *synthetic shortened control* expected the wrong first rejection point (gate absent instead of early length guard). Commit `f7ebf6fd264739bf230b2cbf1cf0eaed35d9a817` repaired the **test expectation only**, without weakening any Native SHA pin, event-order rule, or real-source guard. Retain this historical failure.

**Strict limitation:** No fresh Native PyFunge interpreter execution is claimed for QA13; it independently reaudits immutable traces from the accepted earlier real Native run. Finite measurement does **not** establish universal semantic ownership, absence of races, unrestricted same-object reuse, full production geometry, global functional correctness or Stage 1 completion. `CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`, `FULL_FUNCTIONAL_QA_PASS=NO`, `GEOMETRIC_SPAGHETTI_QA_PASS=NO`; Stage 2 NOT started; PR #17 not merged; main and canonical language branch unchanged.
