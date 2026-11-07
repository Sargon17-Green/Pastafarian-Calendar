# Stage16 CI boundary-fixture regression patch — 2026-11-07

Project: `PC-BRANCH-PERL-GUOYU`; branch: `Perl+國語`; base commit `5b4b15941e8c67fd753dee891644e3048fbea869`.

## Observed completed CI failure (not a pending run)

Canonical push workflow [42250795125](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42250795125), attempt 1, exact source `5b4b15941e8c67fd753dee891644e3048fbea869`, completed **failure** on 2026-11-06. 163 jobs total, 17 required: 14 successful, 3 failed, 146 skipped.

- `perl-stage01` [job 128005015111](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42250795125/job/128005015111): 112 test files, 196279 assertions, 3 failing assertions (t/47 case 213, t/49 cases 376-377); full suite FAIL.
- `stage02-weaving-native` [job 128005024661](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42250795125/job/128005024661): one failed assertion out of 261, `t/47_stage02_weaving_primitive.t` line 64.
- `stage04-month-occurrence-native` [job 128005024728](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42250795125/job/128005024728): two failed assertions out of 385, `t/49_stage04_month_occurrence.t` line 74.
- `stage16-weaving-seven-months-native` [job 128005024690](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42250795125/job/128005024690): dedicated native job succeeded; 1053/1053 TAP, source SHA exact, marker values (8 profiles, 39 positions, 429 Catalan ranks, 5 large cases, 14 invalid profiles, 10 invalid ranks, 8 invalid words), stdout summary PASS. Artifact [13521559747](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42250795125/artifacts/13521559747) was uploaded with provider SHA256 `2c67027022d3d13c145d0b3100406f2f57d534d78bc13042c1f78636dea407a5`; **independent ZIP digest/CRC validation is not claimed**.

## Root cause and minimal change

The Stage16 production change deliberately increased supported configurations from **six months / 24 days** to **seven months / 28 days**. Legacy negative cases in Stage02 and Stage04 still expected newly legal inputs to be rejected. This is an **obsolete test fixture**, not evidence of an algorithm defect:

- Stage02: `[1,1,1,1,1,1,1]` (7 months, 7 days) is now valid; replace only this invalid-fixture input with eight unit-length months (8 months, still rejected).
- Stage04: `[25]` (one month, 25 days) and `[(1)x7]` (7 months) are now valid; replace invalid-fixture inputs with `[29]` (29 days) and `[(1)x8]` (8 months).

All changes are confined to two negative-input tests. Independent algorithm-oracle logic, production implementation, workflow, stage marker, all other fixtures, and `LAST_COMPLETED_STAGE=15` remain untouched.

## Acceptance gate

Do not accept Stage16 from the failed run or the isolated successful job. New push CI on the **patch commit** must reach completed/success; require 17/17 necessary jobs, review all 17 raw job logs, Stage01 full pass, dedicated Stage16 1053 TAP and markers, and independently validate the exact-source seven-member Stage16 artifact (provider/upload/local SHA256 and ZIP CRC). Only then set `LAST_COMPLETED_STAGE=16` and design the next bounded contract. No duplicate manual workflow dispatch, no main/merge/publish.
