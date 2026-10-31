# Stage48 / VERIFICATION25 — interior-day budget monotonicity

PROJECT_ID: PC-BRANCH-PHP-MALAY | PHP+Bahasa-Melayu | 2026-10-31

## Entry gate and scope
Stage47 Actions #41239047688 on d2377b801ca56e682ed192127b6157ec69e3993d:
completed/success 18/18 jobs; Native PHP 8.3.36 64-bit job #124648877874
reports checks=68, years=5, targets=20, max_hops=3, budget_rejections=1.
Exit 0, empty stderr and artifact #13057139578 (upload digest
sha256:01d0e028fc68fd6c83d870d1cf4186a1697bd274b3136b43339f6cea7ed91101).
Stage47 is complete for its declared matrix; no global correctness claim.

## New question
For a valid interior target day, is PATCH22's result invariant under an
increased maxSteps budget, while an insufficient budget rejects? This is
separate from Stage47's seam inclusion/exact-minimum check. No presumed bug.

## Independent test-only oracle, data and boundaries
Generate genuine Year5000 with NormativeOracle, then exactly years 4997..5003
by independent next/previous recurrences, independent of PATCH22's output.
For each of the seven years, choose strictly interior days at floor(1/4),
floor(1/2) and floor(3/4) of the year interval. Assert all are open < day <
close. For each of 21 targets, call PATCH22 twice: exact minimum steps
abs(year-5000) and relaxed budget exact+3 (42 successful calls).
Both must return the exact expected oracle year record, identical entire
output, correct direction, correct steps, usedLegacyOutput=false.
For each of six off-anchor years, try one day with budget min-1; only
PATCH18_STEP_BUDGET_EXHAUSTED is acceptable (6 rejections).
Validate independent gate-index lookup, oracle records, source immutability,
and no NormativeOracle or NormativeMath import into production PATCH22.

Expected line: STAGE48_BUDGET_METAMORPHIC checks=<N> years=7
targets=21 positive=42 short_rejections=6 max_hops=3.
The test does not exercise or modify final five-component generation.

## Native execution and acceptance
One PHP 8.3 64-bit job (<=512 MiB, <=900 s for the test) with syntax check,
zero exit, empty stderr, source SHA, PHP version, stdout/stderr/exit
artifacts. All jobs in canonical workflow must complete/succeed on the
exact Stage48 commit before claiming Stage48 GREEN. Any observed failure
must be diagnosed; no expected-red without reproduction. No main/merge,
production PHP modifications, or oracle reuse as production logic.
