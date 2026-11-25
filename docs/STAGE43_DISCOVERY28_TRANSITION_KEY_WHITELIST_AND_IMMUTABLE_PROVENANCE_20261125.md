# Stage43 / Discovery28 — exact transition-key whitelist and immutable provenance inventory (2026-11-25)

PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG  
Branch: `PowerShell+Tagalog`  
Disposition: **RESEARCH_ONLY / DOCS_ONLY / STAGE43_NOT_ACTIVATED / NO_STAGE43_SEAL**.

This record derives a candidate exact Stage43 lifecycle schema from this branch's Stage41 and Stage42 metadata transitions. It is not authorization to activate Stage43, edit live metadata, change tests/workflows, or seal a stage.

## 1. Audited source and frozen predecessor

- Audited branch HEAD: `c5e68480ad7c015bb36a7dc90ec8933b896d2bae`.
- Its parent is the v006 implementation HEAD `02869d783004c0231a2032638793115db8c0bf81`; the intervening commit is the docs-only Stage43 integration map.
- `DEVELOPMENT_STAGE.md` Git blob: `a3f53b67e4445bdc835179cd484fe27b3e2648f7`.
- The frozen Stage42 document has **728 nonempty assignments, 728 distinct keys and five blank lines**. It contains 72 `STAGE41_*` keys and 56 `STAGE42_*` keys, and no `STAGE43_*` key.
- Current discriminators: `TOTAL_STAGES=55`, `CURRENT_STAGE=42`, `CURRENT_KIND=DISCOVERY`, `CURRENT_DISCOVERY=27`, `CURRENT_PATCH=14`, `LAST_COMPLETED_STAGE=42`, `EXPECTED_REPOSITORY_STATE=GREEN_CONFIRMED`, `STAGE42_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED`.

The pinned Git blob is the immutable Stage42 fixture. It must not be replaced with a mutated Stage43 working document or weakened to make a future transition pass.

## 2. Same-branch transition evidence

### Stage41 — complete three-part lifecycle

1. Activation commit `658fcc833a501d7087f6751e55c03b7211b0bb94`: changed `CURRENT_STAGE=40→41` and `CURRENT_DISCOVERY=25→26`; kept `LAST_COMPLETED_STAGE=40`; added the Stage41 planning, preflight and pending-state record.
2. Implementing-SHA Native evidence was accepted on `af41357a2fcf717cd789fab6ccace3beb47430ec`, run `44613616346`: 15/15 jobs, Stage41 job `135876325383`, 481/481 assertions, Windows PowerShell 5.1, artifact `14573572990`, ZIP digest `54a6b7d669acfbf30cc3ed27ee9efdbb133841b0cd0042d0b81ebba01e22e580`.
3. Evidence-only commit `e315af49ee7efb1ba62ac4560f3ea1640b544a2b`: changed `LAST_COMPLETED_STAGE=40→41`, changed runtime/activation from `PENDING_NATIVE` to `EVIDENCE_ONLY_CONFIRMED`, added the Native evidence fields and set `STAGE41_SEAL_COMMIT_NATIVE_RECHECK=PENDING_NEW_SHA`.
4. Separate exact-seal CI on that seal SHA: run `44633607543`, 15/15 jobs, Stage41 481/481, Stage40 425/425, artifact `14582893873`, finalizer artifact `14582942774`, finalizer SHA256 `EE633FF97AA228F497DC0E9376095628868F403CD45CC1BC663E418480043A4A`, verify SUCCESS. Commit `c0d3ae0bc1578cd4cee6163eb0a4526e1f27c917` changed the recheck marker to `PASS` and added the `STAGE41_SEAL_CI_*` evidence.

This is the clearest same-branch example of an implementing-SHA acceptance followed by a distinct seal-SHA recheck.

### Stage42 — Native acceptance, failed first seal recheck, later recheck evidence

