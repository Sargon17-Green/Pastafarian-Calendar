# Stage21 12-month / 48-day production candidate — local QA (2026-11-20)

PROJECT_ID: PC-BRANCH-PERL-GUOYU
Branch: Perl+國語
Exact parent HEAD verified at edit start: 4291cc7223cc5a7ba5c035cc94867d1641e7f554
LAST_COMPLETED_STAGE=20. Stage21 code is a **production candidate only**. No Stage21 Native CI acceptance, merge, release or full-year generator validation is claimed.

## Scope and design
- Replace recursive comma-joined memoization with a mixed-radix dense-state suffix counter for at most 12 months and 48 days; maintain first-appearance and last-appearance increasing order, numeric lexicographic 1-based ranks, non-mutating profile/rank arguments, fresh returned words and exact Math::BigInt public results.
- Internal packed four 64-bit limbs use base 10^12. Exact count of all 48-day, 12-label four-occurrence words lies below the representable 10^48 bound.
- Preserve MonthOccurrence at <=9 months/36 days and leave date semantics/other languages untouched.
- New independent ordinal Dyck Catalan12 oracle: all 208012 words hashed as CSV rows, SHA256 0dbe36d23b6ffaa14822b1556d3eabc777d5961bdfd2fd79be39ee2daee76bbe, partitioned deterministically into 16 shards: first twelve of 13001 ranks and last four of 13000 ranks. No producer DP recurrence is used in the oracle.
- New independent multiset enumeration for 30 heterogeneous small profiles (74 valid ranked words); boundary, invalid input, immutability, first/middle/last inverse checks.
- Adjust obsolete negative-only fixtures in t/47,t/48,t/61,t/62,t/63,t/64,t/67 to remain invalid under 12/48: 13 months or 49 days, not the newly permitted 12 months and 45 days.

## Source and targeted local QA evidence
Verified native Perl 5.40.1 in isolated GNU/Linux; commands used process timeout 120s and ulimit -v 393216 KiB:
- Production module Perl syntax OK. Test files t/68 and t/69 syntax OK.
- Exact [4x12] count = 11105730970797793977337986040, exit 0, 13.45 seconds, peak RSS 160384 KiB. Digitwise matches both independently implemented backwards and forwards Perl research counters.
- Stage20 [4x11] count = 6769339545226096626603442, exit 0, 3.96 seconds, peak RSS 60544 KiB. This is a focused compatibility check, not a full legacy-suite rerun.
- [4x12] last-rank unrank/rank inverse: exit 0, 27.38 seconds, peak RSS 160416 KiB.
- t/68: shard0 26044/26044 TAP, exit 0, 21.64 seconds, RSS 83712 KiB; shard8 26044/26044 TAP, exit 0, 24.55 seconds, RSS 83712 KiB. The native job must independently run all sixteen shards; running two locally does not prove the remaining fourteen.
- t/69: 208/208 TAP, exit 0, 0.15 seconds, RSS 17664 KiB; independent enumeration verifies 74 valid ranked words across 30 profiles.
- Earlier oracle prototype storing 208012 unpacked Perl ARRAY references exceeded memory cap; replaced with compact packed byte-string words, preserving the independently verified hash. An earlier mixed test included a Math::BigInt::bdiv list-context remainder in the candidate ranks; repaired test only. Neither is evidence of a producer defect.
- The old Stage20/legacy full test suite on the new source SHA has **not** been run locally. Canonical perl-stage01 CI on the new SHA must settle regressions.

## Exact Git object inventory before commit
- production lib/Pastafari/Monster/WeavingPrimitive.pm: ca8180ded4d90c7f122279d16d697285a4e5d584
- t/68_stage21_weaving_twelve_months.t: 245fa2ad898bba4a1925892b76c79d4e92a74e7a
- t/69_stage21_mixed_profiles.t: 4030ca3e0bf04da4eb9bdd9264ff147ef73e7a48
- canonical workflow: 8eaafd498ec363327549b05d1a3b9dbb4b53fdb8
- all seven changed legacy negatives preserved original assertion counts; only invalid profile literals changed.

## Native acceptance gate / NEXT
Commit only to Perl+國語 with exact-parent lease. Automatic push CI must provide source-exact completed/success for all 22 mandatory jobs (not merely overall run status), inspect all raw logs and the dedicated Stage21 result. The new dedicated job checks three Perl syntax OK lines, mixed tests, all sixteen independent Catalan12 shards, two separate bounded [4x12] count and last-rank inverse processes, exit code, stderr and hash. Verify original ZIP contains exactly seven files (source.txt, perl-version.txt, syntax.stderr, test.stdout, test.stderr, test.exit, result.txt), no missing/extra evidence files, SHA256 provider/upload/local match and all CRCs. Only then may LAST_COMPLETED_STAGE advance from 20 to 21. Running/pending jobs are neither PASS nor a blocker; do not dispatch duplicates. No main/merge/release. Full-year generator remains unverified.
