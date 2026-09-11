# HISTORICAL — SUPERSEDED PERFORMANCE EVIDENCE

Stage 58's bounded/weak remembering architecture remains in the branch. The former timing tables and machine-readable benchmark evidence were produced with downstream raw-sum semantics and must not be cited as current canonical performance evidence.

Original historical report: observed base HEAD `b8126dfe6a36f05fd6eb8c45479062e039412678`, original blob `68eeaaf2aaf7453aaa95b5c7054f4aa78c8d587e`.

The saved-sum correction does not attempt a new performance optimization. Correctness-sensitive Stage-58 probes were regenerated from the corrected path:

- `artifacts/STAGE_58_SAUCE_PROBE.json`
- `artifacts/STAGE_58_GATE_CHECKPOINT_PROBE.json`
- `artifacts/STAGE_58_MEMORY_PROBE.json`
- `artifacts/STAGE_58_FINAL_VERIFICATION_LOG.txt`

The old baseline/after benchmark JSONL files and benchmark report are deleted by the delta because a fair full benchmark rerun was outside the semantic-correction scope; retaining them under the same current-looking paths would be misleading. The old material remains recoverable at the recorded base HEAD.

Current canonical semantics and discriminator evidence are documented in `CANONICAL_SAVED_SUM_CORRECTION.md`.
