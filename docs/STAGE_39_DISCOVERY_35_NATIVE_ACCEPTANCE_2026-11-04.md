# Stage39 / DISCOVERY35 — exact-SHA Native acceptance (2026-11-04)

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Accepted SHA: 10e3f620cb0e944f8623f65acbbb760fa839ebb2
Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41884859684 (attempt 1, completed/success)
40/40 CI jobs completed/success. Stage39 Native job 126766478787 success.
Toolchain: GnuCOBOL 3.1.2.0; strict -Werror compile.

Exact executed test markers:
STAGE39_HEAP_MEASURED=YES
STAGE39_INITIAL_SUCCESSES=00024
STAGE39_INTERLEAVED_SUCCESSES=00024
STAGE39_ISOLATED_OUTPUTS=00024
STAGE39_REINITIALIZED_PAIRS=00024
STAGE39_RUNS=00024
STAGE39_PASS=00024
STAGE39_UNEXPECTED_FAILURES=00000
STAGE39_HEAP_LIVE_POST_RELEASE=00000000000000000000
RESULT=PASS_STAGE39_INPUT_LIFETIME_ISOLATION_DISCOVERY_NATIVE
STAGE39_NATIVE_GATE=PASS

Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41884859684/artifacts/13350198838
Artifact SHA-256: 5c7327095a43790d98de70951075a3159134f7a98ecfb6f1ffeb43091121654d

The earlier run 41884257011 (39/40, Stage39 12/24) failed because
the even-j C input literal (n-1 digits) was edited at index n.
Three test-only indexing corrections were committed at the accepted SHA.
The accepted run executes those corrected tests.

Verdict: ACCEPTED_NO_DEFECT_REPRODUCED_IN_BOUNDED_INPUT_LIFETIME_ISOLATION.
No production edits; no full-calendar API integration claim.
