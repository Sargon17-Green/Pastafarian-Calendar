# Logo+Ido — Stage2 wide performance diagnostic (QA only)

- PROJECT_ID: `PC-BRANCH-LOGO-IDO`
- Branch: `qa/logo-ido-wide-perf-diagnostic-20261123`
- Parent source-lock: `f3bcfc743b23aee6cd2598e789aecb97677ee166`
- Canonical branch `Logo+Ido` remains at the separately verified `ad001c6aeeb6c758f5004b206a656fec5d6fc403` until further authorized changes.
- This diagnostic does **not** accept any Stage2 component, change production logic, rerun an unchanged six-shard matrix, or authorize promotion/merge/main.

## New evidence warranting a different test

Exact-SHA `f3bcfc74` run `45069132517`: Native k4/k5/k6 completed successful 22 cases/34 checks each; k64/job `137351914672` timed out after 900s (exit 124) on the first case `v001_k64_no_rejection`; k32/job `137351914783` and k33/job `137351914818` were cancelled while in Native execution, without PASS markers. On previous SHA `dbff8641` run `45068924882`, k32/job `137351265712` timed out on its third case `v003_k32_reject_1`, k33/job `137351265680` on second case `v002_k33_reject_-1`, and k64/job `137351265704` on first case, all with exit 124. These are performance/termination observations, not evidence of numerical mismatch.

## Diagnostic contract

Input: an exact source-locked Logo candidate and QA fixture generator, and one width in {32,33,64}. Test case selection is deterministic and tied to the previously incomplete case: k32 rejection +1, k33 rejection -1, k64 no-rejection. A Python-only generator selects the already specified arbitrary-precision expected result and writes a **temporary instrumented copy** of `src/stage02_choose_wide_general.logo`, without modifying that file in the repository.

Instrumentation inserts only `print` statements immediately before/after the recursion, wide-term multiplication, weight multiplication and quotient/remainder operation. A machine-checked inverse transformation removes every inserted statement and must reproduce the locked original byte-for-byte (UTF-8). The native script invokes precisely one targeted case and compares its returned BI result to the independent Python integer expectation, **if it returns**. The timing wrapper prepends UTC timestamps to streamed output; no reduction in input width or relaxation of the rank's mathematical contract is permitted.

Execution: pin source hashes, upstream UCBLogo 6.2.5 commit `a0215433f07384e4c42fe247525867f11e6f32f7`, and use one independent 240s timeout for each of k32, k33, k64 with `fail-fast: false`. Preserve job/step/exit code, generated original and instrumented SHA256 hashes, exact fixture, UTC-marked Native trace, and Git SHA in per-width GitHub artifacts even on timeout. An incomplete probe is *diagnostic failure/incomplete*, not an `expected-red` or Native PASS.

Oracle / completion conditions: source recovery MUST pass statically; the exact target case must be selected; if Native returns, exact expected BI and canonical shape must be verified. Full exact-width acceptance **still requires** the original complete shard's 23/38 or 22/34 checks and Native markers on a valid source SHA. The purpose of this action is to locate the first expensive operation and plan a separately justified optimization/QA decomposition; no production or stage acceptance can be inferred from it.

NEXT: inspect the completed diagnostic run/job/log/artifacts, identify the last emitted phase per width (prepare, build index, term, weight, division), and choose a measured, QA-scoped remedy. Do not repeat identical timeout tests without a new hypothesis.
