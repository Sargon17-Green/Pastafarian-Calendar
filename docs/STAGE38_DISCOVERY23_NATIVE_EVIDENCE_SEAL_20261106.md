# Stage38 / Discovery23 — Native implementation evidence and exact-seal recheck gate

PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG
Branch: PowerShell+Tagalog
Accepted implementing SHA: 5d2ea173b4eba3c95ddb41d811e7bfd8d3b24206
New seal commit: PENDING_NEW_SHA (not accepted until exact-seal CI).

## Exact implementing-SHA evidence

[Run 41979532297](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41979532297) completed/success 12/12 on 5d2ea173b4eba3c95ddb41d811e7bfd8d3b24206, GitHub-hosted Windows PowerShell 5.1. [Stage38 job 127086185348](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41979532297/job/127086185348) passed **680/680**, zero failures, 4 contexts, 40 independently materialized endpoints, all ten seals, 180 unordered pairs, 32 consecutive triples. Observed First collisions 0; stream collisions 0; curvature nonzero 32/32; Step parity true 15/32. [Stage38 artifact 13393586870](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41979532297/artifacts/13393586870).

Regression jobs on the same SHA: Stage37 516/516 with STAGE37_SEAL_RECHECK=PASS, Stage36 1004/1004 with recheck PASS, Stage35 896/896 with recheck PASS; Stage34 448, Stage33 560, Stage32 239, Stage31 309+441+85, Stage01–30 predecessor 664. These bounded suites account for 5842 assertions when counted by stage. Canonical verify job 127086185330 success.

Stage23 finalizer in [Windows job 127086185121](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41979532297/job/127086185121) reported RESULT=PASS, twice already-finalized=True, exit code 0, stderr length 0 and SHA256 before/after both runs identical: `8BF448968FC603FE29D112C1EDBB56A43889CD1A56A1281C5AFFBF330CBA1355`. [Retained finalizer artifact 13392734071](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41979532297/artifacts/13392734071).

## Evidence-only seal, not final acceptance

This scoped seal changes only Stage38 metadata from CURRENT_STAGE=38/LAST_COMPLETED_STAGE=37/PENDING_NATIVE to CURRENT_STAGE=LAST_COMPLETED_STAGE=38/EVIDENCE_ONLY_CONFIRMED and adds exact pending-or-sealed regression guards. It does not change production source, normative oracle, fixtures, or main. The 680-assertion test budget and finite inquiry are unchanged.

**Required next gate:** New commit must have its own automatic 12/12 completed/success GitHub Actions run on that exact SHA, Stage38 680/680 with STAGE38_SEAL_RECHECK=PASS and retained artifact, Stage37 516/516 and predecessor seals, canonical verify success, Stage23 finalizer twice-idempotent with matching SHA256. Until those completed/log facts exist: STAGE38_SEAL_COMMIT_NATIVE_RECHECK=PENDING; no accepted exact-seal PASS and no Stage39 opening. No statistical uniformity or general calendar mapping claim.
