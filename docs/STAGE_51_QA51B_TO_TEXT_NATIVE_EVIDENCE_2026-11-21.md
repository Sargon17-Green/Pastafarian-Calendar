# QA51-B direct TO-TEXT validation — exact-SHA native evidence (2026-11-21)

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Tested source HEAD: c15a8f06bef403a17857619327f9ecd20b7e2f7b
Parent: b961953470e64cc3e44c990438427eb1c3353d42
Scope: Stage51 post-acceptance test/CI; no production, Stage52, main, merge or release.

## Canonical CI and native execution
- Natural push run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44910442101
- Event=push, attempt=1, run status=completed, conclusion=success, head_branch=COBOL+简体中文, head_sha exactly as above.
- Job inventory: 52/52 completed/success, obtained from full GitHub Actions jobs API with per_page=100 (not the 30-item wrapper).
- Relevant strict Stage51 native job ID 136864912459: completed/success.
- Job log contains STAGE51_NATIVE_GATE=PASS, RESULT=PASS_STAGE51_FIVE_SAME_SIGN_CANCELLATION_NATIVE and STAGE51_PASS=00025 / STAGE51_RUNS=00025.
- Stage51 TO-TEXT direct rejection probes: STAGE51_TO_TEXT_REJECTS=00050, STAGE51_TO_TEXT_GATE=PASS.
- Previously covered INIT-TEXT invalid-input probes: STAGE51_INIT_VALIDATION_REJECTS=00075, STAGE51_INIT_VALIDATION_GATE=PASS.
- Additional observed counters: STAGE51_INVALID_SIGN_REJECTS=00025, STAGE51_OCCUPIED_REJECTS=00025, STAGE51_INITIAL_OWNERS=00125, STAGE51_INPUT_REBUILDS=00100, STAGE51_PRESERVED_AFTER_INPUT_CHANGE=00125, STAGE51_PRESERVED_AFTER_REJECT=00125, STAGE51_SURVIVORS_AFTER_FREE=00100, STAGE51_SURVIVORS_AFTER_REUSE=00100, STAGE51_RESTORED_SNAPSHOTS=00125, STAGE51_FINAL_CLEANUP=00025, target slots=00005 each.
- STAGE51_UNEXPECTED_FAILURES=00000; STAGE51_HEAP_LIVE_POST_RELEASE=00000000000000000000. No unexpected defect observed.

## Artifact independent validation
- Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44910442101/artifacts/14710227564
- Artifact ID: 14710227564, name cobol-stage51-five-live-same-sign-cancellation-evidence, 816 bytes.
- GitHub-reported zip SHA-256: c4a226375fb6decf9bf7880327f68f202f1c22c700c5b8d83de2284e14f37206.
- Independently downloaded ZIP and computed local SHA-256: c4a226375fb6decf9bf7880327f68f202f1c22c700c5b8d83de2284e14f37206, MATCH.
- ZIP CRC verification PASS (ZipFile.testzip returned no bad member); exactly one member stage51-native.log (7,616 uncompressed bytes, CRC 0x6231fe99).
- Embedded PROJECT_ID=PC-BRANCH-COBOL-SIMPLIFIED-CHINESE and HEAD=c15a8f06bef403a17857619327f9ecd20b7e2f7b, both MATCH.

## Gate interpretation and remaining work
PASS is limited to the exact-SHA natural CI and Stage51 QA51-B direct TO-TEXT status49 validation witness plus previously covered bounded INIT rejection, invalid-sign, ownership and heap checks. This is NOT proof that allocator failures, mid-operation failures, FREE-A errors or HEAP-LIVE fault injection have been exercised. Not a new Stage52 or a new formal whole-stage acceptance; prior Stage51 acceptance remains intact.

NEXT: source-grounded QA51-B feasibility audit of a safe deterministic independent test-only witness for remaining failure paths (allocator, mid-operation, FREE-A, HEAP-LIVE); do not inject malformed live pointers or infer any actual failure without evidence. Implement only justified Stage51 test/CI changes on this authorized branch, check exact HEAD before editing and validate any natural completed run. No duplicate dispatch, Stage52, production change, merge, main or release.
