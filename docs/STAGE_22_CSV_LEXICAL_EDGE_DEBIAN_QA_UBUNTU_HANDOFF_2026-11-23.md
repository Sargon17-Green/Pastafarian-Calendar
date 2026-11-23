# Stage22 CSV lexical edges — local Debian 27/27 TAP and Ubuntu handoff

Date: 2026-11-23
PROJECT_ID: PC-BRANCH-PERL-GUOYU
Authorized branch: Perl+國語
Verified branch HEAD before evidence commit: 0ffc57297346de7d90b2a487915d8f1ead007a2b
Stage22 SOURCE_COMMIT_LOCK: bb49201411b6397819c97e5fc2b40238251e48ce
Stage22 historically accepted; no Stage23/main/merge/release.

## Exact-source preflight
- QA fixture: `qa/perl-guoyu/stage22_csv_lexical_boundary_proposal.t`
  Git blob `492fc28ade8c19ff037666cd6a863815c5cc3324`, SHA-256 `036b60fe62140cbeed1c3dae2ebcc40de7c1084134e49bfdcbdd69aef490c241`.
- Independent forward oracle: `qa/perl-guoyu/stage22_max_arena_forward_oracle.pl`
  Git blob `b6f6e055c41e31be369b11fbacc33f6d0279856e`, SHA-256 `4d81dc5df32295aabd1534218eb54b3402e00b44fdde4d8b3aada6df2f6049a5`.
- The other two historical source-lock blobs were fetched and checked at exact source commit:
  `qa/perl-guoyu/stage22_oracle_csv_negative_input.t` = `b41ae40b2b04a07a6b3eb385b2f246097bb5f036`;
  `qa/perl-guoyu/stage22_perl_only_small_contract.pl` = `85d055ae9dfec705105109195b8ed259c552d39c`.
- Local Git `hash-object` matches the exact fixture and oracle blobs. Both Perl scripts pass `perl -c`.

## Observed local execution (not Ubuntu)
- Host: Debian GNU/Linux 13 (trixie), x86-64; Perl 5.40.1.
- Scope: **only** the source-locked QA proposal; no 111/111 replay, 12/52, 13×4, canonical suite or production code.
- Command: `ulimit -v 393216; timeout --signal=TERM --kill-after=5s 90s /usr/bin/time -v perl qa/perl-guoyu/stage22_csv_lexical_boundary_proposal.t` (resource output redirected separately).
- Actual process exit **0**, stdout exactly **27 numbered `ok` assertions plus `1..27`**, stderr **zero bytes**.
- `/usr/bin/time`: wall time **0:00.73**, max RSS **13,184 KiB**, exit status **0**.
- Nine malformed-input groups each have three passing assertions: BOM, embedded NUL, trailing NUL, bare CR, double CRLF, Arabic-Indic digit, fullwidth digit, DEL, and a 64-digit ASCII field.
- Every individual malformed-input child has a nonzero exit, no success stdout and the specified diagnostic class. These are observations of the independent oracle's lexical behavior, **not evidence of a production defect**.
- Full TAP stdout, stderr, exit code, resource usage, source SHA-256, Git blob hashes and environment snapshot are in the accompanying reproducible ZIP.

## Ubuntu gate and delivery
- Ubuntu-specific execution **NOT_RUN**. Debian local success must not be relabeled Ubuntu Native/CI acceptance.
- Package in `/Pending_User_Execution/PC-BRANCH-PERL-GUOYU_STAGE22_27TAP_UBUNTU_PENDING_20261123.zip` (persistent Library).
- ZIP SHA-256: `a1d8aece6c21d62f299cda41cacd52f8f41840aabb6233ada7446fc1ef9c050b`; 13 entries; ZIP CRC/integrity passed.
- Runner: `bash RUN_UBUNTU_STAGE22_27TAP.sh`; refuses non-Ubuntu/non-Perl5.40, validates exact Git blob and SHA-256, applies 90s/393216KiB bounds, emits complete evidence and nonzero error codes.
- Runner shell syntax checked; on Debian it intentionally refused execution with exit **66** and ran no TAP.
- NEXT: execute **only** this source-locked Ubuntu 5.40 27-TAP package once; verify exit, stdout/stderr, wall time, max RSS, source lock and archived evidence. Do not duplicate accepted CI run `45133678832`; its 111/111 acceptance is historical and unchanged.

## Gate classification
- Source and static/syntax gate: PASS.
- Targeted local Debian Perl 5.40.1 behavioral gate: **27/27 PASS**.
- Ubuntu 5.40 Native/CI and full-year: **NOT_VERIFIED**.
- Stage22 historical accepted 13/52 status unchanged. No production source modification or new stage.
