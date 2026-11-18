# Stage32/DISCOVERY29 — new ±5784 remote frontier with ±8-day cross axis

## Proven gate and engineering choice
Stage31 at exact SHA `d859272cfaf02aa3967338204db6f4dff57fb82c` passed [natural push CI 43960263147](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43960263147), attempt 1, completed/success **33/33**, including verify and GNAT13 Native job 133625453885. Observed 139 independent Python selfchecks, 131 Ada invariants, 125 independent numerical scalar matches and exactly 25 distinct ordered Native records. This is bounded Stage31 acceptance only.

Stage32 is DISCOVERY29, **not an assumed defect**. Test the unvisited remote frontier ±5784 and unused near offsets ±8 rather than ±7: Stage23/24 already covered several ±7 local pairs. Both calculation_day and target_day independently take Foundation_Day+{-5784,-8,0,8,5784}, ascending; row-major cross product **25 unique ordered pairs**. Subtract exact Stage15–18,20–31 matrices (Stage19 is a subset of Stage20): **24 genuinely new ordered pairs**, only (F,F) reused. No production source, prior fixtures, historical observers, reference oracle, or main changed.

## Oracle and acceptance contract
Input: 25 real calculation-day/target-day ordered pairs. Native output: one `STAGE32_NATIVE_PAIR` record with two input days and five numerical result fields per pair; exactly 25 unique records, no malformed or extraneous pair. Independent Python `tests/stage14_real_oracle.py` produces expected five-field results using its source-derived mathematical construction, not Ada output. `tests/stage32_remote_eight.py` verifies exact novelty coverage, both axes, domain and full 125-scalar comparison; it rejects duplicates, missing pairs and markers or numerical mismatches. `tests/stage32_remote_eight_observer.adb` invokes the real Ada Calendar_Date, checks domains and independent repeat pivot (F-5784,F+8). Center Python anchor (5000,10,503,30,52) and Ada year 5000.

Required domain on every pair: year 4900–5100, cutlet 1–17, day in cutlet 1–5778, month 1–47, day in month 1–123. Python assertions **139** = 1 count + 1 exact novelty set + 2 axes + 125 domain + 5 pivot + 5 center. Ada assertions **131** = 125 domain + 5 pivot + 1 center year. Independent five-field scalars **125** = 25×5.
Expected exact markers:
```
STAGE32_INDEPENDENT_REMOTE_EIGHT_SELFTEST_ASSERTIONS=139
STAGE32_NATIVE_REMOTE_EIGHT_ASSERTIONS=131
STAGE32_REAL_FIVEFIELD_SCALARS=125
```
Runner limits: Python selftest 180s; Ada observation 600s; Python comparator 180s; nonzero for failed checks or timeouts. GitHub Actions native-stage32-remote-eight runs Ubuntu 24.04 GNAT13, outer limit 30 minutes.

## Final bounded acceptance (2026-11-18)
Natural push CI run 44364672112 on exact SHA a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72, attempt 1, completed/success **34/34**. All 34 jobs reported the same head SHA. Direct GNAT 13 Native job 135015110791 compiled, bound and linked the Ada observer; the completed log recorded 139 Python selftest checks, 25 unique ordered STAGE32_NATIVE_PAIR records, 131 Ada Native invariants and 125 five-field numerical comparisons. Branch Ada+తెలుగు was read back at the same exact SHA. **Stage32 ACCEPTED only for its defined 25-pair matrix**, not as a universal correctness proof. No manual redispatch, main/merge or release.

## Next stage
Stage33/DISCOVERY30 extends the remote frontier to ±5785 and the near cross-axis to ±9 days. Its independent novelty preflight accounts for Stage15–18 and Stage20–32 and must prove 24 new ordered pairs before Native acceptance.
