# Stage41/DISCOVERY38 — ±5793/±17 cross-axis implementation (Native pending)

## Scope and evidence
Stage40 is accepted on exact SHA `1385bd0bb65386d2160ed750cfccc0d5541f1b6a`: first natural [push run 44811219986](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44811219986), attempt 1 completed/success 42/42, verify job 136547946219, GNAT13 job 136547946856, 139/131/125 assertions and 25 distinct ordered records, no artifacts. The documentation-only [Stage41 proposal](STAGE_41_DISCOVERY38_PLAN.md) was on parent HEAD `74920a99c13dbcae770f024dc2c87ab98b3c792c`. Stage41 begins here without a production algorithm change or claimed defect.

## Exact contract
Calculation and target day each range over offsets `(-5793,-17,0,17,5793)` from `Normative_Oracle.Foundation_Day` = -15055671. Independent real-day Cartesian product: **25 unique ordered pairs** in row-major order, exactly **24 novel** against the 441 distinct pairs of Stage15–18 and Stage20–40; only (0,0) repeats. Absolute day axis: `(-15061464,-15055688,-15055671,-15055654,-15049878)`.

Ada `Calendar_Date` observer emits `STAGE41_NATIVE_PAIR <cal> <target> <year> <cutlet> <cutlet_day> <month> <month_day>` once per pair. Ada checks 125 domains (year 4900..5100, cutlet 1..17, cutlet day 1..5778, month 1..47, month day 1..123), five repeat-pivot equalities and one center-year anchor: `STAGE41_NATIVE_REMOTE_SEVENTEEN_ASSERTIONS=131`. Unchanged independent `tests/stage14_real_oracle.py` computes each expected tuple and compares all 125 scalars, requiring `STAGE41_REAL_FIVEFIELD_SCALARS=125`.

Python selftest = 139 inherited mathematical checks plus 7 negative parser-control categories = `STAGE41_INDEPENDENT_REMOTE_SEVENTEEN_SELFTEST_ASSERTIONS=146`. Python-oracle-derived synthetic rows (not Ada observations) are perturbed for duplicate, missing, reordered, unexpected, wrong field count, wrong numerical value, and wrong/repeated Native marker. Each is rejected through the very same `compare_lines` parser and full five-field comparator used on the real Ada output. Synthetic success is not a Native PASS.

## Gate and limits
The new push-only Ubuntu 24.04 job `native-stage41-remote-seventeen` uses GNAT13, Python3 and GNU timeout; Python selftest and comparison <=180 seconds each, Native <=600 seconds; fail on nonzero exit, timeout, missing tools, malformed record, or mismatch; CI <=30 minutes. Prior jobs remain intact; expected job count 43, subject to readback. Stage41 is OPEN and Native/CI/differential **PENDING** until its own first natural push attempt 1, exact implementation SHA, completed/success 43/43 (if count confirmed), GNAT13 compile/bind/link, exact 146/131/125 markers, 25 properly ordered records and artifact inspection. No manual re-dispatch, main, merge or release.
