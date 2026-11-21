# Stage43 / Discovery28 — unique-key metadata parser contract and predecessor gate change map (2026-11-21)

PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG  
Branch: `PowerShell+Tagalog`  
Verified predecessor source HEAD: `f974b2610705bb6c05ae2c8587e86fe983ba26ef`  
Disposition: **EXACT_SHA_RESEARCH_CI_ACCEPTED / PARSER_CONTRACT_DOCUMENTED / STATIC_SCENARIOS_14_OF_14 / STAGE43_NOT_ACTIVATED / NOT_SEALED**.

## 1. Evidence read before writing this docs-only record

- Automatic push run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44889993708, attempt 1, `head_sha=f974b2610705bb6c05ae2c8587e86fe983ba26ef`, `completed/success`, **17/17 jobs completed/success**, Windows hosted.
- Stage43 job `136803523981`, decoded log: 240 endpoints, 160 target pairs, 216 adjacent-seal pairs, 23 guards, **2,215 passed / 0 failed**, `STAGE43_PREFLIGHT=BOUNDED_ORACLE_PASS`, `STAGE43_ACTIVATION=NOT_ACTIVATED`, `STAGE43_STAGE_SEAL=NOT_CLAIMED`, and the exact above SHA. Retained artifact **14702055704**, GitHub API/upload-log ZIP digest `sha256:70419177b80da4d672553439ff22e9b19aed355016945e6e13c5bdf45f9e1262`.
- Stage42 job `136803524033`: **1657/1657**, zero failed, `SEALED_RECHECK_PASS`; artifact **14701598599**, API digest `sha256:a7918f04ba3b018bfe1cce18358292672b225014f698615217b37c2a11ea28d4`.
- Stage41 job `136803523969`: **481/481**, zero failed, `SEALED_RECHECK_PASS`; artifact **14701895720**.
- Stage30/Stage23 job `136803523946`: Stage30 **96/96**, zero failed; finalizer invocations both exit 0, both `ALREADY_FINALIZED=True`, both zero stderr, all before/after SHA256 `0E54874D8D8412185FA9F81F75A5528C820A76BD13C5D61657857AC438E013AF`. Finalizer artifact **14701578458**, API digest `sha256:c3e30234bb1aecc0fd4814f5001a509549f686b24320ecb8761b893d239735e0`. Canonical-lock job `136803523954` completed/success.
- These artifact digests are **GitHub-reported ZIP hashes, not independently downloaded-and-rehashed payloads**. The completed preflight tests the *sealed Stage42* state. It is not Stage43 activation/seal or a proof of hypothetical metadata states.

## 2. Unique-key parser — proposed measurable contract, not yet implemented

**Input:** the complete UTF-8 bytes of `DEVELOPMENT_STAGE.md` at a pinned Git commit. An optional single UTF-8 BOM at byte offset 0 and LF/CRLF line endings are accepted. Blank lines are ignored. Every nonblank line must match `^([A-Z][A-Z0-9_]*)=(.*)$`; split at the **first** `=`, retain the value exactly (including any additional equals signs), and treat keys and protocol values as ordinal case-sensitive text. No implicit trim, trailing comment syntax, case folding or fuzzy matches. Reject malformed lines, any repeated key (even repeated with identical value), and missing mandatory keys. Record the error category and line number. File I/O failures fail closed.

**Output:** either `ParseSuccess(Dictionary<string,string>)` with exactly one value per distinct key, or `ParseFailure(reason,key?,line?)`. A successful parse is **not** a stage acceptance verdict. A separate deterministic state classifier returns exactly one of `RESEARCH_ONLY`, `PENDING_SHAPE_ONLY`, `SEALED_SHAPE_ONLY`, or `REJECT_STATE`. Subsequent evidence validation must return an independently checked verdict for each gate; a shape-only status never implies Native PASS.

