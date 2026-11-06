# Stage16 七月份／二十八日交織擴展：本地獨立 QA（2026-11-06）

Project `PC-BRANCH-PERL-GUOYU`, branch `Perl+國語`. Parent HEAD `569a51ca25f833a4f778d89e5efe3e03c9ae0b32`. Stage15 先前已在源 `7d4151a68ce8b3ce54b51970be24e28748e8d6ec` 以 16/16 必要 jobs 的原生證據驗收。單純文件提交 run 42188259854 已 completed/success，但**不代表 Stage16 Native PASS**。

## 本次修改

- `WeavingPrimitive.pm`: bounded public API keeps 1-based lexicographic ranking and first/last-label rules, extending limit from 6 months/24 days to 7 months/28 days. No production use of oracle or `t/lib`.
- `t/61_stage16_weaving_seven_months.t`: independent complete-multiset-permutation oracle, closed-form Catalan(7)=429 and exhaustive 429 rank round-trips, full 28-day boundary/middle BigInt rank checks, invalid input rejection, immutability.
- `t/47` and `t/48`: historical invalid-limit fixtures adjusted only from newly valid 7/25-day inputs to still-invalid 8/29-day inputs; `[12,13]` changed to `[14,15]`.
- Canonical workflow adds stage16-weaving-seven-months-native, with `source.txt`, Perl version, two syntax traces, test stdout/stderr, exit and result; resource bound 120s/393216KiB, 7-file artifact.

## 本地實測（並非 full suite）

```
Perl v5.40.1
source module syntax OK; new test syntax OK
ulimit -v 393216; timeout 120s prove -e 'perl -CS -Ilib' -v t/61_stage16_weaving_seven_months.t
Files=1, Tests=1053
Result: PASS
exit=0; stderr=0 bytes; ~11 wallclock seconds
STAGE16_EXHAUSTIVE_PROFILES=8
STAGE16_EXHAUSTIVE_POSITIONS=39
STAGE16_CATALAN7_RANKS=429
STAGE16_LARGE_PROFILES=5
STAGE16_INVALID_PROFILES=14
STAGE16_INVALID_RANKS=10
STAGE16_INVALID_WORDS=8
```

The local source reproduced the prior Git blob `bb658cda314b995fb568585715e8bc4e48665c75` before the three-line bounded change. Local updated blob expected `38c887efba2c67f8f0ad2a861f4cace5d07fe80c`; new TAP test blob expected `4afb9cc27b0ca72efcffb1893133df6937832864`. These compare against the remote Git blobs before branch update.

## 尚需 Native 接受證據

Only a completed/success canonical run on this new exact source SHA can establish the stage gate: **17/17 required jobs**, raw 17 logs, Stage01 all-tests PASS, Stage16 syntax2/TAP1053 markers, seven-file ZIP, source/CRC/SHA256 cross-validation. Do **not** set LAST_COMPLETED_STAGE=16 before this. Full calendar with 252..5778 days, sauce and askBowl remain outside this contract. No main/merge/publish.
