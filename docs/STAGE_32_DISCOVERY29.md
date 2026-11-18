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

## Gate (pending)
Require first natural push on exact Stage32 SHA `completed/success` across **34/34 jobs**, including verify, all 33 historical jobs, and direct Stage32 GNAT compile/bind/link. Read completed Native log; verify exact 139/131/125 markers and all 25 distinct pairs. Never classify queued/in_progress as PASS or block. No manual redispatch, main/merge or release.
