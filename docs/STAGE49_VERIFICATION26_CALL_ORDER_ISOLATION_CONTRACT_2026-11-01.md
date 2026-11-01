# Stage49 / VERIFICATION26 — request-order invariance and rejection isolation

PROJECT_ID: PC-BRANCH-PHP-MALAY | PHP+Bahasa-Melayu | 2026-11-01

## Entry gate
Stage48 source 1b39faf7b2b9b6b6ebf3a91f9b658c7b8bf93abd; Actions #41244373597 completed/success 19/19.
Native PHP 8.3.36 64-bit job #124664625971: checks=107, years=7,
targets=21, positive=42, short_rejections=6, exit 0, empty stderr.
Artifact #13058667511; upload ZIP SHA256
f6eb8bb1bea3a1c18f3e2808cb251622ead42c47101dfc6c64df17ba756b374d.

## Independent verification question
Does opt-in PATCH22 return identical complete outputs across different
query orders using the same BootstrapKernel and caller-owned canonical providers?
Does a rejected short-step-budget request leave the immediately following
valid request unaffected? Stage47 covered seams, Stage48 budget monotonicity;
Stage49 examines sequence/state isolation, with no presumed defect.

## Inputs, outputs, oracle and boundaries
Use only test-side NormativeOracle, generate actual years 4997..5003 from
Year5000 with independent previousYear/nextYear. Choose strict interior
quarter, half, three-quarter days in each year: 21 distinct target days.
Three complete orders: ascending year and position, reversed, and woven
[5000,4999,5001,4998,5002,4997,5003] with positions [3,1,2].
For every call use maxSteps=abs(year-5000)+2. Each of 63 positive outputs
must equal independent year record, expected direction, exact hop count,
and usedLegacyOutput=false. Full output arrays of second/third orders
must equal the baseline. During woven pass, before the first target
of each of six off-anchor years, call with budget abs(year-5000)-1,
require PATCH18_STEP_BUDGET_EXHAUSTED, then a valid immediate successor.
Require exactly six rejections. Verify immutable oracle records, actual
gate-index mapping, distinct strict interior days and absence of
test-only Oracle imports from production PATCH22.

## Native acceptance
PHP 8.3 64-bit, <=512 MiB, <=900 s, lint clean, empty stderr,
exit 0, stdout exactly one line matching:
STAGE49_ORDER_ISOLATION checks=<N> years=7 targets=21 orders=3 successful=63 short_rejections=6
Capture source SHA, PHP version, stdout/stderr/exit. All canonical CI jobs
on exactly Stage49 commit must be completed/success for Stage49 GREEN.
No production PHP change, no main/merge, no claim to final five-component
conversion, no expected-red assumption.
