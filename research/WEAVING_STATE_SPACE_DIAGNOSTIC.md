# DISCOVERY03 — month-weaving state growth (bounded, evidence-based)

## Source and scope

GitHub Actions run [41409195449](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41409195449) on Chapel branch `Chapel+Українська-мова`, SHA `e3e5f2e1ef38207d59005ce8bababe4c83910bfa`, completed with `native-stage01=failure` and `verify=success`. The year-boundary probe compiled and printed 45 positive month lengths summing to 4,244 days. It reached `STRUCTURE_MONTH_WEAVING_BEGIN` and timed out at 180 s (exit 124). No numerical discrepancy or third historical Legacy defect has been established. Stage 1–5: 318/318; DISCOVERY03: 2,518 checks / zero failures; both cache-reconfiguration regressions passed.

## Proven state-space bounds

Let `L[1..m]` be the positive month lengths, and a `WeavingCounter` memo state contain `remaining[1..m]`, `openedUpTo`, and `closedUpTo`. The current recursive `countState` uses a string key containing all of these quantities.

A conservative coordinatewise **upper bound** on the number of distinct residual vectors is

`U = product(L[i] + 1)`.

For any lengths `L[i] >= 2`, there is also a constructive **lower bound** on distinct reachable memo states:

`B = product(L[i] - 1)`.

Proof: For each residual vector `r[i] in {1, ..., L[i]-1}`, emit the first occurrence of months 1, 2, ..., m in order. Then emit `L[i]-r[i]-1` additional occurrences of each month i, in any fixed month order. Every opening is legal. No month ever closes because all residuals remain at least 1. The resulting state has `openedUpTo=m`, `closedUpTo=0`, and precisely `remaining=r`. Distinct residual vectors give distinct reachable states, proving the bound without traversing the full graph.

For the exact 45-month fixture from this run:

- `sum(L) = 4244`.
- `B = 3991035906815373105625242639483993147254913074560959521179023099422632606433280000000000` (88 decimal digits).
- `U = 11830849694409842033801632685168653766464341042891367133822803767174129299698483200000000` (89 decimal digits).

The bound concerns *reachable states*, not measured allocations, execution counts, or the number of legal complete weavings. It shows that exhaustive memoization is structurally intractable at this fixture size, not simply that a 180-second timeout was too short. It does not prove any incorrect output.

## Bounded independent verification

Run `python3 test/weaving_reachability_oracle.py` (standard library only). The script reproduces the fixture sum and two exact products, checks *every* residual vector for four small cases (63 distinct constructive witnesses), and verifies three further extremal/alternating witnesses for the full 45-month fixture: **66/66 checks**. Each constructed prefix is replayed against independently coded opening/closing rules, and no full-size state graph is enumerated.

The Chapel year-boundary probe now records `YEAR_BOUNDARY_WEAVING_GUARANTEED_REACHABLE_STATES` immediately before the existing expensive call. This is diagnostic-only and does not change acceptance criteria, rank/unrank behavior or production code. `YEAR_BOUNDARY_PROBE_RESULT=PASS` remains unavailable unless all existing checks genuinely finish.

## Next engineering contract

Avoid increasing the timeout or memory limit as a purported repair. Design a mathematically exact counting/unranking alternative to materializing one memo entry per reachable residual state. Specify (a) five-component date preservation, (b) independent small-case enumeration oracles including unequal lengths and boundary ranks, (c) exact bigint arithmetic, (d) memory/runtime bounds for 45 months / 4,244 days, and (e) a bounded Native differential suite. Do not replace `WeavingCounter` before that algorithm passes its independent proof and test gates; do not classify this performance issue as historical Legacy defect #3.
