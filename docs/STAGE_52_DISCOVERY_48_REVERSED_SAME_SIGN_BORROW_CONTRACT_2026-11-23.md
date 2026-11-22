# Stage52 / DISCOVERY48 — reversed same-sign decimal borrow

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Opened: 2026-11-23, user direction: stage transitions need no separate approval.
Parent HEAD: `f06bcb878a53f37d4b8946fb328d18ed1045b1a2`.
Prerequisite: Stage51 accepted on SHA 99a291cb189a5efc35f3c1c1d5d80c43fb5691c3 (run 44811119586); QA51-B exact-source extended run 44954071859 completed/success on b10ccbe1dd2df691c9c4f73839d0f5f9c47894fc. The four QA51-B untested service-failure paths remain explicitly untested. No injection interface is authorized or used.

## Distinct bounded hypothesis

Stage51's positive operands were C>T and its negative replacement operands C'<T'. The complementary same-sign comparison directions (positive C<T and negative C'>T') with 8192-digit borrow propagation have not been separately tested as a five-live-output lifecycle. Stage52 exercises those directions with a new 25-case fixture family, without alleging a reproduced defect.

For n in {3,9,128,320,8192}, j=1..5, B=10^(n-1):
- Baseline C=3B-j >0 and T=3B >0; candidate slot k=1..5 has C_k=3B-j-(k-1) < T.
- Expected R_k=|T-C_k|+1=j+k, exactly 2..10.
- Reinitialize both owned input descriptors as C'=-C and T'=-(3B+j), both negative; the replacement candidate is -C_k > T'.
- Expected R'_k=|T'-(-C_k)|+1=2j+k, exactly 3..15.
- All magnitudes have n decimal digits; for n=8192, initialize unsigned magnitude and set normalized sign in an owned descriptor rather than supplying 8193 bytes to INIT-TEXT.

In each case retain five independent owned results; snapshot descriptors, text and owner pointers. Release/reinitialize both inputs, assert all five outputs preserved, attempt occupied output and verify rejection without mutation, release slot (caseIndex mod 5), verify four survivors, produce the replacement from negative operands, verify ownership and exact text, restore original inputs and selected output, and release all owners with measured HEAP-LIVE=0. Preserve failure-path cleanup. Distinctness/ownership and service-rejection regressions copied from this same branch's accepted Stage51 harness are regression guards, not evidence that the four QA51-B uncovered service-failure paths have been exercised.

## Independent oracle and gate

`test/stage52_planning_oracle.mjs` computes the true absolute signed difference using JS BigInt. Separately, decimal characters are subtracted digit-by-digit with an explicit borrow and +1 carry. It asserts 25 distinct input pairs, 250 exact decimal results, 250 comparison orientations, 500 sign/endpoint symmetries, five width-8192 cases and balanced release slots 5,5,5,5,5. This is independent of COBOL and must print `STAGE52_PLANNING_GATE=PASS_NOT_NATIVE`.

`test/stage52_discovery_tests.cob` is a new test-only strict GnuCOBOL Native harness, not a production change. The one added canonical CI job must compile -Werror with a 300s limit and run with a 120s limit; upload the exact raw log on success or failure, ensure PROJECT_ID+HEAD in log, and gate 25/25 native cases, zero unexpected failures, five owner slots, 125 initial owners, 100 input rebuilds, 25 occupied rejections, all lifecycle counters, and heap=0. Existing accepted Stage51 service-rejection checks remain regressions, not novel QA51-B coverage. Total workflow jobs expected 53 on the new SHA.

## Acceptance boundary

Creation and a queued/in_progress CI run are not a Native PASS. Require exact new branch SHA, completed/success run and 53/53 jobs (paginate), strict Stage52 job log markers, full artifact byte digest versus GitHub metadata, ZIP CRC and embedded PROJECT_ID/HEAD verification before Native acceptance. Until those conditions hold, `LAST_COMPLETED_STAGE=51`, `STAGE52_NATIVE=AWAITING_EXACT_SHA_COMPLETED_CI_LOG`, and complete calendar integration is NOT_YET_AVAILABLE. Do not relabel any of the four QA51-B service-failure gaps as tested. No production edits, main, merge or release.