1. Activation commit `0aefdce42390ffe0d62391ed51deed6c7276e9b0`: changed `CURRENT_STAGE=41→42` and `CURRENT_DISCOVERY=26→27`; kept `LAST_COMPLETED_STAGE=41`; added the Stage42 planning/preflight and pending-state record.
2. Evidence-only commit `2203a0ce2d5480900fab812c5009639ac2dc4339`: changed `LAST_COMPLETED_STAGE=41→42`, changed runtime/activation to `EVIDENCE_ONLY_CONFIRMED`, recorded `STAGE42_NATIVE_ACCEPTANCE=IMPLEMENTING_SHA_ACCEPTED`, added Native evidence, and left `STAGE42_SEAL_COMMIT_NATIVE_RECHECK=PENDING_NEW_SHA`.
3. Implementing-SHA run `44716461173` on `0aefdce42390ffe0d62391ed51deed6c7276e9b0`: 16/16 jobs; Stage42 job `136220997452`; 1,657/1,657 assertions; 160 endpoints, 80 calculation seams, 80 target seams, 40 mixed faces and 144 seal pairs; artifact `14621569483`, ZIP digest `9a59094813e74ce4526fb9df7cec1509b7e39cc3cd0be8609825bc90dcec22f3`.
4. The first run on the evidence-only commit, `44734310998`, completed **failure** (15/16 jobs). Stage42's numerical job succeeded, but Windows finalizer job `136281712498` failed at the Stage23 finalizer idempotency step. Its artifact `14628486153` has digest `333960fdf6a86ffa7bf086a4d678bf975e8a4b058f86007f15b804d62616d211`. The retained stderr says `Mali ang Stage 23 sealing precondition.`; run 1 had exit 1, stderr length 437, `ALREADY_FINALIZED=False`, and unchanged metadata SHA256 `0E54874D8D8412185FA9F81F75A5528C820A76BD13C5D61657857AC438E013AF`.
5. Fix commit `fcf1640de4f3a96f8bcb60822d067253b79af9ca` added a read-only Stage42 branch to `FinalizeStage23.ps1`. It checks the Stage42 current/last/runtime state plus Stage41, Stage40 and Stage23 runtime markers; it does **not** check `STAGE42_SEAL_COMMIT_NATIVE_RECHECK` or the Stage42 Native SHA.
6. Later exact-SHA run `44799736042` on `fcf1640de4f3a96f8bcb60822d067253b79af9ca` completed/success, 16/16 jobs; Stage42 job `136508451039` succeeded with 1,657/1,657 and `SEALED_RECHECK_PASS`; Stage41 and Stage40 rechecks also succeeded. This is later evidence, not a rewrite of the earlier failed run.

**Important metadata discrepancy:** the live frozen Stage42 record still says `STAGE42_SEAL_COMMIT_NATIVE_RECHECK=PENDING_NEW_SHA`. Later exact-SHA recheck evidence exists, including the current run in §5, but the historical metadata field was not reconciled. Preserve that literal value; do not silently turn it into `PASS` as part of a Stage43 transition. If the project later wants a current-recheck marker in metadata, add it as a separately authorized, append-only reconciliation with its own exact run/SHA/job/artifact provenance.

## 3. Candidate exact Stage43 transition-key whitelist

The whitelist is **closed and phase-specific**. It is not permission to accept every key beginning `STAGE43_`.

### 3.1 Existing keys that may change

Only these three existing global pointer keys may change during the Stage43 lifecycle:

- `CURRENT_STAGE`: `42→43` at a separately authorized pending activation.
- `CURRENT_DISCOVERY`: `27→28` in the same activation commit.
- `LAST_COMPLETED_STAGE`: remains `42` while Stage43 is pending; changes `42→43` only after the activated implementation SHA passes its full Native gate.

The following remain invariant: `TOTAL_STAGES=55`, `CURRENT_KIND=DISCOVERY`, `CURRENT_PATCH=14`, `EXPECTED_REPOSITORY_STATE=GREEN_CONFIRMED`, all Stage41 evidence, and all Stage42 evidence—including the unreconciled recheck marker above.

### 3.2 Stage43 state and planning keys

The exact candidate names are:

```
STAGE43_DISCOVERY
STAGE43_PLANNING_STATUS
STAGE43_PLANNED_CONTEXTS
STAGE43_PLANNED_CALC_DAYS
STAGE43_PLANNED_GATES_PER_CONTEXT
STAGE43_PLANNED_TARGET_OFFSETS
STAGE43_PLANNED_TARGET_DAYS
STAGE43_PLANNED_SEALS
STAGE43_PLANNED_ENDPOINTS
STAGE43_PLANNED_TARGET_PAIRS
STAGE43_PLANNED_SEAL_PAIRS
STAGE43_PLANNED_STRUCTURAL_GUARDS
STAGE43_PLANNED_ASSERTIONS
STAGE43_RUNTIME_VERIFICATION
STAGE43_ACTIVATION
STAGE43_NATIVE_ACCEPTANCE
STAGE43_SEAL_COMMIT_NATIVE_RECHECK
```

