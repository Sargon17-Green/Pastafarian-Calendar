# Stage42 / Discovery27 — Windows Native evidence-only seal (2026-11-20)

PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG
Branch: `PowerShell+Tagalog`
Implementing SHA: `0aefdce42390ffe0d62391ed51deed6c7276e9b0`
State: implementing-SHA `EVIDENCE_ONLY_CONFIRMED`; exact seal-commit CI is **not yet accepted**.

## Independent-oracle Native evidence — exact activation SHA

[GitHub Actions run 44716461173](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44716461173), attempt 1, completed/success on exact branch and SHA `0aefdce42390ffe0d62391ed51deed6c7276e9b0`. All **16/16** jobs completed/success, including canonical `verify`. Hosted **Windows PowerShell 5.1** Stage42 job `136220997452` reported `STAGE42_NATIVE=PASS_PENDING_NO_SEAL` and **1657/1657 assertions, 0 failures** against `oracle/NormativeScroll.ps1`: 160 endpoints, 80 calculation seams, 80 target seams, 40 mixed faces, 144 adjacent seal pairs. The bounded contract is in `tests/Stage42.Tests.ps1`; it does not establish statistical uniformity or Gregorian-date mapping.

Retained [Stage42 artifact 14621569483](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44716461173/artifacts/14621569483); GitHub Actions log reported uploaded ZIP SHA-256 `9a59094813e74ce4526fb9df7cec1509b7e39cc3cd0be8609825bc90dcec22f3`.

Predecessor jobs succeeded: Stage41 job `136220997700` reported `STAGE41_NATIVE=SEALED_RECHECK_PASS`, **481/481**, 0 failures, `STAGE41_SEAL_RECHECK=PASS`. Stage40 job `136220997388` reported **425/425**, 0 failures, `STAGE40_SEAL_RECHECK=PASS`. Windows regression job `136220997933` reported Stage30 **96/96**, 0 failures. Other predecessor jobs and canonical verify completed/success.

Stage23 finalizer in job `136220997933`: both runs exit code 0, both stderr lengths 0, both `ALREADY_FINALIZED=True`. Before and both after SHA-256:
`0546846CEED3277DD32D99A8ADCAAA67A3FFCAB90EABC845745892AFBD6A2491`.
Retained [finalizer artifact 14622451460](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44716461173/artifacts/14622451460). This is an idempotency statement for that exact CI checkout, not an assertion about unrelated source revisions.

## Seal transition and historical QA guard

This commit records `CURRENT_STAGE=42`, `CURRENT_DISCOVERY=27`, `LAST_COMPLETED_STAGE=42`, `STAGE42_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED` and immutable activation evidence in `DEVELOPMENT_STAGE.md`. Existing `src/`, `oracle/`, stage arithmetic, `main` and published releases remain unchanged.

The activated-SHA tests passed, but previously committed historical gate predicates constrained `LAST_COMPLETED_STAGE` to 41. Stage42's own test already supports sealed state. To avoid a demonstrably mismatched metadata contract in the automatic exact-seal run, this commit extends only relevant predecessor/CI/finalizer state predicates: allow `LAST_COMPLETED_STAGE=42` **only together with** `STAGE42_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED`; preserve the prior Stage41 predicate. Stage42 CI now distinguishes preflight, pending and sealed; sealed state requires exact implementing-SHA Native evidence and produces `STAGE42_NATIVE=SEALED_RECHECK_PASS`. These are test/workflow compatibility edits, **not** an algorithmic change.

## Outstanding exact-seal acceptance gate

The new seal commit has a different SHA from the activated implementation. Its automatic GitHub Actions run must independently finish `completed/success` with 16/16 jobs; Stage42 **1657/1657**, zero failures and `SEALED_RECHECK_PASS`; Stage41 **481/481** sealed; Stage40 **425/425** sealed; Stage30 **96/96**; predecessor jobs and canonical verify success; Stage23 two idempotent finalizer runs and identical SHA-256, with retained artifacts. Until that exact-seal completed/log evidence exists, `STAGE42_SEAL_COMMIT_NATIVE_RECHECK=PENDING_NEW_SHA` and full Stage42 acceptance must not be claimed. Queued or in-progress is not a blocker and not PASS. No duplicate dispatch, main change, merge or release.
