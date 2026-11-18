# Stage33/DISCOVERY30 — new ±5785 remote frontier with ±9-day cross axis

## Proven gate and engineering choice

Stage32 at exact SHA a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72 passed natural push CI run 44364672112, attempt 1, completed/success 34/34. Direct GNAT 13 Native job 135015110791 compiled, bound and linked; its completed log recorded 139 Python selftest checks, 131 Ada invariants, 125 five-field numerical comparisons and exactly 25 unique ordered Native records. This is bounded Stage32 acceptance only.

Stage33 is DISCOVERY30, not an assumed defect. Continue the remote frontier by one day to ±5785 and use the next near offset ±9 rather than reusing ±8. Calculation_Day and Target_Day independently take Foundation_Day + {-5785,-9,0,9,5785}, ascending; their row-major cross product contains 25 unique ordered pairs. Subtract the exact Stage15–18 and Stage20–32 matrices (Stage19 is a subset of Stage20): 24 genuinely new ordered pairs, with only (Foundation, Foundation) reused. The novelty check must fail closed if the actual set differs. No production source, prior fixtures, historical observers, reference oracle, or main branch is changed.

## Oracle and acceptance contract

Input: the 25 real calculation-day/target-day ordered pairs. Native output: one STAGE33_NATIVE_PAIR record containing two input days and five numerical result fields per pair; exactly 25 unique records, with no malformed, duplicate, missing or extraneous pair. The independent Python tests/stage14_real_oracle.py produces expected five-field results from its source-derived mathematical construction and does not invoke Ada or read Ada output when constructing expectations.

tests/stage33_remote_nine.py verifies exact novelty coverage, both axes, every output domain, the frontier repeat pivot, the center anchor and all 125 scalar comparisons. It rejects duplicate records, a missing or extraneous pair, an absent/duplicate/wrong Native marker and any numerical mismatch. tests/stage33_remote_nine_observer.adb calls the real Ada Calendar_Date, checks the five output domains for every pair, the center year, and repeat determinism at (Foundation-5785, Foundation+9).

Required domain on every pair: year 4900–5100, cutlet 1–17, day in cutlet 1–5778, month 1–47, day in month 1–123. Python counted checks: 139 = 1 pair-count/uniqueness check + 1 exact novelty-set check + 2 axis checks + 125 domain checks + 5 repeat-determinism checks + 5 center-anchor checks. Ada checks: 131 = 125 domain + 5 repeat + 1 center-year. Independent five-field scalar comparisons: 125 = 25×5. Structural tuple-length guards and the oracle's own internal assertions also execute but are not included in the 139 counter.

Expected exact markers:

~~~text
STAGE33_INDEPENDENT_REMOTE_NINE_SELFTEST_ASSERTIONS=139
STAGE33_NATIVE_REMOTE_NINE_ASSERTIONS=131
STAGE33_REAL_FIVEFIELD_SCALARS=125
~~~

Runner limits: Python selftest 180s; Ada observation 600s; Python comparator 180s; nonzero on mismatch or timeout. GitHub Actions native-stage33-remote-nine runs Ubuntu 24.04 with GNAT 13 and a 30-minute outer limit.

## Acceptance gate

Require the first natural push on the exact Stage33 SHA to complete successfully across 35/35 jobs, including verify, all historical jobs and direct Stage33 GNAT compile/bind/link. Inspect the completed Native log; require the exact 139/131/125 markers and all 25 distinct ordered pairs. A queued or in_progress run is neither PASS nor a blocker. No duplicate dispatch, main/merge or release.
