# QA29 — Accepted finite Native source geometry and live skipped-memory evidence

**Acceptance date: 2026-10-24. Scope: QA29A and QA29B finite original-input evidence only. Stage 1 remains OPEN.**

## QA29A: static source, original Native witness triads — PASS

- Original CI run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39999165959 — `SUCCESS`, HEAD `4e6d74830d98f3e8ae7101181ae94b115d0949dc`.
- Original artifact `12522752672`, independent ZIP SHA-256 `dfac9e8762491521e60485cf02e7bf5428928d01f050a842673c824c88884a6e`; all member CRCs passed.
- Independently checked 15 signed original QA28 directed-step witness triads from SHA-256 `c5a5beaab308df31222652484e5fb18af554bf75e7b492225b107197fb29aa6e`, against original production Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`.
- Exact partition: 2 executed prior `x` followed by rightward `>` reset, 2 eight-cell original Native jumps over 7 **static** ASCII-32 source cells each, 11 simple unit horizontal exits.
- Independent adversarial controls: 120/120 forged original-transition records rejected.
- QA29A does **not** establish the actual runtime contents of those skipped memory cells.

## QA29B: actual live FungeSpace at the original two eight-cell skips — PASS

- First original run `39999789882` FAILED **before Native replay** due to a test harness Python-2-specific `byte_char == ord(' ')` comparison; the archived failing console and red artifact `12527085543` are retained. No production byte or acceptance condition was changed.
- Exact isolated repair: in `qa/stage1_qa29b_native_live_blank_corridors.py`, compare `ord(original_rows[yy][xx]) == 32`. Commit `f3a47d5c0f0d6ed120b19433b32fbe151ebff96b`. All other test requirements unchanged.
- New successful Native run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40124832627 — `SUCCESS`, HEAD `f3a47d5c0f0d6ed120b19433b32fbe151ebff96b`.
- Original artifact `12572164295`: ZIP SHA-256 `d5cbc74e35f804a6f894dc29aa85f54497f734373fd123e5da0cff59866df90b`; original member CRCs passed. Verified both `qa29b_native_live_blank_snapshot.json` and independent `qa29b_independent_live_blank_audit.json`.
- Fresh **original-source PyFunge** replay of exactly the original `QA20/valid00` input (`0 0 0 0\n`) matched **all 17,387 original STEP records** and all seven original output tokens. No IP repositioning, no source edits.
- Live skip witness 1: target `(113,32)`, anchor `(112,29)`, Native tick `9485`. Every intervening `(113..119,29)` cell was ASCII 32 before and after actual execution.
- Live skip witness 2: target `(199,35)`, anchor `(198,38)`, Native tick `9630`. Every intervening `(199..205,38)` cell was ASCII 32 before and after actual execution.
- **69** original `FungeSpace.put` calls, **0** real put events in those fourteen corridor cells, zero corridor writes during either skip tick.
- Independent receipt auditor rejected **12/12 adversarial alterations**.
- Scope is only these finite original executions and observed `FungeSpace.get/put` interfaces; this does **not** prove global completeness of all mutation mechanisms or all input states.

## Remaining open Stage 1 gates

The original **15 source coordinates never naturally executed** within the accepted 136-case historical QA20/24/26 corpus remain *unresolved*, never certified dead. Neither zero observed visits nor either successful finite corridor study proves all-input nonreachability, static byte ownership for all inputs, or geometric spaghetti/functional QA acceptance.

Next is QA30: inspect actual dynamic control operators (`x`, `j`, `k`, `#`, string mode) and all observed incoming/outgoing Native transitions near the fifteen. Separate finite observational claims from universal state-space proofs, and do not manufacture target visits by relocating IPs.

Governance: `CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`, `FULL_FUNCTIONAL_QA_PASS=NO`, `GEOMETRIC_SPAGHETTI_QA_PASS=NO`. Do not edit `main`, `Befunge+Кыргызча`, the immutable signed production blob, historical QA10–QA29 evidence, merge PR #17 or open Stage 2.
