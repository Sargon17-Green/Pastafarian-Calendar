# DISCOVERY24 — in-place insertion-prefix feasibility audit (2026-11-25)

PROJECT_ID: `PC-BRANCH-CLOJURE-DUTCH`

Scope: **TEST/QA ONLY**. No production source, API, public budget, search budget, main, merge, or publication change. `DISCOVERY24` and Stage 2 remain **OPEN**.

## Source and run identity

- Branch: `Clojure+Nederlands`.
- Branch HEAD before this QA-only commit: `a9e3010f21aa476f8e411c0f1ee5ebff234f6696`.
- Current production source path: `src/pastafari/maandrang.clj`.
- Current production Git blob read back from GitHub: `62f304dc013a9a9f70475bb0d34f186838b27318` (unchanged).
- Canonical DP input source SHA: `ec0051ec6335fe178c03bcf3583b3dbfec1ffa84`.
- Search budget remains `128N`; production shared-prefix ceiling remains `5000000N`.
- Current-HEAD automatic run `45671866675`, exact SHA `a9e3010f21aa476f8e411c0f1ee5ebff234f6696`: Native job `139408995528` and verify job `139408996089` both completed SUCCESS. Raw Native log: 152 tests / 168,997 assertions / 0 failures / 0 errors. The six feasibility/witness jobs were SKIPPED; this run did not execute the new Python model or a p82/p520 five-field witness. No run artifacts were produced.

## New independent algorithm

Added `discovery24_inplace_insertion_prefix_qa.py`, a 21,845-byte standalone TEST/QA-only implementation of the exact insertion suffix distribution.

- The recurrence is updated in place from right to left. For each output index `a+1`, the old `dp[a]` is read before the next write can overwrite it. The prefix sum is maintained as `prefix = total`, followed by `prefix -= old`.
- Binomial weights are generated as scalar recurrence values `w_t = w_(t-1) * (t+k-2) / t`; no separate weights vector is allocated.
- The exact suffix count uses a bounded LRU cache (2,048 suffix states and 2,048 insertion factors).
- This implementation is independent of production Clojure and imports no project code.
- A second, separately implemented gap-convolution counter was used to recompute the canonical total, lexicographic rank path, and production shared-charge schedule. It matched the in-place implementation at positions 81, 82, and 520.

### Explicit alternative cost contract

The alternative algorithm counts one `DP_CELL_WRITE` for each computed output-distribution entry. It does **not** count scalar BigInt arithmetic, DP reads, or cache overhead. This is a separate diagnostic work metric, not the production `prefix-cell-upper-bound` metric. The numeric ceiling is held at 5,000,000, but the units are not asserted to be equivalent. Therefore an alternative-model result below 5,000,000 is not a production budget PASS.

## Executed evidence

Command:

```text
python -m py_compile qa/clojure-dutch/discovery24_inplace_insertion_prefix_qa.py
python qa/clojure-dutch/discovery24_inplace_insertion_prefix_qa.py \
  --canonical-artifact-zip <verified-14770898411.zip> \
  --p520-witness-zip <verified-14710227259.zip>
```

