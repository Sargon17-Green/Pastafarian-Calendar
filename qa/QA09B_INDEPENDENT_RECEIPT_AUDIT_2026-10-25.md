# QA09B independent Native receipt audit — 2026-10-25

## Confirmed historic Native evidence

Exact branch HEAD `eaa4b515f685a5cf299bbb8edb708028e9e8b716`:

- Original pinned Funge++ 17D 80-opcode workflow [40193548420](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40193548420) FAILS: six cooperative (`funge`) outputs match the numeric oracle, but first `native` case times out at 12 seconds with exit 124.
- Patched **CI-checkout-only** engine workflow [40193548354](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40193548354) PASSES: 12 of 12 normal runs (six cooperative + six native), 2 trap masks and 20 bounded nonzero mutant outcomes. Artifact `12603137500` has ZIP SHA-256 `867fd3a6de8e1691883b180d22e8f5083761d594e20348d90e585dd723b16fe8` (independently downloaded, CRC PASS).
- Native lifecycle forensic [40193548356](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40193548356): frozen upstream native mode also times out for an independent one-IP program and the two-worker fixture. A single `cv.notify_all()` in a transient Funge++ checkout allows all three samples to complete correctly. That strongly isolates the native scheduler lifecycle issue, but does not prove every engine hang has the same cause. Original RED is **not waived**.

## Independent report-level verification

A new `qa/stage1_spaghetti09_independent_receipt_audit.py` reconstructs 99 integer results for each of the 12 (mode, seed, repetition) records without calling the Befunge runner. It validates the Git blob identities, a full unique Cartesian sample set, exact output SHA-256 values, both 80-trap masking records and four cross-shard plus 16 dimension sabotage records with nonzero bounded outcomes. **16 distinct forged JSON receipts must all be rejected.**

Local offline replay against original GitHub Actions artifact `12603137500`: 12/12 SHA matches, 20/20 recorded nonzero mutant outcomes, and 16/16 tampering controls rejected. This independently verifies **receipt consistency**, not live Native execution, scheduler correctness for arbitrary programs, or mathematical nontermination of mutants. Fresh CI on the new exact HEAD must pass before this gate is recorded as native qualified.

`LAST_COMPLETED_STAGE=0`; functional/geometric final acceptance OPEN; canonical source, `main`, PR #17 merge, and Stage 2 untouched.
