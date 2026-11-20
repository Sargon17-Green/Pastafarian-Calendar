# Stage36/DISCOVERY33 — remote ±5788 and twelve-day cross-axis

## Evidence gate

Stage35 at exact `32022e7cd24f588442b07186a37451127809b479` accepted: [natural push 44701116102](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44701116102) completed/success, attempt 1, 37/37 jobs; verify 136169461239, direct GNAT13 job 136169461345 compile/bind/link, Python 139, Ada 131, five-field scalar comparisons 125, 25 distinct native records. Stage35 acceptance is bounded.

## Independent discovery design

Stage36 is coverage research, **not a claimed historical defect**. Independently select sorted real day axes {-5788,-12,0,12,5788} on each of calculation and target relative to Foundation_Day. Evaluate all 25 ordered row-major pairs. A fail-closed novelty oracle enumerates previous Stage15–18 and Stage20–35 matrices (Stage19 is a Stage20 subset), requiring exactly 24 new pairs plus the Foundation center regression.

Production Ada `Normative_Oracle.Calendar_Date` is unchanged. The new Ada observer emits 25 `STAGE36_NATIVE_PAIR` rows with input days and five output fields. Independently generate expected values from the unmodified source-derived `tests/stage14_real_oracle.py` mathematical oracle, not from any Ada output. The Python comparator requires the exact 25 pairs and one correct native marker, rejects malformed, duplicate, missing and extra rows and compares each field exactly.

Domain: year 4900..5100; cutlet 1..17; day-in-cutlet 1..5778; month 1..47; month-day 1..123. Repeat the (Foundation-5788, Foundation+12) pivot over five fields. Verify Foundation center anchor (5000,10,503,30,52).

## Measured acceptance contract

Python selftest = 139 (1 pair-set + 1 novelty + 2 axes + 125 domain + 5 pivot + 5 anchor); Ada Native = 131 (125 domains + 5 pivot + 1 center year); independent five-field differential = 125. Exactly 25 distinct records. Markers: `STAGE36_INDEPENDENT_REMOTE_TWELVE_SELFTEST_ASSERTIONS=139`, `STAGE36_NATIVE_REMOTE_TWELVE_ASSERTIONS=131`, `STAGE36_REAL_FIVEFIELD_SCALARS=125`.

Runner requires Python3, GNAT13, GNU timeout; 180s each Python phase, 600s Ada phase, explicit nonzero failure propagation. New push-only Ubuntu24.04 job has 30-minute cap. Commit/static QA is **not** Native PASS. Accept only first natural push at exact SHA, completed/success **38/38 jobs** including verify and all historical jobs, direct GNAT13 compile/bind/link, three markers and 25 unique native records. No manual redispatch, main, merge or release.
