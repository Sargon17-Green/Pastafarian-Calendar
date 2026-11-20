# Stage35/DISCOVERY32 — new ±5787 remote frontier with ±11-day cross axis

## Prerequisite and independent engineering selection

Stage34 PATCH02 on exact SHA `4b1448dc1cb53530c81c6529a35dcc4654bc5841` passed first natural push [run 44633339169](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44633339169), attempt 1, completed/success 36/36. Direct [GNAT13 job 135945452220](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44633339169/job/135945452220) compiled/bound/linked; recorded 139 Python selftest assertions, 131 Ada invariants, 125 five-field differential matches and 25 unique real Native pairs. This only accepts the Stage34 bounded matrix.

Stage35 is exploratory coverage expansion, not a claimed historical defect. Choose independently the new calculation and target offsets {-5787,-11,0,11,5787} around Foundation_Day; each dimension is independent and sorted. All 25 ordered row-major combinations are real date arguments, not a synthetic projection. The explicit prior matrix set is Stage15–18, Stage20–34 (Stage19 subset of Stage20), exactly 24 new ordered pairs, one Foundation center regression. The Python preflight fails closed on any discrepancy in this novelty set.

## Inputs, outputs, and independent algorithmic oracle

The Ada observer `tests/stage35_remote_eleven_observer.adb` calls the unmodified production `Normative_Oracle.Calendar_Date(Calculation_Day, Target_Day)` 25 times and emits one `STAGE35_NATIVE_PAIR` record for each date pair plus the five scalar fields (year, cutlet, day in cutlet, month, day in month). Independently, `tests/stage35_remote_eleven.py` derives expected numerical answers via the unchanged source-derived mathematical `tests/stage14_real_oracle.py`, not Ada output and not any fixture copied from another branch.

The comparator rejects absent/duplicate/extra/malformed records, an incorrect pair set, incorrect/duplicated/missing native assertion marker, and a mismatch in any of the five scalar fields. The observer and comparator retain domain checks: year 4900..5100; cutlet 1..17; day in cutlet 1..5778; month 1..47; month day 1..123. A second oracle evaluation of the pivot (Foundation-5787, Foundation+11) verifies five-field repeatability. The Foundation center anchor is (5000,10,503,30,52). This test does not assert general correctness outside the matrix.

## Measurable verification

- Independent Python selftest: exactly **139** assertions = pair uniqueness 1 + exact novelty 1 + axes 2 + domain 125 + pivot repeatability 5 + center anchor 5.
- Ada Native observer: exactly **131** invariants = 125 domains + 5 pivot comparisons + 1 center-year anchor.
- Exact independent real-data differential: **125** five-field scalar comparisons (25 ordered pairs × 5 fields).
- Native output: **25 distinct** `STAGE35_NATIVE_PAIR` ordered records; no extra/missing/duplicate records.
- Expected markers: `STAGE35_INDEPENDENT_REMOTE_ELEVEN_SELFTEST_ASSERTIONS=139`, `STAGE35_NATIVE_REMOTE_ELEVEN_ASSERTIONS=131`, `STAGE35_REAL_FIVEFIELD_SCALARS=125`.

## CI and acceptance

The bounded shell runner `run_stage35_remote_eleven.sh` requires Python3, GNAT13 and `timeout`, exits nonzero on missing prerequisites or failure, caps Python selftest and comparator at 180s each and Ada execution at 600s. A new **push-only** `native-stage35-remote-eleven` Ubuntu 24.04 workflow job has a 30-minute cap. No manual dispatch or duplicate CI.

This stage is NOT ACCEPTED on commit: require natural push on the precise Stage35 SHA to finish `completed/success` across **37/37 jobs** including `verify` and previous jobs, plus direct GNAT compile/bind/link and exact 139/131/125 markers, 25 unique ordered native pairs. A queued/in_progress run is neither PASS nor a blocker. No main, merge or external release.
