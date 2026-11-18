# Stage18 Native CI Acceptance — Perl+國語 (2026-11-18)

Project ID: `PC-BRANCH-PERL-GUOYU`  
Branch: `Perl+國語`  
Accepted source SHA: `7ae6fc32ce7ce9593ad41dc5c75056fa564aa591`  
Previous accepted stage: 17  
New accepted stage: **18**

## Canonical push workflow

- Workflow: `Canonical Names Lock` (`.github/workflows/canonical-names-lock.yml`)
- Run: [44365406989](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44365406989)
- Event / attempt: `push` / `1`
- Run result: `completed / success`
- Run head SHA: `7ae6fc32ce7ce9593ad41dc5c75056fa564aa591`, exactly equal to the verified branch HEAD.
- Required jobs: **19/19 completed/success**.
- Conditional jobs: 146 skipped as designed; 165 jobs total.
- All 19 required raw job logs were fetched and inspected.

## Whole-project required suite

The `perl-stage01` required job completed successfully. Its raw log reports:

- 114 test files
- 209,070 TAP tests
- `Result: PASS`

The separate `verify` job also completed successfully. All stage-specific required jobs Stage02–Stage18 completed successfully; their test summaries and success markers were checked in the corresponding raw logs.

## Stage18 native test

Job: [stage18-weaving-nine-months-native](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44365406989/job/135017694309)  
Job ID: `135017694309`  
Dedicated test: `t/63_stage18_weaving_nine_months.t`

The native job ran with Perl `v5.40.5`, a 120-second timeout and a 393216-KiB virtual-memory limit. It completed in 67 wall-clock seconds.

- TAP: **9,819 / 9,819**, `All tests successful`, `Result: PASS`
- Production module and test syntax: **2/2 syntax OK**
- Test exit code: `0`
- Test stderr: empty
- Native marker: `STAGE18_NATIVE_PASS=1`

Independent checks recorded by the test:

- Four exhaustive nine-month profiles and four exhaustive positions, using complete multiset permutations and independent first/last-occurrence validation.
- Closed-form `Catalan(9) = 18!/(9! 10!) = 4862`.
- All 4,862 independently generated Dyck words compared in lexicographic order, with 4,862 bidirectional rank/unrank checks.
- Three large 36-day profiles, including first/middle/last exact `Math::BigInt` rank roundtrips and input immutability.
- Invalid inputs: 14 profiles, 11 ranks, and 8 words rejected.

The test and workflow explicitly retain `STAGE18_FULL_YEAR_GENERATOR_NOT_VERIFIED`. This acceptance is limited to the nine-month / 36-day weaving primitive; it does **not** establish full-year calendar generation.

## Native artifact verification

Artifact: [14461669928 — perl-stage18-weaving-nine-months-native](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44365406989/artifacts/14461669928)

- Downloaded ZIP size: 26,561 bytes.
- SHA-256: `146fd95dd91efee3da91c645f4b71a161ab3dcd7ff34afc099f9ecba64570f00`.
- The digest matches the upload-step SHA-256 log, GitHub's artifact API digest, and the locally downloaded ZIP.
- ZIP integrity: all 7 members passed CRC validation.
- `source.txt`: exact accepted source SHA `7ae6fc32ce7ce9593ad41dc5c75056fa564aa591`.
- `perl-version.txt`: `v5.40.5`.
- `syntax.stderr`: exactly two `syntax OK` lines.
- `test.exit`: `0`.
- `test.stderr`: 0 bytes.
- `result.txt`: `STAGE18_NATIVE_PASS=1`.

The seven members are `perl-version.txt`, `result.txt`, `source.txt`, `syntax.stderr`, `test.exit`, `test.stderr`, and `test.stdout`.

## Acceptance decision

**Stage18 is accepted as Native CI PASS.** The evidence covers the exact source SHA, the canonical push workflow, every required job, the whole-project required suite, the dedicated Stage18 native test, and the uploaded artifact.

`LAST_COMPLETED_STAGE` advances from 17 to 18. No main-branch update, merge, release, or external publication was performed. The full-year generator remains unverified.
