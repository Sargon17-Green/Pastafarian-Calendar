# Stage22 Native CI Acceptance — Perl+國語 (2026-11-21)

PROJECT_ID: PC-BRANCH-PERL-GUOYU
Authorized branch: Perl+國語
Exact accepted **source** commit: e28e6186c108b2ba2e2e7c4e5f32f778df33bd6a
Previous LAST_COMPLETED_STAGE: 21
Decision: accept Stage22 for 13 months / 52 days **only**. The entire calendar/year generator remains unverified.

## Mandatory canonical GitHub Actions gate
- Canonical push workflow https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44904659215 ; attempt 1, event push, completed/success; head_branch=Perl+國語 and head_sha=e28e6186c108b2ba2e2e7c4e5f32f778df33bd6a.
- Branch HEAD separately verified equal to source SHA immediately before the acceptance commit.
- Pagination read all 169/169 jobs over two pages: **23/23 mandatory completed/success**, 146 conditional/skipped; no queued or in-progress job. All 23 mandatory raw job logs were retrieved and reviewed.
- Verify job ID 136847540928 completed/success.
- Stage01 job ID 136847541199: entire Perl suite Files=121, Tests=243194, Result: PASS.
- Regression repair test Stage02 job ID 136847546031: native 263/263 TAP, Result: PASS; test-only oracle separation check, syntax checks and 7-file-independent evidence style.
- Regression repair test Stage03 job ID 136847545970: native 289/289 TAP, Result: PASS; syntax and oracle checks.
- Dedicated Stage22 job ID 136847546239 completed/success; evidence source SHA echoed after completion.
- All remaining mandatory Stage04..Stage21 jobs completed/success, with raw logs reviewed. Skipped conditional experimental jobs are not represented as passing jobs.
- Stage22 CI shell enforces per-process timeout of 120 seconds and virtual-memory ulimit of 393216 KiB, with return-code/stderr assertions.

## Independently downloaded Stage22 Native ZIP
- Artifact https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44904659215/artifacts/14708038426 (ID 14708038426, 3,989,812 bytes).
- GitHub provider SHA256 = GitHub upload-log SHA256 = independently computed SHA256 over downloaded ZIP bytes:
  `ddef2e09f29b460ad4e5ddf8de4f9bd74b79e2befbd1a83f37dfa388c3de66d8`.
- Seven exact ZIP members; all seven CRC checks passed; ZipFile.testzip() returned None: `perl-version.txt`, `result.txt`, `source.txt`, `syntax.stderr`, `test.exit`, `test.stdout`, `test.stderr`.
- `source.txt` exactly e28e6186c108b2ba2e2e7c4e5f32f778df33bd6a; Perl v5.40.5; production/test 2/2 syntax OK; exit code 0; stderr zero bytes; native marker `STAGE22_NATIVE_PASS=1`.
- Full `test.stdout` scan: 33 passing prove invocations (smoke + exactly each shard 0..31), all 33 `All tests successful.` and `Result: PASS`, 0 `not ok`/TAP fail markers. Twenty shards have Tests=46469, twelve have Tests=46467, smoke Tests=61. Total **20×46469 + 12×46467 + 61 = 1,487,045 TAP**.
- Independent Catalan13 ballot oracle: 742,900 ordinal positions across the 32 shards (20×23216 + 12×23215), plus 12 smoke ordinal checks, covering every rank 1..742900 once in the shards; Catalan(13)=742900. Independent discovery CSV SHA256 `67edb036b070b196c6b889b161a27baef6b0ec7852717586550ef2f8b4d7173d`, as established in the prior Stage22 discovery contract.
- 4×13 (52-day) producer count `21604722570792867375065793772732`; first/middle/last BigInt inverse rank tests PASS. These inverse checks do **not** constitute an independent second algorithm verifying the full 4×13 count.
- Historical erratum: earlier report and QA JSON for run 44896322930 incorrectly wrote 1,487,005 TAP using 32×46467+61. Independently verified correct count is 1,487,045 (20 shards have 46469 TAP). Corrected the historical docs/JSON in this acceptance commit.

## Technical acceptance and bounded scope
- Stage22 `WeavingPrimitive.pm` count/rank/unrank API now accepted for 1..13 positive month lengths, sum 1..52 days, preserving numeric lexical ordering, 1-based ranks, BigInt exactness and input immutability.
- Stage22 producer blob SHA: `4a7cd53e7132a6b3ab5fdaffd2d93a498e9296a6`; Stage22 test blob SHA: `a5da36b27fe40cef8e3a2439f46ed0480697f8cb`. No executable source changes in this acceptance commit.
- The separate `MonthOccurrence` 9-month/36-day bound remains unchanged.
- `LAST_COMPLETED_STAGE` advances from 21 to 22. This approval is **not** a full-year generator claim, not a new Stage23, not a merge to main, not a protected-branch change, and not a release.
- Next authorized activity: bounded Stage22 post-acceptance static review or regression investigation at the already accepted 13/52 limits, without duplicate CI dispatch.
