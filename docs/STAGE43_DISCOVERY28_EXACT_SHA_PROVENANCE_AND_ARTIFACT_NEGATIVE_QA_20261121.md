# Stage43 / Discovery28 — exact-SHA provenance and artifact negative QA (2026-11-21)

PROJECT_ID: `PC-BRANCH-POWERSHELL-TAGALOG`  
Branch: `PowerShell+Tagalog`  
Audited source HEAD: `9bc007334b9c85b6ef80c25e5f5b9d1f3de8bb0f`  
Disposition: **EXACT_SHA_JOB_LOG_AND_ARTIFACT_EVIDENCE_VERIFIED / 15_OF_15_METADATA_VALIDATOR_SCENARIOS_CONSISTENT / RESEARCH_PREFLIGHT_ONLY / STAGE43_NOT_ACTIVATED / NOT_SEALED**.

This is a **docs-only** independent evidence-provenance audit. The metadata validator was run separately in JavaScript against live connector responses and deliberately mutated **copies**; it was not a PowerShell execution, GitHub Actions job, source mutation, stage activation, seal, differential test, or full lifecycle acceptance.

## 1. Source and GitHub checks performed before this report

- Both tracker identifiers match `PC-BRANCH-POWERSHELL-TAGALOG`: `branches tab A9` and `continuation log tab A14`. Prior checkpoint `branches tab H9=9bc007334b9c85b6ef80c25e5f5b9d1f3de8bb0f`.
- `compare(9bc007334b9c85b6ef80c25e5f5b9d1f3de8bb0f...PowerShell+Tagalog)` returned **identical**, ahead 0, behind 0, prior to writing. The audited commit added only `docs/STAGE43_DISCOVERY28_UNIQUE_KEY_PARSER_AND_PREDECESSOR_GATE_CHANGE_MAP_20261121.md`.
- Current `DEVELOPMENT_STAGE.md` blob `a3f53b67e4445bdc835179cd484fe27b3e2648f7`: `CURRENT_STAGE=42`, `CURRENT_DISCOVERY=27`, `LAST_COMPLETED_STAGE=42`; Stage42 seal exists. Stage43 has **not** been activated.
- Existing `tests/Stage43.Tests.ps1` blob `52460ba05442f509f98f45da74ee54840462d922` uses `-ccontains` for its nine research-state predicates.
- Existing `.github/workflows/canonical-names-lock.yml` blob `554f9d07908350fa375f54e8aa34fec31671ec67` uses four `-ccontains` Stage43 entry predicates; its `Retain Stage43 SHA-bound Windows native preflight evidence` step is `if: always()` with `if-no-files-found: warn`, not a hard artifact-presence assertion. The workflow enforces exact Git checkout SHA and Windows PowerShell 5.1. Existing B/H duplicate/mixed-state preflight gaps from the earlier static report remain **unfixed**.

## 2. Completed-job evidence and artifact identities

Run URL: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44892354672  
17/17 returned jobs are individually `status=completed` and `conclusion=success`, all associated with this run ID. Run-level `status/conclusion` and `run_attempt` were **not independently exposed by the connector's available run-summary endpoint**, so this report does not invent their values. GitHub's artifact API listed **17 artifacts**, including all mandatory artifacts below; they were not downloaded and locally rehashed.

| Gate | Job | Decisive decoded log evidence | Artifact ID; GitHub-reported ZIP digest |
| --- | --- | --- | --- |
| Stage43 bounded research | `136810710650` | Windows PS 5.1, exact checkout `9bc00733...`; endpoints 240, target pairs 160, seal pairs 216, guards 23; `STAGE43_ASSERTIONS_PASSED=2215`, `FAILED=0`, `BOUNDED_ORACLE_PASS`, `NOT_ACTIVATED`, `NOT_CLAIMED` | `14702802332`, `sha256:fa40a594cceb7e92acbccc3d6f4eff24959c49801eb4ec04a0a15a05b5326ced` |
| Stage42 sealed recheck | `136810710523` | `STAGE42_ASSERTIONS_PASSED=1657`, `FAILED=0`, `SEALED_RECHECK_PASS` on exact SHA | `14702099955`, `sha256:6936356dd2df07caf370421988a49568697d71e3aabfd78cfc5d315dbf65e781` |
| Stage41 sealed recheck | `136810710634` | `STAGE41_ASSERTIONS_PASSED=481`, `FAILED=0`, `SEALED_RECHECK_PASS` | `14702443868`, `sha256:e16707ed2299ea8fa267c522fd39dd79e430ee951a716b405e3df6cb6a1c4dae` |
| Stage29/30 + Stage23 finalizer | `136810710565` | Stage30 96/96; finalizer runs 1 and 2: exit 0, stderr length 0, `ALREADY_FINALIZED=True`; before/after SHA256 `0E54874D8D8412185FA9F81F75A5528C820A76BD13C5D61657857AC438E013AF` unchanged | `14701959918`, `sha256:ff16e1f7a5e1983c47f012281acf14305d646cfbd80aca2c4b5ebb9e58829ebe` |
| Canonical lock verify | `136810710545` | Job `completed/success`, checkout at exact SHA | No separate artifact required |

