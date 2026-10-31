# Stage34 / Discovery19 — exact-SHA Native evidence seal

Branch: `PowerShell+Tagalog`.

## Implementing-SHA evidence

- Implementing commit: https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/371bd1c709daf87223ec80835dc9fa17b75ae27b
- Exact implementing run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41244612808
- Run state: `completed/success`; event `push`; branch `PowerShell+Tagalog`; `head_sha=371bd1c709daf87223ec80835dc9fa17b75ae27b`, matching the live branch HEAD at adjudication.
- Eight of eight jobs completed successfully. No manual dispatch or duplicate run was used.

| Job | Job ID | Result |
|---|---:|---|
| verify | 124665337203 | success |
| Stage31 normative year-5000 boundary probe | 124665337362 | success |
| Stage33 bounded calculation-target interaction | 124665337386 | success |
| Stage31 bounded ordinal extension | 124665337397 | success |
| Stage32 bounded adjacent target transitions | 124665337469 | success |
| Stage34 bounded seal-axis cubic interaction | 124665337471 | success |
| Stage31 bounded ordinal First/Step research | 124665337508 | success |
| Native Windows PowerShell 5.1 Stage29+Stage30 and regressions | 124665337569 | success |

## Stage34 Native result

The Stage34 job ran the independent-oracle test under Windows PowerShell 5.1 and emitted the exact implementing SHA.

- Assertions: **448 passed, 0 failed**.
- 8 cubes; 32 labeled calculation/target contexts; 24 unique numeric pairs (overlap between neighboring labels is expected and separately counted).
- 64 per-seal endpoints; 32 seal edges; 16 calculation/target faces.
- Third First contrast: (E=0) in 0 cubes and (E\ne0) in 8; 8 distinct E values.
- Step contrast: R flipped in 5 cubes and remained the same in 3.
- The test compares per-endpoint First/Step, seal-edge deltas, both face interactions, and the third-axis E/R contrasts against the independent normative oracle for the finite declared domain.

Stage34 artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41244612808/artifacts/13058627267

## Regression and verification evidence

- Stage31: 309 + 441 + 85 = **835 assertions**, zero failures across ordinal, extension, and normative year-5000 boundary jobs.
- Stage32: **239 assertions**, zero failures; `STAGE32_SEAL_RECHECK=PASS`.
- Stage33: **560 assertions**, zero failures; `STAGE33_SEAL_RECHECK=PASS`.
- Stage01–30 predecessor suite: **664 assertions**, zero failures; Stage29 Native and Stage30 research checks passed.
- Canonical names `verify` job: success.
- Stage23 finalizer idempotency: two runs, both exit code 0, both `ALREADY_FINALIZED=True`, both stderr length 0; the metadata SHA256 before and after each run remained `CF360CA6F74E965DC460CF79034317187FE5A7DC2148BE7C85A6CE16B6C66829`. The job ended `RESULT=PASS`.

Across the counted suites, 664 + 835 + 239 + 560 + 448 = **2746 assertions**, with no reported failures. These are per-suite harness totals, not a statistical sample size.

## Interpretation and limits

This is bounded research evidence only. The observed nonzero E values and R flips apply only to the eight declared cubes, two seals, and selected year-5000/foundation targets. They do not establish statistical uniformity, independence, a Gregorian mapping, or general behavior outside this finite domain. No production code, normative oracle, or `main` branch was modified.

## Seal state and required recheck

The implementing SHA has completed Native verification. This evidence-only commit records `CURRENT_STAGE=34`, `LAST_COMPLETED_STAGE=34`, and `STAGE34_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED`. The automatic CI run triggered by this seal commit must independently recheck the exact new seal SHA: all eight jobs, Stage34 448/448, predecessor suites, canonical verify, and two idempotent Stage23 finalizer passes. The workflow now emits `STAGE34_SEAL_RECHECK=PASS` only when the sealed metadata pair is present and the Stage34 test succeeds. Until that new run is completed and its logs are verified, the seal-commit recheck remains pending; this document does not claim that later PASS.
