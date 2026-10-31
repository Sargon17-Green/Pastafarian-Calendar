# Stage 13 / DISCOVERY10 — చివరి ఐదు తేదీ భాగాలకు పరిమిత సమగ్ర పరీక్ష

## Previous gate
Stage12 [Actions 41200038653](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41200038653) completed/success at `598bbed43d5c44b9c8f26d1ecf8b3e238faa9385`, 13/13 jobs including verify; native job 124533864079 compiled, bound and linked with GNAT 13 and printed `STAGE12_DISCOVERY09_ASSERTIONS= 1344`. The accepted scope is the bounded real Sauce-to-sealed-answer numeric differential, not full calendar correctness.

## Why this stage
Earlier native tests verify arithmetic, Sauce recurrence and Ask_Bowl streams, but not execution of the final public `Calendar_Date` interface returning exactly five components. Stage13 starts a bounded end-to-end test without claiming an independent reconstruction of all calendar data.

## Inputs, oracle and outputs
Use one fixed calculation date `Foundation_Day = -15055671` and three consecutive target days: `Foundation_Day-1`, `Foundation_Day`, `Foundation_Day+1`. Call the real `Calendar_Date` for each; invoke it again independently for the anchor. Assert the five result domains per call: year in [4999,5001], cutlet canonical ID in [1,17], cutlet day in [1,5778], month canonical ID in [1,47], and day in month in [1,123]. These bounds are mathematical consequences of the declared 5000 anchor, year size and month size, not values recomputed using production helpers.

Independently assert `Year_Number=5000` at calculation=target=Foundation_Day, since Year_5000 chooses an interval with open < calculation <= close. Compare all five anchor components between separate invocations. Check neighboring target-day year labels are nondecreasing and increase by at most one. Total: 3×5 domain checks + 1 exact anchor check + 5 replay-equality checks + 2×2 year-order checks = **25 assertions**, marker `STAGE13_DISCOVERY10_ASSERTIONS= 25`.

## Boundaries and acceptance
This is **not** a five-field independent numerical differential: it detects interface exceptions, out-of-range fields, nondeterminism, and simple year-boundary violations only. It does not prove the month weave, cutlet partition, full Sauce or the exact final components. It intentionally avoids dates distant from Foundation to bound gate expansion. No other branch fixture or code is copied. No production source changes.

A dedicated Ubuntu 24.04 / GNAT 13 push job `native-stage13-discovery10` is limited to 15 minutes. The Stage13 gate requires both `verify` and the native job completed/success at the same SHA, actual compile/bind/link, and exactly 25 assertions. Pending CI is not PASS or a blocker. If the test errors or times out, inspect the actual log and reproduce before opening PATCH. No main/merge/publish.
