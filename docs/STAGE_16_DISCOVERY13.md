# Stage16 DISCOVERY13 — nonadjacent sparse-window real-date differential (open)

## Predecessor and motivation
Stage15 accepted on run 41350147495 / SHA a1dd0cd7a6a26d704aaa9e81cb93b8b8eef81463, 17/17 jobs, 53 independent-reference Python selfchecks, 51 GNAT Native domain/repeat assertions, 45 exact five-field comparisons. Stage15 sampled only offsets {-1,0,1}. The new test deliberately samples nonadjacent offsets and crosses multiple target/calculation-day differences, without assuming date monotonicity or inventing a failure.

## Contract, inputs and oracle
C = T = {Foundation_Day - 31, Foundation_Day - 7, Foundation_Day, Foundation_Day + 7, Foundation_Day + 31}. Iterate 25 ordered pairs (C,T) in row-major order, and call actual public Ada Calendar_Date(C,T). Each observer record contains the exact two inputs and five output scalars (year, canonical cutlet, day in cutlet, canonical month, day in month).

The expected five scalars come from Stage14's own independently written Python source-specification-derived numerical reference. Stage16 extends its *input coverage*; this is not a new independent algorithm or proof. Native result log is never used to construct Python expected values. Domain constraints: year 4999..5001, cutlet 1..17, cutlet-day 1..5778, month 1..47, month-day 1..123.

## Measurable checks
Python preflight: 25x5=125 domain checks, five center-pair established goldens, five same-day repeated calculations => STAGE16_INDEPENDENT_MATRIX_SELFTEST_ASSERTIONS=135. Ada: 25x5=125 domain checks, center year-5000 anchor, center repeat on all five fields => STAGE16_NATIVE_DOMAIN_REPEAT_ASSERTIONS=131. Strict comparator: exactly 25 unique ordered (C,T) records and 25x5=125 scalar exact differential comparisons => STAGE16_REAL_FIVEFIELD_SCALARS=125. Missing, duplicate, unexpected or malformed rows and mismatch each fail with explicit diagnostics.

## Bound and acceptance
GNAT13 compile/bind/link; Python each 60-second cap; Ada observer 600-second cap and job 15-minute outer timeout. Accept only completed/success on the same exact SHA for verify and native-stage16-sparse-window, plus exact three markers. Source-only Python checks cannot establish GNAT PASS. No main/merge, production change or claim about all possible dates.
