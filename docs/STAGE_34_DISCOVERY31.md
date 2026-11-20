# Stage34/DISCOVERY31 — new ±5786 remote frontier with ±10-day cross axis

## Proven prerequisite and engineering choice

Stage33 on exact SHA `75295de952d337fe5f77a7277e477335609bdc8a` passed natural push CI [44393141682](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44393141682), attempt 1, completed/success **35/35**, including verify and GNAT13 [Native job 135115857722](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44393141682/job/135115857722). The completed log contains 139 independent Python checks, 131 Ada assertions, 125 five-field scalar comparisons, and exactly 25 distinct ordered Native pairs. This is bounded Stage33 acceptance only.

Stage34 is an exploratory DISCOVERY31, **not an asserted defect**. Both Calculation_Day and Target_Day independently select Foundation_Day plus {-5786,-10,0,10,5786}, in ascending order, giving 25 ordered pairs in row-major order. The explicit prior coverage matrix comprises Stage15–18 and Stage20–33; Stage19 is subsumed by Stage20. Exact set subtraction yields **24 previously untested ordered pairs** and one center regression (Foundation, Foundation). The selftest fails closed unless this exact novelty set holds.

This adds tests and documentary evidence only; it leaves production Ada, the standalone independent mathematical oracle `tests/stage14_real_oracle.py`, prior fixtures and existing observers unchanged.

## Inputs, outputs and independent oracle

Each of the 25 real ordered date pairs is passed to the production `Normative_Oracle.Calendar_Date` by `tests/stage34_remote_ten_observer.adb`. The Ada observer emits one `STAGE34_NATIVE_PAIR` record containing calculation day, target day and the five scalar fields: year, cutlet, cutlet day, month, month day. The Python comparator `tests/stage34_remote_ten.py` computes the expected five fields with the independent source-derived `stage14_real_oracle.date` function. Expected values are not derived from Ada output.

The Python comparator rejects a missing, extra, malformed or duplicated record; incorrect pair set; missing, duplicate or incorrect Ada count marker; and every unequal field. It tests five-field determinism at (Foundation-5786, Foundation+10), along with the center anchor (5000,10,503,30,52). Both Ada and Python require each pair to satisfy year 4900..5100, cutlet 1..17, cutlet day 1..5778, month 1..47, and month day 1..123.

Expected exact check totals:

- Python selftest **139** = 1 count/uniqueness + 1 novelty set + 2 exact axes + 125 domain + 5 repeat + 5 center anchor.
- Ada invariant checks **131** = 125 domain + 5 pivot repeat + 1 center-year.
- Independent scalar matches **125** = 25 pairs × 5 fields.
- Native output **25 distinct ordered `STAGE34_NATIVE_PAIR` records**, with no extras.

Expected markers:

```text
STAGE34_INDEPENDENT_REMOTE_TEN_SELFTEST_ASSERTIONS=139
STAGE34_NATIVE_REMOTE_TEN_ASSERTIONS=131
STAGE34_REAL_FIVEFIELD_SCALARS=125
```

## Execution and acceptance

The bounded runner `run_stage34_remote_ten.sh` uses Python3 and GNAT13 and terminates with a nonzero status on missing prerequisites, Python mismatch, Ada failure, timeout, or malformed output. Python selftest and comparison each have 180-second caps, Ada execution 600 seconds. The natural push workflow job `native-stage34-remote-ten` has a 30-minute outer limit on Ubuntu 24.04.

**Not accepted at creation:** require first natural push for the exact new Stage34 commit to reach completed/success **36/36** jobs including verify and historical Native jobs, and read the Stage34 GNAT compile/bind/link log with all three exact numerical markers and 25 unique native records. A queued or in-progress run is neither PASS nor a blocker. Do not manually dispatch a duplicate, merge to main or publish.

## Final bounded acceptance (2026-11-20)

The PATCH02 [natural push run 44633339169](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44633339169), attempt 1, on exact SHA `4b1448dc1cb53530c81c6529a35dcc4654bc5841` completed/success **36/36**, including verify job 135945452040 and [Stage34 GNAT13 job 135945452220](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44633339169/job/135945452220). The direct Native job log includes GNATMAKE 13.3.0, GNAT bind/link, `STAGE34_INDEPENDENT_REMOTE_TEN_SELFTEST_ASSERTIONS=139`, `STAGE34_NATIVE_REMOTE_TEN_ASSERTIONS= 131`, `STAGE34_REAL_FIVEFIELD_SCALARS=125`, and 25 distinct `STAGE34_NATIVE_PAIR` ordered date records. Live branch HEAD equaled the exact SHA before Stage35 implementation. This is bounded Stage34 acceptance, not proof for arbitrary inputs.

Stage35/DISCOVERY32 opens with independently selected remote ±5787 and near ±11 date axes; it retains the Stage14 independent mathematical oracle, and its 5×5 matrix must prove exactly 24 new ordered cases versus all earlier matrices including Stage34. No production Ada change, merge, main update or release.
