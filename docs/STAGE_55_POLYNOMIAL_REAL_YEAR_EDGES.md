# Stage 55 — four complete 4244-day exact whole-year ranks

**Native status**: PENDING. Stage 55 OPEN. Changes affect only
`WholeMonthWeavingFamilyPolynomial`, an experimental candidate;
historic `WholeMonthWeavingFamily`, its production wrapper, main,
and `normative_oracle` are unchanged.

## Verified foundation

[Native equivalence run 40192007813](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40192007813)
at `0c23ec8f675c2dc34f9dad21395c28464351cd9a`
passed: nine bounded families, all 1437 exact lexical ranks and
5748 partial-prefix cursor assertions against historic production
DAG, with input validation checks.

## Complete-word edge-rank optimization

The newly verified polynomial family still needs too many BigInt
suffix recurrences to decode arbitrary **interior** one-based ranks.
For exactly four special full-family ranks `1`, `2`, `F-1`,
and `F`, existing separately native-verified
`unrankWholeWeavingNearEdge` constructs the full legal word with
exact greedy or adjacent-weave operations in polynomial work.
`F` is the exact cached `BigInt` count, not an estimate.
Independent month multiplicity and opening/closing invariants are
checked on every complete result before it is returned.

The experimental-only `itemAt1` dispatch recognizes those
special ranks after checking the one-based exact input boundary.
Every other rank still takes the general adjoint route unchanged.
`prefixAt1` is unchanged, preserving its full exact-cursor checks
for all ranks. The small exhaustive differential is rerun against
the historic family for all 1437 ranks, including each edge rank.

The real-year test uses the true verified Year 5000 length vector of
45 months and 4244 days. The constructor independently counts the
whole exact family, confirms a 6765-digit count and that the large
rank `10^6764` is valid, then materializes ALL FOUR **complete**
4244-day ranked weavings through the candidate. Every word must
pass the full-length multiplicity and strict month-opening/closing
order invariants plus the existing independently obtained weighted
and squared complete-word regression moments. The first and last
neighboring ranks are checked again through the separately verified
`adjacentWholeMonthWeaving` operation. The four distinct words
must be in increasing lexicographic order.

Required MATLAB-native pass markers:
`STAGE_55_POLYNOMIAL_REAL_YEAR_COUNT_PASS`,
four `STAGE_55_POLYNOMIAL_REAL_YEAR_EDGE_PASS` markers,
`STAGE_55_POLYNOMIAL_REAL_YEAR_FOUR_FULL_WORDS_PASS`, and
`STAGE_55_POLYNOMIAL_REAL_YEAR_EDGE_EXPERIMENTAL_PASS`.

**Limitations:** A full-length result at the four boundary ranks
does not establish reasonable runtime for the other astronomical
number of ranks. It is **not** the five-field production-vs-
`normative_oracle` differential required for Stage 55 acceptance.
The historic production DAG cannot scale to the full year; its
unchanged final-audit workflow remains a genuine blocker.
`LAST_COMPLETED_STAGE=54`.
