# QA51-B — coverage review closure (decision A, 2026-11-22)

PROJECT_ID: `PC-BRANCH-COBOL-SIMPLIFIED-CHINESE`
Authorized branch: `COBOL+简体中文`
Decision: **A — CLOSE THE COVERAGE REVIEW WITH EXPLICIT OPEN GAPS**
Decision authority: explicit user instruction on 2026-11-22, following the source audit.
Scope: Stage51 post-acceptance QA51-B *coverage review only*. This is **not** a four-path failure-test acceptance, new stage acceptance, production change, or permission to begin Stage52.

## Verified basis

- Prior branch HEAD at decision: `55b57761d2b4f8941b3b21b317552d59b0db8a1b`, docs-only child of exact tested source `b10ccbe1dd2df691c9c4f73839d0f5f9c47894fc`.
- [Exact-source run 44954071859](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44954071859): `completed/success`, push, attempt 1, `COBOL+简体中文`, SHA `b10ccbe1dd2df691c9c4f73839d0f5f9c47894fc`. Jobs API `per_page=100`: `total_count=52`, 52 returned and all `completed/success`.
- [Stage51 Native job 136998174720](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44954071859/job/136998174720): GnuCOBOL 3.1.2.0, strict `-Werror`; `STAGE51_RUNS=00025`, `STAGE51_PASS=00025`, `STAGE51_UNEXPECTED_FAILURES=00000`; `STAGE51_INIT_VALIDATION_REJECTS=00075`, `STAGE51_TO_TEXT_REJECTS=00050`, `STAGE51_FREE_A_REJECTS=00050`, `STAGE51_INVALID_SIGN_REJECTS=00025`, `STAGE51_TO_TEXT_OVERFLOW_REJECTS=00001`, `STAGE51_TO_TEXT_OVERFLOW_GATE=PASS`, and `STAGE51_HEAP_LIVE_POST_RELEASE=00000000000000000000`.
- [Artifact 14726943612](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44954071859/artifacts/14726943612), name `cobol-stage51-five-live-same-sign-cancellation-evidence`, 850 bytes, GitHub metadata digest `sha256:18e59a466c2d89cdf61bc7cfa4a3a4027ed1136bd8814dd530cb6615de7c06c0`, associated with exact tested SHA. Previous records report independent ZIP SHA/CRC and embedded identity checks; **this closure did not re-download or independently rehash the ZIP**.
- [Exact-source feasibility audit](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/55b57761d2b4f8941b3b21b317552d59b0db8a1b/docs/STAGE_51_QA51B_REMAINING_FAILURE_PATHS_SOURCE_AUDIT_2026-11-22.md), blob `18f77f56af93aca808021181b4ee9ab6ef665579`. Parent `55b57761...` changed only this audit file relative to tested source, so no code/CI/prod changes were introduced by that audit.

## Explicitly uncovered failure paths — no PASS, no fabricated expected-red

| # | Remaining failure class | Closure verdict |
| --- | --- | --- |
| 1 | Allocation denial / partial allocation during temporary node-chain construction | **NOT TESTED / NOT ACCEPTED**: valid input does not deterministically deny allocation through existing ABI |
| 2 | Valid-owner `FREE-A` failure during release | **NOT TESTED / NOT ACCEPTED**: earlier invalid independent scratch descriptors do not model mid-free failure of a valid owner |
| 3 | `HEAP-LIVE` service failure | **NOT TESTED / NOT ACCEPTED**: observed zero live heap is a successful measurement, not a forced service failure |
| 4 | `PATCHED-DISTANCE` internal cleanup after a subordinate service failure | **NOT TESTED / NOT ACCEPTED**: direct service-rejection witnesses do not drive the internal post-call error cleanup |

The source audit concluded `NO_SAFE_DETERMINISTIC_UNALIASED_FAILURE_SEAM_VERIFIED` for these four paths under the existing nine-argument real-service ABI and ownership constraints. This is a negative *feasibility* finding, not proof of flawless handling or evidence of an implementation defect.

## Decision and closure gate

- **QA51-B coverage review: CLOSED BY DECISION A, WITH FOUR DISCLOSED GAPS.** Its objective was to classify available evidence and explicitly delimit residual coverage, not to prove the untested branches.
- Accepted historical Stage51 and separately verified QA51-B positive/negative witnesses retain **only their original exact-SHA scopes**. No broader coverage, code correctness, differential validation, or new Native PASS is inferred.
- No new Native run, differential run, CI dispatch, artifact regeneration or failure injection is required by this docs-only closure. Its new docs-only SHA (after commit) has **no separately claimed Native PASS**.
- Do not modify production files, tests, workflow, `main`, protected refs, or merge/release; do not open Stage52. Test-build failure-injection interface (decision B) is **not authorized**.
- No pending user execution or cleanup is required by this decision; no newly received user-local run results.

## Next boundary

No outstanding QA51-B action under current authorization. A future request to instrument the four remaining paths requires **new explicit authorization** and a separate test-build interface contract, code review, exact-SHA CI/Native evidence and independent artifact verification. Do not silently convert this review closure into full-path PASS.
