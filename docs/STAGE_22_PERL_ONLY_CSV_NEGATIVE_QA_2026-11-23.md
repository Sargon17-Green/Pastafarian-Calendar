# Stage22 post-acceptance QA: strict lexical CSV input (Perl+國語)

Date: 2026-11-23
PROJECT_ID: PC-BRANCH-PERL-GUOYU
Authorized scope: maintenance QA for already accepted Stage22 only.
Starting branch HEAD: `d5d9682798fe1751bbc9995e542a8605e5371e77`.
No Stage23, full-year, main, merge, release, or change to production.

## Observed code defect and bounded reproduction

The previous independent Perl-only forward oracle blob
`6745f95942bd3376185ce0bc822f15271806bf4f`
in `lex` mode read only `my $line = <$fh>`, immediately closed the handle,
then validated only the first CSV record. Therefore a valid four-label
`STAGE22_ORACLE_PROFILE=2,2` word followed by a second line
(`1,1,2,2\nEXTRA\n`) passed its CSV syntax and word parsing.
This is an oracle QA-input-validation defect, **not** evidence of a
producer rank/unrank or counting defect.

The exact extracted original parsing logic reproduced first-line acceptance
under local Perl v5.40.1 (syntax exit 0, sample prints accepted first line).
The revised parsing excerpt passed ten focused local cases: three valid
single-line encodings and seven malformed/extra-line cases.
These excerpt tests are **not** a run of the complete oracle, CI or Native.

## Fix and regression contract

- QA oracle: `qa/perl-guoyu/stage22_max_arena_forward_oracle.pl`
  changes only the CSV file reader: reject any second physical line, including
  empty trailing lines; retain LF/CRLF single-line and EOF-terminated single
  records. New oracle Git blob: `b6f6e055c41e31be369b11fbacc33f6d0279856e`.
- Independent QA regression:
  `qa/perl-guoyu/stage22_oracle_csv_negative_input.t`,
  Git blob `b41ae40b2b04a07a6b3eb385b2f246097bb5f036`.
  Input profile `2,2` (four positions, exactly two valid words).
  Cases: three accepted records, fifteen rejected files (including second
  record, blank line, garbage, CRLF second record, zero/leading-zero/non-numeric,
  wrong lengths, invalid event ordering), three invalid CLI invocations,
  plus one legal `count` invocation. Contract: nonzero exit and no successful
  stdout for each invalid input; explicit diagnostic; exact ordinal for two
  valid words. Planned `66` TAP assertions; run to verify.
- The source-locked isolated runner
  `qa/perl-guoyu/stage22_max_arena_native_ci.sh` now pins the new
  oracle blob, includes the QA test in its file SHA256 manifest, and runs
  `negative_contract` and `negative_syntax` gates if invoked in future.
  No run is dispatched or represented as successful by this commit.
- Production `lib/Pastafari/Monster/WeavingPrimitive.pm` remains pinned at
  Git blob `4a7cd53e7132a6b3ab5fdaffd2d93a498e9296a6`.
  Independent brute-force positive oracle remains unchanged at
  `85d055ae9dfec705105109195b8ed259c552d39c`.
  Bootstrap source remains unchanged at
  `c157f381e85fbbf6fb6350d0cfb2f307b01d9822`.

## Acceptance and unverified gates

Existing accepted canonical Stage22 source `e28e6186c108b2ba2e2e7c4e5f32f778df33bd6a`,
run `44904659215` and artifact `14708038426` remain historical and unchanged.
Existing isolated 12/52 Perl-only Native acceptance source
`3df76ff3a6e98fcd5b650f0b18a1da203ec8be39`,
run `45068493142`, job `137349926607`, artifact `14771599777`,
SHA256 `8c98e159cd47918d3401eae8da956f971da1fab2d80296de869e1cf8a6d2d28e`
remain historical and unchanged.

Current change is QA-only code + regression + future source-locked runner
maintenance, with only local excerpt parsing proof. It is **not**
new complete-oracle test, Native PASS, CI PASS, differential acceptance, or
renewed Stage22 acceptance. Commit uses `[skip ci]` to avoid automatic
duplicate 12/52 execution.

NEXT: execute the new tiny-profile 66-TAP regression and syntax checks
against the committed exact blob in a source-locked environment. Diagnose
any concrete failure, then decide whether a distinct narrow QA-only job
is warranted; do not rerun accepted Catalan13 or 13x4 or open Stage23.
