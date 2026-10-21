# Stage 1 — gate checklist

Reference: canonical Scroll in `main@56bc4173aae4975ded019ef5ab5a36249f1424df`.
Implementation: independent `SystemVerilog+Kalaallisut` orphan branch.
All statuses below distinguish **written** from **executed**.

| Substep | Status | Acceptance criterion |
|---|---|---|
| 1.1 Orphan branch | VERIFIED | Root commit has no parent |
| 1.2 Base request/ready RTL | WRITTEN_NOT_SIMULATED | Capture, context lifetime, one transaction per ready handshake |
| 1.3 Basic arithmetic test-only oracle | WRITTEN_NOT_SIMULATED | Signed ±64-bit boundary, SAVE and day-index invariants |
| 1.4 Independent sauce intermediate test | WRITTEN_NOT_SIMULATED | 7 hidden, drops 1 and 46, order at 46, six final bowls |
| 1.5 Reset and in-flight recovery | WRITTEN_NOT_SIMULATED | Reset during busy and done; stale data and counter cleared |
| 1.6 Source language catalog shell | 64_PENDING | Exactly 17 cutlet + 47 month indices with independently checked Kalaallisut strings |
| 1.7 Linguistic evidence and approval | 0_OF_64 | Orthography, semantics, phonology/transliteration, Unicode NFC, a knowledgeable reviewer |
| 1.8 Whole-calendar independent oracle | NOT_STARTED | Year/gates/weaving, exact five fields, all normative witnesses |
| 1.9 CI and native simulation | NO_RUN_RECORDED | Simulator exit status 0 and retained reproducible logs |
| 1.10 Contract completion | BLOCKED | All prior items PASS, no Stage 2 until proven |

This document does not assert native fluency or silicon implementation completion.

## Separate ASIC S00–S20 gates

ASIC implementation design cannot be closed by a Stage 1 simulator result.
No PPA, DFT, timing, area, memory-bound or tapeout claims exist yet.

## Auxiliary arithmetic inspection

A scratch mathematical translation of the normative sauce formulas
reproduced the published Foundation witnesses for 7 hidden drops,
visible drops 1 and 46, orderAt46 and all six final bowls. This is
**not** a SystemVerilog simulation, not the branch's normative oracle
and not evidence of a hardware PASS.
