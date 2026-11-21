# Stage 2 / Discovery 21 — unrestricted CHOOSE.SHORT canonical promotion contract

Project: PC-BRANCH-LOGO-IDO (Logo+Ido). Authorized by user 2026-11-21 for bounded canonical branch promotion only; no main, merge, publication, or Stage 2 completion.
Status at creation: CANONICAL_IMPLEMENTED_NATIVE_AND_REGRESSIONS_PENDING. LAST_COMPLETED_STAGE remains 1.

## Production provenance
The canonical addition `src/stage02_choose_short.logo` is the exact unchanged QA-tested Git blob `a556145f52a6c59018b0ef216d7a4fc6813e0f23` from `qa/logo-ido-d21-unrestricted-choose-short` at `ba4b71230b763be56f202a8f3d13836765ce7434`. Its introductory "QA branch only" comment describes provenance and is superseded for this canonical placement by this contract; the executable source is intentionally byte-for-byte identical. Do not change the QA branch or cherry-pick its three commits en masse.
Independent Python-int oracle and fixture generator `qa/logo_d21_unrestricted_oracle.py` retains tested Git blob `b965e18c8e848a5c519d65b0ab9d15c99bf8dba6`. The canonical-only workflow is `.github/workflows/logo-stage02-d21-canonical-native.yml`.

## Frozen mathematical interface
Reporter `monster.stage02.choose.short :stream :N`.
The stream is exactly `[firstValue step]`; `firstValue` and `N` are canonical exact BI integers in `[1,M]`, `step` is precisely +1 or -1, and `M=2^127-1`. Out-of-contract inputs return `[]` with no global side effects. Arbitrarily corrupted BI internals are excluded.
For `x_k = 1 + ((firstValue-1 + step*k) mod M)`, `q=floor(M/N)`, `r=M-qN`, and `L=M-r=qN`, choose the smallest `k>=0` such that `x_k<=L`. Report exact canonical BI rank `1+((x_k-1) mod N)`.
For `firstValue<=L`, k=0 and use BI arithmetic. Otherwise the rejected set is contiguous `(L,M]`; step +1 next accepts x=1, rank=1, while step -1 next accepts x=L, rank=N. Rejection travel length can exceed 32, so no bounded walker may implement unrestricted production.

## Mandatory exact-SHA acceptance
Before any acceptance, verify the `Logo+Ido` ref equals the new intended commit, `git rev-parse HEAD == GITHUB_SHA`, all pinned Git blob locks, and actual Native execution by headless UCBLogo 6.2.5 at upstream commit `a0215433f07384e4c42fe247525867f11e6f32f7`, bounded 900s. The independent Python-int oracle exhaustively tests small moduli 2..48 (76,046 combinations), emits 134 valid and 13 invalid fixtures, 15 large rejection gaps, and a total of 147 cases and 549 checks. Require exact host PASS and Native `D21U_NATIVE_CASES_PASIS 147`, `D21U_NATIVE_CHECKS_PASIS 549`, `D21U_NATIVE_PASIS`, `NATIVE_D21_UNRESTRICTED_CANONICAL=PASS`; prohibit failure-text markers. Retain both raw logs in artifact tied to same commit SHA with verified digest.
Separately verify completed/success GitHub Actions runs/jobs/logs/artifacts on the same new commit for Names Lock, Stage 1 and all applicable accepted D1-D20 regression workflows. Queued/in_progress is neither PASS nor blocker. CI success without Native markers is not Native PASS. Original QA Native run 44896706027 and Names run 44896705958 were successful at QA SHA only, not canonical acceptance. Stage 2 remains incomplete regardless of D21 acceptance. Do not dispatch duplicate runs.

## Authorized branch update
Build an additive Git tree from exact canonical parent `7ed2e187a1ac075a98917b6030aa490a164f63cc`, adding only production source, independent oracle, this contract, and a new push-on-canonical D21 Native workflow; mark Discovery21 as pending in DEVELOPMENT_STAGE.md. Update only `refs/heads/Logo+Ido` using expected_sha `7ed2e187a1ac075a98917b6030aa490a164f63cc`, `force=false`. On lease mismatch, abort and re-evaluate; never substitute a historical SHA for the live branch head.
