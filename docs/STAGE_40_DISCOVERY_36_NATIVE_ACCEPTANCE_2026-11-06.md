# Stage40 / DISCOVERY36 exact-SHA Native acceptance (2026-11-06)

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Accepted source SHA: 414a344565db2e82d591e551aeb99419853f1015
Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42125099817
Status: completed/success, attempt 1, 41/41 jobs success.
Native job: 127587136847, completed/success.
GnuCOBOL 3.1.2.0 strict -Werror; bounded compile 300s, execute 120s.
Independent source-emitted decimal BigInt vs closed-form oracle: 72/72.
Unique base pairs: 24; six at width 8192 digits.

STAGE40_HEAP_MEASURED=YES
STAGE40_INITIAL_OUTPUTS=00024
STAGE40_TRIPLE_LIVE=00024
STAGE40_MIDDLE_RELEASE_ISOLATED=00024
STAGE40_MIDDLE_REBUILT=00024
STAGE40_NONLIFO_CLEANUP=00024
STAGE40_RUNS=00024
STAGE40_PASS=00024
STAGE40_UNEXPECTED_FAILURES=00000
STAGE40_HEAP_LIVE_POST_RELEASE=00000000000000000000
RESULT=PASS_STAGE40_TRIPLE_OUTPUT_NONLIFO_DISCOVERY_NATIVE
STAGE40_NATIVE_GATE=PASS

Native artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42125099817/artifacts/13462355441
Reported artifact digest: sha256:c28a489b19956d83ef0bf979669d56c504f090f5bfabba4148c751b58fb083f3

Prior Stage40 run 41979599182 failed in test-only -Werror
compile diagnostics, not in executed arithmetic. Test-only source
correction 414a344565db2e82d591e551aeb99419853f1015 passed all 41 jobs.
Verdict: ACCEPTED_NO_DEFECT_REPRODUCED_IN_BOUNDED_TRIPLE_OUTPUT_NONLIFO_LIFECYCLE.
This is not full-calendar integration or proof beyond the tested scope.
No production/main/merge/release changes.
