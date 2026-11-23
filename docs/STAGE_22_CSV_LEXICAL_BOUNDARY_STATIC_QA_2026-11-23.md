# Stage22 — post-acceptance CSV lexical boundary coverage audit

Date: 2026-11-23
PROJECT_ID: PC-BRANCH-PERL-GUOYU
Authorized branch: Perl+國語
Prior evidence HEAD: 10abc9920a7e21f15918c8503b3fc3595abb3ad2
SOURCE_COMMIT_LOCK: bb49201411b6397819c97e5fc2b40238251e48ce
New QA-only fixture proposal commit: 84ea1b5e5fafb6da1ecc0205fcf2a15465ad74f9
Fixture Git blob: 492fc28ade8c19ff037666cd6a863815c5cc3324
Fixture local SHA-256: 036b60fe62140cbeed1c3dae2ebcc40de7c1084134e49bfdcbdd69aef490c241

## Source-locked static review

Read exact branch artifacts with verified blobs:
- qa/perl-guoyu/stage22_max_arena_forward_oracle.pl: b6f6e055c41e31be369b11fbacc33f6d0279856e
- qa/perl-guoyu/stage22_oracle_csv_negative_input.t: b41ae40b2b04a07a6b3eb385b2f246097bb5f036
- qa/perl-guoyu/stage22_perl_only_small_contract.pl: 85d055ae9dfec705105109195b8ed259c552d39c

Existing 66 TAP comprise 3 valid single-line encodings × 3 assertions; 15 malformed-word cases × 3; 3 bad CLI cases × 3; and count-mode × 3. The preexisting test set does not explicitly cover the nine byte-oriented cases below.

The forward oracle's exact lexical path opens the input file in raw mode, reads one line, forbids a second line, removes at most one terminal CRLF or LF, checks the byte-oriented ASCII digit grammar /[1-9][0-9]*(,[1-9][0-9]*)*/, then verifies word length and chronological event validity. The static inspection predicts rejection for BOM/NUL/CR anomalies, non-ASCII digits, and DEL. A 64-digit ASCII label passes only the lexical grammar; the domain/order validation is expected to reject it. These predictions remain TEST EXPECTATIONS, not observed runtime outcomes.

## Newly identified coverage gap, not a verified functional defect

The committed, non-executed proposal is:
qa/perl-guoyu/stage22_csv_lexical_boundary_proposal.t

| Fixture | Byte feature | Expected diagnostic |
| --- | --- | --- |
| UTF-8 BOM | EF BB BF before a valid record | invalid CSV format |
| embedded NUL | 00 inside a field | invalid CSV format |
| trailing NUL | 00 before LF | invalid CSV format |
| bare CR | 0D without LF | invalid CSV format |
| double CRLF | 0D 0D 0A | invalid CSV format |
| Arabic-Indic one | D9 A1, not ASCII 31 | invalid CSV format |
| fullwidth one | EF BC 91, not ASCII 31 | invalid CSV format |
| ASCII DEL | 7F before LF | invalid CSV format |
| 64-digit first label | 64 ASCII nines | word violates event order |

Each case makes three assertions: nonzero process exit, zero stdout, and matching error classification. Expected total 9×3=27 TAP. Input is tiny and deterministic; no producer-derived fixture and no other branch's code is used.

## Bounded execution contract and gates

- Inputs: exact source-locked 3 Git blobs; fixture at the blob above; isolated profile STAGE22_ORACLE_PROFILE=2,2; STAGE22_ORACLE_QUIET=1.
- Output: one TAP stream 1..27 and exit 0 if and only if all assertions pass; any child failure, timeout, or diagnostic mismatch is not PASS.
- Resource bound for an Ubuntu/Perl 5.40 job: <=90 s wall time, <=393216 KiB virtual memory; runner script also sets alarm 80. Suggested shell:
  ulimit -v 393216
  timeout --signal=TERM --kill-after=5s 90s perl qa/perl-guoyu/stage22_csv_lexical_boundary_proposal.t
- Required evidence if subsequently executed: exact branch commit and three source blobs; Perl version; command and environment; exit code; wall time; maximum memory; full stdout/stderr; precise TAP 27/27; job/run SHA and artifact with independent checksum when hosted in CI.
- Never run 12/52, 13×4, full Stage01–22, or Stage23 as part of this proposal. No duplicate dispatch on CI 45133678832.

## Observed evidence and classification

- Prior focused Native CSV QA is accepted at GitHub run 45133678832 on workflow SHA 1fce45680162643744f99d4b09dee3b1a72119b8, job 137554747831, artifact 14798647702, provider SHA256 6125942033486ade3bfec40bdf7c613d395705103f9e3351c14d5c0be78c9471. Fetched raw job log contains TAP_VERIFIED=66/66 and TAP_VERIFIED=45/45 and matching upload digest. This is HISTORICAL ACCEPTANCE only, not a new run.
- New QA fixture: Perl v5.40.1 syntax OK locally; local SHA-256 and Git blob computed, branch readback verifies exact blob; no oracle execution or CI/Native/differential PASS is claimed.
- Static coverage review: COMPLETE for the named nine untested lexical classes; no demonstrated runtime producer defect.
- Stage22 historical 13/52 acceptance unchanged. Full-year generator remains NOT VERIFIED. No main/merge/release/Stage23.
- Next authorized action: execute ONLY this bounded 27-TAP QA proposal against the exact source lock, capture full evidence and classify any mismatch; do not promote to Native acceptance until all required gates are verified.
