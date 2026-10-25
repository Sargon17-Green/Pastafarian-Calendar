# QA30B — Accepted finite live Native source-owner/control frontier

**Acceptance: 25 October 2026. PASS for two authentic Native input-origin executions only. Stage 1 remains OPEN.**

## Signed run and original artifact

- GitHub Actions run [40181505221](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40181505221) completed **SUCCESS** with independently checked Native and Python 3 audit stages on tested commit `e7f3936f76c5984898f7ce356a9baae912541f7d`.
- Original CI artifact ID `12594238742`, ZIP SHA-256 `11e26d4602d5c56bc5ef3046aeb33a6240adc6ba434e8e219eaeb3c628238d82`, independently downloaded and verified ZIP CRC PASS.
- Original Native live-state JSON SHA-256: `aabbc2535400e40231d0e3115ba9621b1d0e8b64fb2dd0a6a109094ba59000ed`. Independent audit JSON SHA-256: `45dd7d81786e759e8216bd9f5cb7c1665b523c3c9dace219f6c7c5d7359c3102`.
- Frozen QA20 origin run `39761821210`; original QA30A accepted run `40125781530`, QA30A report SHA-256 `7c3ba01dc00a4f67fc30cc52e594b1cd6a2adee597a21939dbe0176ac2be2d4e`. Production source Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c` unchanged.

## Narrow, actually observed Native results

| Original input | Steps replayed with exact original STEP/output parity | QA30A-near-control live snapshots | Actual `FungeSpace.put` calls | Writes into any of the original 15 candidate source cells |
| --- | ---: | ---: | ---: | ---: |
| `invalid00` | 17,187 | 21 | 68 | 0 |
| `invalid18` | 1,672 | 1 | 5 | 0 |
| **Total** | **18,859** | **22** | **73** | **0** |

All **32/32 independent adversarial modifications** to real Native source-ownership receipts were rejected. Live state values at all 15 candidate coordinates were reconciled against the signed source and observed physical `FungeSpace.put` history at 22 actual signed control-edge witnesses. This is **not** a proof of no other memory modification interfaces, or of all-input byte ownership, global source reachability or complete functionality.

## Historical red evidence retained

First QA30B run `40170081656` completed with 2/2 original Native replays and 22 snapshots, but the independent auditor failed with Python 3 `UnboundLocalError` because local variable `original` shadowed a same-named function. That red result and original artifact `12591218383` remain in the GitHub run history. The precise fix `e7f3936f76c5984898f7ce356a9baae912541f7d` renamed the local variable to `signed_case` without relaxing an acceptance gate or altering any source program.

## Stage 1 governance and next technical gate

Original QA18's 15 source instructions unobserved through the 136-case QA20/QA24/QA26 corpus remain **unresolved**, never globally certified dead or impossible. The QA30A + QA30B pair is a finite original-path dynamic-control/memory witness study, **not Stage 1 signoff**. Subsequent investigations should focus on actual source-driven `x`/`j`/`k` control-state conditions with source-relative provenance, and preserve a strict separation between sampled absence and a universal reachability proof. No forced IP placement, test source rewriting or blanket inferences from proximity.

`CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`, `FULL_FUNCTIONAL_QA_PASS=NO`, `GEOMETRIC_SPAGHETTI_QA_PASS=NO`; no Stage 2, PR #17 merge, `main`, canonical `Befunge+Кыргызча`, or immutable production byte changes.
