# QA31BM — original-signed single-`g` numerical counterfactuals (finite)

**PROJECT_ID:** `PC-BRANCH-BEFUNGE98-KYRGYZ`  
**QA branch:** `qa-befunge98-stage1-order-isolation-20261008`  
**Verified parent HEAD:** `89603a3fc209889993ecbaab8d199486c7390f2e`  
**Date:** 2026-11-20  
**Classification:** local finite QA accepted; **Stage1 OPEN**; no new Native, no Stage2, no main/merge.

## Verifiable evidence and exact provenance

Replayed the original QA31AI archive (SHA256 `9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49`), including embedded QA31AH (`4c17deae595262dcbcb8863da005810f60288c483273e32b3b2955b9fb13e271`) and QA31Y (`1c97b51823ed98b3d333fcb2d0b35d72f7546b04ed8e86c5adebe3aca5703e8a`). Pinned 200 original signed HALT cases, 3,628,390 physical STEPs, all eight shard CRCs and case receipt digests, and the original source Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`.

The 135 cases and 270 observed sink baselines were independently checked against original QA31BL numeric witnesses and pinned QA31BI/BJ/BK records before any intervention. Each selected original case is within 25,000 STEPs.

For each of the four original `g` roots of 135 cases, performed exactly one synthetic `original + 1` intervention, leaving all other signed `g` values unchanged. Two distinct implementations evaluated the same fixed recorded source path:

- A: a concrete forward stack-and-memory exact-integer interpreter with explicit branch/vector/address/iteration assumption guards and changed-code-fetch rejection.
- B: a separately built symbolic arithmetic expression DAG that independently evaluates both sink expressions from the original opcodes and substituted root value.

**Local results:** 540/540 bounded interventions; 270/270 baseline sinks; **405 changed sink predictions**, 135 no-further-numeric-effect cases, zero two-oracle disagreements, zero path-assumption failures on this exact intervention set; **24/24 no-op controls**, **12/12 derived hostile mutations rejected**. Python compilation passed. The result is conditional on the fixed source-control path, recorded memory ownership and input constraints.

## Permanent QA artifact

The full runnable QA-only implementations (both counterfactual evaluator and independent evidence verifier), source pins, original QA31BL verifier, 540 intervention rows, 270 baselines, 24 no-op controls, machine summary, reproducibility instructions, report and manifest are preserved in ChatGPT Library at:

`/Befunge_QA_Artifacts/QA31BM_BEFUNGE98_KYRGYZ_FINITE_COUNTERFACTUAL_20261120.zip`

**Exact ZIP SHA256:** `f15d86ded0fee34febdc166d5b7c72f39398dd0eb74f42b419586ec77e22b070`. Archive: 10 members, ZIP CRC 10/10 and manifest digest checks passed; re-materialized Library copy SHA256 matched. Large unchanged original evidence files are preserved separately, not repackaged or modified.

CI `44717004630` job `136222844192` completed/success on the QA31BL parent SHA **for seven toy numeric gates only**, not for this QA31BM signed-corpus analysis. **No QA31BM GitHub CI or fresh Native run has been executed.** This finite result is not a Native intervention, independent altered Native execution, global input proof, or Stage1 PASS.

## NEXT: QA31BN (QA-only)

Retain exact source and signed proof pins. Independently exercise the same 135×4 original roots with `-1` one-root counterfactuals and at least 12 M=`2^127-1` boundary perturbation controls. Demand matching concrete/symbolic sink values (or explicit UNKNOWN), 12 genuine no-op checks and 12 hostile evidence checks, and record first numeric divergence, branch/memory assumptions and signed-versus-Euclidean negative remainder behavior. Do not infer Native or global Stage1 acceptance, open Stage2, merge, or touch main.
