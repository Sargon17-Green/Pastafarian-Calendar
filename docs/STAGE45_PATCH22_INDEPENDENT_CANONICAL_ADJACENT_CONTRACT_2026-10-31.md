# Stage45 / PATCH22 — independent canonical adjacent-year boundary

PROJECT_ID: PC-BRANCH-PHP-MALAY | PHP+Bahasa-Melayu | 2026-10-31

## Evidence gate
Stage44/DISCOVERY22 Actions #41199851276 at da77d83a2d9d8945d1d608d485cada8fde448a3e:
completed/success 15/15 jobs. Native PHP 8.3.36, 64-bit job #124533328466:
18 controls, two tested physical alternatives, two reproduced, no rejected
or unclassified, lint success, stderr empty, exit 0. The red cases intentionally
violate a contractually trusted *external* canonical adjacent-provider; they
are not a claim of failure on compliant trusted input.
Artifact #13042193909 SHA256:
2098a088709527d66c924bb49f8d3d3f58be1462b578ffd228d3fb0ba036b8c3.

## Engineering choice
Add optional TARGET_YEAR_PATCH_22. The caller supplies two independent,
canonical next/previous year providers, in addition to existing proposed
providers, independent Year5000 anchor source, and independent gate-day map.
For each actually traversed edge: compare five primitive fields
(number, open/close gate index and day) before delegating to PATCH21/20/19/18.
Never substitute test-only NormativeOracle in production; source trust is the
caller's operational responsibility. This does not prove algorithmic
independence or detect two colluding/faulty providers that agree. On zero
steps no adjacent-year provider is consulted.

## Measurable acceptance
Input: action day=NormativeMath::FOUNDATION_DAY, independent test-only
NormativeOracle for years 4999,5000,5001, genuine dayByGate.
Outputs: same targetYearCandidate/steps/direction/legacy provenance as
PATCH21 for seven real target days; two archived Stage44 mismatches reproduce
under PATCH21 and are rejected by PATCH22. Ten invalid/trust regression cases:
mismatching canonical forward/backward, missing canonical field, wrong
canonical type, wrong proposed field/type, forged anchor, wrong gate map,
zero/negative budget. Preserve three real years, two historical red witnesses,
input immutability, no test oracle in production.

Native gate: PHP 8.3 64-bit, <=512MiB and <=900s; lint three changed PHP
sources; stdout one LULUS summary with genuine_years=3 real_targets=7
stage44_red=2 invalid=12, stderr empty, exit=0; commit-exact source SHA,
PHP version, stdout/stderr/exit in artifact; all 16 workflow jobs successful
only after completed evidence. Prior SHA's CI must not be duplicated.

## Scope guard
No merge or main change; no claim of five-component completion. Stage45
not GREEN until completed Native evidence is inspected. No external provider
is manufactured and previous routes stay unchanged.
