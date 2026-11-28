# QA31CA — independently verified one-off changed Native receipt (2026-11-21)

**Project:** `PC-BRANCH-BEFUNGE98-KYRGYZ`  
**QA branch:** `qa-befunge98-stage1-order-isolation-20261008`  
**Production source Git blob:** `560d6aa5807a7f766213a33835cce85eab0fa40c` (unchanged).  
**Experiment commit:** `4e0f75f4a6c301228075348286ebc490845a50c9`. This is historical, not the current QA branch HEAD.

## Completed CI/Native evidence

- Altered run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44937431984 — `completed/success`, one job `136947026674`, checkout SHA `4e0f75f4a6c301228075348286ebc490845a50c9`. All steps including Native execution, independent audit, and upload succeeded.
- Altered artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44937431984/artifacts/14720763428 ; actual ZIP SHA-256 `0ee73101adc21b076152fc9a96f2a029ed44a8f472f4cd0502efa655e7a39023`, size 233,911 bytes, seven entries, ZIP CRC all valid.
- Prior original control: run https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44927920020 ; artifact 14717136552; ZIP SHA-256 `988045a5a51fde51cfa544ca3fdbba23b7b33fa76f7e9e89b9a942c0ab3d707c`, CRC valid. Nested original QA31V ZIP SHA-256 `5732cdf515a81c37982c8e79e5c4368e11e7a3b4e35fb1eae82bed2e17e24553`, CRC valid.
- Original replay: exactly **17,875** consecutive JSONL STEP events, no tick gaps. Altered Native: exactly **17,999** consecutive JSONL STEP events, clean `HALT`, two actual stdin reads. Both full gzip traces independently decompressed and parsed; recorded compressed SHA-256 digests matched. Changed compressed trace SHA-256: `699b0e3c05085fd054e603ff07c756ec65a3816e55f1cf79e144dbd27c4072ab`.
- Independent byte-for-byte JSON STEP comparison: original and altered are identical for ticks **1–17816** inclusive. The **first** difference is tick **17817**, a single changed pre-`p` TOSS: original `[62,1500,1860]`; altered `[118,1500,1860]`. The `p` IP is `[96,480]`, physical target `[1500,1860]`, storage offset `[0,0]`, original cell byte/value 32.
- At tick **17845**, original physically fetches opcode 62 (`>`) at `[1500,1860]` and continues to `[1501,1860]`. Altered Native fetches opcode 118 (`v`) at that same physical cell and continues to `[1500,1861]`. Altered Native halts at tick 17,999. This establishes a finite, runtime-observed code-cell/route effect under one controlled stack-value intervention.
- Independent auditor emitted `FINITE_NATIVE_ONE_INTERVENTION_PASS_NOT_STAGE1`, `changed_native_steps_verified=17999`, `changed_p_g_events=204`, `changed_target_fetches=1`, `independent_detached_hostiles_rejected=18` (18/18). These are verified log and audit-file claims. The changed receipt explicitly stores `differential_accepted=false`, and both receipts store `stage1_accepted=false`.

## Boundary and non-claims

This intervention is **not** an ordinary-input test and cannot establish natural stdin reachability of value 118, exhaustive input/output behavior, or full Stage 1 acceptance. The signed original and altered Native evidence is accepted **only** for the one controlled intervention. No original Native rerun, production-source edit, `main` change, merge, or Stage 2 action was performed in this review.

## Subsequent QA31CB check

At review, QA branch advanced via `7b546393065320fda61695239f83ac763f532bbc` to a separate, **900-natural-input** QA31CB contract. Its first run `44951094858` failed *before Native* because the code TAR actual SHA-256 `434b28e54bab23155606fde529a4d5bbe43a9f32acb317257a3ee8a60e1651f3` disagreed with workflow's pinned expected SHA-256 `c4cd888e84b317c73bb844d8afadb3e7017d478e6b8a2c915a5c159c995a80c5`. Separately, the `always()` manifest step failed because the output directory had not yet been created. QA-only workflow fix `4b338ecb60ff89fba4e30a1100fb058b020a7495` pins the real TAR digest, adds TAR listing integrity preflight, creates the output directory before verification, fixes mistakenly backslash-escaped workflow expressions, and ensures manifest directory existence. The new QA31CB run `44953826371` was **queued** at review; it must not be called PASS until completed and independently checked. No duplicate QA31CA run was dispatched.
