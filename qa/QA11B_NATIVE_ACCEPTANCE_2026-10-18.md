# QA11B — pinned full Native acceptance checkpoint (2026-10-18)

**Status: QA11B ACCEPTED for the narrow, separate 17D three-worker runtime-code-generation experiment.** QA11A was accepted separately. **This does not complete calendar Stage 1 (LAST_COMPLETED_STAGE=0), authorize QA-branch merge, open Stage 2, or qualify the 2D calendar implementation.** The candidate source is immutable; the checkpoints below document its later independent evidence.

## Exact subjects and provenance

- Repository and QA branch: `Sargon17-Green/Pastafarian-Calendar`, `qa-befunge98-stage1-order-isolation-20261008`.
- QA11B candidate 17D BeQunge source Git blob: `afa261c6eab74d69b6c3afbe6c641fc130d627c0` (`qa/spaghetti11_17d_cascade_208_generated_candidate.beq`). **No source changes during these acceptance tests.**
- QA10 accepted parent source: `010efd012ae52a60740aa97750b5a02519912e92`, [Native run 39069333028](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39069333028) SUCCESS.
- QA11A accepted three-IP parent source: `990d8fb2b84c7ee728634bb93a8e7baaef992c40`, [Native run 39076971620](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39076971620) SUCCESS.
- Manifest SHA-256: `58b06360f58ddb8fd2efc08b0182e21d1258cbd8d8e4155c156feaa7c2a31d63`.
- Locked production source (`src/interleaved_work_counts.b98`) Git blob: `560d6aa5807a7f766213a33835cce85eab0fa40c`; remains untouched.
- Full Native CI: [run 39081164334](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39081164334), exact tested commit `613a9cf5a9cd9f46ec2655d5237c97003d71c247`, 5/5 jobs SUCCESS, 40 collected Native run receipts.
- Independent physical `p`-write tracer CI: [run 39081952073](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39081952073), exact tested commit `3ab144f7d472bd13a5c7c7feb5696c6d9d9163f9`, SUCCESS.

## Native evidence by group

| Group | Job ID | Original CI artifact ID | Evidence |
|---|---:|---:|---|
| baseline | 117538202915 | 12119756363 | 8 normal runs: seeds 1/2, cooperative/native OS scheduling, two repetitions; 2 independent mask-all-208-traps runs; all 228-number outputs exact |
| third | 117538202954 | 12119681426 | Worker C standalone physical arithmetic remains complete with `31 33 21` after `/2` to `/3`; generated first code byte changes on each seed; neutral control passes |
| roles | 117538202976 | 12119605986 | Generated multiply, divide, stack-drop, and direction-turn role perturbations all produce indexed opcode witnesses |
| axes-low | 117538202753 | 12119123549 | Eight axis-specific source mutants, axes 1–8; each produces an indexed generated-opcode difference with intact preceding expected prefix |
| axes-high | 117538202959 | 12119133725 | Eight axis-specific source mutants, axes 9–16, with the same localized requirement |

The Native harness records a bounded timeout as exit code 124. **Timeout alone never counts as a causal proof**: the full harness requires a nonempty output witness from the precise generated-code index, and healthy/neutral controls must complete under comparable timing. Some mutant programs do not terminate, as intended; there is no claim of successful mutant completion.

## Actual physical Funge-space code writing

The independent Funge++ trace instruments the **disposable, pinned engine only** at the genuine `p` interpreter operation. Its successful healthy run reports **208 actual writes into 208 distinct 17-dimensional target cells**, 228 numeric output values, and zero repeated target writes. The five counterfactuals change physical written opcode values as follows:

| Mutant | Written target cells seen | Changed opcodes in focused axis |
|---|---:|---:|
| Third worker divisor `/2`→`/3` | 13 | 13 |
| Axis 1 contribution | 13 | 13 |
| Axis 9 contribution | 117 | 13 |
| Axis 16 contribution | 208 | 13 |
| Multiply opcode role on axis 8 | 117 | 1 |

Artifact [12119981510](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39081952073/artifacts/12119981510) includes counts, actual first/last trace coordinates, and observed changed opcode values. **Limit:** not all 208 raw physical write events are serialized into this compact receipt. The CI trace source independently checks membership in the exact 208-cell manifest set and counts unique coordinates; an offline audit can validate the recorded counts/examples but cannot reconstruct the missing raw events without re-running the Native tracer.

## Independent offline check and deliberately limited claim

- Download all six original ZIP artifacts above. The two independent Python audit scripts are distributed inside the *private continuation handoff ZIP* (not committed to GitHub): run `qa11b_validate_acceptance.py` with the five group ZIPs and the trace ZIP, keeping `qa11b_audit_receipts.py` in the same folder.
- The independent group auditor recomputes 228-element oracles (including seed parity and final checksum), validates SHA-256 digests, exact five-group coverage, source/manifest pins, mutations and healthy/neutral controls.
- The trace auditor checks the locked source/manifest, all six physical-writing cases, distinct target-cell counts, 17D coordinate/value examples and actual changed values. It also reports its residual limits explicitly.
- Result for these original six artifacts: `PASS_QA11B_EVIDENCE_AUDIT`. This is **QA11B acceptance only**, not an assertion of Stage 1/full calendar or release readiness.
- A deliberately tampered group source or trace SHA must be rejected; historical failed Native attempts remain in CI history, not retroactively reinterpreted.

## Remaining work (outside this bounded checkpoint)

`DEVELOPMENT_STAGE.md` continues to report `CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`, open full functional/geometric acceptance, no Stage 2, and no merge to the canonical language branch. Future QA milestones must focus on the remaining actual Stage 1 contractual gaps or explicitly scoped integration work; this 17D proof cannot substitute for a complete, independently verified Pastafarian calendar port.
