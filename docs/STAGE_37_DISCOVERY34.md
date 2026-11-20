# Stage37/DISCOVERY34 — remote ±5789 and thirteen-day cross-axis

## Evidence gate

Stage36 at exact `8f32107460c9f77e081db34d80d63ca80431c7b5` accepted: [natural push 44707643723](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44707643723) completed/success, attempt 1, 38/38 jobs; verify 136191117563; direct GNAT13 job 136191118043 compile/bind/link; Python 139, Ada 131, five-field scalars 125, exactly 25 distinct native records. Stage36 acceptance is bounded.

## Independent discovery design

Stage37 is coverage research, **not a claimed historical defect**. Independently select sorted real day axes {-5789,-13,0,13,5789} on each of calculation and target relative to Foundation_Day. Evaluate all 25 ordered row-major pairs. A fail-closed novelty oracle enumerates previous Stage15–18 and Stage20–36 matrices (Stage19 is a Stage20 subset), requiring exactly 24 new pairs plus the Foundation center regression.

Production Ada `Normative_Oracle.Calendar_Date` is unchanged. The new Ada observer emits 25 `STAGE37_NATIVE_PAIR` rows with input days and five output fields. Independently generate expected values from the unmodified source-derived `tests/stage14_real_oracle.py` mathematical oracle, not from any Ada output. The Python comparator requires the exact 25 pairs and one correct native marker, rejects malformed, duplicate, missing and extra rows and compares each field exactly.

Domain: year 4900..5100; cutlet 1..17; day-in-cutlet 1..5778; month 1..47; month-day 1..123. Repeat the (Foundation-5789, Foundation+13) pivot over five fields. Verify Foundation center anchor (5000,10,503,30,52).

## Measured acceptance contract

Python selftest = 139 (1 pair-set + 1 novelty + 2 axes + 125 domain + 5 pivot + 5 anchor); Ada Native = 131 (125 domains + 5 pivot + 1 center year); independent five-field differential = 125. Exactly 25 distinct records. Markers: `STAGE37_INDEPENDENT_REMOTE_THIRTEEN_SELFTEST_ASSERTIONS=139`, `STAGE37_NATIVE_REMOTE_THIRTEEN_ASSERTIONS=131`, `STAGE37_REAL_FIVEFIELD_SCALARS=125`.

Runner requires Python3, GNAT13, GNU timeout; 180s each Python phase, 600s Ada phase, explicit nonzero failure propagation. New push-only Ubuntu24.04 job has 30-minute cap. Commit/static QA is **not** Native PASS. Accept only first natural push at exact SHA, completed/success **39/39 jobs** including verify and all historical jobs, direct GNAT13 compile/bind/link, three markers and 25 unique native records. No manual redispatch, main, merge or release.

## Stage37 bounded acceptance — observed 2026-11-20

On exact SHA `4929dc562577e885af1d7ab9ebeb6794056926cc`, [natural push run 44715791577](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44715791577), event=push, attempt=1, completed/success: 39/39 jobs, including verify job 136218725369. [Direct GNAT13 Native job 136218725466](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44715791577/job/136218725466) compiled, bound and linked the Stage37 observer, then emitted Python=139, Ada Native=131, independent five-field scalar comparisons=125; exactly 25 distinct `STAGE37_NATIVE_PAIR` records. This is bounded Stage37 acceptance only, not a universal proof. No main/merge/release.
