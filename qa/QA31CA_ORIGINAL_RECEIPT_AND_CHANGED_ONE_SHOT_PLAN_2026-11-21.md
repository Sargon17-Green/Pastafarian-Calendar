# QA31CA — original signed Native acceptance and distinct one-shot alteration

**PROJECT_ID:** PC-BRANCH-BEFUNGE98-KYRGYZ  
**Branch:** qa-befunge98-stage1-order-isolation-20261008  
**Recorded source Git blob:** `560d6aa5807a7f766213a33835cce85eab0fa40c` (production source unchanged)

## Immutable original receipt (newly verified 2026-11-21)

- Exact original QA31CA run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44927920020; job `136917985803`; exact head `3dac94a82107853583e8b2a6e6c24f2e72454220`; completed/success.
- Original control artifact: `14717136552`; outer ZIP SHA-256 `988045a5a51fde51cfa544ca3fdbba23b7b33fa76f7e9e89b9a942c0ab3d707c`; downloaded archive ZIP CRC verified.
- Nested original QA31V shard 0 ZIP SHA-256 `5732cdf515a81c37982c8e79e5c4368e11e7a3b4e35fb1eae82bed2e17e24553`, source Git blob as above, exact raw input bytes `312030203020303030`, signed original trace compressed SHA `3c6650510eca52dd3614ab136cc4b090c07a8b41520486b1a64e52474f18603a`.
- Native execution exactly matched all **17,875** original physical STEP records. At tick **17,817** native IP `[96,480]` executed `p`, pre-TOSS `[62,1500,1860]`, post-TOSS `[]`, storage offset `[0,0]`, target `[1500,1860]`, physical cell `32 → 62`. Both original read events and stdout were reconciled, 19 detached hostile receipts rejected. **Original one-case evidence accepted; Stage1 remains OPEN.**
- Original fetch at tick **17,845** uses dynamic opcode `62 ('>')` at `[1500,1860]`. No new altered execution was present in QA31CA artifact.

## Exact independent next-run contract

1. Fetch the immutable successful QA31CA artifact and rehash it, nested QA31V original ZIP and **all** original signed STEP / original replay before changing anything. Do not rerun accepted original Native on the same pinned SHA.
2. Run **one** new actual PyFunge 0.5-rc2 Native execution of the **same original `.b98` and stdin**, with unchanged entry IP and no changed production file. Require all STEP rows before tick 17817 to match the immutable original control and prove actual original pre-p TOSS, storage offset, cell owner and value. A single-fire latch changes only the third-from-top Native TOSS value from `62` to `118` at the exact writer IP/tick. Require all other p operands, original source and p pop behavior to remain unchanged; physical FungeSpace cell must become 118.
3. Preserve full altered physical STEP trace, SHA-256, stdin/read and timestamped stdout events, p/g actual physical owners/values, first dynamic opcode fetch, `HALT` or bounded failure. Cap altered case at 100,000 steps; retain outputs even on non-success. First fetched altered instruction is expected `118 ('v')` at `[1500,1860]`, with successor `[1500,1861]`; this is a claim that must be physically observed, not assumed.
4. Independent Python3 auditor imports **none** of the Native producer or its preflight helpers. It must validate full baseline, complete changed STEP continuity, initial exact equality, tick 17817 as first mutated record, one exact p operand change, p/g physical receipts, actual dynamic fetch, changed input and stdout event reconciliation, and reject at least 12 independently detached modifications of receipts and STEP rows.
5. Run only the specific changed-case workflow once; don't claim natural-input reachability, whole-source dead-code coverage, global correctness, Stage1 accepted, production/main/merge/release, or Stage2. A `queued` or `in_progress` run remains unaccepted. If Native fails or hits its cap, inspect preserved specific diagnostics; do not auto-dispatch duplicates.

**Delivered QA-only files:** `qa/qa31ca_changed_native_once.py`, `qa/qa31ca_independent_changed_audit.py`, `.github/workflows/befunge-qa31ca-changed-once.yml`.  
**Next after a completed run:** verify exact SHA/run/job, log and artifact ZIP SHA/CRC; independently audit the changed full physical trace; then investigate any real discrepancy or determine the remaining global Stage1 gap. A successful one-case alteration is finite differential evidence only.
