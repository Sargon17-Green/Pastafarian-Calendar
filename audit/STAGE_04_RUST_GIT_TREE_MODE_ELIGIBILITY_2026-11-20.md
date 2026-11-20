# Stage04 — Git tree mode eligibility regression (Rust + Azərbaycan)

- PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
- Parent branch HEAD before change: `879d161a98522bb6beb4c37d1d84755f78e9dc62` (verified identical via branch comparison).
- Branch: `Rust+Azərbaycan-dili`. No main, merge, Stage05, or production Rust source changes.
- CURRENT_STAGE=4; LAST_COMPLETED_STAGE=3; Stage04 remains OPEN / NOT_CLAIMED.

## New failure, independently reproduced (synthetic Git; not historical Rust RED)

An exact Git source path can resolve via `git rev-parse COMMIT:src/witness.rs` to a `blob`, even when its tree entry has **mode 120000** (symbolic link). The old `verify_pin` source gate checked blob SHA/type and ancestry but never verified tree-entry mode, so a symlink inside eligible pre-Stage04 ancestry could be marked `source_pin_eligible=True`. A minimal, newly constructed Git history reproduced that old behavior before patching.

Mode matrix from an isolated local Git fixture:
- 100644 regular Rust file: old accepts, new accepts.
- 100755 executable regular Rust file: old accepts, new accepts.
- 120000 symlink named `src/shortcut.rs`: old accepts, new rejects.

This is **source provenance misclassification only**. The later historical archive extraction already rejects symlinks. Neither this reproducer nor this fix establishes a historical callable production Rust day-tag or numerical Rust RED.

## Patch and reproducible QA contract

`tools/stage04_rust_witness_provenance.py` now uses `git ls-tree -r -z --full-tree <commit> -- <path>`, matches the exact returned path, and requires one regular Git tree blob entry with mode 100644 or 100755 and the already-pinned blob SHA. A symlink (120000), non-blob, missing or ambiguous entry fails closed. This preserves existing commit/ancestry/checkpoint and checkout-SHA guards.

Two new synthetic Git integration tests are added to `tools/tests/test_stage04_rust_witness_provenance.py`:
1. pre-stage3 symlink blob with matching SHA must be rejected;
2. pre-stage3 executable regular Rust blob must remain eligible.

The Stage04 workflow provenance expected count changes from 14 to 16, with no relaxation of other tests or verification thresholds. Local Git mode matrix above is a focused static/synthetic reproducer, **not** complete CI or Native PASS.

## Prior evidence / unchanged acceptance boundaries

Canonical Names Lock on the parent report-only SHA: workflow run 44800020713, job 136509432286, completed/success with exact checkout SHA in decoded logs and successful Verify canonical names lock step.

Prior Stage04 code SHA `08d1eba8f2d0ebaafb23cb562008c4f3aced5903`: Stage04 run 44734470550 and Names Lock 44734470528 completed/success with prior 14 provenance controls, 16 callability, 6 TSV, 34 Rust native, 15 cross-runtime differential; artifact 14628677552 independently checked. This patch is a **new SHA**, and these historical results cannot certify the patched code. Await exact completed/log evidence from automatically triggered CI; do not duplicate a run.

Closure requirement remains an ancestry-pinned executable historical **production Rust** day-tag and an independently verified normative numeric RED. None has been shown.
