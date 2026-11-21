# Stage43 / Discovery28: monotonic gate contamination proof and exact-SHA CI (2026-11-21)

PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG
Branch: PowerShell+Tagalog
Audited source HEAD: b957a92f65211d198b01e6dd0ed780c4c37b5b47
Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44909997733
Disposition: EXACT_SHA_RESEARCH_CI_COMPLETED_SUCCESS; STATIC_GATE_NEGATIVES_EXPOSED; STAGE43_NOT_ACTIVATED; STAGE43_NOT_SEALED.
Scope: documentation-only. The report is not authorization to change executable lifecycle gates.

## 1. Source and CI provenance

- Branch ref resolved to the exact audited source HEAD before this report was committed.
- GitHub run 44909997733: push workflow attempt 1, completed/success, head_sha=b957a92f65211d198b01e6dd0ed780c4c37b5b47. The connector returned 17/17 completed/success jobs and 17 not-expired artifacts associated with the same run/branch/SHA.
- Decoded hosted Windows PowerShell 5.1 logs: Stage43 job 136863586069 (240 endpoints, 160 target pairs, 216 seal pairs, 23 structural guards, 2215 assertions passed, 0 failed, BOUNDED_ORACLE_PASS, NOT_ACTIVATED, NOT_CLAIMED); artifact 14709309540, GitHub ZIP digest sha256:32715de7d2b70b3aa019850ab0ee8f53de984abddaaeb3ca46e08e2b1ceccb5f.
- Stage42 job 136863585915: 1657 passed / 0 failed, SEALED_RECHECK_PASS; artifact 14709617743. Stage41 job 136863586001: 481 passed / 0 failed, SEALED_RECHECK_PASS; artifact 14709078867.
- Stage29/Stage30 regression and Stage23 finalizer job 136863585884: Stage30 96/96; finalizer first and second runs both exit 0, stderr length 0, ALREADY_FINALIZED=True, and unchanged SHA256 0E54874D8D8412185FA9F81F75A5528C820A76BD13C5D61657857AC438E013AF; artifact 14709312860.
- Canonical verify job 136863585843: completed/success. The 17 decoded job logs and their upload-record lines were inspected; each of the 17 current GitHub artifacts has a matching logged ID, ZIP name and digest. Digests are GitHub API/upload-log reports, NOT independently recalculated ZIP hashes.
- DEVELOPMENT_STAGE.md blob a3f53b67e4445bdc835179cd484fe27b3e2648f7 has 728 distinct assignments; CURRENT_STAGE=42, CURRENT_DISCOVERY=27, LAST_COMPLETED_STAGE=42. No Stage43 activation or seal.

## 2. New source-bounded proof: positive membership cannot reject appended contamination

- tests/Stage43.Tests.ps1 blob 52460ba05442f509f98f45da74ee54840462d922: research-state predicate is a conjunction of nine case-sensitive `-ccontains` full-line membership tests.
- .github/workflows/canonical-names-lock.yml blob 554f9d07908350fa375f54e8aa34fec31671ec67: Stage43 CI precondition is a conjunction of four `-ccontains` full-line membership tests.
- Let M be the set of distinct metadata lines and P(M) be the conjunction of mandatory positive membership predicates. For any appended lines X, P(M)=true implies P(M union X)=true. Therefore positive-only gates are incapable of enforcing absence, uniqueness, or consistency, regardless of the number of existing positive checks.
- This is a source-level logical proof about the two predicates, not a claim that the live repository contains the hypothetical invalid metadata.

## 3. Source-derived, standalone synthetic gate evaluation

Method: read the exact audited metadata; extract the literal membership strings from the nine-test and four-workflow Stage43 predicate blocks; evaluate case-sensitive full-line set membership on isolated, in-memory copies. Expected disposition below is the proposed strict unique-key research-only contract, not the current executable behavior.

| ID | Isolated input alteration | Strict expected | Stage43 test gate | Stage43 workflow gate |
| --- | --- | --- | --- | --- |
| C0 | No alteration, sealed Stage42 baseline | ALLOW | ALLOW | ALLOW |
| X1 | Append STAGE43_RUNTIME_VERIFICATION=PENDING_NATIVE | REJECT | ALLOW | ALLOW |
| X2 | Append STAGE43_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED | REJECT | ALLOW | ALLOW |
| X3 | Append duplicate CURRENT_STAGE=42 | REJECT | ALLOW | ALLOW |
| X4 | Append contradictory CURRENT_STAGE=43 | REJECT | ALLOW | ALLOW |
| X5 | Append contradictory CURRENT_DISCOVERY=28 | REJECT | ALLOW | ALLOW |
| X6 | Append contradictory LAST_COMPLETED_STAGE=43 | REJECT | ALLOW | ALLOW |
| X7 | Append contradictory STAGE42_RUNTIME_VERIFICATION=PENDING_NATIVE | REJECT | ALLOW | ALLOW |
| X8 | Append unknown STAGE43_ACTIVATION_PROOF=UNVERIFIED | REJECT | ALLOW | ALLOW |
| X9 | Append malformed line THIS IS NOT METADATA | REJECT | ALLOW | ALLOW |
| X10 | Append both pending and sealed STAGE43 verification lines | REJECT | ALLOW | ALLOW |
| D1 | Delete LAST_COMPLETED_STAGE=42 | REJECT | REJECT | REJECT |
| D2 | Delete STAGE42_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED | REJECT | REJECT | REJECT |

Observed: C0, D1 and D2 behave as strictly expected; all ten append-only contamination cases are falsely accepted by BOTH existing membership predicates. Overall only 3/13 cases meet the strict expected disposition, with 10/13 exposed false accepts. These are 13 static source-model cases, NOT PowerShell Native tests, NOT differential tests, and NOT ten live CI failures. Older B/H gaps are included; the contribution here is the monotonic proof, broader same-value/other-key negative classes, and exact-current-SHA evidence.

## 4. Invariants for separately authorized executable remediation

1. Parse DEVELOPMENT_STAGE.md as strict unique keys. Accept optional UTF-8 BOM only at file start, LF/CRLF line endings, and blank lines; reject malformed nonblank lines, duplicates even when same value, and unknown/contradictory lifecycle data.
2. Research mode must have exactly coherent Stage42 seal values, no STAGE43_* keys, and independent predecessor proof. Fail closed before running Stage43 preflight on mixed or malformed input.
3. Future pending/sealed shapes need separate authorization and individually checked exact-SHA run/job/log/artifact evidence. Shape-valid must never mean Native accepted.
4. Keep sealed Stage42 C0 and missing-key D1/D2 as controls. Preserve Stage43 2215-assertion independent-oracle preflight and existing Stage41/42/Stage23 regressions.
5. The current Stage43 artifact upload has `if-no-files-found: warn`; a future mandatory activation/seal artifact requires fail-closed handling. Do not silently promote research preflight artifacts.
6. Any future implementation must extend the stage-locked predecessor/finalizer/workflow checks deliberately, not append '43' to a permissive membership expression.

## 5. Scope and next step

This audit changes no src/, oracle/, tests/, workflow, DEVELOPMENT_STAGE.md, protected main or merged branch. Stage43 remains RESEARCH_ONLY, NOT_ACTIVATED / NOT_SEALED.

NEXT: On this documentation-only commit's SHA, inspect the automatic push run after completion, validating run/attempt/head SHA, jobs, decisive logs and artifacts. Do not dispatch duplicate runs or claim new-SHA CI PASS ahead of evidence. Continue documentation-only negative-case QA under the current authorization; executable parser, tests, workflow and lifecycle require a distinct permission.
