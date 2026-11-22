# QA31CB — 900-input native sweep: completed evidence review (2026-11-22)

**PROJECT_ID:** `PC-BRANCH-BEFUNGE98-KYRGYZ`  
**Scope:** QA-only review of the existing Stage 1; no production modification, branch merge or global acceptance.  
**Branch:** `qa-befunge98-stage1-order-isolation-20261008`  
**Executed SHA / original HEAD:** `faf93de8d27ec112c7c57d6fbfe193c3475a4187`  
**Original production Git blob:** `560d6aa5807a7f766213a33835cce85eab0fa40c`  
**Pinned PyFunge 0.5-rc2 source TAR SHA-256:** `e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac`

## Immutable native evidence

- Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44996727508 — completed/success, head SHA matches the above executed SHA.
- Job: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44996727508/job/137129240977 — completed/success. Preflight, pinned runtime, all 900 fresh Native executions, independent trace auditor and artifact upload steps all completed/success.
- Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44996727508/artifacts/14745206712
- Downloaded artifact ZIP SHA-256 (independently computed): `ea247b7c907d9cd0e1fb8e211619ff538b99b435dd43bcdaef70f084f6e499be`; agrees with GitHub's artifact digest and job log.
- Archive inspection: ZIP CRC **13/13** members; artifact-manifest SHA-256 **12/12** data members; project, run ID and SHA match.

## Native and independent auditor conclusions

- 900/900 distinct supplied **natural stdin strings** `1 0 0 N`, `N = 100..999`: Native `HALT` 900, runtime errors 0, step-limit 0, multi-IP 0.
- 24,853 physical STEP records per case, totaling **22,367,700**. The independently executed CI auditor reports trace SHA-256 checks **900/900** and physically checked STEP records **22,367,700**, all consistent with CI's asserted `evidence_integrity=PASS`.
- 1,800 stdin read events, 1,800 `p/g` owner-cell events, 900 dynamic-code `p` events, 900 corresponding fetched code opcodes verified by the CI auditor. Detached hostile mutations **20/20** rejected by CI.
- 900/900 audit classifications: **`FINITE_NEGATIVE_FOR_INPUT`**; anomaly 0, natural reachability case 0, route-divergence case 0. Original owner-cell `g(19,1696)` returned 0; effective code `p(1500,1860)` wrote 62 (ASCII `>`) and the dynamic fetch observed 62. Output and route were identical over the tested input range.
- The `56*g_value+62` relation is verified for the observed finite cases; it is not a general reachability theorem.

## Separate offline inspection (post-download)

- Recomputed SHA-256 of the complete artifact and each of its 12 manifest-listed data files; checked ZIP CRC.
- Joined 900 Native case receipts to 900 independent per-case audit records, checked distinct complete numeric input domain and exact stdin bytes + raw SHA-256, original source pins, status, step count, owner/code events, and classification.
- Checked 20 archived hostile-result records (20 unique mutations, `rejected=true`); their *execution* is substantiated by the completed CI auditor, **not independently rerun offline**.
- Fully decompressed the **four retained** physical traces (`token_100`, `token_199`, `token_500`, `token_999`): verified each gzip-file SHA, 24,853 monotone STEPs, HALT, precise `p/g` event ticks, storage offset and dynamic fetch opcode.
- **Retention limitation:** the full physical traces for the other **896** cases were checked during CI but **not archived**; only case receipts/digests/audit records remain. Therefore an independent reviewer of the downloadable artifact cannot repeat 900/900 physical STEP walk without fresh execution. Never describe the artifact itself as retaining 900 complete traces.

## Gate decision and NEXT

**QA31CB bounded Native + CI auditor gate: ACCEPTED** for the exact SHA, toolchain, original source and tested 900 input strings. This corrects the prior failed run `44958764254`; preserve that failed artifact as evidence of the Docker-owned pre-existing trace permission regression. The QA-only permission repair is validated by the completed run.

**Stage 1: OPEN / NOT ACCEPTED.** No global reachability, source-wide ownership theorem, or functional/geometrical proof is implied by 900 finite negatives. Production blob remains untouched; no main, merge or Stage 2.

**NEXT within authorized Stage 1:** perform a source-guided, falsifiable control-flow/stack-origin search for a **reachable** natural input making `g(19,1696) != 0` at the relevant code-writing `p(1500,1860)`; define input domain, exact original-source pin, independent oracle, bounds and hostile controls *before* any distinct Native experiment. If no witness is found, report the proved bounded domain only; do not extrapolate to global nonreachability or repeat this 900-case sweep at the same SHA.
