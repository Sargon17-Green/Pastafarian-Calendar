# Stage43 / Discovery28 — exact-document CI acceptance and separate lifecycle-gate plan (2026-11-21)

PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG  
Branch: `PowerShell+Tagalog`  
Disposition: **EXACT-DOC-CI_ACCEPTED / STAGE43_PREFLIGHT_ACCEPTED / STAGE43_NOT_ACTIVATED / NO_STAGE43_SEAL**.  
This is a documentation-only plan and evidence record. It does **not** authorize a stage transition, alter state metadata, or replace any Native gate.

## 1. Provenance and source identity

- Prior research implementation: [`52377393c07815b1879a533b8b7d6cfad1b69eb3`](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/52377393c07815b1879a533b8b7d6cfad1b69eb3); bounded Stage43 preflight [run 44819982120](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44819982120) already accepted (17/17, Stage43 2,215/2,215).
- Evidence-document commit: [`beed6b61f82e5def24c1f0752ecfaba46809995a`](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/beed6b61f82e5def24c1f0752ecfaba46809995a). Its sole parent is `52377393c07815b1879a533b8b7d6cfad1b69eb3`; compare showed ahead=1, behind=0, only one new `docs/STAGE43_DISCOVERY28_NATIVE_PREFLIGHT_ACCEPTANCE_20261121.md`. Branch HEAD matched `beed6b61...` before this plan was created.
- Automatic [run 44828239762](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44828239762) on **exact `beed6b61f82e5def24c1f0752ecfaba46809995a`**, branch `PowerShell+Tagalog`, attempt 1, event push: `status=completed`, `conclusion=success`. **17/17 jobs completed/success**, including the following checked job logs and artifacts. No manual rerun was dispatched.

| Gate | Exact job | Observed log / artifact |
| --- | --- | --- |
| Stage43 independent normative-oracle research, hosted Windows PowerShell 5.1 | [136606232792](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44828239762/job/136606232792) | 240 endpoints, 160 target pairs, 216 seal pairs, 23 structural guards; 2,215 assertions passed, zero failed; `STAGE43_PREFLIGHT=BOUNDED_ORACLE_PASS`, `STAGE43_PREFLIGHT_SHA=beed6b61f82e5def24c1f0752ecfaba46809995a`; explicit `NOT_ACTIVATED`, `NOT_CLAIMED`. |
| Stage43 retained evidence | [artifact 14674808370](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44828239762/artifacts/14674808370) | `powershell-tagalog-stage43-neighbor-year-preflight`; 16,314 bytes; GitHub API / upload log ZIP SHA-256 `970ce898b116de17cd1e58a49f3cc2ae941b2a1683d02114c036b62b632c2cb7`. This is an **API/log digest**, not a locally recomputed ZIP digest. |
| Canonical lock | [136606232860](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44828239762/job/136606232860) | completed/success; job runs hash check of canonical lock. |
| Stage42 predecessor seal regression | [136606233608](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44828239762/job/136606233608) | 1,657 passed, zero failed; [artifact 14674864142](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44828239762/artifacts/14674864142), ZIP digest `c03bf40bc06cf7e6a16d1f9e6d947ecb53ab7c88fc5785c05c26fcd4976304fa`. |
| Stage30 regression and Stage23 twice-idempotent finalizer | [136606232874](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44828239762/job/136606232874) | Stage30 96/96, zero failed. Both invocations: `EXIT_CODE=0`, `STDERR_LENGTH=0`, `ALREADY_FINALIZED=True`; before/after SHA-256 identical: `0E54874D8D8412185FA9F81F75A5528C820A76BD13C5D61657857AC438E013AF`. [Finalizer artifact 14674847854](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44828239762/artifacts/14674847854), ZIP digest `9c9b58d18bad66afcfcffaba173bd0b5b205070fd8076fb265c0b614ecca6961`. |

