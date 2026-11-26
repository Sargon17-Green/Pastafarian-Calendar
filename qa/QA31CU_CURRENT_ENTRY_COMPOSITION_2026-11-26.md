# QA31CU — composition audit of the active seven-field entry point

2026-11-26 · **PC-BRANCH-BEFUNGE98-KYRGYZ** · Stage 1 remains open (0/55).

## Scope and correction to the queued NEXT description

The active source is **src/work_counts.b98** (Git blob **7418e1ec5fe88fe5c14b75710dea2d5607527f28**); the compatibility baseline is **src/interleaved_work_counts.b98** (blob **560d6aa5807a7f766213a33835cce85eab0fa40c**). The pinned patch **qa/signed_increment_gate.patch** (blob **96690deb1360ec35ba64e997957b6b1a6cea64f2**) applies to the baseline and reproduces the active file byte-for-byte.

The previous NEXT description said **x→j** at (1030,1050). That is not present: the byte at that coordinate is a space in both pinned sources. The actual patch changes four source rows (zero-based 1046, 1047, 1048, 1050): 61 glyphs, plus the runtime-writable gate cell, for 62 changed/writable cells. The signed gate is at (1020,1046), with + and - arms at (1021,1046) and (1020,1047). The source entry/successor replacement is +5 → ^> at (959,1050) and (960,1050). No production source was changed in this QA31CU work.

## Composition of the accepted proofs

| Proof | Pinned scope and verified result |
|---|---|
| QA31CH | Baseline scanner: 9 states, 2,313 transitions; 116 read returns, 2,195 rejections, 2 first arithmetic handoffs |
| QA31CJ | First arithmetic join: a=0, a=1, a≥2; 5,091 Native steps calibrated |
| QA31CK | First live gate: 36 canonical classes; 1,039 corridor steps; 17,663 Native calibration steps |
| QA31CL | Shared decimal loop: rank max(B,D) decreases under (B,D)→(⌊B/10⌋,⌊D/10⌋); 102 archived iterations, 237,252 steps, 17 final east fetches |
| QA31CM | Kernel and outputs: 341,158 archived Native steps from first gate; 9,724 arithmetic positions and 258 incoming directions; independent work_counts and save references |
| QA31CP | Active-source patch composition: 9,730 original directed arithmetic edges checked; all three signed-increment classes; no external arithmetic ray or memory alias |
| QA31CT | Active-source Native semantic domain: 6 invalid and 8 valid cases; 2 valid above-modulus controls; 38 Native invocations |

The QA31CP static proof uses the exact old/new source pins and the signed-gate chamber. It composes the unchanged scanner and original arithmetic graph with the replacement, checks every original directed arithmetic edge, and confirms that the gate is rewritten before being fetched. Its abstract cases cover z<0, z=0, and z>0.

For each decimal iteration, let z=P(e+f) be the signed contribution to the sum accumulator. The patched route computes:

\[
S' =
\begin{cases}
S-|z| & z<0\\
S+|z| & z\ge 0
\end{cases}
= S+z.
\]

Thus the exact sum increment is preserved. The difference and modular accumulators are not modified by this local gate. The baseline kernel proof supplies their loop invariants and the seven output equations; QA31CP checks the new live branch and its join.

## Completed Native and CI evidence

- **QA31CP Native:** [run 45635056768](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45635056768), job 139278155210, completed/success on commit e124409b2e5d8b34f08af3f7914ede29b3741054. Artifact 15030924408, SHA-256 8e3a1572686e5fd9dcbd2f7717c9590bcdd119be6c0053745e6df4b7fe157696. The job log records NATIVE_SIGNED_INCREMENT_GATE_PASS; the ZIP CRC passed. Four inputs produced seven-field baseline/candidate/reference equality. Two forced opposite-arm interventions produced the independently expected counterfactual outputs; the zero-increment and zero-loop controls remained unchanged.
- **QA31CT Native on the current HEAD:** [run 45699183636](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45699183636), job 139504468512, completed/success at 31c6f2950483dd66b940dd053cb505002ec69343. Artifact 15062438663, SHA-256 9bfb863c51e2eab6efac64a39fbf82eb84ce535a2c97583eb52ebbc0d2eb6a2b. ZIP CRC and all six internal SHA-256 entries passed; exit code 0. Its JSON pins the active source blob 7418e1…, reports 6/6 invalid probes, 8/8 valid oracle controls, and 2/2 above-modulus valid controls.
- **Stage 1 regression:** [run 45699183338](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45699183338), at the same 31c6f295… commit, completed/success: 30/30 jobs, 69 artifacts. The regression is not a Stage 1 acceptance decision.

The new QA31CU workflow downloads these exact historical artifacts and their run/job/artifact metadata, rechecks the pinned source patch and baseline proof receipts, and emits qa31cu_composition.json. It does not rerun QA31CP or QA31CT Native tests.

## Limits and status

This is a compositional source/static proof with Native calibration, not a new exhaustive Native run over all possible inputs. QA31CH–CM remain proofs of the pinned baseline; QA31CP establishes the local active-source replacement and route isolation; QA31CT exercises the active source's semantic domain. The finite Native corpus does not itself prove all-input termination or all Stage 1 architecture/ownership properties.

CURRENT_STAGE=1, LAST_COMPLETED_STAGE=0, FULL_FUNCTIONAL_QA_PASS=NO, GEOMETRIC_SPAGHETTI_QA_PASS=NO, QA_CANONICAL_MERGE_AUTHORIZED=NO.

**NEXT:** QA31CV — independently extend the active-source differential/causal corpus to later decimal iterations and mixed-sign contributions, retaining seven-field comparisons against the separate Befunge references. Do not rerun the already accepted QA31CP/QA31CT cases on the same source SHA.
