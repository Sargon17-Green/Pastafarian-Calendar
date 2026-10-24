# Stage 55 — real year 5000: eight-day arbitrary interior rank, full unopened frontier

**Branch**: `MATLAB+Polski`. **Native CI: PENDING**; no completion
claim until all markers are verified. Production, main, normative_oracle,
and the 54 completed stages remain unchanged.

## Scope

The real production-selected year has 45 months and 4244 total days.
All months are **unopened** in the initial state `R=L, opened=0, closed=0`.
The selected true interior rank is `10^6764`, 6765 decimal digits.

The test advances four two-day chunks from the actual unopened state
using `unrankGeneralWeaveSuffixChunkLazyJoint`. Each new chunk recounts
its incoming parent independently from the preceding chunk's stored
child count, checking equality. MATLAB prints explicit progress after
days 2, 4, 6 and 8, with seconds and frontier indices; partial
progress never counts as experiment PASS.

Then the independent `rankGeneralWeavePrefix` computes the exact
lexicographic interval for the first four days and checks that both
rank residual and block cardinality agree with the saved day-4
cursor. A separate `countWholeWeavingSuffixByFirstEndpoint` recounts
all 4236-day completions at the day-8 frontier. A portable JSON
checkpoint is restored with independent count verification.

## Native evidence required

- `STAGE_55_REAL_YEAR_UNOPENED_8_PROGRESS` at days 2, 4, 6 and 8.
- `STAGE_55_REAL_YEAR_UNOPENED_8_UNRANK_PASS`
- `STAGE_55_REAL_YEAR_UNOPENED_8_FIRST4_INVERSE_PASS`
- `STAGE_55_REAL_YEAR_UNOPENED_8_INDEPENDENT_COUNT_PASS`
- `STAGE_55_REAL_YEAR_UNOPENED_8_CHECKPOINT_PASS`
- `STAGE_55_REAL_YEAR_UNOPENED_8_EXPERIMENTAL_PASS`

The historic three-day native run took 817 seconds plus another
191 seconds for independent recount; this experiment may require
substantial CI time. It is not the same as the verified 1024-day
**all-open** suffix experiment and does not yet prove arbitrary
rank unranking through the entire 4244-day year.

## Separate Stage 55 blocking issue

Run [40126272295](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40126272295)
terminated at the preexisting production `WholeMonthWeavingFamily`
forward DAG. Its native diagnostic trace reached day 16 with
32768 states after 13.216 seconds from DP start. The runner then
received a shutdown signal before further completed layer logs;
the cause of shutdown is not separately proven. The full
five-field comparison against `normative_oracle` did not execute.
This new experiment does not replace or bypass that acceptance gate.
`LAST_COMPLETED_STAGE=54`.