The other thirteen jobs in the run's latest-attempt job list were also `completed/success`; this record does not claim to have inspected all thirteen raw logs individually. There is no evidence for a Stage43 activation run or Stage43 seal run.

## 2. Frozen pre-activation state and finite test contract

Current `DEVELOPMENT_STAGE.md` at `beed6b61...`: `TOTAL_STAGES=55`, `CURRENT_STAGE=42`, `CURRENT_KIND=DISCOVERY`, `CURRENT_DISCOVERY=27`, `LAST_COMPLETED_STAGE=42`, `STAGE42_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED`. There is **no** Stage43 state transition here.

The source under test is `src/MonsterSkeleton.ps1`; the independent same-repository normative oracle is `oracle/NormativeScroll.ps1` with NormativeCore/NormativeCalendar. The completed `tests/Stage43.Tests.ps1` currently asserts a **sealed-Stage42 / not-activated** precondition, and the Stage43 workflow job makes the same assumption. Those gates will reject a Stage43 activation unless separately adapted and retested. Do not simply change `DEVELOPMENT_STAGE.md` in isolation.

The bounded oracle contract is **2 calculation contexts × 4 neighboring-year gates × 3 target offsets × 10 legal seals = 240 endpoints**; 160 target pairs and 216 adjacent seal pairs, 23 structural guards; **1,440 + 320 + 432 + 23 = 2,215 assertions**. Numeric queried bowl ID is exactly 1, legal seals 1..10. Expected First/Step and pair deltas are independently computed by the normative oracle, not by the source under test; arithmetic uses `System.Numerics.BigInteger`. Each count and every assertion is mandatory; no skipped invalid cases, synthetic expected-red outcomes, uniformity claims or Gregorian date-mapping claims.

## 3. Three mutually exclusive lifecycle states — a future contract, **not yet implemented**

| State | Exact required metadata | Required test/CI disposition | Permitted conclusion |
| --- | --- | --- | --- |
| Research / preflight (CURRENT) | `CURRENT_STAGE=42`, `CURRENT_DISCOVERY=27`, `LAST_COMPLETED_STAGE=42`, Stage42 evidence seal confirmed | A preflight result on same exact source SHA with all 2,215 assertions, predecessor regressions and finalizer | `STAGE43_PREFLIGHT_ACCEPTED` only |
| Activated pending (requires separate recorded Stage43-scoped authorization and commit) | `CURRENT_STAGE=43`, `CURRENT_KIND=DISCOVERY`, `CURRENT_DISCOVERY=28`, `LAST_COMPLETED_STAGE=42`, `STAGE43_RUNTIME_VERIFICATION=PENDING_NATIVE`; retain exact predecessor evidence IDs | New *automatic* exact-activation-SHA Windows 5.1 CI with 2,215/2,215 and zero failures; distinguish `PASS_PENDING_NO_SEAL` from preflight | Native acceptance for the *activation SHA* only; no seal yet |
| Evidence sealed (only after accepted activated-SHA Native) | `CURRENT_STAGE=43`, `CURRENT_DISCOVERY=28`, `LAST_COMPLETED_STAGE=43`, `STAGE43_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED`, with immutable accepted activation SHA/run/job/assertion/artifact provenance | Separate evidence-only sealing commit, then *its own* completed successful exact-SHA CI and explicit `SEALED_RECHECK_PASS` with predecessor checks | Stage43 seal acceptance only after this last distinct gate |

Any mismatched combination (for example Stage43 pending with `LAST_COMPLETED_STAGE=43`, or a sealed status with no exact activation evidence) must fail closed. New SHA means a new gate; neither `52377393...` nor `beed6b61...` can supply the activation-SHA result.

## 4. Scope and technical acceptance plan for a separately authorized activation

