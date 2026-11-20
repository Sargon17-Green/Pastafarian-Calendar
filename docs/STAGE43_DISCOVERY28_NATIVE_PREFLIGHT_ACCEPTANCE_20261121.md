# Stage43 / Discovery28 — exact-SHA Windows preflight acceptance (2026-11-21)

PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG  
Branch: `PowerShell+Tagalog`  
**Disposition: STAGE43_PREFLIGHT_ACCEPTED, not Stage43 activation, not a Stage43 seal, not Stage43 completion.**

## Source and strict provenance

- Implementing source commit: [`52377393c07815b1879a533b8b7d6cfad1b69eb3`](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/52377393c07815b1879a533b8b7d6cfad1b69eb3).
- Automated [GitHub Actions run 44819982120](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44819982120): **attempt 1; status `completed`; conclusion `success`; event `push`; head branch `PowerShell+Tagalog`; head SHA `52377393c07815b1879a533b8b7d6cfad1b69eb3`**. The run-level fields were read from the GitHub REST workflow-run resource; the latest-attempt job listing contains **17 of 17 completed/success jobs**.
- No rerun or duplicate dispatch. The original Stage42 exact-seal evidence remains accepted separately on `fcf1640de4f3a96f8bcb60822d067253b79af9ca` ([run 44799736042](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44799736042)); it is not substituted for the Stage43 SHA.

## Stage43 native preflight: bounded independent normative oracle

- Job [136578060056](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44819982120/job/136578060056): `completed/success` on hosted **Windows PowerShell 5.1**, with an explicit PowerShell 5.1 and checkout/`GITHUB_SHA` check in the workflow.
- Test: `tests/Stage43.Tests.ps1`. Source under test: `src/MonsterSkeleton.ps1`. Independent same-repository normative oracle: `oracle/NormativeScroll.ps1` via NormativeCore and NormativeCalendar; expected First/Step values come from the oracle, not from the production function or another branch.
- Actual log evidence: `STAGE43_ENDPOINTS=240`, `STAGE43_TARGET_PAIRS=160`, `STAGE43_SEAL_PAIRS=216`, `STAGE43_STRUCTURAL_GUARDS=23`, `STAGE43_ASSERTIONS_PASSED=2215`, `STAGE43_ASSERTIONS_FAILED=0`, `STAGE43_PREFLIGHT=BOUNDED_ORACLE_PASS`, `STAGE43_PREFLIGHT_SHA=52377393c07815b1879a533b8b7d6cfad1b69eb3`.
- The finite domain is **two calculation contexts × four neighboring-year gates × three target offsets × ten legal seals**, comparing First/Step, modulo-M deltas and seal adjacencies. It does not establish global equivalence or statistical uniformity.
- Retained [Stage43 artifact 14671659389](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44819982120/artifacts/14671659389): `powershell-tagalog-stage43-neighbor-year-preflight`; 16,310 bytes; ZIP SHA-256 `f144bdc2ab5c77b62c3c700101a424101c6e8ae717580086f612e19fee5bec14`. The GitHub artifact API digest matches the upload-artifact step log; no independent local ZIP hash computation is claimed.

## Predecessor regressions and invariant preservation

| Scope | GitHub job | Completed log evidence |
| --- | --- | --- |
| Canonical names lock | [136578059363](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44819982120/job/136578059363) | completed/success; same checkout SHA |
| Stage42 seal recheck | [136578059874](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44819982120/job/136578059874) | completed/success; 1,657/1,657, failed=0, `SEALED_RECHECK_PASS` |
| Stage41 regression | [136578060059](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44819982120/job/136578060059) | completed/success |
| Stage40 regression | [136578060423](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44819982120/job/136578060423) | completed/success |
| Stage30 regression + Stage23 finalizer | [136578060031](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44819982120/job/136578060031) | completed/success; Stage30 96/96; finalizer twice with exit=0, stderr length=0, already-finalized=true |

Stage23 finalizer invariant: `SHA256_BEFORE=0E54874D8D8412185FA9F81F75A5528C820A76BD13C5D61657857AC438E013AF`; `RUN_1_SHA256_AFTER` and `RUN_2_SHA256_AFTER` equal that exact value. [Finalizer artifact 14671298664](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44819982120/artifacts/14671298664), ZIP API/log digest `ba192f7f52e4967177761b09aa5fdf29225bafb9bec4f3c6ecfd82a8334e04bd`.

## Exact acceptance boundary

The above is **Native Windows preflight acceptance for the Stage43 *research test* at implementing commit `52377393c07815b1879a533b8b7d6cfad1b69eb3` only**. It is not a complete Stage43/Discovery28 acceptance, differential coverage of all inputs, a Stage43 evidence seal, or authorization to change production.

The source `DEVELOPMENT_STAGE.md` remains `CURRENT_STAGE=42`, `CURRENT_DISCOVERY=27`, `LAST_COMPLETED_STAGE=42`, with Stage42 evidence-only seal confirmed. The Stage43 test log expressly reports `STAGE43_ACTIVATION=NOT_ACTIVATED` and `STAGE43_STAGE_SEAL=NOT_CLAIMED`.

This evidence-only document must not mutate `src/`, `oracle/`, tests, workflows, stage metadata, `main`, or any protected branch. A future Stage43 activation must be separately scoped and then reverified by completed exact-SHA CI, rather than inferring acceptance for the new SHA from this run.

## NEXT

Preserve the Stage43 preflight acceptance at implementing SHA. Check this evidence-document commit for exact one-file scope and branch HEAD after non-force advance. Do **not** mark Stage43 activated or completed. In a separately scoped next step, plan the Stage43 activation/lifecycle gates without re-running already accepted SHA `52377393c07815b1879a533b8b7d6cfad1b69eb3`.
