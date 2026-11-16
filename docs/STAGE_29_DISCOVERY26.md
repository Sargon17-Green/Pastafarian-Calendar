# Stage29/DISCOVERY26 — ±5781 remote frontier crossed with ±4 days

## Verified predecessor and selection
Stage28 branch-only SHA `29d512ac2b6c74dc20938ae190935ccaf9034b81` passed [automatic CI 42390633217](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42390633217) attempt 1: completed/success **30/30**, including verify, Stage04, Stage16, Stage27 and Stage28 direct GNAT13 job **128457271595**. Stage28 log observed independent Python 139, Ada Native 131, five-field numerical 125 and exactly 25 distinct ordered Native pairs. Stage28 is accepted for this bounded matrix only.

This next independent extension tests the next real calendar-day frontier ±5781 and previously uncovered ±4 local offsets around Foundation_Day. No calendar algorithm, production source, fixtures or other branch code is modified. This stage is **DISCOVERY**, not a claim that a defect exists.

## Inputs, oracle and novelty proof
Let F=Foundation_Day. Enumerate row-major all 25 ordered (calculation_day,target_day) pairs using **both** axes F+{-5781,-4,0,+4,+5781}. Compare their exact sets against explicitly enumerated Stage15,16,17,18,20,21,22,23,24,25,26,27 **and 28** matrices (Stage19 is a Stage20 subset). Assert that the only old pair is (F,F); all other **24** pairs are novel. Both dimensions are asymmetric and order matters.

Independent source-derived Python reference `tests/stage14_real_oracle.py` computes the expected five-field tuple for each real input (not read back from Ada). Ada public `Normative_Oracle.Calendar_Date` is observed by a dedicated GNAT13 program emitting exactly 25 `STAGE29_NATIVE_PAIR` lines: calculation day, target day, year, cutlet, cutlet-day, month, month-day. Strict comparator checks no missing, extra, duplicate or malformed lines; one exact Ada assertions marker; five numerical fields per pair against Python.

Domain checks per result: 4900≤year≤5100; 1≤cutlet≤17; 1≤day_in_cutlet≤5778; 1≤month≤47; 1≤day_in_month≤123. Repeat pivot (F−5781,F+4) checking all five fields independently. Verify full center tuple (5000,10,503,30,52) in Python and center year 5000 in Ada.

## Measurable gates
Python independent selftests = **139** (unique 1 + exact new set 1 + axes 2 + domains 125 + repeat 5 + center 5).
Ada Native assertions = **131** (domains 125 + repeat 5 + center-year 1).
Independent numerical comparisons = **125** (25 pairs × five fields).
Required markers:
`STAGE29_INDEPENDENT_REMOTE_FOUR_SELFTEST_ASSERTIONS=139`
`STAGE29_NATIVE_REMOTE_FOUR_ASSERTIONS=131`
`STAGE29_REAL_FIVEFIELD_SCALARS=125`.

Python selftest timeout 180 s, Ada observer execution 600 s, comparator 180 s. Nonzero exit on any mismatch or timeout. Dedicated `native-stage29-remote-four` GNAT13 workflow job has 30-minute outer budget for previously observed apt mirror delays.

**Stage29 PENDING**, until the automatic push CI on the exact new SHA is **completed/success 31/31** jobs (including verify and all prior jobs); inspect GNAT13 compile/bind/link and the exact direct markers and 25 unique Native pair rows. A source preflight or queued/in_progress result does **not** constitute Stage29 PASS. No duplicate dispatch, main modification, merge or publication.

## Final completed acceptance (2026-11-16 verification)
Exact branch SHA `f7943419f74aeb55659c1579eef89b73dbd4b4e3` passed automatic push [run 43767092068](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43767092068), attempt 1: **completed/success 31/31** jobs, including verify, historical native jobs and direct Stage29 job **132974552721**. GNAT 13.3.0 compile/bind/link, independent Python **139**, native Ada assertions **131**, five-field scalar comparisons **125**, and **25 unique ordered STAGE29_NATIVE_PAIR** records were observed in the direct job log. **Stage29 ACCEPTED** only for its bounded 25-pair matrix; earlier PENDING is historical. No universal correctness claim.