For the mandatory Stage43, Stage42, and finalizer artifacts, provider metadata shows `expired=false`, correct `workflow_run.id=44892354672`, `workflow_run.head_branch=PowerShell+Tagalog`, and the exact `workflow_run.head_sha=9bc007334b9c85b6ef80c25e5f5b9d1f3de8bb0f`. Digests were cross-compared with the matching upload-log SHA256; they are **GitHub-reported upload ZIP digests**, not independent content rehashes.

## 3. Independent in-memory evidence validator — measurable contract

**Input:** `jobs[]` and `artifacts[]` retrieved for run `44892354672`, together with pinned repo/branch/SHA, fixed required job names, and fixed mandatory artifact names. No runtime scripts or metadata files are changed.

**Oracle:** allow the evidence-metadata envelope only if:
1. Exactly 17 jobs are returned, all with the specified run ID and `completed/success`; Stage43, Stage42, Stage41, Stage29/30+finalizer, and `verify` job names occur **exactly once**.
2. Each mandatory Stage43, Stage42 and finalizer artifact name occurs **exactly once**, is not expired, and its `workflow_run.id/head_branch/head_sha` all match the pinned identity.
3. Each required digest has `sha256:` plus precisely 64 lowercase hexadecimal characters. The known values must still be compared against GitHub's upload logs; a syntactically valid but false digest is not independently proven by this validator.
4. Any missing, duplicated, contradictory, pending, failed, expired or mismatched required item fails closed. This **metadata gate** does not alone prove log assertions, ZIP file contents, run-level conclusion, artifact contents, independent oracle validity, or Stage43 lifecycle approval.

The validator was applied to the actual returned metadata and to 14 **isolated synthetic mutations of deep-copied metadata**. Expected and observed classification matched in **15/15** cases:

| Case | Isolated input | Expected | Observed |
| --- | --- | --- | --- |
| V00 | Actual 17 successful jobs + required matching artifacts | ALLOW | ALLOW |
| V01 | Stage43 job in progress, conclusion null | REJECT | REJECT |
| V02 | Stage43 job conclusion failure | REJECT | REJECT |
| V03 | Remove Stage43 job | REJECT | REJECT |
| V04 | Duplicate Stage43 job | REJECT | REJECT |
| V05 | Change Stage43 artifact head SHA | REJECT | REJECT |
| V06 | Change Stage43 artifact branch to main | REJECT | REJECT |
| V07 | Change Stage43 artifact run ID | REJECT | REJECT |
| V08 | Mark Stage43 artifact expired | REJECT | REJECT |
| V09 | Remove Stage43 artifact | REJECT | REJECT |
| V10 | Duplicate Stage43 artifact | REJECT | REJECT |
| V11 | Replace Stage43 digest with malformed value | REJECT | REJECT |
| V12 | Remove finalizer artifact | REJECT | REJECT |
| V13 | Remove canonical `verify` job | REJECT | REJECT |
| V14 | Change Stage42 artifact head SHA | REJECT | REJECT |

This is **15/15 static metadata-classifier consistency**, not 15 Native assertions, not a committed test script, and not Stage43 activation/seal. The validator's positive result is corroborated by the separately inspected decisive job logs recorded in section 2.

## 4. Fail-closed gap, consequence, and independently authorized future repair

**Current research run:** required Stage43 artifact exists, is non-expired, and matches exact run/branch/SHA. This is sufficient evidence of retention for the checked run. There is **no observed missing artifact** or current artifact upload failure.

