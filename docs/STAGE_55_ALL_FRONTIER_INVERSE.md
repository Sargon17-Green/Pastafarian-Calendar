# Stage 55 — complete rank/unrank from every small reachable frontier

**Branch:** `MATLAB+Polski`. **Status:** native CI **PASS** (experimental).
No change to `main`, canonical calendar engine, or `normative_oracle`.

## Independently enumerated oracle

`tests/run_stage55_all_frontier_inverse_tests.m` generates **all reachable**
opening and closing frontier states by direct legal-move DFS, deduplicating
equivalent residual states. It then independently enumerates all legal suffix
words at each frontier in ascending lexical order. Families:
`[1 2 2]`, `[2 3 2]`, `[3 2 3]`, `[2 2 2 2]`.

For **every** complete legal suffix rank, it compares three exact algorithms:
`unrankGeneralWeaveSuffixChunk` (`reference`, `joint`) and
`unrankGeneralWeaveSuffixChunkLazyJoint`. For selected depths including
the empty and terminal prefixes, each inverse rank interval is compared
against enumerated lexical positions with both `joint` and `reference`
methods. Every frontier is also tested with column-shaped inputs. An
unopened/partially opened cursor undergoes independently recounted JSON
restoration.

## Isolated defect correction

The experimental `unrankGeneralWeaveSuffixChunk` previously compared
`remaining <= L` before normalizing the vectors to a common orientation.
In MATLAB a K-by-1 column compared with a 1-by-K row uses implicit expansion
and can produce a K-by-K result. Compare matching column representations
instead. This is a representation/validation correction only, not a change
to legal weaving, ranking formulas, or production engine.

## Acceptance

Native MATLAB R2026a [run 40126272380](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40126272380) finished success and its log contains:

- `STAGE_55_ALL_FRONTIER_INVERSE_BRUTE_PASS`
- `STAGE_55_ALL_FRONTIER_PARTIAL_JSON_PASS`
- `STAGE_55_ALL_FRONTIER_INVERSE_EXPERIMENTAL_PASS`

Native log evidence: four families, **53 reachable frontiers**, **208 complete inversions**, **1582 exact prefix intervals**, and **53 column orientation checks**. Every listed marker is present.
The separate 1024-day all-open suffix test, initial unopened 4244-day
arbitrary-rank decoding, and five-field production/`normative_oracle`
differential remain distinct requirements. Preserve
`LAST_COMPLETED_STAGE=54` and the open Stage 55 acceptance gate.
