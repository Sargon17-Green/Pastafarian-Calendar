# Stage53 / DISCOVERY49 — Native acceptance (2026-11-23)

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Authorized branch: COBOL+简体中文
Decision: **ACCEPTED_NO_DEFECT_REPRODUCED_IN_25_BOUNDED_CASES**.
Exact tested source SHA: `a986b5ee65af5fc9da402685942e19cf7f8a9e13`
Test-only harness: `test/stage53_discovery_tests.cob` (blob `0f60a2b22291de86ce6599118411612ed537434b`).
Contract: `docs/STAGE_53_DISCOVERY_49_CANONICAL_ZERO_FIVE_LIVE_CONTRACT_2026-11-23.md`.
No production or protected-branch change.

## Exact source CI and Native evidence

- [Natural run 45263265922](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45263265922): status=completed, conclusion=success, attempt=1, head_branch=COBOL+简体中文, head_sha=a986b5ee65af5fc9da402685942e19cf7f8a9e13.
- Paginated GitHub jobs API (`per_page=100`): total_count=54, returned=54, all 54 status=completed and conclusion=success.
- [Stage53 native job 138003368333](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45263265922/job/138003368333): completed/success; GnuCOBOL 3.1.2.0, `cobc` strict flags including `-Werror`; compile and executable ran; marker `STAGE53_NATIVE_GATE=PASS`.
- Raw job log was inspected, including compiler command, executable output, asserted markers, and artifact upload. Some underlying C `_FORTIFY_SOURCE redefined` warnings were nonfatal; strict COBOL compilation and executable succeeded.
- [Stage53 artifact 14860169407](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45263265922/artifacts/14860169407), name `cobol-stage53-canonical-zero-five-live-evidence`: downloaded full ZIP 731 bytes, independent SHA256 `e03e37f98959e5ef54ec21e8adc2f3bea6e7cabf10ba7b991dd49f46e1bf243b`, exactly matching GitHub metadata and upload log; ZIP CRC checked with `testzip()` and passed.
- ZIP has exactly one member, `stage53-native.log`, uncompressed 1998 bytes, member CRC `474a9228`. Embedded PROJECT_ID and HEAD match exact run and source SHA. No manual duplicate rerun.

## Independent planning oracle — PASS_NOT_NATIVE, not a substitute for Native

```text
STAGE53_PLANNING_CASES=25/25
STAGE53_PLANNING_UNIQUE_PAIRS=25
STAGE53_PLANNING_ARITHMETIC=250/250
STAGE53_PLANNING_METAMORPHIC_SYMMETRIES=500/500
STAGE53_PLANNING_ZERO_CANONICAL=50/50
STAGE53_PLANNING_WIDTH_8192_CASES=5
STAGE53_PLANNING_OCCUPIED_OWNER_MODEL=25/25
STAGE53_PLANNING_SURVIVORS_FREE_MODEL=100/100
STAGE53_PLANNING_SURVIVORS_REUSE_MODEL=100/100
STAGE53_PLANNING_RESTORED_MODEL=25/25
STAGE53_PLANNING_TARGET_SLOT_BALANCE=5,5,5,5,5
STAGE53_PLANNING_GATE=PASS_NOT_NATIVE
```

## Measured GnuCOBOL Native counters (embedded artifact)

```text
STAGE53_RUNS=25
STAGE53_PASS=25
STAGE53_INITIAL_OWNERS=125
STAGE53_ZERO_CANONICAL=50
STAGE53_PRESERVED_AFTER_INPUT_CHANGE=125
STAGE53_OCCUPIED_REJECTS=25
STAGE53_SURVIVORS_AFTER_FREE=100
STAGE53_SURVIVORS_AFTER_REUSE=100
STAGE53_REPLACEMENT_OWNERS=25
STAGE53_RESTORED_OWNERS=25
STAGE53_FINAL_CLEANUP=25
STAGE53_HEAP_SAMPLES=25
STAGE53_HEAP_LIVE_POST_RELEASE=0
STAGE53_TARGET_SLOT_1=5
STAGE53_TARGET_SLOT_2=5
STAGE53_TARGET_SLOT_3=5
STAGE53_TARGET_SLOT_4=5
STAGE53_TARGET_SLOT_5=5
STAGE53_UNEXPECTED_FAILURES=0
STAGE53_HEAP_MEASURED=YES
RESULT=PASS_STAGE53_CANONICAL_ZERO_FIVE_LIVE_NATIVE
STAGE53_NATIVE_GATE=PASS
```

## Decision scope and nonclaims

Stage53's *specific* canonical-zero / maximum-width / five-live caller-owned lifecycle contract is accepted in 25 bounded Native executions. The measured post-release heap is zero for these cases. This is not a universal arithmetic correctness proof, whole-calendar integration test, or cross-implementation Native differential test. No general production defect was reproduced. The four pre-existing QA51-B injected-service failure paths (allocation denial/partial allocation; valid-owner FREE-A service failure; HEAP-LIVE service failure; subordinate PATCHED-DISTANCE error cleanup) remain NOT TESTED / NOT ACCEPTED and outside Stage53 scope. Full calendar integration remains NOT_YET_AVAILABLE.

Acceptance attaches to exact **tested** source SHA `a986b5ee65af5fc9da402685942e19cf7f8a9e13`; the evidence-only documentation child that adds this report and updates the append-only development ledger has no independent Native PASS. No production, `main`, merge, release, fault injection, or Stage54 source implementation is performed by this acceptance documentation.
