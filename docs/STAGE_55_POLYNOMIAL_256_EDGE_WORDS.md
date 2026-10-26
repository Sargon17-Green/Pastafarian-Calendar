# Stage 55 — bounded near-edge window with 256 full year-5000 words

**Experimental only.** This does not replace historic production
`WholeMonthWeavingFamily`, its wrapper, or `normative_oracle`.
`LAST_COMPLETED_STAGE=54`, `STAGE_55_COMPLETE=NO_AWAITING_NATIVE_FINAL_AUDIT`.

The experimental `WholeMonthWeavingFamilyPolynomial.itemAt1`
now implements exact near-edge ranks `1..min(128,F)` and
`max(1,F-127)..F` by reusing the separately native-verified
`unrankWholeWeavingNearEdge` route. Only these ranks bypass the
general expensive adjoint recurrence; arbitrary interior ranks
remain unchanged. Every complete word undergoes the same
independent month multiplicity and first/last occurrence checks.

The new `edgeWindowAt1(maxOffset,'first'|'last')` method produces
rows `1..d+1` (or `F..F-d` in reverse order) in one forward/backward
walk from the legal extremal word. Every word is a COMPLETE legal
weaving, never a truncated prefix or approximate rank. This
also avoids `O(d^2)` replays when enumerating an entire adjacent
edge window. `maxOffset` is deliberately capped at 127; requests
outside rank cardinality, invalid distances, and unsupported sides
are rejected.

The independent real-year experiment verifies the genuine 45-month,
4244-day Year 5000 length vector, two windows of 128 full words
each and strict adjacency/order at each step. It additionally
checks independently obtained full-word weighted and squared
witnesses at offsets `0,1,2,7,31,127` on BOTH edges, compares
selected one-shot `itemAt1` outputs against their window rows,
and checks small/invalid cardinality behavior.

Native full-year four-word baseline:
[run 40235268884](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40235268884)
PASS, 6765-digit exact count computed in 144.955 seconds, complete
word construction at boundary ranks in 0.008..0.023 seconds.
Small historic DAG differential:
[run 40235268862](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40235268862)
PASS 1437 one-based ranks + 5748 partial cursor cases.

Full Stage 55 production/oracle audit still FAIL:
[run 40235268891](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40235268891)
reported 32768 historic DAG states at day 16 then runner shutdown.
No full five-field native oracle differential exists. The 256-word
experiment must not be confused with one.
