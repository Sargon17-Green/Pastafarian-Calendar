# Stage56 B5 — foundation coordinate isolation (QA only)
Date: 2026-11-22 Asia/Jerusalem
PROJECT_ID: PC-BRANCH-PHP-MALAY
Branch: PHP+Bahasa-Melayu
Base commit: eadad7c6354421ae531015aa1c168a445a16fbf8
External reference: Sargon17-Green/pastafari-calendar@cc2cf0b422757a5e7c33218ce30cffa8f99c6786
Stage56: NOT ACCEPTED.

## Exact completed evidence
GitHub Actions #45065545962 completed/failure on exact base SHA: 29/30 jobs success. Sole failed job: external-reference-differential #137340750450.
Exact artifact #14771173098: 37/37 valid CRC, ZIP sha256:a6bad65ce5174a4075fda8e7d2f1ba508a712aa532eb9b24954e4e4a7868fc7f (matches upload log). PHP probe exit=0 and stderr empty; Python raw comparator reports mismatch for each 4999/5000/5001, including first bowl and drop46 order. The original PHP real-year profiles were deliberately skipped by the fast fail.

## Proven input-coordinate discrepancy, not yet proven full cause
In PHP `src/Patches/FoundationScarPatch02.php` and `LegacyDayTag.php`: foundation JDN -15055671.
In external source `implementations/python/pastafari_calendar/core.py`: FOUNDATION_JDN -13334246.
The difference is 1,721,425 days. On calculation day -13334246, PHP counts 3442851 versus canonical Python day_number=1. This discrepancy arises before the first sauce mixing operation and can explain downstream divergence, but *cannot yet certify* all other operations.

## New measurable experiment
In the existing fast PHP QA probe, compute the original three source pairs unchanged AND a second set after shifting both PHP calculation and target JDN by -1721425. Shift preserves target-minus-calculation distance and direction while aligning foundational day counts. Shifted calculation=-15055671; targets: year 4999=-15061828, 5000=-15057702, 5001=-15053458. Compare both sets independently against the unchanged SHA-pinned Python sauce/response oracle.
Output: `sauce-php.json` includes `foundation_coordinate_diagnostic` with shift/provenance/translated records; `sauce-compare-report.json` includes both original and normalized verdicts, plus independent differences. Invalid input/provenance returns exit2; *raw* mismatch returns exit1 even if translated passes. Explicitly no production modification or blanket Stage56 PASS.
Execution: single automatically triggered existing CI after atomic QA-only commit. Do not rerun old SHA or start a duplicate workflow.

Links:
- https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45065545962
- https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45065545962/job/137340750450
- https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45065545962/artifacts/14771173098
