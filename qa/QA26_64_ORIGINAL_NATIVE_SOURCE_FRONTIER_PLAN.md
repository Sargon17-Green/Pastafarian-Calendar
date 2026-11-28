# QA26 — 64 fresh natural-input Native source-frontier routes

**Status at submission:** GitHub Actions run [39945902093](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39945902093), `queued`. This is an experimental QA gate, **not a PASS or Stage 1 sign-off**.

## Fixed foundations

- Original production Git blob: `560d6aa5807a7f766213a33835cce85eab0fa40c`, strictly unchanged.
- Accepted QA18 21-source-candidate roles, SHA-256 `263a73a40afa17a8a9b1c831a01239be671d9ea0a9c331fd3f725f83cf1cfea7`, from original Native run `39423789058`.
- Accepted QA20 48-source-route aggregate, SHA-256 `75d2ee07eaf998fcb69bcb238d5fcb2163ab8305efe4abe4378af95f41385117`, from run `39761821210`.
- Accepted QA24: 24 additional natural-input Native cases, no new contact among original 15. Accepted QA25: real `FungeSpace.put` physical provenance for those 24 cases, not global ownership.

## Proposed Native experiment

1. Freeze **64 new unique input strings** in `qa/stage1_qa26_frozen_input_corpus.py`: 32 valid signed/magnitude tuples, 32 malformed lexemes using negative magnitudes or out-of-domain sign flags. All new raw inputs must differ from QA20's original 48 and QA24's original 24. Cases are enumerated deterministically before CI; no post-hoc selection.
2. Four actual PyFunge-98 Native shards, **16 unchanged original programs per shard**. The previously accepted PyFunge 0.5-rc2 archive is SHA-256 pinned. Each valid program must match results of independently executed Befunge `reference/work_counts.b98` and two Befunge `reference/save.b98` calls; each malformed case must yield the exact seven `-1` rejection fields. No Python calendar arithmetic.
3. Save all actual per-tick Native IP coordinates, direction, fetched opcode and stringmode into individual compressed original STEP traces. No forced IP relocation, `z` mutation, source edit, or changed test acceptance threshold.
4. Separate Python 3 auditor must replay **all 64 physical source STEP files**, verify every SHA-256, step index, case input, valid/invalid output and the full original 21-cell source-coordinate proximity and hits. On all four shards require **52 negative forged receipts rejected** (13 per shard).
5. Compute the exact subset of original **15** source cells newly encountered with matching runtime opcode outside stringmode. Any still missing remain **unresolved, not dead**. A matching fetched runtime opcode is not proof that the original source byte still owns the cell; QA25's physical ownership audit covers its earlier different finite corpus only.

## Explicit limitations

Input expansion tests **finite natural routes**, not whether the original fifteen are reachable for every possible input, not whether source writes are absent, and not the global memory/geometry contract. If a difficult case exceeds the Native cap, retain RED/unresolved evidence and fix the exact experimental problem; do not silently skip or recategorize it as valid PASS. Keep all QA10–QA25 accepted artifacts immutable. No modification to `main`, canonical `Befunge+Кыргызча`, original 2D production, PR #17 merge, or Stage 2.

`CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`, `FULL_FUNCTIONAL_QA_PASS=NO`, `GEOMETRIC_SPAGHETTI_QA_PASS=NO`.