**Source-bounded pre-activation classifier:**
- `RESEARCH_ONLY`: unique `TOTAL_STAGES=55`, `CURRENT_STAGE=42`, `CURRENT_DISCOVERY=27`, `LAST_COMPLETED_STAGE=42`, `STAGE42_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED`; **no `STAGE43_*` metadata keys**. Additional Stage42 predecessor seal identity keys and their values must be checked before research execution.
- `PENDING_SHAPE_ONLY` (future lifecycle state, not authorized now): exact `CURRENT_STAGE=43`, `CURRENT_DISCOVERY=28`, `LAST_COMPLETED_STAGE=42`, `STAGE43_RUNTIME_VERIFICATION=PENDING_NATIVE`, with Stage42 sealed. Its required predecessor evidence is confirmed separately. *Pending* does not assert that a future activation-SHA Native run succeeded.
- `SEALED_SHAPE_ONLY` (future lifecycle state, not authorized now): exact `CURRENT_STAGE=43`, `CURRENT_DISCOVERY=28`, `LAST_COMPLETED_STAGE=43`, `STAGE43_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED`, with Stage42 sealed. The implementing-SHA Native run, job logs, artifact and exact SHA must be checked separately, followed by exact seal-SHA CI before claiming full acceptance.
- All other combinations, non-unique keys, contaminated research state, unknown `STAGE43_*` lifecycle values, missing provenance, or mixed statuses are rejected. Do not infer acceptance from a `-contains`/`-ccontains` membership check.

**Evidence validator contract (separate from parser):** compare `run.head_sha`, `head_branch`, `run_attempt`, `status=completed`, `conclusion=success`, expected workflow/job ID and **each required job** conclusion; inspect decisive assertions and exit codes in decoded job logs; verify mandatory artifact ID/name and API `expired=false`, and compare artifact digest as reported. The digest from GitHub is not a substitute for an independent local ZIP rehash if that stronger claim is made. Reject SHA mismatch, missing job, no artifact, contradictory metadata, or partial successful jobs. Do not accept queued/running. Required artifact uploads in future Stage43 activation and seal workflows must fail on absence, not merely warn.

## 3. Independent source-scoped static scenario evaluation (NOT PowerShell execution)

Source `DEVELOPMENT_STAGE.md` blob `a3f53b67e4445bdc835179cd484fe27b3e2648f7` contains **728 distinct key assignments** and five blank lines at the verified HEAD. A standalone JS structural classifier (not copied from any other implementation) parsed this exact source, then evaluated **14 isolated synthetic mutations** without changing repo files. Expected = observed in **14/14 static scenarios**:

| Scenario | Expected = observed | Meaning |
| --- | --- | --- |
| S01 original full metadata | RESEARCH_ONLY | Sealed Stage42 research fixture |
| S02 duplicate identical `CURRENT_STAGE=42` | REJECT_DUPLICATE | Same-value duplicate rejected |
| S03 duplicate contradictory `CURRENT_STAGE=43` | REJECT_DUPLICATE | Prior H gap closed by proposed parser |
| S04 Stage43 pending key added to Stage42 | REJECT_STATE | Prior B gap closed by proposed classifier |
| S05 missing CURRENT_STAGE | REJECT_STATE | Mandatory key missing |
| S06 CURRENT_STAGE changed to 43 alone | REJECT_STATE | Mixed stage/discovery |
| S07 coherent Stage43 pending shape | PENDING_SHAPE_ONLY | Shape only; no evidence verdict |
| S08 coherent Stage43 sealed shape | SEALED_SHAPE_ONLY | Shape only; no evidence verdict |
| S09 pending with LAST=43 | REJECT_STATE | Wrong predecessor |
| S10 sealed with LAST=42 | REJECT_STATE | Inconsistent last completed |
| S11 leading whitespace before key | REJECT_MALFORMED | Unambiguous grammar |
| S12 colon instead of equals sign | REJECT_MALFORMED | Unambiguous grammar |
| S13 duplicated Stage43 verification keys | REJECT_DUPLICATE | Conflicting statuses |
| S14 original source with BOM and CRLF | RESEARCH_ONLY | Encoding/line-ending boundary |

These **14/14 results verify only the standalone proposed classifier and synthetic fixtures**, not a PowerShell parser, CI test, Native test, differential comparison, or lifecycle transition. The previous eight-case source audit remains independently documented at `docs/STAGE43_DISCOVERY28_STATIC_STATE_MATRIX_AUDIT_20261121.md`; its two genuine current **B/H fail-closed gaps are still present in executable tests/workflow**.

## 4. Scoped migration map for a separately authorized Stage43 lifecycle change

