# Stage46 / DISCOVERY23 — multi-hop second-edge canonical consistency

PROJECT_ID: PC-BRANCH-PHP-MALAY | PHP+Bahasa-Melayu | 2026-10-31

## Entry gate
Stage45/PATCH22 closed only after commit 6be70b6c624e3839cbe677765404dd455780e4c8
and GitHub Actions #41210727971, attempt 2, completed/success **16/16**.
See artifacts/STAGE45_PATCH22_NATIVE_CLOSURE_2026-10-31.md.
Previous Stage45 tests covered 0 and 1 actual adjacent-year steps; this experiment
tests specifically the *second* step of a two-hop traversal.

## Hypothesis and independent oracle
Question: can a physically plausible, noncanonical year record supplied only
on the second visited edge evade PATCH22's per-edge comparison? This is a
test-only fault injection violating the external-provider trust contract, **not
an assertion of a production bug or a proven expected-red**.
Use PHP test-only NormativeOracle (never production code) to compute genuine
years 4998, 4999, 5000, 5001, 5002 from Year5000 using independent next/
previous recurrence. Independent ensureGateIndex supplies true gate-day mappings.
For both target days, a full trusted PATCH22 traversal must return the actual
year in exactly two steps, without using the legacy guessed result.

## Test matrix
Two genuine baselines:
  forward target=Year5002.openGateDay+1 -> Year5002; steps=2.
  backward target=Year4998.closeGateDay -> Year4998; steps=2.
Four noncanonical fault injections:
  forward proposed, forward trusted, backward proposed, backward trusted.
The first callback edge remains genuine; only the second edge substitutes a
different physically plausible endpoint generated against the test gate-day map.
For each case classify exactly one of reproduced, rejected, or other. Track
the exception code if rejected. Count total candidates=4, verify classification
exhaustive, inputs unchanged and oracle absent from production PATCH22 source.
Do **not** pre-mark reproduced=4, expected-red, or PATCH23 as needed.
If no noncanonical year is accepted, the tested hypothesis is unsupported;
select a distinct engineering question before claiming another patch.

## Native acceptance and limits
PHP 8.3 64-bit, memory <=512 MiB, timeout <=900 s, lint new probe,
exit 0, stderr empty, summary counts in stdout, evidence artifact containing
commit SHA, PHP version, stdout, stderr and exit code, plus full workflow
completed status. Probe execution must **not** be called completed until CI
artifacts and logs exist. No production PHP source change at Stage46.
No copying test oracle or fixtures from another branch. Do not merge main.
