# Issue #29 / v188 — source-only same-stream conditional month-weave fork

**Not a native original-date test.** This is a synthetic component-level differential extracted from the actual pinned original sources, with NO calls/imports of original F(c,t), Calendar_Date, Sauce, gate generation, or native converters.

## Locked original sources
- Ada original a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72, normative_oracle.adb blob 923733d4f8face03586aee304640bf7540c28b4c, month_weaving.adb blob 9b02c62dfbc7d8b3b532aba8cd9f1ad0f8b28fef.
- Python original 0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4, normative_reference.py blob d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53.
- Immutable corrected Ada base: 1160096aa847c54cbef27c232771ce1549d7ba8f.

## Constructed admissible upstream state, not the historical state

L=713 days, six synthetic cutlets with gate gaps (503,42,42,42,42,42), six month lengths (123,123,123,123,123,98), target at offset0=502 (so day 503 in first cutlet). All structural numeric contract constraints are satisfied. **No claim** original deterministic Sauce produced these gate gaps, month lengths or stream.

Apply exactly the **same** chosen month lengths, first answer and direction to both historical algorithms:
- Ada: fixed opening rail, pick per-index ticket from cyclic answer stream using Choose_Rank_Short, map ticket into remaining interior month multiplicities, fixed closing rail.
- Python: build globally legal ordered-first-and-last family using the weighted H-table and state-completion count, select its lexicographic rank from the same stream using wide-radix rejection, and unrank that single global rank.

For six streams (first=1, floor(M/2), M, direction ±1; M=2^127−1), **6/6 different full weaves** and **6/6 different day-in-month counts at offset0=502**. This shows that the structural weave algorithm alone is a *sufficient possible mechanism* for different fifth fields when the upstream year, month lengths, offset, stream and month-name assignment are all held fixed. In the stream first=1, step=+1, selected Ada chronological month ID 3/day 91 versus Python chronological ID 1/day 85. The first differing weave token occurs at offset0=1. The globally legal Python family count is **1,799 bits** for these lengths.

**Independent small-domain validation:** a fresh brute recursive generator exhaustively enumerated 1,356 globally legal multiset words across (4,4), (4,5), (4,4,4); every rank and complete decoded output matched the separately coded H-table unrank implementation. Fixed-rail Ada words satisfy exact multiplicity/opening/closing checks. This is not an independent full-size algorithmic proof, and source-derived algorithms may share assumptions.

## Strong limit on causal conclusion

This is **NOT** a replay of source originals for c=t=-15055671. The historical terminals were Ada [5000,10,503,30,52] vs Python [5000,10,503,20,56]. Field 4 is canonical *month-name* index, not chronological month ID. The historical internal open/close boundaries, Source Sauce, month lengths, rank, weave prefix, offset and names are unavailable. This demonstration **does not** prove that historic divergence arose from the month-weave algorithm, and the synthetic values 91/85 do NOT equal observed 52/56. Issue #29 stays OPEN; original full-year approvals 0/10,000; original converter halt remains.

Run: python3 -B qa/issue29/v188_shared_stream_fork.py. GitHub Actions runs only Python source-level code and preserves output and hashes, with 42 original native-dispatch gates verified. No production edits, no native converter jobs, no merge.
