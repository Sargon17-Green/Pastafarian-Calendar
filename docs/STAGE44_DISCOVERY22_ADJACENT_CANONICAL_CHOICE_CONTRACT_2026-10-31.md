# Stage44 / DISCOVERY22 — canonical adjacent-year selection trust boundary

PROJECT_ID: PC-BRANCH-PHP-MALAY | PHP+Bahasa-Melayu | 2026-10-31

## Verified predecessor
Stage43/PATCH21 at `5fa2536215db32f8e94983f8a7ab3b6c56212fd4` completed 14/14 jobs on Actions run #41196039482.
Native PHP 8.3.36 64-bit job #124522286306: lint 4 files, checks=42,
genuine_years=3, real_targets=7, stage42_red=2, invalid=10, empty stderr,
exit=0, native artifact #13042080436 SHA256
638c83c2ab62bd4b2e8c2c206ccbd18ff2db38f8ef5ed2d5fc5c08219741d183.
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41196039482

## Scope and hypothesis
PATCH21 verifies the independently rebuilt Year5000 anchor identity; PATCH20
validates gate-day/index coherence; PATCH19 verifies seam indices; PATCH18
checks year-number increment and day boundary. None of those operations
computes the *unique normative choice of the next/previous end gate*.
Hypothesis: a callback returning a different physically valid adjacent-year
boundary (with valid gate days, seam, number and interval) may be accepted.
This tests an intentionally NONCANONICAL next/previous callback, so the
claim is strictly about the declared external trust boundary, NOT a failure
under correctly trusted provider inputs.

## Deterministic test-only experiment
Input: NormativeMath::FOUNDATION_DAY; independent test-only NormativeOracle
Year5000, Year5001, Year4999; genuine independent gate-day lookup.
Control: two baseline TARGET_YEAR_PATCH_21 lookups to true next/previous;
three genuine-year gate mapping checks; trusted anchor rebuilt independently.
For each direction construct a distinct year with the same year number and
same adjacent seam, changing only the *far* gate index/day via offsets
[+1,-1,+2,-2,+3,-3,+4,-4,+5,-5]. Admit a candidate only if its gate
count >=6, span 252..5778 days, both gate days match independent lookup,
and the probe target is inside both the normative and alternative interval.
Expected-independent oracle: NormativeOracle::nextYear/previousYear;
it is used only by tests, never production. The returned year must equal
the normative one. Probe logs exact `CANDIDATE_REPRODUCED`,
`CANDIDATE_REJECTED`, or `CANDIDATE_NOT_REPRODUCED` for each direction;
no expected-red assertion before actual Native results.

## Evidence and acceptance
PHP 8.3 64-bit lint; memory_limit=512M; timeout<=900s; two controls plus
two independently altered candidates; 2 classified outcomes; immutable
records; no code imported from another branch. CI job must archive exact
source SHA, version, stdout, stderr, exit code; stderr empty, exit 0.
CI checks classifications and summary but DOES NOT require reproduction.
The research hypothesis is confirmed only after review of completed Native
stdout/log and exact source SHA. If rejected, do not invent a defect/PATCH22.
Do not change production code, main, or merge; no global five-component PASS.
