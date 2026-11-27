# Stage22 CSV lexical edge QA — Ubuntu WSL2 acceptance

Date: 2026-11-27
PROJECT_ID: PC-BRANCH-PERL-GUOYU
Branch: Perl+國語
Verified test-package branch HEAD: 83c7aa5b9f404a164543cad313829afaee358787
Historical oracle source lock: bb49201411b6397819c97e5fc2b40238251e48ce

## Independent evidence adjudication

- User-returned ZIP: PC_PERL_GUOYU_STAGE22_20261127T055516Z_ab811ac19e4d429280b62236a972f487.zip
- SHA256: aaa779ac2c7682ce1ba0a86c76b8ef845e4190b679d7efec5da422608e16323d; 46/46 ZIP members CRC verified; 9/9 guest evidence SHA256 verified against manifest.
- Delivered v011 CMD SHA256: 89ad6d57729fde80bb77f338905b5fc64811724abc9f1199885dd715eaeea4d4; original source ZIP SHA256 a1d8aece6c21d62f299cda41cacd52f8f41840aabb6233ada7446fc1ef9c050b independently recalculated.
- Fixture Git blob 492fc28ade8c19ff037666cd6a863815c5cc3324 and oracle Git blob b6f6e055c41e31be369b11fbacc33f6d0279856e: independently computed from source ZIP, matched live exact HEAD and guest verification. Fixture was introduced after historical oracle lock; no claim that fixture exists at that older commit.
- Ubuntu 26.04.1 LTS x86_64, WSL2 kernel 6.18.58.1-microsoft-standard-WSL2, WSL app 3.0.5.0, stock Perl 5.40.1. Ubuntu image SHA256 expected=actual 48d56724b5c8e60f24893e83e73bbb58c60b3ca22fba3da977075420acd54104 (recorded in RUN.log).
- Process exit/stream self-tests, WSL capabilities, read-only VMP, installation, stock tools and Perl version all pass. APT skipped; no tool upgrades. Guest test started 05:58:26Z and returned 05:58:32Z.
- Actual command: ulimit -v 393216; timeout --signal=TERM --kill-after=5s 90s /usr/bin/time -v perl qa/perl-guoyu/stage22_csv_lexical_boundary_proposal.t
- Profile 2,2, quiet 1 (fixture-local). Raw stdout contiguous ok 1 through ok 27 plus 1..27; no not ok; stderr 0 bytes. Guest exit 0; wall 4.07s; max RSS 15848 KiB; time exit 0. TAP verdict 27/27 TAP OK.
- Nine malformed-input groups: UTF-8 BOM, embedded NUL, trailing NUL, bare CR, double CR before LF, Arabic-Indic digit, fullwidth digit, DEL byte, 64-digit label. Each verified nonzero child exit, no misleading success output, expected error classification.
- Terminate/unregister exit 0; CLEANUP_OK=True; FINAL_EXIT=0. No rerun required.

## Decision

ACCEPTED: exact-source targeted 27-TAP independent oracle lexical QA on Ubuntu WSL2. Debian 27/27 historical local result corroborates. This is user-machine guest native execution, not GitHub Actions, not a bare-metal Ubuntu result and not a new production differential test. No production defect established. Historical Stage22 13/52 acceptance unchanged; full-year NOT_VERIFIED. No Stage23, main, merge or release. Evidence-only record; no CI rerun. NEXT: review remaining authorized Stage22 coverage gaps and contract scope before any further implementation; do not repeat accepted tests without justification.
