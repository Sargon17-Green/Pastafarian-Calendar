# Stage22 post-acceptance independent 13x4 count — local QA

Date: 2026-11-27
PROJECT_ID: PC-BRANCH-PERL-GUOYU
Branch: Perl+國語
Exact reviewed HEAD: 6a0b988b95dab0a9be41c692a7c9846ccd732ea1
Producer blob (unchanged): 4a7cd53e7132a6b3ab5fdaffd2d93a498e9296a6
Oracle blob: b6f6e055c41e31be369b11fbacc33f6d0279856e
Oracle SHA256: 4d81dc5df32295aabd1534218eb54b3402e00b44fdde4d8b3aada6df2f6049a5

## Coverage gap and contract

The canonical Stage22 acceptance report explicitly says the 13x4 inverse rank checks do not independently verify its count. The subsequent 12/52 maximum-arena independent comparison addresses a different profile. The new test independently counts the 13-month profile (4 repeated 13 times), 52 days. Expected exact count from the previously accepted production report (source e28e6186c108b2ba2e2e7c4e5f32f778df33bd6a, run 44904659215, artifact 14708038426): 21604722570792867375065793772732. Compare the complete decimal integer, not a floating approximation. The already-committed independent forward-transfer oracle never loads the producer. No producer rerun, no new fixture copied from another branch.

## Execution and evidence

- Debian GNU/Linux 13 x86_64, Perl 5.40.1; syntax exit 0.
- Oracle extracted from original source ZIP SHA256 a1d8aece6c21d62f299cda41cacd52f8f41840aabb6233ada7446fc1ef9c050b (CRC passed); exact blob/SHA256 matched GitHub.
- STAGE22_ORACLE_PROFILE=4,4,4,4,4,4,4,4,4,4,4,4,4; ulimit -v 393216; timeout --signal=TERM --kill-after=5s 120s /usr/bin/time -v -o resource.txt perl oracle.pl count.
- Actual stdout: 21604722570792867375065793772732. Exact equality: PASS.
- Oracle stderr: profile_months=13 days=52 capacity=3587219 nonzero_states=3587218 transitions=31089292. This is intentional statistics.
- GNU time: elapsed 41.18s, max RSS 162484 KiB, exit status 0; no swap. Outer tool returned a timeout while the bounded process continued and finished; no separate shell exit file was captured. Exit status is from completed GNU time report, not the outer call.
- Evidence ZIP: /PC-BRANCH-PERL-GUOYU_Evidence/PC_BRANCH_PERL_GUOYU_STAGE22_13X4_INDEPENDENT_COUNT_20261127.zip; SHA256 af9fad0b6f2ea0665185ddf7a8313dd453243cef968a819f04100c9b55ac5c44; 12 members CRC verified.

## Decision

PASS: new local exact independent count agrees with the historical accepted producer count. The historical run/artifact are referenced via prior acceptance, not downloaded or re-adjudicated in this turn. No new Native CI, no new production execution, no independent 13x4 rank comparison, no full-year verification. Historical Stage22 and Ubuntu lexical QA acceptance unchanged. No Stage23/main/merge/release. NEXT: targeted independent lexical rank validation on a new, nontrivial 13x4 ordinal using the existing bounded oracle and a fresh producer-generated word (not a repeat of an accepted inverse case); preserve exact source locks and classify local versus CI separately.
