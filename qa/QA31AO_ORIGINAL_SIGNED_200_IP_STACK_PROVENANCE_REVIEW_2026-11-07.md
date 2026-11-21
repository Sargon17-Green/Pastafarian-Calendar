# QA31AO — original signed 200-case vector predecessor and stack provenance review

PROJECT_ID: PC-BRANCH-BEFUNGE98-KYRGYZ
Branch: qa-befunge98-stage1-order-isolation-20261008
Exact pre-review HEAD: 049d836d71967e0bd1833f327c396168f3bda114
Original source git blob: 560d6aa5807a7f766213a33835cce85eab0fa40c
Review date: 2026-11-07

## Exact input provenance

Read-only source QA31AI archive:
`/Befunge_QA_Artifacts/QA31AI_BEFUNGE98_KYRGYZ_SIGNED_200_COUNTER_PREFIX_20261106.zip`
SHA256: `9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49`

Original-source algebra QA31AM artifact:
`/Befunge_QA_Artifacts/QA31AM_BEFUNGE98_KYRGYZ_COUNTER_ADDRESS_EVIDENCE_20261107.zip`
SHA256: `34c81db90cb222c00b1ef0b2a8909cd2a5bd81d7e3fb95fe050cdc15a111f975`

Independent original signed-event QA31AN evidence:
`/Befunge_QA_Artifacts/QA31AN_BEFUNGE98_KYRGYZ_ORIGINAL_200_SIGNED_TARGET_AUDIT_20261107.zip`
SHA256: `9aebc80a4b9a1c7b8b32482ec2eaeaf0849bbaef382bfc019e5a7e5a5bfe8124`

## Local finite original-source/trace audit

1. Independently verified all nested original ZIP SHA256 manifests,
   eight QA31V shards, 200 original gzip trace receipts and HALT states,
   3,628,390 contiguous STEP indices and recorded next→IP consistency.
   No new Native execution, mutation of production source, or new CI
   on the 46MB signed corpus.
2. For all 1,710 executed original source p instructions at the ten
   QA31AM candidate sites plus compound p(369,575), the entire
   unchanged-source local ray was dynamically replayed, instruction
   by instruction, against signed IP, original opcode bytes,
   and original pre/post stacks. All 1,710 source-ray replays PASS.
3. Each ray arrived directly from a specific signed original-source
   vector instruction x one STEP before its original-source anchor.
   All 1,710 x→anchor predecessor checks PASS. Every one of eleven
   executed p sites had exactly one observed x source IP across
   the 200 frozen cases; see the machine-readable site ledger.
4. A conservative executed-stack provenance pass tracked the
   observed memory writes p, reads g and input reads ~. Unsupported
   effects are marked UNKNOWN, not magically constant. Across
   1,710 original puts, 1,555 write VALUES had INPUT provenance
   (a positive control); the two ADDRESS operands for every put
   had neither INPUT nor UNKNOWN provenance on those observed paths.
   This is an empirical signed-path property, **not** an invariant
   across alternative natural inputs, code modifications, or unobserved
   vectors.
5. An independent QA31AN receipt-based oracle without imports from
   the forward replay checked 200/200 receipt IDs and raw stdin,
   1,710/1,710 exact signed step/site/target/value events and
   source-ray entry metadata. It rejected 16/16 actual synthetic
   report mutations, including falsely asserted q/m writes,
   invented x source, and invented Native/Stage1 acceptance.

Finite outcome: exactly 140 signed cases visit candidates; 1,710
original-site p events; 0 of those events wrote to q=(1,49) or
m=(3,49). 1,555 p VALUES carry recorded INPUT provenance, while no
p ADDRESS coordinate in this site set carries it in this corpus.
The earlier QA31AN result of 2,920 counter writes at other canonical
source p sites is not contradicted.

## Durable evidence

Complete inspectable QA31AO ZIP with both complete independent Python
scripts, 200 signed input receipts, 1,710 per-event predecessor/stack
provenance ledgers, aggregate CSV, JSON and gate logs:
`/Befunge_QA_Artifacts/QA31AO_BEFUNGE98_KYRGYZ_SIGNED_200_PREDECESSOR_AUDIT_20261107.zip`
ZIP SHA256: `68f48fc44260352a4ebe759b4ae63e259efd2e52f3171b022010af25910d45e8`
9 ZIP members, CRC 9/9 and member SHA256 verified. The source
46MB archive is not duplicated; it is frozen separately as above.
The scripts are analysis/CI reproducibility source code within an
**evidence artifact**, not a user Windows runnable package; no user
computer operation is needed for this acceptance.

## Interpretation, status and NEXT

QA31AO is **PASS for finite original signed 200-case predecessor and
stack provenance audit ONLY**. Stage1 global, functional and
geometric acceptance remains OPEN. No new original Native execution,
no fresh GitHub CI/full-corpus run, no main/merge/Stage2.

NEXT QA31AP: bound the *upstream* predecessor and input-dependent
branch selection that dispatches x to the eleven observed ray entries.
Investigate natural-input path constraints and potential
self-modification with an independent source/receipt oracle, using
already signed original traces first. Do not claim a natural-input
counter-target witness without a concrete independently verified
stdin. Only then may new Native be considered, capped at
<=25000 STEP per case. Preserve UNKNOWN for alternate routes.
