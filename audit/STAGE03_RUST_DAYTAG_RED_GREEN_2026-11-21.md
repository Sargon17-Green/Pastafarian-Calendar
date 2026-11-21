# Rust Azerbaijani Stage03 reconstruction: executed RED evidence and proposed GREEN patch

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Date: 2026-11-21
Historical Stage03 root: 716e5a6f335b1a15464029b446edb468f3a8482c
Executed reconstructed RED SHA: 108833d04786be22bfcadc987c7208b35c373451
RED run/job: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44937766996 | 136948055584
RED artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44937766996/artifacts/14722536019
Artifact ZIP bytes/SHA256: 6200 / 81a8f8ce4346f33dc011888bb055e0d785bfce4667a5e2f24e302f755c1150b1
Artifact content: 6 files; ZIP CRC passes, exit.txt=0, source SHA exact, rustc/cargo 1.100.0.
Observed native production Dispatcher RED: 3 numeric mismatches (F-2, F-1, F-2^256); 3 controls match (F, F+1, F+2^256); unexpected=0. Original Stage01-03 regression suites 16+3+4=23 passed, reconstruction suite 1 passed. Full signed numeric values remain in the job log and artifact stdout.
This is an executed **2026 reconstruction**, not an existing October 2026 Rust production bug or historical Stage04 witness.

## Distinct descendant corrective change
After the observed RED, implement sign-sensitive day-tag: for day < F return 2*(F-day); otherwise 2*(day-F)+1. Preserve unbounded BigInt and the previously callable Rust dispatcher, per-invocation context and metrics. Keep previous RED SHA immutable. Test the identical six cases with independent piecewise-integer oracle, plus 128 deterministic signed-BigInt dispatcher observations (different shifts / distances). Preserve original 23 tests. Native GREEN must be assessed only after a completed run on the exact new commit, examining job logs, artifact, exit, SHA and source ancestry.

## Scope / gates
- Change only reconstruction branch source, test, its existing workflow and this report.
- No changes to original branch Rust+Azərbaycan-dili, historical Stage03, main, or release.
- Existing historical Stage04 stays OPEN / NOT_CLAIMED (CURRENT_STAGE=4, LAST_COMPLETED_STAGE=3).
- Writing the corrective commit is NOT a CI, Native, or differential PASS. Automatic push should initiate exactly one GREEN run; no manual duplicate.
