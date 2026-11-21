# D21 CHOOSE.SHORT — canonical promotion preflight (QA only)

Project: `PC-BRANCH-LOGO-IDO` (Logo+Ido)
Date: 2026-11-21
Document scope: QA-only preparation. **NOT** permission to promote; **NOT** canonical implementation, Native acceptance, Stage 2 acceptance, or a release.

## 1. Verified inputs and immutable anchors
- Canonical branch: `Logo+Ido`; verified HEAD `7ed2e187a1ac075a98917b6030aa490a164f63cc`.
- Accepted candidate branch: `qa/logo-ido-d21-unrestricted-choose-short`; verified HEAD `ba4b71230b763be56f202a8f3d13836765ce7434`.
- Compare canonical...QA: ahead 3, behind 0; exactly 12 added files and no modified/deleted files. The 12 additions include three QA-only GitHub Actions workflows and should **not** be blindly promoted as a unit.
- Candidate source: `src/stage02_choose_short.logo`, Git blob `a556145f52a6c59018b0ef216d7a4fc6813e0f23`.
- Independent integer oracle/fixture generator: `qa/logo_d21_unrestricted_oracle.py`, Git blob `b965e18c8e848a5c519d65b0ab9d15c99bf8dba6`.
- QA workflow: `.github/workflows/logo-stage02-d21-unrestricted-qa.yml`, Git blob `de340c5c88844ed0aacb9f2cfeeaff7305e00c52`.
- Frozen QA contract: `STAGE02_D21_UNRESTRICTED_QA_CONTRACT.md`, Git blob `47bcf62736a6a7ae7efb332b9e94d732b795f9f8`.
- Existing exact arithmetic dependency: `src/exact_integer.logo`, blob `f2c1a8aa5822423402cd5825255891183f0fc83c`. Freeze and verify dependency hashes on the new candidate SHA; do not assume the old canonical HEAD remains unchanged.

## 2. Evidence already passed — QA scope only
- GitHub run `44896706027` / job `136823805745`, completed/success at exact QA SHA `ba4b712...`. In the decoded original job log:
  `D21U_HOST_SMALL_EXHAUSTIVE 76046`, `D21U_HOST_VALID 134`, `D21U_HOST_LONG_GAPS 15`, `D21U_HOST_CASES 147`, `D21U_HOST_CHECKS 549`, `D21U_HOST_ORACLE=PASS`;
  `D21U_NATIVE_CASES_PASIS 147`, `D21U_NATIVE_CHECKS_PASIS 549`, `D21U_NATIVE_PASIS`, `NATIVE_D21_UNRESTRICTED_QA=PASS`.
- Names lock: run `44896705958` / job `136823805653`, completed/success.
- Log artifact `14705142911` (`d21-unrestricted-qa-logs`): attached to head SHA `ba4b712...`, expired=false at inspection, archive digest `sha256:ffb8f5e951561d20bf1943af7a324fd5d1ccdee50f1bb40881e83f285f81a4e9`.
- These are **not** same-SHA canonical D21 or Stage 2 gates. Do not rerun already accepted QA on the same SHA without a new reason.

## 3. Promotion decision and allowed write set
**Decision owner: user.** The live tracker explicitly reserves to the user whether D21 `CHOOSE.SHORT` may be transferred to canonical `Logo+Ido`. A generic QA authorization does not answer that question.

On explicit approval only:
1. Re-read both branch heads and compare; require canonical HEAD lease equal to the fresh expected SHA and candidate source blob equal to the frozen hash, else stop and re-evaluate.
2. Select **only** production code, a canonical contract and the required independent D21 fixture/oracle. Do not fast-forward/cherry-pick the entire 3-commit/12-file QA history; retain QA-only workflows, exploratory near-M source/tests, and audit files on QA unless explicitly justified as production dependencies.
3. Add a **new canonical-only** D21 Native verification workflow, with trigger restricted to `push` on `Logo+Ido` (not a QA workflow relabeled after the fact), source-blob locks and exact `git rev-parse HEAD == GITHUB_SHA`. A canonical state manifest update is allowed only to the verified D21 scope; `LAST_COMPLETED_STAGE=1` remains unchanged.
4. Use an expected-head/lease-guarded branch-only commit/update. No `main`, merge, branch protection change, release or Stage 2 completion.

## 4. Measurable canonical acceptance contract
- **Input:** stream `[firstValue step]`, exact canonical BI `firstValue,N in [1,M]`, integer `step in {-1,1}`, `M=2^127-1`. Invalid input must report `[]` without global mutation.
- **Oracle, independent of Logo:** `x_k=1+((firstValue-1+step*k) mod M)`, `L=floor(M/N)*N`, first `k>=0` with `x_k<=L`; rank `1+((x_k-1) mod N)`. Enumerate small moduli independently; for long gaps prove that all prior positions lie in rejected suffix `(L,M]`, confirm predecessor and first accepted boundary.
- **Boundary tests:** `N=1,2,M/2,M-31,M-1,M`; `firstValue=1,L-1,L,L+1,L+33,M-1,M`; both signs; malformed stream, step, BI, N. Include gaps exceeding 32 and huge integer magnitudes. Keep fixture generator computationally independent of production Logo.
- **Native:** pinned headless UCBLogo `6.2.5` source commit `a0215433f07384e4c42fe247525867f11e6f32f7`; bounded wall clock; unambiguous nonzero exits on failure or timeout. At least the previously proven **147 cases / 549 checks**, plus exact PASS markers and failure-text exclusion. Preserve source-lock, host and native raw logs with a nonexpired artifact, its digest, and matching SHA.
- **Regressions:** on the **new canonical SHA**, verify completed/success for names lock, stage 1 and all applicable accepted D1–D20 native regression workflows. Validate jobs, logs and required artifacts individually, not merely a green summary badge. Do not count queued/in_progress as PASS or blocker and do not dispatch duplicate runs.
- **Acceptance:** D21 canonical accepted **only** when all exact-SHA Native, differential, source-lock, artifact and regression gates complete successfully; QA PASS is merely an input. Even then `Stage2 = incomplete` until separate full-stage acceptance.

## 5. Next actions and explicit non-actions
Current gate remains `D=ממתינה להכרעה`, `G=ממתין להכרעה`. The pending question is **whether to authorize bounded transfer of D21 CHOOSE.SHORT to canonical Logo+Ido**, within the strict write set and gates above. There is no identified user-computer Native dependency, no need to build a `/Pending_User_Execution` package and no cleanup of user-execution files merely because this document exists. This preflight document is an actionable engineering checklist, not a request to repeat QA or a substitute for the user's decision.
