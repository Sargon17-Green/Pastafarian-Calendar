# Stage38/DISCOVERY35 — remote ±5790 and fourteen-day cross-axis

## Evidence gate

Stage37 exact `4929dc562577e885af1d7ab9ebeb6794056926cc` accepted: [first natural push 44715791577](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44715791577) event=push, attempt=1, completed/success 39/39 jobs; verify 136218725369 and direct GNAT13 observer job 136218725466 compile/bind/link. Python selftest 139, Ada Native 131, independent five-field comparisons 125; exactly 25 distinct records. This is bounded acceptance, not proof for other dates.

## Independent discovery design

This is coverage research **without an asserted historical defect**. Use real integer day offsets {-5790,-14,0,14,5790} independently for the calculation-day axis and target-day axis relative to Foundation_Day, in sorted order. Evaluate all 25 ordered row-major pairs (5×5). The fail-closed novelty oracle enumerates the actual prior Stage15–18 and Stage20–37 matrices (Stage19 is a Stage20 subset), requires exactly 24 new ordered pairs and retains only the Foundation center regression; reject missing, duplicate or extra native records.

Production Ada `Normative_Oracle.Calendar_Date` and independently derived `tests/stage14_real_oracle.py` remain unchanged. The observer invokes production `Calendar_Date` for each pair, emits five values under `STAGE38_NATIVE_PAIR`, and checks the five-domain invariants. The Python expected-output oracle does not read Ada output when computing the expected results; the strict comparator checks each of five scalars for each pair. Domain gates: year 4900..5100, cutlet 1..17, day-in-cutlet 1..5778, month 1..47, day-in-month 1..123. Repeat pivot (Foundation-5790, Foundation+14), verify center (5000,10,503,30,52).

## Counted acceptance gate

Python selftest=139 (1 pair cardinality, 1 novelty, 2 axes, 125 domain assertions, 5 repeat, 5 anchor). Ada Native=131 (125 domain checks, 5 repeat, 1 center-year). Independent five-field numeric comparisons=125; exactly 25 unique pair records. Markers `STAGE38_INDEPENDENT_REMOTE_FOURTEEN_SELFTEST_ASSERTIONS=139`, `STAGE38_NATIVE_REMOTE_FOURTEEN_ASSERTIONS=131`, `STAGE38_REAL_FIVEFIELD_SCALARS=125`.

Runner requires Python3, GNAT13 and GNU timeout; each Python phase has a 180s limit, Ada observer 600s and fail-closed exit status. Separate push-only Ubuntu 24.04 job capped at 30m. Stage38 is not accepted by static review/commit alone: require natural push attempt1 on exact committed SHA, completed/success **40/40 jobs** including verify and all existing jobs, GNAT13 compile/bind/link and three exact markers plus 25 unique ordered native pairs. No manual redispatch, main, merge or release.

## Stage38 bounded acceptance — observed 2026-11-20

On exact SHA `17cfd875f682d72f1f542cdedbd0ed2babb5db24`, [natural push run 44734285843](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44734285843), event=push, attempt=1, completed/success: **40/40** jobs, including verify 136281630324. Direct GNAT13 Native job [136281631721](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44734285843/job/136281631721) compiled, bound and linked Stage38, then emitted Python selftest **139**, Ada Native invariants **131**, independent real five-field scalar comparisons **125**, and exactly **25 distinct** `STAGE38_NATIVE_PAIR` rows. This proves bounded Stage38 acceptance only, not universal calendar correctness. No main/merge/release.
