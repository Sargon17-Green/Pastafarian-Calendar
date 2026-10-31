# Stage47 / VERIFICATION24 — exact year-seam inclusion matrix

PROJECT_ID: PC-BRANCH-PHP-MALAY | PHP+Bahasa-Melayu | 2026-10-31

## Entry gate
Stage46/DISCOVERY23 native GitHub Actions #41222231792 completed/success
17/17 on 74cbda364885c47b3a8ac0f0b5e836d88b8199e8.
PHP 8.3.36 64-bit job #124599023830: controls=12, candidates=4,
reproduced=0, rejected=4, other=0, stderr empty, exit 0.
Artifact #13050357874; see artifacts/STAGE46_DISCOVERY23_NATIVE_CLOSURE_2026-10-31.md.
This rejects the tested Stage46 hypothesis; it is not evidence of a bug.

## Independent question and oracle
The next concern is a different, valid-input question: does the existing
PATCH22 sequential year traversal preserve the half-open year convention
(openGateDay, closeGateDay] at every seam, for both directions and at exact
step budgets, rather than just at the previously sampled target dates?
No expected-red or new production patch is presumed.

Test-only PHP NormativeOracle deterministically derives the seven genuine
years 4997..5003 from Year5000 via independent next/previous recurrences.
This source must remain absent from production. For years 4998..5002, create
four target days per year: exactly openGateDay (belongs to preceding year),
openGateDay+1 (current), exactly closeGateDay (current), and closeGateDay+1
(next). This yields 5*4=20 classified valid targets, including overlaps in
sampled targets by design. An independent table of expected whole-year
records comes from NormativeOracle, never from PATCH22's result.

## Testable acceptance
For each target, PHP PATCH22 must return the exact independent year record
with steps=abs(expectedYear-5000), direction=stay/forward/backward, and
usedLegacyOutput=false, using exact maxSteps equal to the expected steps.
Every seam must agree in the independently generated records, and all seven
gate-day mappings must match. Exactly one separate maxSteps=1 case for a
two-step target must raise PATCH18_STEP_BUDGET_EXHAUSTED.

Print STAGE47_SEAM_MATRIX checks=<N> years=5 targets=20 max_hops=3
budget_rejections=1. Require immutable inputs and absence of NormativeOracle
from production PATCH22. Any discrepancy must be investigated as observed,
not re-labelled expected-red; never adjust expected labels to force GREEN.

## Native gate and permissions
PHP 8.3 64-bit, <=512 MiB, timeout <=900s per probe; lint, exit=0,
stderr empty, preserved source SHA, stdout, stderr, PHP version and exit code.
Full GitHub workflow must complete before stage acceptance. No change to
production PHP, five final calendar date components, main or merges.
