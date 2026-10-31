# Stage45/PATCH22 — native closure (2026-10-31)

PROJECT_ID: PC-BRANCH-PHP-MALAY | branch PHP+Bahasa-Melayu

Commit-exact source: 6be70b6c624e3839cbe677765404dd455780e4c8.
GitHub Actions: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41210727971

## Acceptance evidence
After the initial workflow completed/failure with only Stage38 failing due to the
runner startup library error `gd.so: libabsl_synchronization.so.20220623`, a
**single targeted re-run** was requested for failed job #124564944472.
The second workflow attempt completed/success: **16/16 jobs** completed/success,
with head SHA unchanged. Successful Stage38 replacement job #124597489084:
controls=18, candidates=2, reproduced=2, rejected=0; no previous missing-library
error; output artifact #13050057507,
SHA256 55ef229551c2ece275e2b0c4f5e3b44fd9c52ab61ae9092bdc862f80b59ae314.
These intentionally noncanonical external-provider witnesses do not prove a defect
for trusted/canonical input.

Stage45 Native job #124597524323 completed/success. PHP 8.3, 64-bit:
checks=44, genuine_years=3, real_targets=7, stage44_red=2, invalid=12,
stdout LULUS, stderr empty, exit 0. Stage45 artifact #13045908114,
SHA256 3217ca0be69344d9020f5a2b726e0d8beb7b4dd074519fb1b10bcae0392ae9c0.
The prior forged-anchor fixture fix is included in this exact commit.
Other 14 jobs in second attempt completed/success.

## Scope
Stage45/PATCH22 accepted on this source SHA only. The canonical adjacent-year
source remains caller-owned and must be independent. No five-component algorithm
completion, production calendar oracle, main merge, or external publication is
asserted. The next authorized phase is Stage46 test-only DISCOVERY23.
