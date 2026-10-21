# Exact month weaving: experimental endpoint recurrence

Native run **39552537262** proved the old full-state DAG grows too quickly:
year 5000, 4244 days, 45 months, 32768 distinct states at day 16,
then the runner received a shutdown signal. This is no oracle mismatch.
Stages 1–53 and static Stage 54 were PASS in that run.

## State reduction proof (for counting only)

For a legally formed suffix, let **c** be the last closed month and
**o** be the last opened month. Its remaining copies are
r_(c+1), …, r_K. Month IDs c+1,…,o were opened earlier and therefore
need no further first-occurrence constraint; months o+1,…,K must first
appear in increasing ID order. All remaining months must have last
occurrences in increasing ID order.

Build a word by inserting r_i identical copies of month i into each
word for the preceding remaining IDs. Let N be the length of that old
word, f and l the first and last positions of the old largest ID, and
p and q the first and last positions of the new largest ID.

- Last-occurrence order: q >= l + r_i, because exactly r_i-1 new
  letters occur before position q.
- First-occurrence order, only when i > o+1: p > f, because no new
  letter occurs before p.
- For r_i >= 2, the r_i-2 interior copies occupy any of q-p-1 positions,
  giving C(q-p-1, r_i-2) choices.
- For r_i = 1, the sole copy satisfies p=q.

Let DP_i(p,q) be the number of exact words whose largest ID first
appears at p and last appears at q. Then for r_i >= 2:

    DP_i(p,q) = C(q-p-1,r_i-2) *
        SUM DP_(i-1)(f,l)
        over l<=q-r_i, and f<p if first-order is required.

If first-order is not required, there is no bound on f. For r_i=1
only p=q is legal and the same sum has l<=p-1. The sum is evaluated
using a two-dimensional cumulative sum, not enumeration of each
remaining-multiplicity vector.

The base case of one remaining month is one word, with first position
1 and last position r_(c+1). The empty suffix also has one completion.
Consequently the recurrence counts every and only legal suffix word
once, preserving distinct lexicographic words and arbitrary exact
integer counts.

This recurrence uses O(K*T*T) arithmetic for T remaining days and
O(T*T) working entries, rather than storing an exponential set of
remaining-multiplicity states. It does **not yet** provide practical
rank/unrank performance: retrieving a completion count for each child
on each of 4244 positions is a separate optimization problem.

## Independent validation gates

- Python exhaustive small-state reference checked all reachable suffix
  states for every length vector with 1..3 months and each length 1..3:
  PASS. Python is a design check, **not** MATLAB native evidence.
- MATLAB experimental implementation:
  `src/+pastafari/countWholeWeavingSuffixByEndpoints.m`.
- MATLAB tests:
  `tests/run_stage55_endpoint_counter_tests.m`, checking exact totals,
  invalid input, and reachable suffixes against a separate exhaustive
  recursive test oracle. Native MATLAB R2026a Update 5 CI run
  [39603046056](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39603046056)
  **PASS** at commit `801bc516dc517724fb912405e7e610b304a234a6`.
  Verified exact totals in 7 cases, **all 41 reachable small suffix states**
  in three additional families, and strict invalid-input handling.
  Observed markers: `STAGE_55_ENDPOINT_TOTALS_PASS CASES=7`,
  `STAGE_55_ENDPOINT_SUFFIX_EXHAUSTIVE_PASS STATES=41`,
  `STAGE_55_ENDPOINT_VALIDATION_PASS`,
  `STAGE_55_ENDPOINT_EXPERIMENTAL_PASS`.
  These are genuine native PASS results for the experimental *counter*,
  not for big-input runtime or production rank/unrank.
- Existing `WholeMonthWeavingFamily` remains unchanged and continues
  to define the published semantics.

Do not mark Stage 55 or the heavy differential PASS until both the
actual production calendar and independent normative oracle have
completed and their complete tuples matched.

## Native rank/unrank experiment — 2026-10-21

At commit `62630272b1e1b12b68d3a4d40229c1e87865ff32`, GitHub Actions
[run 39609688589](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39609688589)
completed with native MATLAB R2026a **PASS**. Markers:

- `STAGE_55_ENDPOINT_UNRANK_BRUTE_PASS CASES=9 RANKS=120`
- `STAGE_55_ENDPOINT_UNRANK_OLD_DAG_DIFFERENTIAL_PASS`
- `STAGE_55_ENDPOINT_UNRANK_VALIDATION_PASS`
- `STAGE_55_ENDPOINT_COUNT_BENCH DAYS=60 MONTHS=6 SECONDS=0.214 DIGITS=37`
- `STAGE_55_ENDPOINT_COUNT_BENCH DAYS=160 MONTHS=8 SECONDS=2.344 DIGITS=129`
- `STAGE_55_ENDPOINT_UNRANK_EXPERIMENTAL_PASS`

These are real but bounded CPU measurements, not a performance
extrapolation to 4,244 days. The experimental lexicographic unrank
calls the exact endpoint counter for every candidate suffix. Correctness
on small cases is established; this unoptimized repeated-count strategy
is likely too expensive for the largest full-year input. A future
incremental/rank-oriented method must be demonstrated separately before
production integration.

Next experiment expands to **every rank** of multiple small families,
including all 1301 ranks of [4,4,4] and four-/five-month cases. Its
PASS must be verified independently before marking that work complete.

GitHub native Stage 55 push triggering intentionally excludes only
the two experimental source files and their dedicated unit tests, to
avoid repeated expensive known-failing full-year runs when iterating on
an unintegrated experiment. The complete native Stage 55 workflow still
runs for production and full-stage test modifications and remains
manually dispatchable; the heavy test has not been skipped or
weakened.