**Potential lifecycle hazard:** the current workflow's `if-no-files-found: warn` can leave a job successful without mandatory future evidence files. The current exact research run therefore cannot establish the safety of a hypothetical future Stage43 pending/sealed lifecycle gate. Combined with known **B/H** membership-predicate gaps (metadata contamination and duplicate stage keys), this calls for a separately authorized strict parser, negative tests, artifact presence failure policy and explicit per-gate provenance binding. No executable repair is authorized by the present docs-only scope.

Required future validator (subject to separate authorization): verify run-level status/conclusion and attempt, exact commit SHA and branch, all required job IDs and their logs, specific artifact IDs/names, file presence with fail-on-missing semantics, expected metadata content, declared digest and independently rehashed ZIP bytes if claiming file-integrity verification; reject unknown or contradictory lifecycle states **before** any Stage23 finalization. `PENDING_SHAPE_ONLY` and `SEALED_SHAPE_ONLY` must remain distinct from acceptance. Earlier 14/14 proposed unique-key scenarios remain a *static proposal*, not PowerShell code.

## 5. Scope and NEXT

Audit-only addition to `docs/`. No changes to `src/`, `oracle/`, `tests/`, `.github/workflows/`, `DEVELOPMENT_STAGE.md`, `main`, protected refs, or stage policy. No new workflow dispatch, Windows local user execution, or pending package; no cleanup without results of a user-local package.

NEXT: on the **new docs-only commit SHA**, inspect the automatically triggered exact-SHA CI after it finishes (jobs, decisive logs, artifacts and provider digests) **without duplicate dispatch**; meanwhile additional docs-only independent QA is permitted. Stage43 remains NOT_ACTIVATED/NOT_SEALED. Any Stage43 executable parser/lifecycle changes await separate explicit authorization.

## 6. Exact-SHA regression and docs-only correction

Run [44895698141](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44895698141), attempt 1, on exact SHA `6b01759e5b7315076f89cb3d5bb0c0d96e2de2c6` was `completed/failure`: 16 of 17 completed jobs succeeded. The one failing job, Windows PowerShell 5.1 Stage29+Stage30 and regressions (`136820750973`), logged `STAGE01_TESTS_PASSED=72`, `STAGE01_TESTS_FAILED=1`, `STAGE01_RESULT=FAIL` followed by `Stage01 regression failed Stage29` and exit 1. The failed assertion was `Walang Hebrew prose sa human-authored project files`. The source test `tests/Stage01.Tests.ps1` scans all `.ps1`, `.psd1` and `.md` files for literal U+0590..U+05FF, except the `NATURAL_LANGUAGE` line in `DEVELOPMENT_STAGE.md`. The only new file relative to the last passing commit `9bc007334b9c85b6ef80c25e5f5b9d1f3de8bb0f` is this report, whose literal Hebrew spreadsheet tab names caused the regression. The correction changes all three occurrences of those labels to ASCII-only descriptive labels, preserving exact cells A9, A14, and H9.

On this failed run, Stage43 job `136820751099` nevertheless completed/success with `STAGE43_ASSERTIONS_PASSED=2215`, failed 0, `BOUNDED_ORACLE_PASS`, `NOT_ACTIVATED`, `NOT_CLAIMED`; artifact `14704201433`, correct exact run/branch/SHA, GitHub ZIP `sha256:538e77e4f0f844374e18bb1eafbc0c56e821f035b347339a072d41043a86b086`. Stage42 job `136820751027` completed/success with 1657/1657 and artifact `14703961427`, ZIP `sha256:b96a3d163664d5373f1a13b1da031d9dbfffe74f310e44984795fb96f914654a`; Stage41 job `136820751038` completed/success 481/481; canonical `verify` job `136820750830` succeeded. The run lists 16 artifacts, with the Stage23 finalizer artifact absent because the failed job exited before generating it (upload step recorded missing path); Stage23 double-idempotency was **not tested on this SHA**. These individual passes do **not** upgrade the failed run to CI acceptance.

Scope: documentation file only. No PowerShell source, tests, workflows, normative oracle, stage metadata or protected branch touched. A literal Unicode scan of the corrected document is a **static** check, not Native acceptance. The automatically triggered CI on the corrective commit must be checked separately, without duplicate dispatch. Stage43 remains **NOT_ACTIVATED / NOT_SEALED**; executable parser/B/H and lifecycle work remains outside this authorization.
