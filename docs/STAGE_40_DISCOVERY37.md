# Stage40/DISCOVERY37 — remote ±5792 and sixteen-day cross-axis

## Precondition — verified Stage39 bounded acceptance
Stage39 on exact commit `f84348dd6b000384d95b5fc8e7b975a925b9da2f`: [natural push 44800192559](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44800192559) was event=push, attempt=1, completed/success 41/41, including verify 136510019362 and GNAT13 Native job 136510019818 (compile/bind/link); Python=139, Ada Native=131, independent five-field scalars=125, and 25 distinct pair records. Not a universal proof.

## New test contract
Coverage discovery, not a claimed defect. Calculation-day and target-day axes each use sorted actual day offsets `{-5792,-16,0,16,5792}` from `Foundation_Day`. The 5×5 Cartesian product has **25 distinct ordered pairs**, emitted and checked in strict row-major order. A self-contained prior-pair enumeration in `tests/stage40_remote_sixteen.py` covers Stage15–18 and Stage20–39 (Stage19 subsumed by Stage20); **24 must be novel** and only the foundation/foundation pair may be repeated. Any duplicate, missing, unexpected or out-of-order Native row is rejected.

The independent Python real-date oracle `tests/stage14_real_oracle.py` and production `src/normative_oracle.adb` are unchanged. The Ada GNAT13 observer invokes `Calendar_Date` directly on each real-day pair, checking year 4900..5100; cutlet 1..17; cutlet day 1..5778; month 1..47; month day 1..123. Independent Python computes the expected 5-tuple without deriving it from Ada output, then compares all five values exactly. Pivot repeat uses `(Foundation-5792,Foundation+16)`; center anchor is `(5000,10,503,30,52)`.

## Measurable acceptance gates
- Python selftest: 139 = 1 cardinality + 1 exact novelty + 2 exact axis checks + 25×5 domains + 5 pivot-repeat comparisons + 5 center-anchor comparisons.
- GNAT Native invariants: 131 = 25×5 domain checks + 5 pivot-repeat + 1 center-year.
- Independent five-field differential: 125 = 25×5 scalar equalities, with exactly 25 unique ordered `STAGE40_NATIVE_PAIR` rows in correct row-major order.
- Exact unique markers: `STAGE40_INDEPENDENT_REMOTE_SIXTEEN_SELFTEST_ASSERTIONS=139`, `STAGE40_NATIVE_REMOTE_SIXTEEN_ASSERTIONS=131`, `STAGE40_REAL_FIVEFIELD_SCALARS=125`.
- Runner: Python3, GNAT13, GNU timeout; two Python phases ≤180s each, Native executable ≤600s, errors and timeout exit nonzero; push-only ubuntu-24.04 job with 30-minute cap.

Source-only validation or the commit is not Native PASS. Bounded Stage40 acceptance requires first natural push on the exact new branch SHA, event=push, attempt=1, completed/success **42/42** including verify/historical jobs, direct GNAT13 compile/bind/link log, all exact markers and all 25 unique ordered pairs. Do not manually redispatch, merge to main or release.
