# HISTORICAL — SUPERSEDED

This report name is retained as an archaeology marker for the former Stage-56 raw-bowl-sum correction. Its former claim that `rawBowlSum` inside `u` was authoritative is **wrong under the current Scroll**.

Original historical report: repository `Sargon17-Green/Pastafarian-Calendar`, branch `JavaScript+Interlingue`, observed base HEAD `b8126dfe6a36f05fd6eb8c45479062e039412678`, original blob `0ff4b46a0815f471e53c8a78496ead43aafffb90`.

The original raw-sum witnesses and PASS statements are retained in Git history only as evidence of the superseded interpretation; they are not canonical expectations and must not be used to regenerate tests or vectors.

Current canonical correction: see `CANONICAL_SAVED_SUM_CORRECTION.md`. The reachable implementation now uses saved `R=SAVE(S+149*r)` inside `u`; the raw-sum implementation survives only as the explicit mutant in `tests/stage-56-reference.js`.