1. **Authorization gate:** record explicit authority to activate Stage43/Discovery28 on `PowerShell+Tagalog`. This planning document is not that authority. Until recorded, no stage-metadata transition and no Stage43 activation commit.
2. **Pre-edit concurrency gate:** re-read the live branch HEAD and exact `DEVELOPMENT_STAGE.md` state; ensure no intervening commits. Keep commits non-force on `PowerShell+Tagalog`; never reset to historical preflight/evidence SHA.
3. **State predicate implementation:** in `tests/Stage43.Tests.ps1`, separate three strict and mutually exclusive preflight/pending/sealed states with SHA-bound evidence requirements. Preserve the numeric oracle (240/160/216/23/2215); only lifecycle predicates and status output should change absent an independently proven functional defect. Add static positive and negative state-matrix test cases before Native.
4. **Workflow compatibility:** adapt the existing Stage43 Windows PS5.1 job so that it accepts exactly the three proven states and logs the appropriate state-specific result. Review and narrowly extend *only* older workflow/test/finalizer predicates demonstrably requiring 43 (Stage23 idempotency; predecessor Stage30–42). Reject contradictory metadata; never replace a strict gate with an unconditional bypass. Preserve exact `git rev-parse HEAD == GITHUB_SHA`, 35-minute bounded Stage43 job, deterministic inputs, transcript and retained artifact. Ensure `if-no-files-found` behavior is treated as an explicit evidence gate rather than a silent success.
5. **Activation commit:** only after authorized static QA, set pending Stage43 metadata with the accepted preflight identifiers and evidence; do not change `src/`, `oracle/`, canonical names, protected branches or release paths. Verify changed files and exact HEAD/readback. A push's newly queued CI is not PASS; do not dispatch a duplicate.
6. **Activated-SHA Native decision:** require status `completed/success`, correct attempt, branch, all jobs (count from actual run, not assumed 17), explicit Windows PS5.1 and checkout SHA; Stage43 all 2,215 assertions, zero failures; predecessor Stage42 1,657, Stage41/40 seals, Stage30 96 and other jobs; canonical verify; Stage23 twice exit0/stderr0/unchanged SHA256; artifact ID and ZIP API/log digest. On real failure, repair *only* a reproduced failure on the authorized branch.
7. **Sealing decision:** separately commit immutable exact-activation evidence and compatible sealed predicates, only after full activated-SHA success. Verify a new exact seal-commit CI, complete jobs/logs/artifacts before accepting Stage43 as completed. Never infer final acceptance from research preflight or from an evidence-document CI alone.

## 5. Static state-matrix QA for the next non-activating work item

Proposed read-only / documentation-level checks before any authorized activation: (a) Stage42 sealed + Stage43 absent => research mode; (b) Stage42 sealed + Stage43 pending with CURRENT_STAGE=42 => reject; (c) Stage43 pending + LAST_COMPLETED_STAGE=42 => accepted state shape if all precursor evidence present; (d) Stage43 pending + LAST_COMPLETED_STAGE=43 => reject; (e) Stage43 sealed + LAST_COMPLETED_STAGE=43 + immutable activated-SHA evidence => accepted state shape; (f) Stage43 sealed without accepted activation SHA => reject; (g) Stage43 sealed + LAST_COMPLETED_STAGE=42 => reject; (h) unknown/multiple state declarations => reject. These are **planned cases**, not claimed test results.

## 6. Change boundary and NEXT

This commit is intended to add **this one new `docs/` file only**. No `DEVELOPMENT_STAGE.md`, `src/`, `oracle/`, `tests/`, CI workflow, `main`, merge or publication changes are authorized or made by this plan. Any automatic CI triggered on this documentation-only SHA must be checked separately, not assumed successful.

NEXT: verify this new document commit has exactly one added docs path, is a non-force child of `beed6b61...`, and becomes the actual branch HEAD; check automatic exact-SHA CI without duplicate dispatch, then perform a *non-activating* state-predicate inventory/static gate QA as needed. A separate authorized Stage43 activation remains a distinct later action.
