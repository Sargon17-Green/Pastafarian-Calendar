# Stage1 normative interleaving: explicit coverage boundary

PROJECT_ID: PC-BRANCH-FORTRAN-ENGLISH
Baseline: Fortran+English @ 3ed11b0a4dc0ea83b0c5d4bcbd01e99a9da68923.

Previous run 44892813372 completed 11/11 successful jobs. Those checks include
seven original direct-date results, 14 original calculation contexts / 70 fields,
four original boundary-neighbor dates / 20 fields, and 58 full-mode assertions.
The 45-month 4244-day candidate projection is not an original end-to-end
materialization of a confirmed actual normative 45-month year. Differential
agreement with Python also does not independently prove the specification.

## New gate (QA only)

- Input: original Fortran normative_calendar_date, calculation day -15055671,
  exact Python reference blob d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53.
- Select four dispersed distinct month IDs from year 5000 as actually
  constructed by that reference; take first and last available occurrences,
  skipping known fixed-date QA targets. Record the actual month count and year
  length; do not assume the actual year has 45 months.
- Require sound month counts/length frequencies, eight novel distinct dates,
  exactly five output fields/date, matching input framing, no failures/timeouts,
  8/8 case equality and 40/40 field equality.
- Fortran: per-case 65s wall-clock timeout and 1GiB memory; CI job 18min.
  Retain log, self-test output, and JSON record with exact dates and fields.
- Successful execution proves only those eight selected original-date
  comparisons. It is not full Stage1 acceptance.

## Remaining acceptance gap

Run 44937396296 on SHA
`d5893a6e6820555fee77fa5f006c1647a2c4febb` completed 14/14 jobs. Its
QA-only full-year artifact compared the actual 45-month / 4,244-day year
against the SHA-pinned Python reference: 4,244/4,244 month IDs and
21,220/21,220 date fields, with no discrepancies. This establishes the
actual year structure and full-year build-plus-projection comparison; it
does not establish 4,244 calls to the public entry point.

The rank-boundary extension below is a new QA gate and is not evidence until
a completed run on its own SHA has matching job logs and artifact. Even if
it passes, full Stage1 acceptance remains open: the public
`normative_calendar_date` entry point has not been executed for every day
of the 4,244-day year, and differential agreement with Python does not by
itself independently prove the specification. The eight selected
public-entry comparisons are bounded witnesses, not an exhaustive
substitute. No Stage2, main change, merge or publication.


## QA-only extension: actual 45-month weaving rank boundaries

Input remains the original Fortran year 5000 built from foundation day
-15055671 and the independently pinned Python reference blob
`d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53`.

The added gate must:

- Reconstruct the actual 45-month year with the original Fortran
  `build_year_structure`; do not synthesize month lengths.
- Compute the exact weaving count with original Fortran `count_weavings`
  and compare its full decimal representation with the independent Python
  `MonthWeavingFamily.count()`.
- Execute original Fortran `unrank_weaving` at ranks 1, 2, N-1 and N,
  passing the exact total as the count hint; independently compute all four
  expected sequences with the pinned Python `MonthWeavingFamily.unrank1()`.
- Compare all 4,244 month IDs for each rank, not only hashes or prefixes.
- Check month frequencies and strict first-occurrence and last-occurrence
  ordering for the actual selected weave and all four boundary sequences.
- Retain the full-year projection, exact 21,220 date-field comparison,
  explicit QA-only status, self-test and artifact.

The four-rank boundary gate and five ordering checks are QA evidence only.
They do not call the public `normative_calendar_date` entry point 4,244
times: the full-year probe still builds the original year once and calls
`project_calendar_date` for each day. The eight selected public-entry
differential cases remain a separate, narrower end-to-end check. No Stage1
acceptance, Stage2 transition, main change, merge or publication follows
from these QA results alone.
