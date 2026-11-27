# Stage44 strict transition schema — research only
PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG
Branch: PowerShell+Tagalog
Status: DESIGN_ONLY; NOT_ACTIVATED; NO_NATIVE_CLAIM.

## Frozen provenance
Accepted predecessor fafca7cf90f3a77eea27fcbaa0827b4fa2e4e686, run 46015468647. Preflight commit 3f22d9520b928a27bcbbc1f5d9abbc44c179a819; DEVELOPMENT_STAGE.md blob 91f8dd0237903bc4db9131ba506bc398c92c3258. Parsed 796 distinct keys (68 STAGE43), 793 immutable values. Freeze all except CURRENT_STAGE, CURRENT_DISCOVERY, LAST_COMPLETED_STAGE. Retrieve pinned Git blob with strict UTF8 parser, reject unavailable or wrong identity, never use candidate as baseline. Preserve CURRENT_KIND=DISCOVERY and CURRENT_PATCH=14; active pointers CURRENT_STAGE=44, CURRENT_DISCOVERY=29. Existing Stage43 classifier remains unchanged for genuine Stage43 candidates.

## Exact additions
STAGE44_DISCOVERY=MOVING_NEIGHBOR_YEAR_GATE_INTERACTION
STAGE44_PLANNING_STATUS=IMPLEMENTED_PREFLIGHT_VERIFIED
STAGE44_PLANNED_CALC_DAYS=6
STAGE44_PLANNED_GATES_PER_CONTEXT=4
STAGE44_PLANNED_TARGET_OFFSETS=-1,0,1
STAGE44_PLANNED_TARGET_DAYS=12
STAGE44_PLANNED_SEALS=10
STAGE44_PLANNED_ENDPOINTS=720
STAGE44_PLANNED_RECTANGLES=320
STAGE44_PLANNED_STRUCTURAL_GUARDS=67
STAGE44_PLANNED_SOURCE_CONTEXTS=72
STAGE44_PLANNED_ORACLE_CONTEXTS=72
STAGE44_PLANNED_ASSERTIONS=5027
Four lifecycle fields RUNTIME_VERIFICATION, ACTIVATION, NATIVE_ACCEPTANCE, SEAL_COMMIT_NATIVE_RECHECK, all STAGE44-prefixed. Profiles (LAST_COMPLETED_STAGE, runtime and activation, native acceptance, seal recheck):
- pending: 43, PENDING_NATIVE, NOT_CLAIMED, NOT_RUN; PREFLIGHT only.
- implementing: 44, EVIDENCE_ONLY_CONFIRMED, IMPLEMENTING_SHA_ACCEPTED, PENDING_NEW_SHA; PREFLIGHT and NATIVE.
- sealed claim: 44, EVIDENCE_ONLY_CONFIRMED, IMPLEMENTING_SHA_ACCEPTED, PASS; all three groups. Final exact-new-HEAD external recheck mandatory.

Each group has exactly 20 keys, prefix STAGE44_PREFLIGHT_, STAGE44_NATIVE_, or STAGE44_SEAL_:
- ASSERTIONS_PASSED = 5027
- ASSERTIONS_FAILED = 0
- ENDPOINTS = 720
- RECTANGLES = 320
- STRUCTURAL_GUARDS = 67
- SOURCE_CONTEXTS = 72
- ORACLE_CONTEXTS = 72
- CANONICAL_JOBS = 17_OF_17_SUCCESS
- STAGE43_ASSERTIONS = 2215
- FINALIZER_IDEMPOTENCY = PASS
- CANONICAL_VERIFY = SUCCESS
- CI_SHA : 40 lowercase hex
- DEDICATED_RUN : positive decimal
- DEDICATED_JOB : positive decimal
- CANONICAL_RUN : positive decimal
- DEDICATED_ARTIFACT : positive decimal
- DEDICATED_ARTIFACT_SHA256 : 64 lowercase hex
- FINALIZER_ARTIFACT : positive decimal
- FINALIZER_SHA256 : 64 lowercase hex
- RUNTIME : 5.1.build[.revision]
Exact key counts 833/853/873. Reject unknown, missing, duplicate, case-variant, premature keys, mixed status, invalid encoding, noncanonical format and same-cardinality substitutions. Each phase binds dedicated and canonical run IDs to same checkout SHA; distinct SHA and all run IDs across phases; distinct artifact IDs. Freeze evidence groups once accepted, not just syntactic shape. Canonical 17/17 reflects current separate-workflow topology; schema revision required if topology changes. External adjudication must validate actual run/job/attempt/checkout, artifact ZIP bytes/digest, logs and counters; shape cannot prove historical evidence.

## Integration order
1. Dedicated preflight 5027/0 and canonical exact same SHA before activation. Canonical run 46020802797 completed success (17/17, 18 artifact API entries, Stage43 job 140579657305 2215/0, finalizer job 140579657146 RESULT=PASS and unchanged EF31C98A432EBF68275014FDBAC26EE3927E5C5A5B1E0829A20779EA968D18AC twice). Actions head_sha query found only canonical run; no dedicated run observed; no PASS for Stage44.
2. Implement fail-closed Stage44 classifier separately, then update all Stage43 profile consumers and finalizer/workflows via exact profile whitelist, preserve predecessor counters, revise Stage44 test's sealed-Stage43-only guard for authorized phases and workflow blob lock accordingly. No src algorithm/oracle changes. Verify strict parser adversarial cases, identity reuse, phase mutations, predecessor regression and all call sites before pending metadata.
3. Activate only after gates; pending exact SHA Native and canonical success before implementing evidence, distinct seal evidence and exact-seal recheck. No main/merge/release.

## Design QA
JS in-memory exact-map model, actual 796-key baseline, symbolic placeholders for evidence fields (not fabricated CI data). Checked all 793 frozen values individually changed and removed in each of three profiles, every new-field omission, unknown-key addition and positive shape. 4935 checks passed, 0 failed. This is structural design QA only; does not implement production classifier or test byte parser, evidence value patterns, cross-phase identity or Native. Those checks are explicit remaining work.
