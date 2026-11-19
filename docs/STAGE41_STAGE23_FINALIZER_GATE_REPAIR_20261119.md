# Stage41 Stage23 finalizer gate repair — 2026-11-19

PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG
Branch: PowerShell+Tagalog
Pre-fix HEAD: 886ffbf2ebadc3dcc085a1f8a497194069ffdba3
Evidence: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44395295485

## Reproduced failure
Completed 15-job workflow: 14 success, 1 failure. Exact-SHA Stage41 Native job 135123457121 completed/success, 481/481 assertions, zero failures, 48 endpoints, 24 calculation seams, 24 target seams, 12 mixed faces, 32 seal pairs. Windows PowerShell 5.1 Stage29+30 regression job 135123456654 completed/failure. Stage30 emitted 96/96 with zero failures; Stage23 finalizer verification stopped *before invoking the finalizer* with "Stage23 is not in the expected sealed state."

Metadata on 886ffbf2ebadc3dcc085a1f8a497194069ffdba3: CURRENT_STAGE=41, LAST_COMPLETED_STAGE=40, STAGE40_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED, STAGE41_RUNTIME_VERIFICATION=PENDING_NATIVE, STAGE23_RUNTIME_VERIFICATION=GREEN_CONFIRMED.

## Scoped repair contract
- The Stage23 idempotency verifier now permits CURRENT_STAGE=41 pending only with LAST_COMPLETED_STAGE=40, STAGE40 seal and prior Stage39 seal; or Stage41 sealed only with LAST_COMPLETED_STAGE=41, Stage41 seal, Stage40 seal and Stage39 seal.
- The Stage23 finalizer now accepts LAST_COMPLETED_STAGE=41 only when Stage41 is evidence-only sealed. It already accepts pending Stage41 through LAST_COMPLETED_STAGE=40.
- Historical stage gates and Stage23 GREEN_CONFIRMED remain required.
- No changes to source code, oracle, stage metadata, or main.

## Qualification
Delimiters/string static preflight + 5-case abstract predicate model checked locally; these do not establish PowerShell Native PASS. The only acceptable new-SHA verdict is GitHub Actions completed/log evidence: all 15/15 jobs success, Stage41 481/481, Stage40 425/425 and seals, Stage28 71/71, canonical verify SUCCESS, Stage23 finalizer twice exit=0, stderr=0, ALREADY_FINALIZED and unchanged SHA256. Then Stage41 evidence-only seal is a distinct commit requiring separate exact-SHA CI.
