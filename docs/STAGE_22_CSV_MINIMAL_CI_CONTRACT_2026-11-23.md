# Stage22 post-acceptance CSV-focused GitHub CI contract

Date: 2026-11-23
PROJECT_ID: PC-BRANCH-PERL-GUOYU
Branch: Perl+國語
Locked parent HEAD: 72034f71d106a4427621af4afb114318e60fc051
Locked QA source commit: bb49201411b6397819c97e5fc2b40238251e48ce

Code change: only canonical CI workflow; 23 previous default jobs now exclude [stage22-csv-only]. A new dedicated job is activated solely for push to Perl+國語 with [stage22-csv-only]. The existing 12x52 maximal-arena job, 13x4 Stage22 job and all other 169 old jobs remain skipped by this commit marker. No production, oracle, fixture, main, merge, release, or Stage23 changes.

Inputs: Perl 5.40 or above; three exact blobs:
- b6f6e055c41e31be369b11fbacc33f6d0279856e (forward oracle).
- b41ae40b2b04a07a6b3eb385b2f246097bb5f036 (CSV negative test).
- 85d055ae9dfec705105109195b8ed259c552d39c (independent small positive test).

Gates: exact new GitHub push SHA and locked parent; Git blob identity; syntax 3/3 exits0; negative 66/66 contiguous TAP with exact marker; independent positive 45/45 contiguous TAP with marker; each run exit0/stderr0; separate <=90s timeout and <=393216KiB VSZ cap. Raw TAP, stderr, syntax, exit codes, source SHA, provider run context, SHA256 and summary are uploaded as artifact even on failure.

This document defines gates but is NOT a test result. A new Native/CI QA PASS requires completed exact-SHA run, successful dedicated job, raw log and independently downloaded artifact/hash. Historical Stage22/12x52 results remain on their old source SHAs. Full-year unverified. No Stage23.

NEXT: inspect the automatic push run, job, raw logs and artifact; only then update acceptance evidence. If pending, keep this QA in READY without claiming PASS.