For the existing neighbor-year contract, the planned values are: discovery `NEIGHBOR_YEAR_GATE_RESPONSE`; 2 calculation contexts; 2 calculation days; 4 gates per context; 3 target offsets; 12 target days per context; 10 seals; 240 endpoints; 160 target pairs; 216 adjacent-seal pairs; 23 structural guards; 2,215 assertions; planning status `IMPLEMENTED_PREFLIGHT_VERIFIED`.

Allowed lifecycle values, in order:

- `STAGE43_RUNTIME_VERIFICATION`: `PENDING_NATIVE` → `EVIDENCE_ONLY_CONFIRMED`.
- `STAGE43_ACTIVATION`: `PENDING_NATIVE` → `EVIDENCE_ONLY_CONFIRMED`.
- `STAGE43_NATIVE_ACCEPTANCE`: `NOT_CLAIMED` → `IMPLEMENTING_SHA_ACCEPTED`.
- `STAGE43_SEAL_COMMIT_NATIVE_RECHECK`: `NOT_RUN` → `PENDING_NEW_SHA` → `PASS`.

No state may skip a phase. In particular, `LAST_COMPLETED_STAGE=43` and `EVIDENCE_ONLY_CONFIRMED` require a successful completed Native run on the exact implementing SHA; `SEAL_COMMIT_NATIVE_RECHECK=PASS` requires a separate successful completed run on the exact seal commit SHA.

### 3.3 Append-only Stage43 evidence keys

Planning/preflight evidence (record only values actually emitted by a completed run):

```
STAGE43_PREFLIGHT_CI_RUN
STAGE43_PREFLIGHT_CI_SHA
STAGE43_PREFLIGHT_JOBS
STAGE43_PREFLIGHT_RUNTIME
STAGE43_PREFLIGHT_ASSERTIONS_PASSED
STAGE43_PREFLIGHT_ASSERTIONS_FAILED
STAGE43_PREFLIGHT_ARTIFACT
STAGE43_PREFLIGHT_ARTIFACT_SHA256
STAGE43_PREFLIGHT_FINALIZER_ARTIFACT
STAGE43_PREFLIGHT_STAGE42_SEAL_RECHECK
STAGE43_PREFLIGHT_STAGE41_SEAL_RECHECK
STAGE43_PREFLIGHT_STAGE40_SEAL_RECHECK
STAGE43_PREFLIGHT_STAGE30_ASSERTIONS
STAGE43_PREFLIGHT_CANONICAL_VERIFY
STAGE43_PREFLIGHT_STAGE23_FINALIZER_IDEMPOTENCY
STAGE43_PREFLIGHT_STAGE23_FINALIZER_SHA256
```

Implementing-SHA Native evidence:

```
STAGE43_NATIVE_IMPLEMENTATION_ACCEPTED
STAGE43_NATIVE_CI_SHA
STAGE43_NATIVE_CI_RUN
STAGE43_NATIVE_JOBS
STAGE43_NATIVE_RUNTIME
STAGE43_NATIVE_JOB
STAGE43_NATIVE_ASSERTIONS_PASSED
STAGE43_NATIVE_ASSERTIONS_FAILED
STAGE43_NATIVE_ENDPOINTS
STAGE43_NATIVE_TARGET_PAIRS
STAGE43_NATIVE_SEAL_PAIRS
STAGE43_NATIVE_STRUCTURAL_GUARDS
STAGE43_NATIVE_ARTIFACT
STAGE43_NATIVE_ARTIFACT_SHA256
STAGE43_NATIVE_STAGE42_SEAL_RECHECK
STAGE43_NATIVE_STAGE41_SEAL_RECHECK
STAGE43_NATIVE_STAGE40_SEAL_RECHECK
STAGE43_NATIVE_STAGE30_ASSERTIONS
STAGE43_NATIVE_STAGE23_FINALIZER_IDEMPOTENCY
STAGE43_NATIVE_STAGE23_FINALIZER_SHA256
STAGE43_NATIVE_STAGE23_FINALIZER_ARTIFACT
STAGE43_NATIVE_VERIFY
```

Separate seal-SHA recheck evidence, following the fully demonstrated Stage41 pattern:

