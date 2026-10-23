# QA27 — Finite Native geometric source-frontier acceptance (2026-10-23)

**PASS, historical 136 original PyFunge-98 Native executions only. Stage 1 remains open.**

## Original evidence
- GitHub Actions original independent CI: [39966335703](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39966335703), **SUCCESS**.
- Exactly audited HEAD `368e5f09ca875c423080ba138bfc90c8bde9b1d6`.
- Original aggregate artifact `12508163830`, original ZIP SHA-256 `670a5293ead50bb1f63ccbb7058b258bd794198b0b5657637171708cd2b6a179`; ZIP CRC verified.
- Full original physical STEP coverage: QA20 48 / 1,939,997; QA24 24 / 776,706; QA26 64 / 1,796,720. **136 original runs and 4,513,423 actual STEP events** reproduced.
- 12 original shard Native artifacts, original QA18 source role SHA-256, original 2D production Git blob, all 136 compressed trace SHA-256 entries and Native saved nearest/hit receipts were checked independently by the GitHub CI job.
- 60 of 60 adversarially changed Native-manifest headers rejected.
- Exactly the six earlier observed candidate original source-coordinate/opcode contacts; no natural runtime source opcode visits to the other **15 original cells**. Every minimum L1 witness for those 15 is already present in QA20, with distances in `[3,9]`. Full coordinates and nearest witness input/direction/opcode are documented in `qa/QA27_ORIGINAL_NATIVE_DIRECTED_SOURCE_FRONTIER.md`.

## What has **not** been proven
- No claim that the unobserved 15 cells are impossible to reach on any input, universally dead code, or unnecessary to output.
- No claim that proximity or absence of an edge from finite traces proves reachability or nonreachability.
- Physical STEP value matching source does not establish original static-byte ownership when arbitrary future/earlier changes through other memory APIs are possible.
- The general functional, geometric spaghetti, state-ownership and all-input gates of Stage 1 are not accepted.

**Next engineering gate:** study actual directed predecessor/successor edges and dynamic instruction selection near the 15 cells, with explicit source-byte provenance or bounded actual Native counterfactuals only where warranted. Do not initiate a merely larger undirected random corpus.

Governance: `CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`, `FULL_FUNCTIONAL_QA_PASS=NO`, `GEOMETRIC_SPAGHETTI_QA_PASS=NO`. Do not change immutable production blob `560d6aa5807a7f766213a33835cce85eab0fa40c`, `main`, canonical `Befunge+Кыргызча`, historical signed QA sources, PR #17 or Stage 2.
