# Stage42 / DISCOVERY21 — provenance of Year5000 anchor (research only)

PROJECT_ID=PC-BRANCH-PHP-MALAY | PHP+Bahasa-Melayu | 2026-10-31
Parent: Stage41/PATCH20 Native GREEN, run 41187047640, 12/12 success on
63913fe8620d4fd55be66a823438373c925d98f4; native checks=40,
real_targets=7, stage40_red=2, invalid=11, PHP 8.3.36/64-bit, exit=0, stderr empty.
Evidence: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41187047640
Native job: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41187047640/job/124495979107
Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41187047640/artifacts/13038001082
Artifact digest: sha256:431c9680267a52881b3c948a96767ef59d066e2b49998758664c1005e6fff1f4

## Hypothesis (not yet an established defect)
PATCH20 authenticates each visited (gate index, gate day) pair using a trusted
independent mapping, but does not derive the canonical Year5000 identity from
that mapping. If a caller violates its explicit contract and supplies another
physical year relabelled 5000, a correct mapping may still accept that anchor
and return the wrong calendar-year number. This is an untrusted-anchor boundary
study, NOT proof of an error for callers meeting the trusted-anchor precondition.

## Independent oracle, controlled mutation, measured output
tests/stage42_discovery21_probe.php builds true Year4999/5000/5001 records
using the test-only NormativeOracle; all six gate endpoints are verified by
test-only ensureGateIndex. Two positive controls traverse from a true Year5000
anchor to real 5001 and 4999, returning the exact expected year with steps=1.

Two negative candidates change only the claimed number to 5000:
(1) the actual Year5001 record; target its first day;
(2) the actual Year4999 record; target its last day.
Their gate indexes, days and test oracle remain untouched. Expected observation
IF vulnerable: PATCH20 returns the mislabelled anchor (year=5000) with steps=0
rather than the normative year (5001 or 4999). A rejection or different
result falsifies the particular hypothesis. Count each candidate independently.

Native PHP 8.3 with PHP_INT_SIZE=8: lint, bounded 900s, 512 MiB, exact source
SHA, stdout witnesses, stderr empty, exit 0, artifact. All predecessor CI jobs
and Stage42 probe must conclude success on the same SHA. Do not claim
EXPECTED_RED from code inspection or a queued run. Only after actual native
reproduction can a subsequent PATCH contract be selected; no production
code, legacy or true oracle is changed by this DISCOVERY.