| Target | Current verified anchor | Proposed gated change (NOT made here) | Required negative/positive oracle |
| --- | --- | --- | --- |
| `tests/Stage43.Tests.ps1` blob `52460ba05442f509f98f45da74ee54840462d922` | `$sealed42` uses nine `-ccontains` membership checks; tests only preflight | Invoke strict unique-key parser first; reject any Stage43 key in research state; add explicit pending/sealed modes only with separate authorization | Original 2215/2215 remains unchanged; B/H now reject; S07/S08 shape distinct from evidence PASS |
| `.github/workflows/canonical-names-lock.yml` blob `554f9d07908350fa375f54e8aa34fec31671ec67` | Stage43 workflow uses four `-ccontains` checks; Stage43 artifact `if-no-files-found: warn` | Reuse the same parser contract at CI entry; require artifact on future activation/seal, enforce SHA/job/run identity | Duplicate key, missing job/artifact, wrong SHA must hard-fail; research stays Stage42 only |
| `tests/Stage30.Tests.ps1` blob `406379c61db115ae64fce5b43ad36e24862f6005` | `LAST_COMPLETED_STAGE` regex stops at **42** | Extend only through validated Stage43 pending/sealed classifier, never by appending `43` to a membership regex alone | 42-sealed control PASS; pending 43 with LAST42 accepted *only where intended*; sealed 43 with LAST43 accepted only with proof; B/H reject |
| `tests/Stage41.Tests.ps1` blob `36586ca7f13b093d75f755efdc1fa6f96f51994b` | `$stage41Sealed` recognizes CURRENT 41/42, not 43 | Recognize 43 only when shared unique-key state is coherent and Stage41/42 seals persist | Preserve 481/481 on sealed42; reject contradictory duplicate stage and mismatched predecessor |
| `tests/Stage42.Tests.ps1` blob `6a04c17d58e0dd7382b59559398a8ea24d10c5db` | `$stage42Sealed` anchored to CURRENT=42, LAST=42 | Permit Stage42 regression under coherent Stage43 pending/sealed metadata with strict Stage42 seal evidence | Preserve 1657/1657 and independent oracle; B/H and false Stage42 seal reject |
| `tests/FinalizeStage23.ps1` blob `2bcd0544a7bfb5f7fa06c275e6fb87c49c0fd71b` | `$stage42Sealed` terminal postSeal branch, no 43 | Add explicit Stage43 pending/sealed **read-only idempotent** path after shared parser check; retain Stage23 preSeal write path unchanged | Two calls exit0/stderr0/already-finalized and unchanged SHA256; malformed Stage43 must fail before write |
| `tests/VerifyFinalizeStage23Idempotency.ps1` blob `15aff14706231cba428e79a0d43f98ac31d7fa6a` | Stage39/41 compatibility anchored through 42; no 43 | Add explicit unique-key validated 43 state and consistent predecessor gates | Both finalizer calls verify clean git tree and identical before/after SHA256; negative states reject |
| `DEVELOPMENT_STAGE.md` blob `a3f53b67e4445bdc835179cd484fe27b3e2648f7` | CURRENT=42, DISCOVERY=27, LAST=42, Stage42 sealed, no Stage43 status | **Do not edit under present authorization.** Future transition must carry exact provenance and be evaluated on the new SHA | Never backfill a PASS from a prior SHA or call pending Stage43 sealed |

Implementation sequencing when separately authorized: (1) parser and its negative tests; (2) Stage43 pending state + predecessor compatibility + finalizer and workflow hard gates; (3) completed activation-SHA Windows PS5.1 CI and artifact review; (4) evidence-only seal metadata; (5) completed seal-SHA CI with regressions; (6) only then consider Stage43 fully accepted. No new stage is activated by this document.

## 5. Scope, acceptance, NEXT

This is a **docs-only** change on `PowerShell+Tagalog`. No `src/`, `oracle/`, `tests/`, workflow, `DEVELOPMENT_STAGE.md`, `main`, or protected refs may change in this step. Stage43 research preflight remains accepted **only on the exact source SHA named above**. No local-user execution, pending package, artifact cleanup, or duplicate dispatch is needed.

NEXT: check any automatic CI for this new documentation SHA once completed (run/job/log/artifact and exact SHA); preserve Stage43 `NOT_ACTIVATED/NOT_SEALED`. Further parser code or lifecycle changes require a separate explicit Stage43 lifecycle authorization. If no such permission is available, continue strictly docs/static QA only without inventing additional lifecycle stages.
