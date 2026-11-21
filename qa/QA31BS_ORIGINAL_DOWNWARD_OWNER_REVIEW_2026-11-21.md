# QA31BS — original signed last writers of the downward code corridor

**PROJECT_ID:** `PC-BRANCH-BEFUNGE98-KYRGYZ`  
**Authorized branch:** `qa-befunge98-stage1-order-isolation-20261008`  
**Exact entry HEAD:** `468e3c8b1cbcd33025369980dd68a3226ff3cfbd`  
**Frozen original source Git blob:** `560d6aa5807a7f766213a33835cce85eab0fa40c`  
**Date:** 2026-11-21  
**Result:** LOCAL FINITE QA31BS ACCEPTED; STAGE1 OPEN; NO NEW Native or CI specifically for QA31BS.

## Grounded original inputs

The six existing archives QA31AI/BN/BO/BP/BQ/BR were separately pinned by exact SHA256 and verified for ZIP integrity and their applicable manifests. The original QA31AI nested eight signed Native shards are source-pinned. Across these, 200 HALT receipts and 3,628,390 physical STEP records are accounted for. The selected original cohort contains 135 complete gzip traces, validated for per-case signed compressed SHA256 and contiguous t=1..N, and cross-matched to earlier BP/BQ/BR records.

No original execution was rerun or modified. Source excerpt at x=1500 was originally inspected against Git blob `560d6aa...` in QA31BR, but the full 1.8 MB original source was **not** locally rehashed; this scope limitation remains.

## Original observed ownership

For every selected case, both independently implemented scans — a chronological physical `p` map and a separately traversed reverse physical `p` last-writer scan — found **zero original `p` writes before the executable fetch** to both `(1500,1861)` and `(1500,1862)`. These positions therefore still hold the original source characters `v` (ASCII 118) and `7` (ASCII 55), respectively, at that exact observed original fetch boundary. Each of the 135 case results agrees with the signed earlier original fetch at `(1500,1860)` and its original executed `>` to `(1501,1860)`. The full selected original traces also have **zero executed IP visits** to either downward position.

Only the first two downward cells have this independently checked physical-owner status. The pinned static column excerpt beginning at `(1500,1861)` reads `v7a*9+1a*7+a*1+a*0+g`; the remaining cells of this excerpt have **not** been individually certified here against pre-fetch writes.

Conditional source-only geometry: if — and only if — a modified execution reaches the same writer, writes `v` at `(1500,1860)`, fetches that byte in the same vector state, and does not otherwise modify the downward cells, then the first downward move is to `(1500,1861)`; if the `v` there executes unchanged, it directs execution to `(1500,1862)`, whose original source is `7`. This is **not** a proof that this route occurs in any changed execution, or that the stack or output matches a hypothetical interpretation.

## Control and audit results

- 135/135 selected signed original traces: both physical last-owner methods agree for both cells.
- Original 200/200 HALT receipts / 3,628,390 physical STEPs accounted for by the historical archive loader.
- 24/24 *genuine prior unchanged/no-effect input controls* cross-pinned against original signed cases and baseline sinks.
- 19/19 *detached hostile mutations* rejected, including target-writer operands, fetch/next transitions, and actual source-excerpt corruptions passed through the auditor. These are local auditor negative controls, **not** new Native witnesses.
- Python `py_compile` and full local evidence CLI PASS. A first draft incorrectly required all `p` instructions to have three explicit stack operands and an empty post-stack. This was fixed to implement Befunge stack-underflow zero operands and to preserve any underlying stack, then the complete six-input check was rerun to completion.

## CI distinction and next step

Existing branch push run [44876548729](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44876548729), exact prior HEAD `468e3c8b...`, subsequently completed/success, with 30/30 jobs completed/success. Specifically job `136762400343` reported `STAGE1_TARGETED_NATIVE_REGRESSION_PASS total_invocations=421`, while also explicitly retaining an unproven in-process FungeSpace ownership property. This is an existing regression, **not QA31BS CI**; its presence does not change the stage verdict. Its artifacts have not all been independently downloaded and audited here.

**NEXT: QA31BT QA-only, Stage1 OPEN** — independently audit original signed `p` ownership and physical visits for the *remaining* bounded original-source vertical cells `(1500,1863)..(1500,1880)`, cross-check against the immutable source excerpt, and define precise conditional behavior only where source characters and original ownership are verified; include >=12 genuine unchanged controls and >=12 detached hostile controls. Changed-run route, current writers, address, stack and output remain UNKNOWN until a distinct evidence-backed Native intervention is justified. Do not change production, merge/main or Stage2.