# Canonical year-5000 weaving rank: independent selection bridge

PROJECT_ID: PC-BRANCH-CHAPEL-UKRAINIAN
Branch: Chapel+Українська-мова
Scope: **research only**. No normative-code changes, Stage 6 claim, merge, or release.

## Evidenced coverage gap

In completed run 44928123463 on
`165252728529a9db747e1ef707b56921ff840398`, independent Native
4244-symbol witnesses were verified for ranks floor(R/2), floor(R/2)-1
and floor(R/2)+1 (two directions). They do **not** establish equality at
the real Year 5000 selection rank. The legacy year-boundary GateOracle
calls the exponential `chooseMonthWeaving` counter and timed out at
`STRUCTURE_MONTH_WEAVING_BEGIN` (exit 124, 180 seconds); inconclusive.

The actual normative contract in `src/NormativeOracle.chpl` is:
`r=sauce(FOUNDATION_DAY, year.openGateDay+1)`;
`stream=askBowl(r,4,SEAL_MONTH_WEAVING)`;
`rank1=chooseRank(stream, WeavingCounter.countAll())`;
`monthWeaving=WeavingCounter.unrank1(rank1)`.
The last two operations were not observed to finish for Year 5000.

## Bounded new test

`test/weaving_canonical_selected_rank.chpl` reads an independently
computed, SHA-locked R as input, constructs the canonical Year 5000
sauce/month lengths, and invokes **actual** normative `askBowl` and
`chooseRank`, without ever calling the exponential counter.

`test/weaving_canonical_rank_bridge.py` independently recomputes the
selected rank from the emitted first stream value and +/-1 direction
using positional base-M arithmetic and a **closed-form** rejection
transition, then requires exact rank equality. Input: source-fresh
Chapel 2.10.0, full-year lengths, R (22470 bits), exact root digest
925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da.
Output: SHA-tied JSON, Native transcript, compilation diagnostics, binary
hash, resource observations and independent selected-rank equality.
Bounds: Native compile <=150s; Native execution <=90s; full source SHA
and all fields must agree. A timeout is not PASS.

Synthetic tests compare the closed-form rejection algorithm against
an independent slow stepwise algorithm for moduli 5, 7 and 11 across
both directions and spaces smaller/larger than each modulus. These
tests are **static/Python only**, not Native verification.

## Acceptance boundaries

Successful bridge proves the canonical normative **rank-selection**
arithmetic is consistent with an independent reference at one real
full-year input. It does NOT show that the exponential normative
`WeavingCounter.unrank1` completes, matches the research algorithm,
or that `calendarDate` correctly maps each day. It also does not
test a full 4244-symbol rank/unrank at the selected canonical rank.
These remain separate coverage gaps for later bounded research.

Until completed CI log + exact SHA + artifact prove the bridge:
`BRIDGE=NOT_ACCEPTED`. Even if passed, `STAGE6=NOT_ACCEPTED`.
