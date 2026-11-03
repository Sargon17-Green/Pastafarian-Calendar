# Stage21 DISCOVERY18 — adjacent sides of the 5778/5779-day boundary (open)

## Verified predecessor and coverage gap
Stage20 accepted only its 25 ordered matrix pairs at 9b170a49d92281d244e73992aa1b70d810de71a6. GitHub Actions push 41536989033 completed/success 22/22; native job 125591236236 shows GNAT 13 compile/bind/link and exact markers 135/131/125.
Stage20 included offsets -5779 and +5779, but not offsets -5778 and +5778. The 5778 limit is the maximum normative cutlet-day domain bound in the existing oracle. This stage intentionally tests immediately adjacent offsets on both axes. Four corner pairs were already covered; 12 of the 16 ordered pairs are new. The boundary is a coverage target, NOT a verified off-by-one bug.

## Exact contract and oracle
Let F = Foundation_Day. Enumerate pairs (Calculation_Day, Target_Day) = (F+a, F+b) in row-major order, each offset from {-5779,-5778,+5778,+5779}, giving exactly 16 distinct pairs.
Call the public Ada Calendar_Date for each pair and extract (year, cutlet, cutlet_day, month, month_day). Compare each field with the existing Stage14 independent source-derived Python numerical oracle; the oracle must not use Ada outputs or any fixture copied from another language branch.

## Test contract
Python selftest: one count/uniqueness assertion, two offset-magnitude set assertions, 16*5=80 field-domain checks, five repeated Python evaluations at the (-5778,+5778) pivot; total 88 assertions. Re-evaluation checks determinism, not independent mathematical agreement.
Ada GNAT observer: 16*5=80 field-domain checks plus five field-repeat checks at the pivot; total 85 assertions. Five-field comparison: precisely 16 ordered unique pairs * 5 = 80 scalar equalities with independently computed Python values, exactly one valid Native marker, no malformed, missing, duplicate or extra input pairs.
Domain: year 4900..5100, cutlet 1..17, cutlet_day 1..5778, month 1..47, month_day 1..123. Do not assume numerical monotonicity in either input axis. Investigate any observed mismatch before asserting a historical defect.
Budgets: Python selftest <=180s, Ada executable <=600s, Python comparator <=180s; CI <=15min.

## Acceptance gate
Accept only on a completed/success push run for the exact Stage21 commit with **23/23 jobs**, including verify and native-stage21-edge-adjacent. Require evidence of GNAT13 compile/bind/link and these exact log markers:
- STAGE21_INDEPENDENT_EDGE_ADJACENT_SELFTEST_ASSERTIONS=88
- STAGE21_NATIVE_EDGE_ADJACENT_ASSERTIONS=85
- STAGE21_REAL_FIVEFIELD_SCALARS=80

Queued/in_progress is neither failure nor PASS. Do not manually duplicate the push-triggered job. No main merge, protected branch update, or publication.
