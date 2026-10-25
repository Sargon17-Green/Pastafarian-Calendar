# Etap 55 — exact cumulative first letter and binary rank selection

**Branch**: `MATLAB+Polski`. **State**: two native experiments
pending; not Stage 55 acceptance. Production, main and test-only
`normative_oracle` are unchanged.

## Mathematics

Let `C_s(t)` be the exact cardinality of all legally completed nonempty
suffixes from reachable frontier `s` whose **first month ID is <=t**.
The first-letter blocks are a partition, so `C_s(t)` is nondecreasing
with `C_s(0)=0` and `C_s(K)=F(s)`.

The established insertion recurrence for the new largest month `j`
with multiplicity `m>=2` uses its first position `p` and exactly
`binom(Nnew-p-1,m-2)` placements for its interior copies.
Its final copy is necessarily at position `Nnew`. If `p>1`, the
first symbol stays the previous suffix's first symbol. At `p=1`,
the first symbol becomes `j`, which can contribute to `C_s(t)`
only if `j<=t` and `j<=openedUpTo+1` at this frontier.
The prior-largest first-position prefix constraint still enforces
the future opening order whenever `j>openedUpTo+1`.
When `m=1`, month `j` is appended as the final symbol and the
earlier first label remains unchanged.

Thus a **single** BigInt first-position prefix array, rather than
one array per possible first label, computes each cumulative bound
exactly. For a candidate lexical next month `j`, all its completions
have global interval `(C_s(j-1), C_s(j)]`. Binary search finds the
unique interval containing the exact one-based rank, then updates
the residual rank and remaining multiplicity vector. A previous
child's completion count becomes the next parent's count; it is
not an untrusted estimate.

This reduces the number of first-letter threshold recurrences at a
branch from linear to logarithmic in the number of choices, at the cost
of computing one recurrence for each queried bound. It does **not**
promise that the full 4244-day rank can finish within a CI timeout.

## Native verification

`run_stage55_binary_first_letter_tests` independently enumerates
all legal suffixes of four small families from all reachable states.
At each nonterminal state it checks every threshold `0..K`, all
one-based ranks, complete suffixes and split/resume rank invariants.
It also compares exact partial-rank intervals to the previously
separately verified reference route.

`run_stage55_real_year_binary_four` is a bounded, independent
performance pilot at the true 45-month initial unopened state with
the fixed 6765-digit rank `10^6764`. It checks the first four month
IDs against the native-verified eight-day joint method and separately
recounts the complete 4240-day child suffix with a distinct exact
first-endpoint recurrence. The result is an experiment, not production
or five-field oracle acceptance.

The following markers must appear in native logs before PASS:
`STAGE_55_BINARY_FIRST_LETTER_BRUTE_PASS`,
`STAGE_55_BINARY_FIRST_LETTER_VALIDATION_PASS`,
`STAGE_55_BINARY_FIRST_LETTER_EXPERIMENTAL_PASS`,
`STAGE_55_BINARY_REAL_YEAR_FOUR_UNRANK_PASS`,
`STAGE_55_BINARY_REAL_YEAR_FOUR_CHILD_COUNT_PASS`,
`STAGE_55_BINARY_REAL_YEAR_FOUR_EXPERIMENTAL_PASS`.

## Existing confirmed progress / still blocked

[Eight-day native success](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40134999401)
at commit `31d805144f5c0daae6201c1b92156667c5917e0a`:
eight unopened-year days, 4236 remaining, day-four rank inverse,
independent 4236-day count, portable JSON checkpoint and all final
experiment markers PASS. The eight-day unrank took 4478.521 seconds;
the four-day inverse took another 1587.983 seconds.

[Final audit](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40134999411)
is still FAIL due to runner shutdown during the historic production
`WholeMonthWeavingFamily` state-layer DAG after a logged day-16
32768-state frontier. There is **no** complete native five-field
production versus normative-oracle result. Do not close Stage 55:
`LAST_COMPLETED_STAGE=54`.
