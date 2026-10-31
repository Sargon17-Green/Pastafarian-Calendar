# Stage16 / DISCOVERY12 — 带符号零与前导零正规化 Native 验收

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Accepted SHA: ec07effca4604d909e8faef0c57b0aa475103391
Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41230714962
Job: stage16-signed-zero-normalization-discovery-native (124624173172)
Evidence: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41230714962/artifacts/13052914001
Date: 2026-10-31

## Verified acceptance
- GitHub Actions completed/success on exact SHA: 17/17 jobs, including verify and Stage1–16.
- GnuCOBOL 3.1.2.0 with strict -Werror compiled and executed Stage16.
- STAGE16_RUNS=00024, STAGE16_PASS=00024, STAGE16_UNEXPECTED_FAILURES=00000.
- STAGE16_HEAP_MEASURED=YES, following actual BIG-INTEGER-SERVICE/HEAP-LIVE read.
- STAGE16_HEAP_LIVE_POST_RELEASE=00000000000000000000.
- RESULT=PASS_STAGE16_SIGNED_ZERO_NORMALIZATION_DISCOVERY_NATIVE and STAGE16_NATIVE_GATE=PASS.
- Verdict: NO_DEFECT_REPRODUCED_IN_TWENTY_FOUR_SIGNED_ZERO_CALLS; no claim about other inputs or whole calendar.
- The 24 test fixtures were independently checked against arbitrary-precision BigInt abs(t-c)+1 and closed-form sign/zero identities. No production change, main mutation or merge.
