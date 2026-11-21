# QA51-B FREE-A: completed exact-SHA Native evidence (2026-11-21)

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Authorized branch: COBOL+简体中文
Tested source/HEAD: a8162a9ed254e04623a2f9865e15cc29587a6eee
Previous source tree: b858f841e3dde0e19e808f4f533ed09ce80e2c54
Production src/big_integer.cob blob: 982c1f266a18c2bcaba79b994177a93750f27bfa (unchanged)
Scope: existing Stage51 post-acceptance QA51-B only. No new Stage52 acceptance.

## Independent completed-run verification

- GitHub Actions push run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44927984916
- Exact SHA: a8162a9ed254e04623a2f9865e15cc29587a6eee; attempt 1, completed/success.
- All jobs: GitHub REST jobs per_page=100 total_count=52, 52 returned, 52 completed/success. No pagination gaps.
- Strict Stage51 job ID 136918187365: completed/success; job name stage51-five-live-same-sign-cancellation-discovery-native. Step includes GnuCOBOL compilation with -Werror and bounded native execution.
- Observed Stage51-native log: RUNS=25, PASS=25, UNEXPECTED_FAILURES=0, INITIAL_OWNERS=125, PRESERVED_AFTER_INPUT_CHANGE=125, SURVIVORS_AFTER_REUSE=100, RESTORED_OWNERS=25, OCCUPIED_REJECTS=25, INVALID_SIGN_REJECTS=25, INIT_VALIDATION_REJECTS=75 with INIT_VALIDATION_GATE=PASS, TO_TEXT_REJECTS=50 with TO_TEXT_GATE=PASS, FREE_A_REJECTS=50 with FREE_A_GATE=PASS. All target slot counts 5; FINAL_CLEANUP=25. HEAP_MEASURED=YES, HEAP_LIVE_POST_RELEASE=0, RESULT=PASS_STAGE51_FIVE_SAME_SIGN_CANCELLATION_NATIVE and STAGE51_NATIVE_GATE=PASS.
- Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44927984916/artifacts/14718245087
- Artifact ZIP size 834 bytes. GitHub API-reported digest sha256:32e3a7414165bc6a72289ff47853aaba49246f21490a7339e01493d4cf91e9a5. Independently downloaded bytes hashed to precisely the same SHA-256.
- Python zipfile.testzip() returned None: CRC PASS. One member stage51-native.log (uncompressed 9620 bytes; member CRC 0x2f1b6ff4), containing exact PROJECT_ID and HEAD above, all noted counts, and gate markers.

## Explicit scope separation

This establishes completed CI and actual strict GnuCOBOL Native verification for the FREE-A **invalid independent NULL-head descriptor rejection witness** at tested SHA only; it does not prove a valid-owner FREE failure, allocation denial, failure inside PATCHED-DISTANCE, failure of HEAP-LIVE, or Stage52. A subsequent documentation-only commit must not be relabeled as an exact-SHA Native run. No production, main, merge or release changes.