```
STAGE43_SEAL_CI_RUN
STAGE43_SEAL_CI_SHA
STAGE43_SEAL_CI_JOBS
STAGE43_SEAL_CI_STAGE43_ASSERTIONS
STAGE43_SEAL_CI_STAGE42_ASSERTIONS
STAGE43_SEAL_CI_STAGE41_ASSERTIONS
STAGE43_SEAL_CI_STAGE40_ASSERTIONS
STAGE43_SEAL_CI_STAGE30_ASSERTIONS
STAGE43_SEAL_CI_ARTIFACT
STAGE43_SEAL_CI_FINALIZER_ARTIFACT
STAGE43_SEAL_CI_FINALIZER_SHA256
STAGE43_SEAL_CI_FINALIZER_IDEMPOTENCY
STAGE43_SEAL_CI_VERIFY
```

These are candidate schema names, not current metadata. The current research-only run must remain external evidence and must not be represented as an activated-SHA Native result. No extra aliases (for example a duplicate `STAGE43_ACTIVATION_CI_RUN`) or unknown `STAGE43_*` keys are admitted by this whitelist.

### 3.4 Mutually exclusive profiles

| Profile | Required discriminators | Evidence rule |
| --- | --- | --- |
| Research-only (current) | CURRENT=42, DISCOVERY=27, LAST=42; no Stage43 keys | Stage43 preflight is research evidence only |
| Pending | CURRENT=43, DISCOVERY=28, LAST=42; runtime/activation=PENDING_NATIVE; native acceptance=NOT_CLAIMED; seal recheck=NOT_RUN | Exact pending schema and all predecessor provenance; no Native acceptance implied |
| Implementing SHA accepted | CURRENT=43, DISCOVERY=28, LAST=43; runtime/activation=EVIDENCE_ONLY_CONFIRMED; native acceptance=IMPLEMENTING_SHA_ACCEPTED; seal recheck=PENDING_NEW_SHA | Completed exact-SHA Native run, decisive logs, all required artifacts and predecessor rechecks |
| Seal rechecked | Same Stage43 pointers/status as above; seal recheck=PASS | Separate completed exact seal-SHA run, full regressions, finalizer and mandatory artifacts |

Reject duplicates (even identical duplicates), unknown keys, missing keys, extra keys, hybrid profiles, contradictory status combinations, premature LAST=43, a seal marker without a separate seal-SHA run, or any mismatch in run/SHA/job/artifact identity.

The earlier one-key `729-key` pending proposal is only a **minimal discriminator shape** (two pointer values changed plus `STAGE43_RUNTIME_VERIFICATION=PENDING_NATIVE`). It is not the complete lifecycle ledger demonstrated by the Stage41/42 history. The closed list above separates mutable phase discriminators from append-only evidence fields.

## 4. Immutable provenance inventory to carry forward

