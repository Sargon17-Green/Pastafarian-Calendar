# Stage19 Native CI Acceptance — Perl+國語 (2026-11-20)

Project ID: PC-BRANCH-PERL-GUOYU
Branch: Perl+國語
Accepted exact source SHA: 70ace36b86d71b83e44884e033080a491239212c
Previous accepted stage: 18
Accepted stage: **19**

## Canonical run and raw-log evidence

- Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44613592783
- Event: push; run attempt: 1; result: completed / success.
- GitHub run head SHA and fresh branch HEAD both equal the exact source SHA above.
- Total jobs: 166; mandatory jobs: **20/20 completed/success**; conditional skipped jobs: 146.
- All 20 mandatory raw logs individually fetched and inspected: verify, perl-stage01, and stage02 through stage19 native.
- The required perl-stage01 complete suite reports **Files=117, Tests=242773**, All tests successful, Result: PASS.
- The distinct stage04-month-occurrence-native job reports **385/385 TAP PASS**, after reproducing and correcting the Stage04 contract regression caused by Stage19's broadened WeavingPrimitive domain.
- The stage19-weaving-ten-months-native job: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44613592783/job/135876256522
- Stage19 t/64: 33634 assertions PASS (40 wall-clock seconds); t/66: 9 assertions PASS (16 seconds); t/65: 60 assertions PASS (51 seconds). Total: **33703 / 33703**.
- Independent Catalan(10) closed form = 16796. The Stage19 test checks 16796 Dyck oracle words, all 16796 unrank and 16796 rank positions; three smaller exhaustive profiles and four large roundtrip-only profiles. The latter are **not** independent count oracles.
- Three prove invocations use a 120-second timeout and 393216-KiB virtual-memory limit. No failures in the dedicated job.

## Seven-file artifact, independently downloaded and checked

Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44613592783/artifacts/14576430937
Name: perl-stage19-weaving-ten-months-native
Archive size: 94745 bytes
SHA-256 (GitHub provider, job upload step, independently downloaded ZIP):
0806044132cba87d2e497d12e158a1c2a60c58475ef6944db1b8b95db072fdbb

- ZIP: seven members, every CRC checked; testzip returned no corrupt file.
- source.txt: 70ace36b86d71b83e44884e033080a491239212c, exactly matching run and branch.
- perl-version.txt: v5.40.5 (>= v5.40).
- syntax.stderr: four exact syntax OK lines (module, t/64, t/65, t/66).
- test.stdout: all three required TAP totals and PASS summaries, and named Stage19 evidence markers.
- test.stderr: zero bytes.
- test.exit: 0.
- result.txt: STAGE19_NATIVE_PASS=1.

## Decision and scope

**Stage19 Native CI ACCEPTED; LAST_COMPLETED_STAGE 18 -> 19.**
Acceptance is for Pastafari::Monster::WeavingPrimitive up to 10 months and 40 days, with the MonthOccurrence independent projection domain retained at <=9 months / 36 days. The complete-year calendar generator remains unverified.

No merge to main, main modification, release or publication. A Stage20 discovery contract may be opened separately, without claiming Stage20 implementation or Native PASS.
