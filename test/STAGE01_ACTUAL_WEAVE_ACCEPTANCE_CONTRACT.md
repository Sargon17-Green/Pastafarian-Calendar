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

An actual *45-month* normative example still requires an independently
justified source of expected structure and all 45 month IDs/lengths, first-
and last-occurrence ordering, rank boundary coverage, and end-to-end dates
across the relevant year, including runtime bounds. A synthetic 45-month
structure, eight witness dates, and a passing CI job cannot be substituted
for that contract. No Stage2, main change, merge or publication.
