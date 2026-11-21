# Stage51 / DISCOVERY47 — invalid-sign negative-path QA evidence (2026-11-21)

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
**Tested source HEAD:** `1d6573306b344c3ebb555649ce46fcc11c94e3b2`
Parent: `3504b29766d35e20748d1c8a5aefffcce81dd6d2`
Scope: post-acceptance Stage51 test-only QA; Stage52 unopened. No production, main, merge or release.

## Completed exact-source CI and Native evidence

- Natural push run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44884376577
- Run attempt 1, head_branch=`COBOL+简体中文`, head_sha=`1d6573306b344c3ebb555649ce46fcc11c94e3b2`, status=completed, conclusion=success.
- Paginated GitHub jobs (per_page=100): **52/52 completed/success**, no missing jobs.
- Stage51 strict Native job: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44884376577/job/136786359002 ; completed/success.
- Runner Ubuntu 24.04.5; GnuCOBOL **3.1.2.0**, compile flags include `-Werror`. Test executable actually compiled and ran. Compiler's `_FORTIFY_SOURCE` redefinition warnings came from the toolchain, without a failing exit.
- Actual native: `STAGE51_RUNS=25`, `STAGE51_PASS=25`, `STAGE51_INVALID_SIGN_REJECTS=25`, `STAGE51_OCCUPIED_REJECTS=25`, `STAGE51_UNEXPECTED_FAILURES=0`, `STAGE51_HEAP_LIVE_POST_RELEASE=0`, `STAGE51_NATIVE_GATE=PASS`.
- Original ownership/reuse invariants retained: initial=125, rebuilds=100, preserved-after-change=125, preserved-after-reject=125, survivors-after-free=100, survivors-after-reuse=100, replacements=25, restored owners=25, restored snapshots=125, final cleanup=25, each target slot=5; 26 `STAGE51_HEAP_MEASURED=YES` markers.
- Independent planning/model results in job log, *not themselves Native*: `STAGE51_PLANNING_CASES=25/25`, arithmetic `250/250`, sign symmetry `125/125`, `STAGE51_PLANNING_GATE=PASS_NOT_NATIVE`.

## Artifact provenance independently checked

Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44884376577/artifacts/14700371157

- Artifact ID `14700371157`, name `cobol-stage51-five-live-same-sign-cancellation-evidence`, ZIP size **759 bytes**.
- Downloaded exact ZIP bytes independently; SHA-256:
  `5e5aa7964c67d5030ca41ceb178f55ec9b95a803c628d152dd11540337d9c46a`.
- ZIP CRC integrity check PASS (`testzip() == None`); exactly one member: `stage51-native.log`.
- Embedded `PROJECT_ID=PC-BRANCH-COBOL-SIMPLIFIED-CHINESE` and `HEAD=1d6573306b344c3ebb555649ce46fcc11c94e3b2` MATCH.
- Embedded log independently checked for `INVALID_SIGN_REJECTS=00025`, `PASS=00025`, `UNEXPECTED_FAILURES=00000`, `HEAP_LIVE_POST_RELEASE=00000000000000000000`, `STAGE51_NATIVE_GATE=PASS`.
- No duplicate workflow run dispatched.

## Exact verdict and limits

**VERIFIED: bounded Stage51 invalid-sign rejection QA on tested source SHA**. The 25 real non-occupied sign=2 validation rejections return status 22 while five live result owners remain preserved, and the full Stage51 lifecycle continues to clean up. This supplements, but does not replace, the Stage51 formal acceptance dated 2026-11-20.

This is **not** proof of generalized service-failure cleanup: allocator/INIT-TEXT, TO-TEXT, FREE-A and HEAP-LIVE injected error paths are not covered by these 25 cases. QA51-B remains an explicit evidence/coverage gap, not an observed production defect. Do not mark Stage52 opened or accepted, or infer a production patch.

This evidence file is docs-only and records the run on its **parent tested source HEAD**. If this documentation commit causes another natural CI run, do not regard that new run as completed or Native PASS without separately checking its exact SHA, jobs and logs. No manual rerun is warranted for the already-accepted tested SHA.

NEXT: source-grounded QA51-B feasibility audit of deterministic *supported* non-occupied service-failure injection at the ABI boundary; define inputs, expected status, unchanged output/owners and cleanup invariants before writing any test. Do not invent a failure code, change production, or open Stage52.
