# Stage43 post-v006 integration gate acceptance map

PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG
Branch: PowerShell+Tagalog
Reviewed source: 02869d783004c0231a2032638793115db8c0bf81
Tree: fb4aa2f435dd65ccda015902695467b73fb4c315
Frozen metadata blob: a3f53b67e4445bdc835179cd484fe27b3e2648f7
Disposition: RESEARCH_ONLY / NO_STAGE43_ACTIVATION / NO_SEAL

## Accepted evidence and remaining boundary

Windows PowerShell 5.1 v006 R19737_30296 on the reviewed exact SHA:
16/16 fail-closed + 20/20 comparator regression accepted, HANDOFF SHA256
874987ca3dee55323c8e28319c51656610e956384fa9a440c5d8cbb4ae6030e5.
Historical automatic CI 45083110441 completed/success 17/17, separate
from the opt-in comparator. No test was rerun for this review.
The comparator is an opt-in read-only full-map gate, not a lifecycle
classifier or automatic CI integration. Stage42 stays sealed.

## New source inventory

- tests/StrictUtf8StageMetadata.Tests.ps1:171-196: the Stage01 suite
  directly tests actual working metadata against 728 keys, exact Stage42
  state, and exact committed metadata Git blob. This is an additional
  mandatory integration target beyond the 2026-11-21 predecessor map.
  A legitimate future metadata commit would break the current Stage01
  assertions even with an otherwise correct lifecycle classifier.
  Keep the frozen fixture and its exact provenance test independent
  of the live-state validation; never merely weaken the blob check.
- tests/Stage43.Tests.ps1:9-18: nine membership predicates; neither
  rejects additional declarations nor checks CURRENT_KIND or the
  STAGE42_NATIVE_CI_SHA. Lines 151-153 always emit research-only markers.
- .github/workflows/canonical-names-lock.yml:940: four membership
  predicates; lines 953-972 write transcript/metadata and upload with
  if-no-files-found: warn. The earlier jobs at 45,518,573,579,633,690,737,
  790,841,893-896 also contain Stage42-bounded predicates; inventory
  all reachable historical branches before modifying any.
- tests/Stage23.Tests.ps1:15-19 and 30-32: regression stage regex stops
  at 42; needs coherent 43 classification, not a broad regex bypass.
- tests/Stage30.Tests.ps1:7: LAST_COMPLETED_STAGE regex stops at 42.
  Pending 43/LAST42 passes this particular expression but sealed
  43/LAST43 does not. Other assertions are outside this narrow model.
- tests/Stage41.Tests.ps1:9-13; tests/Stage42.Tests.ps1:18-34:
  current predicates do not recognize a future 43 state.
- tests/FinalizeStage23.ps1:4-8: Stage01 and Stage23 run before the
  metadata write decision. Lines 11-20,22-36: preSeal is tested before
  sealed branches. Append LAST_COMPLETED_STAGE=22 and
  STAGE23_RUNTIME_VERIFICATION=AWAITING to valid sealed42 data:
  the local write selector becomes true. This is NOT a demonstrated
  end-to-end write vulnerability: the current Stage01 strict parser
  rejects duplicate keys first. Preserve that defense and require
  strict unique-key state classification before every write path.
- tests/VerifyFinalizeStage23Idempotency.ps1:98-103: historical state
  predicate; lines 116-131 record stderr length but never assert zero.
  A zero-exit run emitting stderr could pass those checks. This is a
  source-level omission, NOT an observed failing Native run.

## Executed static source-derived model

Read the 728 unique assignments of the pinned metadata via GitHub.
No STAGE43_* key is present. Evaluate literal membership predicates
from Stage43 test (9), workflow (4), Stage30 LAST regex, Stage23 preSeal
(2), and exact unordered frozen map in memory. No PowerShell execution,
file mutation, CI dispatch, or differential acceptance.

| Case | Stage43 test gate | workflow gate | Stage30 LAST regex | Stage23 local preSeal | frozen exact map |
|---|---|---|---|---|---|
| unchanged | true | true | true | false | true |
| append Stage43 pending (B) | true | true | true | false | false |
| append CURRENT_STAGE=43 (H) | true | true | true | false | false |
| replace current/discovery with 43/28; add pending; LAST42 | false | false | true | false | false |
| preceding shape with LAST43 and confirmed status | false | false | false | false | false |
| append LAST22 and Stage23 awaiting | true | true | true | true | false |
| replace Stage42 native SHA with 40 zeroes | true | true | true | false | false |
| replace CURRENT_KIND with PATCH | true | true | true | false | false |

Eight modeled observations; the last two lifecycle states are deliberately
incomplete shape probes, NOT accepted transition metadata. No fabricated
expected-red or execution result.

## Proposed measurable acceptance contract (requires separate authority)

Input: exact Git checkout and strict UTF-8 metadata bytes, frozen baseline
Git object, and immutable run/job/artifact evidence. Output: RESEARCH_ONLY,
PENDING_SHAPE_ONLY, SEALED_SHAPE_ONLY or REJECT; separate evidence verdict
never inferred from shape. Require ordinal unique keys and full predecessor
map preservation; allow only explicitly enumerated transition keys and
values. Research exact 728-map comparison remains as accepted. Pending and
sealed transition key inventories must be separately approved and pinned;
do not assume 729 keys is sufficient for real evidence. Reject unknown
additions, missing keys, conflicting duplicates, altered historical evidence,
wrong CURRENT_KIND, SHA or artifact. No write on any reject.

| Gate | Required acceptance |
|---|---|
| A frozen parser/comparator | Preserve v006 36/36 historical evidence; rerun only if relevant code or fixtures change |
| B live research gate | frozen positive; B/H, wrong SHA/kind, missing/extra/same-cardinality mutations reject before oracle |
| H predecessor compatibility | coherent pending and sealed shape reach predecessor regressions; inconsistent shape rejects, no broad regex bypass |
| Stage01 fixture/live split | historical pinned blob and 728 map still checked; live 43 uses independently validated transition schema |
| Stage23 write isolation | actual Stage23 awaiting control only may write; late contamination rejects before writing; two later-state calls exit0, stderr0, already-finalized, unchanged SHA256 and clean tree |
| CI evidence | exact checkout SHA; required jobs and artifact paths present; missing artifact fails; verify run/job/attempt/branch and upload digest; no queued PASS |
| Stage43 numeric oracle | preserve 240 endpoints, 160 target pairs, 216 seal pairs, 23 guards, 2215/2215 zero failed |
| Stage42/41/30 regression | preserve 1657/1657, 481/481, 96/96; full actual job list required |
| Lifecycle ordering | authorization -> pending commit -> exact implementing-SHA Native acceptance -> separately sealed commit -> exact seal-SHA recheck |

Before any executable change, derive a complete transition-key whitelist
from existing stage history and explicitly pin accepted evidence fields.
A source-level contract is not a Native or full-stage acceptance verdict.
No src, oracle, test, workflow, metadata, main, merge or stage promotion
changes in this document. NEXT: separately authorize executable integration
and activation, or continue bounded research-only analysis.
