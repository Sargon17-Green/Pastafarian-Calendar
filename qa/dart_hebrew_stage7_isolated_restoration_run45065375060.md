# Stage7 isolated A-restoration QA — verified run 45065375060

- PROJECT_ID: `PC-BRANCH-DART-HEBREW`
- Scope: Stage7 **QA-only**, `Dart+עברית`; no production planner mutation, main/merge, Stage8, release, or performance/default promotion.
- Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45065375060
- Dedicated job: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45065375060/job/137340224012
- Run attempt: 1; event: push; status: `completed/success`; exact source HEAD: `fd86224c588461f44deee45c000591830288cc8f`.
- Run summary: 27 successful jobs, 1 intentionally skipped, 0 failed. Dedicated job, Python syntax step, isolated differential step, and upload step: `completed/success`.
- Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45065375060/artifacts/14771965438
- Artifact ZIP SHA-256 (verified against downloaded bytes, GitHub metadata and job log): `549f8d010fb63501ce0e23222936cf85102d2bba8e67348a96e4df9fbff9516c`. Archive contains `results.json`, `oracle.json`.
- Oracle SHA-256 (verified against extracted `oracle.json`): `7b7a920608ec1c4952cfdd6b4df1de06e2aa422ec813996fa8a1764e7e3b5a24`.
- Actual artifact verdict: `DIFFERENTIAL_PASS_WITH_FORMAT_DRIFT`. Do **not** simplify to `PASS_ISOLATED_QA_ONLY`.

## Source locks and isolation

- B planner blob at current branch HEAD: `d736ca8afe3409a10474b8514284aceb154a46a9`; retained identically after non-mutating format diagnostic.
- Restored A blob: `3553a7f2e3899c958d56620c5449daa35b0731e2` from `1d98a83db7446ceb4548c39e0eaf9b4441b72b9a`; exact reconstruction in disposable worktree, unchanged after diagnostic.
- Restoration performed only inside isolated temporary worktree. Runner modification at `fd86224c...` adds `dart pub get` separately to both worktrees before `dart analyze`, correcting the previous missing-package failure.
- Python syntax succeeded. `dart pub get` succeeded separately for B and restored A. `dart analyze` returned `No issues found!` for both.
- Both exact source locks were preserved, and no production planner source was edited.

## Independent exhaustive oracle and differential verification

| Domain | Oracle words | B ranks checked | Restored A ranks checked |
| --- | ---: | ---: | ---: |
| [3,3,2] | 26 | 26 | 26 |
| [4,4,3] | 461 | 461 | 461 |
| [4,4,4] | 1,301 | 1,301 | 1,301 |
| **Total** | **1,788** | **1,788** | **1,788** |

Both variants emitted `STAGE7_ISOLATED_DIFFERENTIAL_PASS` with `ranks=1788 domains=3 bounds=6 immutable=3`. Each variant rejects ranks 0 and count+1 in each domain (6 invalid-rank checks); first result of each domain is immutable; input-length arrays preserved.

Independent artifact readback additionally reproduced the expected word sets using an alternative full multiset-sequence enumeration followed by *first-appearance and last-appearance ordering* filters, rather than the runner's opened/closed DFS transitions. It matched all 26, 461 and 1,301 words exactly in lexicographic order, with no duplicates. This checks the artifact oracle itself, not just the test harness output. It is independent Python validation, **not** another Dart Native run.

## Separate format gate — open

- B: `BASELINE_FORMAT_DRIFT` (`dart format --output=none` reported 1 changed file).
- Restored A: `BASELINE_FORMAT_DRIFT` (same report).
- In both cases the formatter was diagnostic-only and source blob was unchanged. This is *not* a code-mutating format fix, a clean formatter PASS, or an algorithmic mismatch.
- `format_gate=BASELINE_FORMAT_DRIFT`; resolve as an explicitly separate historical-source-format gate, without silently modifying source-locked A/B.

## Acceptance boundaries and next authorized work

- **Accepted now, narrowly:** isolated source-locked A-vs-B correctness/differential QA of 1,788 ranks per variant, negative bounds, immutable outputs, input preservation, clean static analysis, complete evidence artifact, exact SHA and unchanged source files.
- **Not accepted:** source-locked format cleanliness, B performance advantage over A, B promotion to default, new production code, Stage8, main, merge, or release.
- Previous targeted performance data failed for [4,4,4] (only 2/5 B faster, median -9.308410%); policy remains `KEEP_A_DEFAULT`. Branch implementation still contains B as the active default, which is not evidence of approval to promote it.
- **NEXT:** perform a new, focused QA-only investigation of the *precise* format drift between locked A and B under Dart 3.13.2, recording a nonmutating formatter diff and its origin. Do not re-run already accepted source-locked differential tests at the same SHA without a new reason. Separately preserve the failed performance gate; any proposed default-route change requires a fresh justified technical basis and its own authorization.
