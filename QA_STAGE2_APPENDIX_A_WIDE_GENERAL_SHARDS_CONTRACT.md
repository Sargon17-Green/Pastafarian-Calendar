# Logo+Ido Stage 2 Appendix-A — exact-width Native QA shards (k=4,5,6,32,33,64)

PROJECT_ID: PC-BRANCH-LOGO-IDO
BRANCH: qa/logo-ido-stage2-wide-general-shards-20261122
QA_BASE: 587a3e3969e9c3aba48636e2fdf43af32f64b3c0
CANONICAL_LOGO_IDO_HEAD_AT_AUTHORING: ad001c6aeeb6c758f5004b206a656fec5d6fc403
SCOPE: QA_ONLY; NO_CANONICAL_PROMOTION; NO_MAIN_OR_MERGE
LAST_COMPLETED_STAGE: 1
STAGE2_ACCEPTED: NO

## Prior evidence and exact interpretation

The previous full-general-k Native run 44960408541 / job 137017741464 timed out (exit 124 at 1200 s) with empty Native log: NOT PASS. After fixing the fixture's uninitialized modulus reference and introducing a case-start trace, diagnostic run 44997206360 / job 137130705374 completed SUCCESS on exact SHA 587a3e3969e9c3aba48636e2fdf43af32f64b3c0. Its pinned UCBLogo 6.2.5 Native log emitted 26 cases, 50 assertions, WIDE_GENERAL_NATIVE_PASIS and NATIVE_LOGO_STAGE2_WIDE_GENERAL_K3_DIAGNOSTIC=PASS. The same-SHA canonical Names Lock run 44997206375 / job 137130705583 completed SUCCESS. The diagnostic evidence artifact is 14744865567, GitHub-reported sha256:30fa54c00d7a4890877e6c5a95b234944e010b3c8225713c382b90ee6c2ff88c. These results establish only the bounded k=2 compatibility/k=3 diagnostic; all higher widths remain unaccepted.

## Independent oracle and selection semantics

The existing QA fixture generator computes every expected rank with Python arbitrary-precision integers, with no calls to the Logo candidate, Logo normative reference, or prior-branch fixtures. The existing independent host enumerator validates 42,748 bounded finite cases against a different direct equation. This branch adds a strict selector `--only-width K`, where K is one of 3,4,5,6,32,33,64. This selector preserves historical `--max-width 3` behavior but selects exactly one width and **no k=2 controls** in each new shard.

For a selected width k, valid vectors contain the N=M^k no-rejection boundary; both +1 and -1 rejection directions at N=(M^k+1)//2; the N=M^(k-1)+1 transition; and, for k=32,33 only, the N=M^(k-1)+M transition. M=2^127-1. Every vector has four Native assertions: canonical exact-BI result, Python-integer expected rank, in-range [1,N], and deterministic repeat. The fixed 18 independent invalid-input guards each require output [] without failure. The explicit coverage oracle is:

| K | Valid vectors | Invalid guards | Total cases | Total assertions |
|---|---:|---:|---:|---:|
| 4 | 4 | 18 | 22 | 34 |
| 5 | 4 | 18 | 22 | 34 |
| 6 | 4 | 18 | 22 | 34 |
| 32 | 5 | 18 | 23 | 38 |
| 33 | 5 | 18 | 23 | 38 |
| 64 | 4 | 18 | 22 | 34 |

## Native acceptance gate (per width, not overall Stage 2)

Each width executes as an independent matrix job on ubuntu-24.04, fail-fast disabled, with a 25-minute job cap. UCBLogo 6.2.5 is built from pinned upstream commit a0215433f07384e4c42fe247525867f11e6f32f7. Require exact branch, exact CI HEAD=$GITHUB_SHA, locked dependency/source Git blobs, host finite-oracle PASS, generated fixture counters, and per-width Native execution under timeout 300s (k4,5,6) or 900s (k32,33,64). Native must exit 0, include its case-count/check-count/full PASS markers and no Logo error/failure text. Emit a separately named artifact for every width containing commit, blobs, SHA256 source manifest, host, vectors, generated input and Native log including case-start markers. Verify completed run/job/steps/log/artifact, SHA and digest before accepting any width. No stage acceptance on partial width PASS.

A matrix shard may fail independently; don't rerun an unchanged source/fixture without a new diagnostic finding. For a timeout, use the last observed WIDE_GENERAL_NATIVE_CASE_START marker to isolate the first uncompleted case and make a QA-only correction or finer bounded test. A complete absence of case-start markers is a boot/init failure hypothesis, not a confirmed failed case.

No change to src/stage02_choose_wide_general.logo, canonical source or canonical names is authorized by this QA contract. When all six shards and Names Lock meet their gates, revisit the remaining Stage 2 Appendix-A gates; do not infer Stage 2 acceptance or promote without a separately authorized and verified decision.