1. **Frozen Stage42 baseline:** blob `a3f53b67e4445bdc835179cd484fe27b3e2648f7`; 728 unique assignments; 72 Stage41 keys and 56 Stage42 keys. Keep every Stage41/42 key/value unchanged in a Stage43 transition, except the three global pointers explicitly listed in §3.1.
2. **Stage41 implementing Native:** run `44613616346`, SHA `af41357a2fcf717cd789fab6ccace3beb47430ec`, 15/15 jobs, 481/481, artifact `14573572990`, digest `54a6b7d669acfbf30cc3ed27ee9efdbb133841b0cd0042d0b81ebba01e22e580`.
3. **Stage41 seal recheck:** run `44633607543`, SHA `e315af49ee7efb1ba62ac4560f3ea1640b544a2b`, 15/15 jobs, Stage41 481/481 and Stage40 425/425, artifacts `14582893873` and `14582942774`, finalizer SHA256 `EE633FF97AA228F497DC0E9376095628868F403CD45CC1BC663E418480043A4A`.
4. **Stage42 preflight history:** run `44701413210` on `c0d3ae0bc1578cd4cee6163eb0a4526e1f27c917`, 16/16 and 1,657 assertions; hardened run `44707630282` on `2af5debb6d624d9206b20a09aba618e366a3582f`, 16/16 and 1,657/1,657; artifacts `14612949259`, `14614961168`, `14617212319`.
5. **Stage42 implementing Native:** run `44716461173`, SHA `0aefdce42390ffe0d62391ed51deed6c7276e9b0`, 16/16 jobs, job `136220997452`, 1,657/1,657, artifact `14621569483`, digest `9a59094813e74ce4526fb9df7cec1509b7e39cc3cd0be8609825bc90dcec22f3`.
6. **Stage42 first seal-commit failure:** run `44734310998`, SHA `2203a0ce2d5480900fab812c5009639ac2dc4339`, 15/16; finalizer failure and artifact `14628486153` / digest `333960fdf6a86ffa7bf086a4d678bf975e8a4b058f86007f15b804d62616d211`. Preserve as failed historical evidence; later success does not erase it.
7. **Stage42 post-fix exact recheck:** run `44799736042`, SHA `fcf1640de4f3a96f8bcb60822d067253b79af9ca`, completed/success 16/16; Stage42 job `136508451039` passed. The current metadata's pending marker was not rewritten.
8. **Current exact-SHA CI on audited HEAD:** run `45660544507`, branch `PowerShell+Tagalog`, attempt 1, push, completed/success, exact SHA `c5e68480ad7c015bb36a7dc90ec8933b896d2bae`, 17/17 jobs:
   - Stage43 research job `139368891534`: 2,215/2,215, zero failures; `BOUNDED_ORACLE_PASS`, `NOT_ACTIVATED`, `NOT_CLAIMED`; artifact `15044803418`, digest `323a02de0a23cb5a04b0f62ffb81ab16201de2cf99f5390c2c011321d5ae2cbd`.
   - Stage42 exact recheck job `139368891557`: 1,657/1,657; log `STAGE42_NATIVE=SEALED_RECHECK_PASS`; artifact `15045376147`, digest `48ba18c1f06b70e5548053d469241b8f2f6e3df4483476312e4b8d42d2f4dffa`.
   - Stage41 recheck job `139368891294`: success; artifact `15045700701`, digest `64a06869a80b369108bd8a5c308244f2d60bbb1751945c16c54d8bb910b25e3f`.
   - Stage40 job `139368890843`: success; artifact `15044966805`, digest `22024efd61d931d6c70824540a880cac6eaa6b2a4989b3062560ee1bf4f19dfb`.
   - Windows regression/finalizer job `139368890453`: finalizer ran twice; both exit codes 0, stderr length 0, `ALREADY_FINALIZED=True`, identical before/after SHA256 `0E54874D8D8412185FA9F81F75A5528C820A76BD13C5D61657857AC438E013AF`; artifact `15044479133`, digest `f949033811e404c506140582a92831751ba4be97fce17705afd96744ac00b0b1`.
   - Canonical `verify` job `139368890845`: completed/success.

GitHub API artifact digests above are provider-reported ZIP digests; they are not claims of a separate local ZIP rehash. The 2,215/2,215 Stage43 result is **research preflight only**, not an activation-SHA Native acceptance or a Stage43 seal.

## 5. Existing fail-closed and compatibility gaps (research findings only)

- `tests/Stage43.Tests.ps1` uses nine case-sensitive line-membership checks for its Stage42 predecessor; the Stage43 workflow uses four. They do not enforce unique keys, complete-map equality, absence of extra Stage43 keys, or the complete predecessor evidence inventory. The previously documented B/H contamination and duplicate-key gaps remain.
- `tests/StrictUtf8StageMetadata.Tests.ps1` pins the exact Stage42 Git blob and 728-key live file. A legitimate Stage43 metadata transition would fail that frozen-snapshot assertion unless the immutable fixture and live-state validator are separated. Keep the blob pin; do not broaden the frozen fixture.
- The current Stage23 finalizer has a Stage42 read-only branch but no Stage43 pending/sealed branch. Stage30 and Stage41/42 predecessor predicates are also anchored to earlier lifecycle states. They require a shared, exact state classifier before any authorized Stage43 transition.
- `tests/VerifyFinalizeStage23Idempotency.ps1` records stderr length but does not itself assert zero; the current run's zero stderr is evidence for that run, not a permanent assertion in the script.
- The Stage43 research artifact upload currently uses `if-no-files-found: warn`; a future activation/seal gate must make required artifacts fail closed.

## 6. Disposition and next authorization boundary

Completed here: same-branch Stage41/42 transition analysis, the candidate closed Stage43 key whitelist, and the immutable predecessor/current-run provenance inventory.

Not done: no source, oracle, test, workflow, metadata or branch-protection change; no Stage43 activation; no Stage43 seal; no merge/main.

**NEXT:** obtain separate explicit authorization before implementing the strict byte parser, versioned live-state classifier, negative Windows PowerShell 5.1 fixtures, and narrowly scoped predecessor/finalizer/workflow compatibility. The frozen 728-key Stage42 fixture must remain independent from the live Stage43 schema. A research preflight or a shape-only state must never be promoted to Native or seal acceptance.
