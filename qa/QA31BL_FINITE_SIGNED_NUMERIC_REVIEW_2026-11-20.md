# QA31BL — exact-integer signed g-to-overwrite arithmetic, finite evidence

**PROJECT_ID:** `PC-BRANCH-BEFUNGE98-KYRGYZ`  
**QA branch:** `qa-befunge98-stage1-order-isolation-20261008`  
**Parent HEAD validated before QA:** `d76d18b3065f274af464d3dc5dd5e659c6bb668d`  
**Date:** 2026-11-20  
**Acceptance:** **LOCAL FINITE QA31BL ACCEPTED**, **Stage1 OPEN**, **not Stage2**, no fresh Native run, no production code modifications, no merge/main change.

## Input provenance

Original archive QA31AI SHA-256: `9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49`.
Nested QA31AH: `4c17deae595262dcbcb8863da005810f60288c483273e32b3b2955b9fb13e271`.
Nested QA31Y: `1c97b51823ed98b3d333fcb2d0b35d72f7546b04ed8e86c5adebe3aca5703e8a`.
QA31BI rebuilt JSONL: `7660413b191784de8ec4f54ee51aea66c509a6726ea30f19401432a2816733d2`.
QA31BJ original g-root witnesses JSONL: `cba7da292cf8d595a5a680743ea29ca3642299bd9aecd62094fb8f42652251c3`.
QA31BK owner witnesses JSONL: `16aa91dfc48b0329d396d311dc7f68d826286484debc9024deeca78e12a9f9e2`.
Original source Git blob: `560d6aa5807a7f766213a33835cce85eab0fa40c`.

Before numeric analysis, verify all listed hashes, ZIP CRCs, eight shard receipts, 200 original trace digests and exact physical counts. The full signed original input comprises **200 HALT cases and 3,628,390 physical STEPs**, of which **135 selected cases** satisfy the QA31BL contract and the per-case bound of **25,000 STEPs**.

## Two independent numeric oracles

- **Oracle A (forward)** starts from each selected original trace's concrete stack at the first of four relevant `g` reads. It evaluates every subsequent source STEP to the second overwrite site, using Python's arbitrary-precision integers and an independent forward memory owner map. It checks full pre-/post-stack equality and verifies physical `g` values against prior signed `p` writes. **147,825** numerical operation STEPs checked over the selected intervals.
- **Oracle B (reverse)** reconstructs the two replacement `p` value operands per case using a separate backward stack-slot expression traversal. It computes values from the signed `g` roots and literals, verifies each calculated node against its physical post-stack value and compares every reachable arithmetic node with oracle A. **21,330** arithmetic nodes reconstructed, and **270** replacement `p` values reconstructed from **540** signed `g` roots.

Both oracles interpret the same original STEP receipts. Their independent control flow/arithmetic code helps detect implementation errors but does **not** make them independent native executions or independently prove that the recorded source opcodes themselves were executed correctly. The structural g→p paths were previously certified by QA31BJ/BK; this stage strengthens their **observed numeric correspondence** only.

## Arithmetic and mutation gates

The observed `%` operations using the divisor \(M=2^{127}-1=170141183460469231731687303715884105727\) are evaluated with exact integers and Euclidean residues for positive `M`, **270 observed such STEPs**. No floating-point conversion or blanket modulo wrapping of other operations is used. Division is exact integer truncation toward zero, but the result is not a new general ISA proof outside the observed operations.

**12/12** genuine non-noop value mutations to original STEP records were rejected *by numeric transition checks*, after maintaining adjacent physical STEP linkage. Seven local toy assertions including a deliberate expected-red gate passed. `py_compile` passed locally. New Native runs: **0**. Global acceptance claims: **none**.

## Reproducible outputs

- Per-case signed numeric review: `qa31bl_cases.jsonl`; SHA-256 `364f34ee16a4b3e9343f688063d918eac40fece73213843ecb60301cea5c9634`.
- Gzipped per-node exact numeric receipts: `qa31bl_numeric_steps.jsonl.gz`; SHA-256 of the *uncompressed* JSONL is `860eb4c1baa4e33a1b7719f025b3ccf8bd2f9e50221f4f511e9c57279a6dbc53`.
- Machine summary: `qa31bl_summary.json`.
- Self-contained Python QA-only auditor: `stage1_qa31bl_numeric_chain.py` (Python 3.10+, stdlib).

Local reproducibility invocation:

```sh
python3 qa/stage1_qa31bl_numeric_chain.py --self-test
python3 qa/stage1_qa31bl_numeric_chain.py \
  --ai ORIGINAL_QA31AI.zip --bi QA31BI_REBUILT.jsonl \
  --bj QA31BJ_WITNESSES.jsonl --bk QA31BK_WITNESSES.jsonl \
  --out new-empty-qa31bl-results-directory
```

No extra script downloads are required besides this script, but original historical evidence files are required for full reproduction; they are retained separately in `/Befunge_QA_Artifacts` rather than redundantly repacked into this lightweight ZIP. The ZIP contains the reproducible derived evidence and hashes of every member.

## Limits and next

`QA31BL` **does not prove counterfactual causality**, all possible inputs, alternative ingress, source geometric reachability, or full `Stage1` functional/geometry gates. The signed original trace is observational evidence. A complete Native validation of a genuinely varied input is a different gate.

**NEXT: QA31BM (QA-only; no Stage2).** Under the same 135 cases and source/receipt pins, inject bounded counterfactual changes to each of the four observed `g` values per case *only within a source-only arithmetic replay*; derive both replacement `p` values independently; classify changes versus cancellations and first numeric divergence. Preserve instruction path and branch conditions as assumptions; reject any assumption mismatch rather than claiming a physical Native result. Verify at least 12 nontrivial intervention controls with nonzero expected sensitivity and 12 independent no-op controls; record 540 input interventions and 270 observed sink baselines. Do not label the synthetic interventions as actual original program behavior; Stage1 remains OPEN.
