# QA31BN — finite original-signed `g=-1` source-only counterfactuals

**PROJECT_ID:** `PC-BRANCH-BEFUNGE98-KYRGYZ`  
**Branch:** `qa-befunge98-stage1-order-isolation-20261008`  
**Verified predecessor HEAD:** `56806c6b97d418f85aa70e47c9b9cf9ce1f5e970`  
**Date:** 2026-11-20  
**Classification:** FINITE LOCAL QA ACCEPTED; **Stage1 OPEN**; no new Native, no main/merge/Stage2.

## Frozen inputs and method

Original QA31AI ZIP SHA256 `9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49`, with embedded QA31AH and QA31Y ZIP hash/CRC checks. The previously recorded 200 HALT cases contain **3,628,390 original signed STEP events**; all case receipt trace hashes, 8 shard CRCs, step counts and original Git source blob `560d6aa5807a7f766213a33835cce85eab0fa40c` checked. The 135 selected cases have <=25,000 STEP each. QA31BI/BJ/BK witness hashes, original QA31BL case rows, and 270 baseline sink outputs from QA31BM were checked before intervening. The exact QA31BM ZIP was checked at SHA256 `f15d86ded0fee34febdc166d5b7c72f39398dd0eb74f42b419586ec77e22b070`.

Exactly **one** of the four source reads (`g`) in each of 135 cases was changed to `original - 1`, leaving other original signed reads unchanged: **540 synthetic source-only interventions**. The two arithmetic evaluators remain independently implemented: (A) explicit concrete stack/memory forward replay and (B) a distinct deferred symbolic arithmetic DAG. Any changed branch, vector, `p`/`g` address, iteration operand, modified future code fetch or dependent memory read is classified **UNKNOWN** rather than interpreted as executable Native behavior. The original signed source control path is fixed; no altered Native is executed or inferred.

## Results and test boundaries

- **540/540 interventions**: 410 yielded changed sink predictions and 130 had no numerical effect; 0 UNKNOWN, 0 A/B disagreements, 0 assumption-guard failures on *this finite selection*.
- **270/270 original baseline sinks** and 135 original signed selected cases verified. First numerical deviations in the `-1` set occurred at 270 `+` and 140 `!` instructions.
- **48/48 boundary controls** from 12 distinct original `g` roots using `M=2^127-1`, `-M`, `M-1`, and `-M+1`: 36 changed sink predictions and 12 no numerical effect; 0 UNKNOWN in this selection.
- **24/24 genuine no-op controls** preserved original sink values. **28/28 independent signed/floor remainder checks** passed, including 11 where floor-based remainder differs from truncation-to-zero remainder.
- Independent derived-evidence structural auditor accepted all rows, links, digests and class counts and rejected **12/12 intentionally hostile altered records**. `py_compile` passed for producer and auditor.

These are **local source-only numerical predictions conditional on the original signed path and memory/branch ownership**. They do *not* establish that changing stdin can produce the substituted `g` value, that a changed branch would preserve the same path in a different execution, that integer behavior of an altered Native run matches the model, global source ownership, or complete functional/geometric Stage1 acceptance.

## Reproduction and permanent evidence

An independent archived package preserves the complete producer and verifier source, unchanged upstream QA31BM and QA31BL arithmetic source files, original-data pins, five machine evidence JSONL files, summary, reproducibility instructions, and SHA256 manifest. The original 46 MB signed QA31AI archive and three independent witness files remain in `/Befunge_QA_Artifacts` and are **not repackaged**. Library path: `/Befunge_QA_Artifacts/QA31BN_BEFUNGE98_KYRGYZ_SIGNED_MINUS_ONE_20261120.zip`. ZIP SHA256: `6aaaa08c0edc66f529936d173a2894a7ed9123c523f5b47987498af4fa84ff79`; re-materialized Library readback matched byte-for-byte, all 13 ZIP members passed CRC, and all 12 manifest digest checks passed.

**NEXT — QA31BO (QA-only, Stage1 OPEN):** review the 410 changed sink predictions and the 36 changed boundary predictions for subsequent read/branch/memory ownership dependencies *after* the second sink, using original signed trace and source-only static checks. Document the first downstream dependency or an explicit finite negative result, with >=12 no-op and >=12 adversarial checks. Any possible altered control flow is UNKNOWN until new independently justified Native evidence. No Native causality claim, Stage2, main or merge.