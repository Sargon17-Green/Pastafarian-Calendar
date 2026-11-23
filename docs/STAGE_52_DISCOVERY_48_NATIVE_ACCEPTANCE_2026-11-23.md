# Stage52 / DISCOVERY48 — Native acceptance (2026-11-23)

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Authorized branch: COBOL+简体中文
Decision: ACCEPTED_NO_DEFECT_REPRODUCED_IN_25_BOUNDED_CASES.
Exact tested source SHA: `c63e4a5be045b1732aa1a9c3e4eb2b5e7c086f6c`
Source parent before the one-line test-only correction: `12444a4dba0d8126832e95c3bf697ec4194f7ba6`
Correction scope: `test/stage52_discovery_tests.cob`, one declaration `WS-J PIC 9(4) COMP-5` changed to `WS-J PIC 99`; production files unchanged.
Prior failed strict compile: [run 45075786714](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45075786714), 52/53 jobs success, Stage52 job failed on `-Werror` possible-truncate. This is historical failure evidence, not accepted Native execution.

## Exact source CI and independently verified artifact

- [Natural push run 45083047039](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45083047039): event=push, attempt=1, status=completed, conclusion=success, head_branch=COBOL+简体中文, head_sha=c63e4a5be045b1732aa1a9c3e4eb2b5e7c086f6c.
- Paginated Jobs API (`per_page=100`): total_count=53, 53 returned; all 53 status=completed and conclusion=success.
- [Native Stage52 job 137395293176](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45083047039/job/137395293176): completed/success; Ubuntu 24.04.5; `cobc (GnuCOBOL) 3.1.2.0`, strict `-Werror` compile actually ran; Native executable ran.
- [Artifact 14777914060](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45083047039/artifacts/14777914060), name `cobol-stage52-reversed-same-sign-borrow-evidence`: 805 ZIP bytes; GitHub metadata SHA256 `d69fec662e7cbca50672b0cd9f7fcdac6fe699c121f936e1693a2ebad86ab2d3`; independent full-byte SHA256 computation MATCH.
- ZIP `testzip()` CRC PASS; exactly one member `stage52-native.log`, uncompressed 9303 bytes, CRC `52e9402a`. Embedded `PROJECT_ID=PC-BRANCH-COBOL-SIMPLIFIED-CHINESE` and `HEAD=c63e4a5be045b1732aa1a9c3e4eb2b5e7c086f6c` match exact branch/run. No duplicate workflow dispatch.
- Compiler output includes non-fatal underlying C `_FORTIFY_SOURCE redefined` warnings. The strict `cobc -Werror` step and Stage52 job nevertheless completed/success; these messages do not constitute a hidden Native failure.

## Independent planning oracle (not Native)

```text
STAGE52_PLANNING_CASES=25/25
STAGE52_PLANNING_ARITHMETIC=250/250
STAGE52_PLANNING_ORIENTATION=250/250
STAGE52_PLANNING_SIGN_AND_ENDPOINT_SYMMETRY=500/500
STAGE52_PLANNING_UNIQUE_PAIRS=25
STAGE52_PLANNING_MAX_WIDTH_CASES=5
STAGE52_PLANNING_SLOT_BALANCE=5,5,5,5,5
STAGE52_PLANNING_GATE=PASS_NOT_NATIVE
```

## Native lifecycle and error guards

```text
STAGE52_INITIAL_OWNERS=125
STAGE52_INPUT_REBUILDS=100
STAGE52_PRESERVED_AFTER_INPUT_CHANGE=125
STAGE52_SURVIVORS_AFTER_FREE=100
STAGE52_SURVIVORS_AFTER_REUSE=100
STAGE52_REPLACEMENT_OWNERS=25
STAGE52_RESTORED_OWNERS=25
STAGE52_RESTORED_SNAPSHOTS=125
STAGE52_OCCUPIED_REJECTS=25
STAGE52_INVALID_SIGN_REJECTS=25
STAGE52_INIT_VALIDATION_REJECTS=75
STAGE52_INIT_VALIDATION_GATE=PASS
STAGE52_TO_TEXT_REJECTS=50
STAGE52_TO_TEXT_OVERFLOW_REJECTS=1
STAGE52_TO_TEXT_OVERFLOW_GATE=PASS
STAGE52_FREE_A_REJECTS=50
STAGE52_FREE_A_GATE=PASS
STAGE52_TO_TEXT_GATE=PASS
STAGE52_PRESERVED_AFTER_REJECT=125
STAGE52_TARGET_SLOT_1=5
STAGE52_TARGET_SLOT_2=5
STAGE52_TARGET_SLOT_3=5
STAGE52_TARGET_SLOT_4=5
STAGE52_TARGET_SLOT_5=5
STAGE52_FINAL_CLEANUP=25
STAGE52_RUNS=25
STAGE52_PASS=25
STAGE52_UNEXPECTED_FAILURES=0
STAGE52_HEAP_LIVE_POST_RELEASE=0
RESULT=PASS_STAGE52_REVERSED_SAME_SIGN_BORROW_NATIVE
STAGE52_NATIVE_GATE=PASS
```

## Scope and remaining gaps

This evidence accepts Stage52's **specific** reverse same-sign borrow and five-live-output lifecycle under 25 bounded Native cases. No broad or universal arithmetic correctness, cross-implementation differential validation, or full-calendar integration is claimed. Four prior QA51-B failure paths (allocation denial / partial allocation, valid-owner FREE-A service failure, HEAP-LIVE service failure, and PATCHED-DISTANCE subordinate-error cleanup) remain NOT TESTED / NOT ACCEPTED. No injection was performed. No production, `main`, merge, release, or Stage53 creation. Stage52 accepted on **tested SHA** `c63e4a5be045b1732aa1a9c3e4eb2b5e7c086f6c`; an evidence-only documentation child, if committed, does not acquire a separate Native pass.
