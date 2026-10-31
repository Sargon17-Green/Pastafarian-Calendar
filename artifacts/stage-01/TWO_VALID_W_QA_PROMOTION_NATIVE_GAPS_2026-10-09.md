# Stage 1 — guarded QA promotion and remaining Native architecture findings

**QA branch only**, recorded 2026-10-09. Do not merge PR #17, modify canonical `Befunge+Кыргызча` or main, or begin Stage 2.

## Exact source provenance

- QA production now: `src/interleaved_work_counts.b98` — Git blob `b6cf50de9ed45376db5fc4ebd003157210dff03b`.
- Old QA production frozen intact: `qa/interleaved_work_counts_pre_two_valid_w_production.b98` — Git blob `8f2cf8afef61818244747582fe7c20a74ee18943`.
- Predecessor stand-alone w source: `qa/interleaved_work_counts_w_data_branch_candidate.b98` — Git blob `31807edb2b44b141d2af340555d6e97e63428613`.
- Promoted two-valid input w/_ source differs from the predecessor w source by exactly 18 independently audited 2D cells. All 1531 x 2016 source dimensions and per-row byte widths remain unchanged.
- Stage-1 Native oracle proof and two independent graph/fault ownership auditors passed 17 core cases and 22 additional boundary cases *before* promotion, including two valid w outcomes and proper invalid-upper `_` route.
- Historical geometry/counterfactual tests were redirected to the immutable snapshot, preserving their original causal claims without misattributing those claims to the new running source.

## Production qualification status (must not overclaim)

- The last all-green 30-job GitHub Actions run on the **earlier** frozen production was `37919066363` (commit `35bd0388f6670e627f7d9d3f29ff2d489d5dd357`). That result does not by itself qualify the new production blob.
- First post-promotion suite `37922215422` exposed an observable difference: forcing the upstream `|` conditional opposite on valid `zero_equal` was not output-causal on the new production. The historical strict four-case test is preserved against the old source; an explicit read-only Native report now measures the current source and leaves that causal claim OPEN.
- A separately added `{ u }` stack-stack arithmetic experiment, based on the promoted candidate bytes, initially timed out on valid `zero_equal`. Raw Native STEP evidence showed its vector `x` returning to the intended coordinate but eventually executing a zero-delta `x` repeatedly at `(920,1335)`. Attempts to repair this isolated candidate continue; **do not count it as a passed Native stack-stack implementation**.
- Post-promotion production regression must be confirmed from the **exact current QA HEAD** before claiming that all current jobs pass. Any newer workflow/commit supersedes earlier success for that assertion.

## Closure boundaries

`CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`; `FUNCTIONAL_QA_PASS=NO`, `GEOMETRIC_SPAGHETTI_QA_PASS=NO`. The upstream gate causal question, stack-stack { } u ownership and meaningful arithmetic, broader recursive entanglement and independent final functional/geometric verification remain open. No canonical merge authorization.