- `py_compile`: exit 0.
- `py_compile`: exit 0.
- Full standalone run: exit 0, 28.472 seconds.
- Script SHA-256: `6750797787c19a3b860aacd0153444387751686584eeb53fbebeb0b863fec5f1`.
- The local invocation omitted `--source`, so the script output correctly says `current_production_blob_verified=false`; the current production blob was independently verified by exact GitHub file readback at current HEAD.
- Stdout SHA-256: `a50a0fa93fa80a3f12ed145325f4accb823391cc1454c6ee786f38934f3d7ce5`.
- Small exhaustive tests: 8 profiles, 67 legal words, 480/480 rank-position matches, 480/480 exact-budget accepts, 413 budget-minus-one refusals.
- Canonical artifact 14770898411: ZIP SHA-256 `eb7c55739ab2ff9c237138c4f2a8a28ebfd006cfe00d373ca1621c8b8e460cd5`; 33 months, 3,569 days, 5,288-digit rank; search budget 128. The independent exact total equals the frozen source-locked total.
- p81: prefix SHA-256 `2d44e8c3ba6770c498098be3a463df3941d1079ee8c0bfbdd9c2010b87be8e1a`; production shared cost `4,995,675`.
- p82: exact alternative prefix SHA-256 `3408b680fac534e4c34ef0d123b6f09e05314be31210d82f14d2a61e84d8c219`; month ID 20, occurrence 5. Alternative DP writes `3,507,625`. The existing production shared-charge schedule requires `5,002,652`: billed before the group `4,995,675`, active-group charge `1 + (33-31)*3488 = 6,977`, exceeding the production ceiling by `2,652`.
- p520: exact alternative prefix SHA-256 `65c683810ee69f740e38334bbc67969d4ac429bc7d7943646a2a02aa14d8ae0b`; month ID 10, occurrence 18. Alternative DP writes `3,713,186`, leaving `1,286,814` of its separate 5,000,000 DP-write allowance. The hypothetical production shared-charge total through p520 is `5,218,257`; the existing production method would already have refused at p82.
- The independent gap-convolution implementation matched both prefix hashes, month IDs, occurrences, exact canonical total, and shared-charge totals.

## Historical production p520 witness

The existing p520 production witness was re-read from run `44910763612`, exact historical SHA `faa37816ae4e1384e019d406c62415af7ab028b6`.

- Witness job `136865879505` and verify job `136865879727`: completed SUCCESS; full Native job `136865915887`: SKIPPED.
- Raw witness log: `DISCOVERY24 CANONICAL PLUS17 BOUNDED REFUSAL (NO NUMERIC PROOF)`; requested year 5000 / position 520; refusal `:bounded-prefix-budget-unproven`.
- Artifact `14710227259`, ZIP SHA-256 `13a4d2855eb71dae4a3d2f526e68b6301bf41880cab9388c495226ca2202ccd4`: `:five-fields-proven? false`, `:stage2-accepted? false`, search budget 128N and production budget 5000000N.
- This is an observed production refusal at the historical SHA, not a date equality and not a current-HEAD Native result.

## Gate classification

| Gate | Result |
|---|---|
| Python syntax and bounded local execution | PASS |
| Small exhaustive rank-prefix oracle | PASS — MODEL ONLY |
| Canonical total and p81/p82/p520 rank path | PASS — MODEL ONLY |
| Independent gap-convolution agreement | PASS — MODEL ONLY |
| Alternative DP writes through p520 | 3,713,186 / 5,000,000 — MODEL ONLY |
| Existing production shared-charge p82 | REFUSED: 5,002,652 > 5,000,000 |
| Historical production p520 witness | REFUSED: `:bounded-prefix-budget-unproven` |
| p82 production observation on current HEAD | NOT RUN |
| Five-field differential from the alternative model | NOT RUN |
| Native/CI for this new Python model | NOT RUN |
| Stage 2 | OPEN |

## Conclusion and NEXT

The existing production algorithm remains budget-refused at p82; the historical real p520 witness also refused without five-field proof. No production defect is inferred from these refusals.

A separate in-place exact insertion algorithm computes the canonical rank prefix through p520 with 3,713,186 DP-cell writes under its own unchanged numeric 5,000,000 allowance. This is a promising test-only optimization candidate, but its DP-write metric is not yet proven equivalent to the production cell-accounting contract and does not produce a five-field date.

NEXT: port this recurrence into a Clojure **test-only** prototype, compare it against this Python oracle and the gap-convolution oracle on the same small and canonical cases, and explicitly measure its DP-cell writes. Keep the production API and both existing budgets unchanged. Do not call it a production PASS or accept Stage 2 until a source-reviewed accounting correspondence and an independent five-field witness exist. No duplicate dispatch; future QA-only commits use `[skip ci]`.
