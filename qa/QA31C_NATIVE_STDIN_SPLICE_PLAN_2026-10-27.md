# QA31C — Native stdin read intervention, deliberately unaccepted (2026-10-27)

## Authorized boundary
- Branch: `qa-befunge98-stage1-order-isolation-20261008`; Stage 1 only, `CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`.
- Unchanged source blob: `560d6aa5807a7f766213a33835cce85eab0fa40c`.
- Native runtime: PyFunge 0.5-rc2, archive SHA256 `e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac`.
- Previously accepted finite QA31B: [original Native evidence](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/1b01d9030bf408429dae6f9dce099d500b287837/qa/QA31B_NATIVE_ACCEPTANCE_2026-10-27.md), [run 40495897566](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40495897566). Pre-j operands: valid00 tick 9607 = 61; invalid18 tick 1455 = 0.
- Signed original QA20 shard0 manifest SHA256 `782fb868a11a105550ef5af6f8f7cd39e4ba9de77d9565f7549e310549b0073a`; shard1 manifest SHA256 `9c5af6212cfd7c1ab58e9603f385767e64b10799c90be416a86c4f09d613bfdd`.

## Exact new acceptance gap
QA20 physical seven-column STEP traces contain no stdin read-event receipts. QA31B measures the stack before `j`, but does not show that altering bytes delivered by a real native input operation modifies the operand. The older between-input difference is **correlation, not intervention**.

## Controlled diagnostic added in this commit
The new Python 2 `qa/stage1_qa31c_native_read_probe.py` uses **the original PyFunge Program**, exact production Funge-space bytes and natural initial IP. A `StringIO` subclass initializes its backing buffer with the **original valid00 input in both arms**; it records the actual `read`/`readline` call, active physical tick, real IP state, TOSS fingerprint and cursor bounds. In sham, it returns unchanged bytes. In the experimental arm, only at a real stdin read return does it replace bytes at the same cursor offsets with the equal-length, equal-newline-offset suffix from the signed invalid18 input. No source mutation, IP move, stack edits, PyFunge modifications or arbitrary post-read changes are permitted.

The first changed IO receipt must have the identical pre-read IP, tick, cursor, method and TOSS fingerprint in both arms; every earlier IO receipt must match exactly. The changed bytes must be inside the actual read interval, not a fabricated input label. All **17,387 sham + 1,672 spliced = 19,059 physical Native STEP records** must reproduce the corresponding independently SHA-pinned original QA20 route, including output and real pre-`j` operand/pop and physical successor. Full raw physical-step history is preserved in two gzip files, not sampled.

The separate Python 3 `qa/stage1_qa31c_independent_read_audit.py` checks both original QA20 manifests, both full SHA-bound original STEP traces and their new complete reproductions, all structured read receipts, the source blob, stack and geometric consistency, the pre-intervention sham parity, and **12 intentionally forged reports** that must all be rejected. The workflow always uploads original evidence/RED diagnostics, and pins checkout, Python 2 runtime and QA20 artifacts.

## Strict conclusions
- This is **a candidate experiment, not a QA31C PASS**. It can fail if PyFunge bypasses the instrumented stream API, changes the read/cursor semantics, or if any independently signed physical-step, output, pre-read-state or stack observation diverges. These are real falsifiers; do not relax them merely to obtain GREEN.
- Even successful full-step native replay and the suffix intervention would establish at most a **finite causal dependency of this selected stdin suffix on this selected pre-j operand**, after exact-head CI success, artifact verification and independent review. It would not establish which individual byte is necessary, universal input/state ownership, or reachability/deadness of the remaining control glyphs.
- `qa31c_accepted=false`, `stage1_complete=false`; no Stage 2, no merge/main, no relaxation of the full Native requirement.

## NEXT after code delivery
Inspect **the exact GitHub Actions run triggered by the QA31C commit**; if completed/success, download that run's one QA31C artifact, validate ZIP SHA256/CRC and every full STEP/read/independent receipt, then document finite acceptance or a precise remaining gap. If failure, use the specific failing job/log as evidence and correct only the demonstrated QA bug. Do not report PASS from code presence or CI initiation alone.
