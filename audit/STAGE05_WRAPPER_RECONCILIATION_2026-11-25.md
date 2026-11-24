# Stage05 PATCH02 — 2026 Rust reconstruction wrapper reconciliation

PROJECT_ID=PC-BRANCH-RUST-AZERBAIJANI
START_HEAD=df2f09119dac6ac80636fde938b1dfc7684c2016
SCOPE=STAGE05_WRAPPER_REPAIR_ONLY
NATIVE=NOT_YET_VERIFIED
STAGE06_DISTANCE=NOT_CLAIMED
STAGE07=NOT_STARTED

The pinned approved reconstruction source at 108833d04786be22bfcadc987c7208b35c373451, src/discovery02_legacy_day_tag.rs blob f256bde42a8e62576d20c500a46517663bc0d5ed, computes 2*abs(day-F)+1, including before F=-15055671. The Stage05 wrapper now calls this reconstructed Rust arithmetic once per input and subtracts one only before F. It deliberately does not replace the original historical SHA or claim a historical runtime RED. Kotlin's documented legacy formula differs; do not import its code or fixture. Normative WorkCounts distance is retained as an auxiliary positive route, not Stage06 discovery.

Production handler records raw and corrected tags in the call-local log, counts both legacy calls, and rejects repeat observations without changing context. Independent test derives the piecewise expected tag using signed offsets and addition, 63 consecutive offsets plus 6 signed wide offsets (129, 1031, 4097 bits); expected 34 pre-foundation discrepancies and 35 controls, one dispatch per pair, 69 duplicate guards. The CI gate requires the exact marker and keeps existing tests. These counts are a test contract, not observed Native results.

The old Stage06 stone workflow no longer emits whole-stage acceptance from stone evidence. The recorded DEVELOPMENT_STAGE counters are unchanged pending repaired Native evidence; the old 230-stone acceptance is disputed in semantic scope and remains auxiliary. Stage06 distance route is deliberately not implemented in this commit. No Stage07, main, merge, release, or manual dispatch.

NEXT: check exact SHA Stage05 wrapper job/log/artifact and prior regressions, then implement Stage06 legacy distance using these corrected production tags with independent strict expected-red gate.
