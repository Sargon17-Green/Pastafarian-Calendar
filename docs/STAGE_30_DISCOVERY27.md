# Stage30/DISCOVERY27 — ±5782 remote frontier crossed with ±5 days

## Verified predecessor and engineering decision
Stage29 on exact branch SHA `f7943419f74aeb55659c1579eef89b73dbd4b4e3` passed automatic [push run 43767092068](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43767092068), attempt 1, completed/success **31/31** jobs (including verify and job **132974552721**). Direct GNAT 13.3.0 compile/bind/link observed independent Python 139, native Ada 131 and five-field numerical 125, plus 25 distinct ordered real-date pair records. **Stage29 ACCEPTED for its bounded matrix only.**

This Stage30 is **DISCOVERY**, not an asserted defect. Choose the next untested remote frontier ±5782 and previously unused local offsets ±5 around F=Foundation_Day. No production algorithm, fixtures, source-derived Stage14 oracle, main branch, or foreign-branch implementation changes.

## Inputs, independent oracle, measurable coverage
Both `calculation_day` and `target_day` independently take F+{-5782,-5,0,+5,+5782}; 5×5 row-major = **25 unique ordered pairs**. Enumerate exact prior coverage of Stage15,16,17,18,20–29 (Stage19 a subset of Stage20) and subtract it. Exactly **24 novel ordered pairs**; (F,F) is the only reused pair. Verify full novelty set, not just count, and preserve axis order.

The independent source-derived reference `tests/stage14_real_oracle.py` computes five expected fields without using Ada output. `tests/stage30_remote_five.py` performs strict selftests and rejects malformed, missing, extra, repeated records, invalid assertion marker, or any field mismatch. Ada Native `tests/stage30_remote_five_observer.adb` calls `Normative_Oracle.Calendar_Date`, emitting 25 `STAGE30_NATIVE_PAIR` records (two input day values plus year, cutlet, cutlet-day, month, month-day).

Each result must satisfy year 4900–5100; cutlet 1–17; cutlet-day 1–5778; month 1–47; month-day 1–123. Independently recalculate the pivot (F−5782,F+5) and check its five fields. At (F,F), check Python anchor exactly (5000,10,503,30,52) and Ada year 5000.

## Executable gate
- Independent Python assertions **139** = 1 distinct-count + 1 exact-novelty-set + 2 axes + 125 domain + 5 pivot repeat + 5 center.
- Ada Native assertions **131** = 125 domain + 5 pivot repeat + 1 center year.
- Independent five-field numerical comparisons **125** = 25 × 5.
- Exactly **25 unique ordered Native pair records**.
- Required markers: `STAGE30_INDEPENDENT_REMOTE_FIVE_SELFTEST_ASSERTIONS=139`, `STAGE30_NATIVE_REMOTE_FIVE_ASSERTIONS=131`, `STAGE30_REAL_FIVEFIELD_SCALARS=125`.
- Runner bounds: 180-second Python selftest, 600-second Ada observer, 180-second comparator; any failure nonzero. Dedicated GNAT13 job outer budget 30 minutes.

**Stage30 PENDING** until automatic push CI on the exact committed Stage30 SHA is **completed/success 32/32**, including verify and all historical jobs. Inspect direct GNAT compile/bind/link, the exact numerical markers and full 25-pair set before acceptance. No duplicate dispatch, merge, main modification or publication.
