# QA24 — Original Native finite 24-input source glyph reachability acceptance

**PASS — finite actual PyFunge-98 QA scope only. Stage 1 remains open.**

Original GitHub Actions run [39841651046](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39841651046) completed SUCCESS at exact tested commit `68bfc0d8118a6705d0a0af318f4a48a38e3a159f`. Four 6-case original-input Native shards and independent aggregate: **5/5 PASS**. All five original ZIP archives were retrieved and CRC/integrity checked, and all **776,706 STEP** records from the 24 original compressed files were independently decompressed and recounted with SHA-256-per-trace verification and physical coordinate/opcode/stringmode filtering. Aggregated metrics match the original independent audit exactly.

Immutable production source blob: `560d6aa5807a7f766213a33835cce85eab0fa40c`. Prior accepted QA18 source roles SHA-256 `263a73a40afa17a8a9b1c831a01239be671d9ea0a9c331fd3f725f83cf1cfea7` and QA20 aggregate SHA-256 `75d2ee07eaf998fcb69bcb238d5fcb2163ab8305efe4abe4378af95f41385117` reproduced.

## Original artifact identity

| Native source shard | Artifact ID | Original ZIP SHA-256 | Actual Native STEP count |
|---|---:|---|---:|
| 0 | 12459094867 | `bd999f1fe30b79d1f16e36c6823e648e23155b86091b105109640daa63392142` | 141,532 |
| 1 | 12460262287 | `f39484923a13abc0a07ff65b4118b3da35fc0fd06757217fe1829e2a81f5988d` | 141,456 |
| 2 | 12460231373 | `c5ee06b484830467e1e310bf59016262301a287acb5a66df2744fc695a8a26d9` | 249,308 |
| 3 | 12459358621 | `eefb903da4ba460bdccd718614b3f11b36f71c0733609f6ec7c684fff34d8b7e` | 244,410 |
| Independent aggregate | 12462014347 | `b53d8e10ddd6fb5725146d6087957b59f5638fc5082b772c1b839397536cf6ba` | 776,706 |

## Narrow results

- 24 unique new original inputs disjoint from the 48 QA20 inputs: 16 valid, 8 invalid. All 24 actual Native executions completed and passed the independent executable-Befunge result checks. No production code altered and no forced IP movement.
- Four original source-coordinate/opcode matches observed outside stringmode: `(10,44)`, `(179,44)`, `(235,11)`, `(396,17)`. All were **already** naturally observed in QA20, so **0 of 15** new previously unseen original source coordinates were demonstrated.
- All 15 not-yet-reached candidate cells remain unresolved. The 13 forged receipt controls were rejected. Not reached in 72 actual QA20+QA24 cases is not proof of global unreachability, source-cell deadness, or dispensability.
- QA24 saved source-coordinate STEP traces, not complete chronological physical `p/g` histories. Consequently a runtime matching opcode is **not automatically proven to be an unmodified static source byte**. A subsequent distinct QA25 physical mutation/byte-ownership audit is required for that narrower claim.
- No full numerical necessity, unrestricted geometric spaghetti ownership, all-input state isolation, Stage 1 acceptance or Stage 2 authorization is implied.

Governance unchanged: `CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`, `FULL_FUNCTIONAL_QA_PASS=NO`, `GEOMETRIC_SPAGHETTI_QA_PASS=NO`. Neither `main`, canonical `Befunge+Кыргызча`, immutable source nor approved historical QA evidence has been changed; PR #17 remains unmerged.
