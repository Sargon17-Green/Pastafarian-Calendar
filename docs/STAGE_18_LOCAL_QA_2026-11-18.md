# Stage18 local implementation QA — Perl+國語 (2026-11-18)

Project ID: PC-BRANCH-PERL-GUOYU. Parent checkpoint: 5098617468965caf9a534be8be44d6606bd88269.
Scope: extend only WeavingPrimitive upper bounds to 9 months / 36 days, retain existing BigInt APIs. Stage17 is last Native accepted stage; LAST_COMPLETED_STAGE stays 17.

## Exact local test sources
- Production module Git blob: 7402605a542ddad2da9eb8d29ccbf6e7b4c32723 (matched GitHub created blob and native local git hash-object).
- New t/63 Git blob: 68d2bbd47a73ac78b8b04b933666d4480e9162f4 (matched GitHub created blob and native local git hash-object).
- Perl 5.40.1, Linux x86_64; both sources syntax OK.
- `ulimit -v 393216` KiB, `ulimit -c 0`, `timeout --signal=TERM --kill-after=5s 120s`, `prove -e 'perl -CS -Ilib' -v t/63_stage18_weaving_nine_months.t`.
- **9819 / 9819 TAP PASS**, no not-ok, stderr empty, exit 0, **57 wallclock seconds** within 120s.
- Independent full-multiset permutation filter: 4 nine-month profiles, 4 positions (complete enumerations without production-state pruning).
- Independent Dyck-path/Catalan(9): 4862 words, 4862/4862 rank/unrank comparisons, closed-form count 4862.
- Three large 36-day profiles, first/middle/last Math::BigInt roundtrips; 14 rejected profiles, 11 rejected ranks, 8 rejected words, no caller-mutation.
- Obsolete negative fixtures in t/47, t/48, t/49, t/61, t/62 updated only at expanded 9/36 boundary. Historical full-suite tests were not executed in isolated local workspace.

## Acceptance still missing
Canonical GitHub push workflow with 19/19 mandatory jobs completed/success, all 19 raw logs, Stage01 historic suite, Stage18 dedicated 9819 TAP and 7-file artifact with provider/upload/local SHA256, 7/7 CRC, source SHA, Perl version, syntax2, stderr0 and exit0. Do not call Stage18 Native PASS or full-year generator verified until these checks succeed.
