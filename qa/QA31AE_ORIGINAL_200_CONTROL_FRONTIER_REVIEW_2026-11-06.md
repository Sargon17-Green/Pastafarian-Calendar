# QA31AE — 200×15 original signed Native control coverage (2026-11-06)

**PROJECT_ID:** `PC-BRANCH-BEFUNGE98-KYRGYZ`
**Working branch:** `qa-befunge98-stage1-order-isolation-20261008`
**Pre-review HEAD:** `d7f089680d47fa39b9587feec996f2586ab462cc`
**Frozen original source blob:** `560d6aa5807a7f766213a33835cce85eab0fa40c`; original production not edited.

## Input and provenance

Reused the eight original signed QA31V ZIPs containing 200 HALT Native traces (run [41689861481](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689861481)), preserved in [the immutable QA31Y archive](https://drive.google.com/file/d/1N3QeYs6FTJEafeHyeU0u5wiLdIRfv5CV/view), SHA256 `1c97b51823ed98b3d333fcb2d0b35d72f7546b04ed8e86c5adebe3aca5703e8a` (46,421,841 bytes).

The original Git blob was retrieved, and all 15 target source coordinates from QA31Q were compared independently with the exact original opcode. The local runner can additionally SHA1-check the complete original Git blob if the source is supplied with `--source`; without it, the runner relies on the 15-byte GitHub-verified source snapshot and the original receipt source identity.

## Measured finite results

| Check | Result |
|---|---:|
| Original shard ZIP SHA256 and CRC | 8/8 |
| Original compressed Native trace digests and receipts | 200/200 |
| Original physical STEP records checked for physical continuity | 3,628,390 |
| 200×15 per-case/source-cell matrix | 3,000/3,000 |
| Control sites with observed physical execution | 12/15 |
| Original physical control instruction executions | 1,200 |
| Positive case×site cells | 1,200 |
| Distinct physically observed immediate predecessor edges | 12 |
| Hostile changes rejected (36 original-record tests + 15 source snapshots + 1 original ZIP byte mutation) | 52/52 |
| Independent second auditor: complete physical recount and CSV validation | PASS: 200 traces, 3,000 matrix cells, 1,200 events |

Exactly 100 distinct input cases visited each of the 12 observed source sites once. The remaining three sites had **zero observed execution in this finite corpus**:
- `(286,5) x`
- `(235,23) x`
- `(235,32) x`

**These are not globally unreachable proofs.** This audit executes neither new Native nor CI, and claims no Stage1 PASS, no global input ownership, no full functional/geometric acceptance, no merge/main or Stage2.

## Reproducible evidence — conversation attachment

A 46,455,068-byte reproducible ZIP was created for delivery as a conversation file:
`QA31AE_BEFUNGE98_KYRGYZ_ORIGINAL_200_CONTROL_FRONTIER_20261106.zip`
SHA256 `21e16bd57029e79aa9b701086963a2263406e10355de05e34ab00e7289db49ae`. It contains the frozen original QA31Y ZIP, independent Python auditors, Windows launcher, 200×15 CSV, source-site snapshot, observed physical predecessor CSV, JSON outputs and contract. The local auditors executed successfully, the ZIP CRC is valid and both scripts compile.

**Persistence scope:** This report is committed to GitHub. The reproducible ZIP exists as a downloadable conversation attachment. An attempted upload of the ZIP to the Library `/Befunge_QA_Artifacts/` failed with `container_session_unavailable`; do NOT infer the Library copy exists. The user's existing original QA31Y evidence archive remains separately available in Drive.

## NEXT: QA31AF (bounded, independently specified)

Analyze only the three residual unobserved cells with source-pinned finite branch-gate contract: `(286,5)` versus hypothetical negative `~` return; `(235,23)` versus source conditions `m=1,q>3`; `(235,32)` versus `q>3` upon row32 entry. Inputs: frozen source and QA31V 200 signed traces plus QA31AE per-case witnesses. Output: conditional route model, measured original gate-prefix table, separate oracle, source/trace mutation negatives. Do **not** invent a natural Native witness or run Native until a grounded input candidate exists. Stage 1 OPEN.
