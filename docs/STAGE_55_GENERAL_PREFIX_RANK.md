# Stage 55 — exact inverse rank intervals for arbitrary opening frontiers

**Branch:** `MATLAB+Polski` · **Status:** experimental, unsealed. Production,
`main`, and the normative oracle are unchanged.

## Contract

`pastafari.rankGeneralWeavePrefix(L,R,o,c,prefix,method)` calculates
the contiguous BigInt 1-based interval `[lo,hi]` of all legal suffix
weavings beginning with the specified prefix. Unlike the earlier
all-open rank-inverse tool, this accepts **any reachable frontier**:
closed months 1..c have zero remaining occurrences, opened and
unfinished months c+1..o have 1..L(i)-1 remaining occurrences,
and unopened months o+1..K have their full original lengths L(i).

Both first-occurrence and last-occurrence order matter. On choosing
month i with old remainder n: it opens a new month iff n=L(i),
and closes a month iff n=1. New openings must use i=o+1; new
closures must use i=c+1. Every selected prefix letter must belong
to a positive exact next-letter completion block.

## Exact interval recurrence and proof

Each legal next month i partitions the parent's complete suffix
language into the exact disjoint set of words whose first letter
is i. Let B_i be the exact cardinality of this language.

Start with `lo=1`, the parent complete count `F`.
For a selected legal letter j, update:

```text
lo    := lo + sum_{i<j} B_i
F     := B_j
state := child(state,j)
hi    := lo + F - 1
```

The children form an exhaustive disjoint partition in ascending
lexical order. Consequently all completions sharing the new
prefix form the contiguous block `[lo,hi]` and its exact width
is F. Induction on prefix length proves every returned interval.
A terminal full word yields one rank; the empty prefix returns
the complete interval `[1,F(initial)]`.

The default `joint` algorithm uses the independently native-tested
single-pass first-letter exact DP when at least two months remain
unopened, exact endpoint factorization when at most one month
remains unopened, and the exact common-denominator algebra when
all months are open. The `reference` algorithm computes child
cardinalities separately via the independent first-endpoint DP.
All counts are `pastafari.BigInt`, and every step checks that
the sum of legal child blocks equals the parent exactly.

## Native verification gates

Commit `d0af9a874cdaaa7d48e1266a6cb103530e58b988`
introduces two independent CI workflows, deliberately separated
to prevent one large 4244-day check from delaying all small tests.

1. [Small legal-frontier rank oracle, run 39999374686](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39999374686):
   an independent complete lexical word enumerator, the historical
   `WholeMonthWeavingFamily` count/itemAt1, both rank-inverse modes,
   all selected depths, invalid prefix rejection and a reachable
   partially opened mid-frontier differential.
2. [Real year-5000 three-day inverse, run 39999374649](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39999374649):
   the **actual** 45-month/4244-day vector selected by production;
   interior rank `10^6764`; prefix `[1,2,3]` previously unranked
   natively in run 39945747252; exact opening state and 4241 remaining
   days; full 6765-digit original count witness from independent
   production-length dual-counter PASS.

The corrected small native test was independently completed in
[MATLAB R2026a run 40124989834](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40124989834),
commit `e58088b13e8d7abbf4847d8d28bb53c45264a3d0`: **PASS**.
Its actual log confirms **9 families, 1546 exact prefix rank interval
checks**, input validation PASS, and separately a reachable
partially-open mid-frontier differential PASS. The initial native
run 39999374686 failed before evaluating the algorithm because the
test indexed a non-existent second day in a one-day family; the
probe depths were clipped to the actual family day count.

## Limitations

This is an **inverse rank interval for a supplied prefix**, not yet a
fast way to find the full 4244-day word for an arbitrary interior rank.
It incurs expensive joint BigInt DP counts at branching days before
the all-open phase. The final Stage55 requirement additionally needs
an end-to-end five-component Pastafarian date differential against
`normative_oracle`. Preserve `LAST_COMPLETED_STAGE=54`,
`STAGE_55_COMPLETE=NO`; do not merge into `main`.
