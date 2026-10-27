# QA31B — finite original Native pre-j stack acceptance (2026-10-27)

## Exact scope and provenance
- Branch: `qa-befunge98-stage1-order-isolation-20261008`.
- Code/run HEAD: `518b835c7061842d476d56fa42083373429b740a`.
- Workflow: [QA31B original Native pre-j](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40495897566) — status completed; conclusion **success**; original-native-pre-j job and every reported step success.
- Uploaded evidence artifact: [qa31b-original-native-pre-j-stack](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40495897566/artifacts/12730603894) (artifact ID `12730603894`, unexpired at review).
- Artifact ZIP SHA-256 (GitHub digest independently recomputed on downloaded ZIP): `d76c87989b9ff478c0be65ebb3ed3946e8a3aa668961f86dfa4c552ad2d5cf14`.
- ZIP central-directory file CRC verification: PASS for all four entries (Python `ZipFile.testzip() is None`).
- Exact original source Git blob: `560d6aa5807a7f766213a33835cce85eab0fa40c` (no source modification, no IP relocation).
- Runtime: pinned PyFunge 0.5 rc2 archive SHA-256 `e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac`.
- Signed prior QA31A JSON SHA-256: `39f017ea8cb4b6865df031639763f8546fb87427ca94b487e18493fc475a189c`.
- Signed original QA20 manifest SHA-256 values: valid00 `782fb868a11a105550ef5af6f8f7cd39e4ba9de77d9565f7549e310549b0073a`; invalid18 `9c5af6212cfd7c1ab58e9603f385767e64b10799c90be416a86c4f09d613bfdd`.

## Evidence verified
1. Complete original PyFunge Native replay: `valid00` **17,387** steps and `invalid18` **1,672** steps, **19,059** physical STEP records total; each physical STEP matched its SHA-pinned original full trace, and each original output vector matched.
2. At the natural `j` execution position (114,38), with no source or IP intervention, measured actual **pre-j top-of-stack operands**:
   - `valid00`, tick **9607**, operand **61**, next x=**176** (physical dx=**62**).
   - `invalid18`, tick **1455**, operand **0**, next x=**115** (physical dx=**1**).
   Both were popped exactly once; queue/invert modes were disabled.
3. The independent Python 3 auditor checked original SHA-pinned steps and replay receipts, rejecting **28/28** adversarial alterations (14 for each route).
4. Extracted artifact file hashes: `qa31b_native_pre_j.json` SHA-256 `aeabff435363c50cda4e7a109657d7f0b9b66a8a2dbf1e04da8fa82bc3279224`; `independent.json` SHA-256 `a2b74c3c9c6b8aec42a3836dc8876c1dfd3f424a694bd094805ea525f0b049ce`; `native.log` SHA-256 `0f832b8568e6bf2a78b95eff3dd94506b0cdd82096e9ac08f0188272866acdbf`; `audit.log` SHA-256 `0e7987f756529496c64c96ed7cd0160c4e523854419bcdbb2403879bb8d5289b`.

## Bounded acceptance
**QA31B finite original Native pre-j stack parity: PASS at exact run HEAD only.** This establishes observed operands and geometric/stack consistency at the two signed natural-input routes. It **does not** establish that differences in input *caused* the stack differences. It is not global input/geometry/source ownership proof, not certification that the other 15 candidate glyphs are dead code, and **not** Stage1 sign-off. `CURRENT_STAGE=1`; `LAST_COMPLETED_STAGE=0`; Stage2 unopened; no canonical merge authorized.

## Single follow-up gate
Next: design a bounded QA31C **causal input-read-to-pre-j operand** original-Native gate. First identify an actual input-read event and a controlled real-input intervention retaining the pinned production source, original instruction entry, full physical Native tracing, genuine read/write and stack provenance, identical-runtime sham controls, explicit finite budgets, and independent adversarial receipt checks. Do not equate between-run correlation with causality. Do not report Native PASS or input causality until an exact-head original GitHub Actions run and artifacts have been independently verified. Existing QA09C calibration work remains separate; no new development stage is approved.
