# Stage39/DISCOVERY36 — remote ±5791 and fifteen-day cross-axis

## Gate from previous stage

Stage38 at exact `17cfd875f682d72f1f542cdedbd0ed2babb5db24` accepted: [first natural push 44734285843](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44734285843), event=push, attempt=1, completed/success **40/40** jobs; verify 136281630324; GNAT13 Native job 136281631721 compiled/bound/linked, Python=139, Ada Native=131, independent five-field scalar comparisons=125, and 25 distinct pair records. This acceptance is bounded.

## Independent discovery design

Coverage research only: no historical defect is asserted. Use sorted real-day offsets `{-5791,-15,0,15,5791}` on the calculation axis and independently on the target axis, both relative to `Foundation_Day`. Generate all **25** ordered row-major pairs. The source-only novelty guard enumerates Stage15–18 and Stage20–38 (Stage19 subsumed by Stage20) and must prove **24 previously untested ordered pairs**, retaining only the Foundation center regression. Reject unexpected duplicates, omissions, malformed records, and extra native pair records.

Production Ada `Normative_Oracle.Calendar_Date` and independent `tests/stage14_real_oracle.py` remain unchanged. The new Ada observer calls production `Calendar_Date` once per pair, checks domain/repeat invariants and emits exactly 25 `STAGE39_NATIVE_PAIR` records; the Python oracle independently calculates the expected five fields without using Ada output to generate expectations, then requires all five scalar values to agree exactly.

Bounds: year 4900..5100, cutlet 1..17, day-in-cutlet 1..5778, month 1..47, month-day 1..123. Repeat pivot `(Foundation-5791, Foundation+15)`; retain the center reference `(5000,10,503,30,52)`.

## Measured acceptance contract

Python selftest **139** = 1 cardinality + 1 novelty + 2 axis checks + 125 domain checks + 5 pivot comparisons + 5 center anchors. Ada Native invariants **131** = 125 domain checks + 5 pivot comparisons + 1 center year. Independent numerical comparisons **125** = 25 pairs × 5 fields. Require exactly 25 unique native pair rows and exactly one Native marker.

Expected markers: `STAGE39_INDEPENDENT_REMOTE_FIFTEEN_SELFTEST_ASSERTIONS=139`, `STAGE39_NATIVE_REMOTE_FIFTEEN_ASSERTIONS=131`, `STAGE39_REAL_FIVEFIELD_SCALARS=125`. Python3, GNAT13 and GNU timeout required; Python phases 180s each, Ada phase 600s; observer errors and timeouts must propagate as nonzero exits. Push-only Ubuntu 24.04 job capped at 30 minutes.

Static/source validation and Git commit do **not** establish Native PASS. Acceptance requires the first natural push at the exact new SHA with `event=push`, attempt 1, completed/success **41/41** jobs including verify and historical jobs; direct GNAT13 compile/bind/link log, all three exact counts and 25 unique native rows. No manual redispatch/main/merge/release.

## Stage39 bounded acceptance — observed 2026-11-20

Exact commit `f84348dd6b000384d95b5fc8e7b975a925b9da2f`, [first natural push 44800192559](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44800192559), `event=push`, attempt 1, `completed/success`, all **41/41** jobs successful including verify job `136510019362`. Native job `136510019818` directly logged GNATMAKE 13.3.0 compile/bind/link and the exact markers: Python **139**, Ada **131**, independent five-field scalars **125**; **25 distinct** `STAGE39_NATIVE_PAIR` records. No workflow artifacts were published. This is bounded stage acceptance, not universal correctness; no merge/main/release.
