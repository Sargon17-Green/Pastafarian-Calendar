# Stage15 / DISCOVERY11 — 已验证的 Native 验收 (2026-10-31)

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Accepted SHA: 749375f41eb5be83a380306d658128984c916919
Canonical GitHub Actions: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41230511867
Stage15 Native evidence artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41230511867/artifacts/13053254628
Job ID: 124623577275

## Verified evidence
- 16 of 16 workflow jobs: completed / success; verify, Stage1 through Stage15 native jobs.
- Stage15 GnuCOBOL 3.1.2.0 strict compilation with -Werror: success.
- STAGE15_RUNS=00030; STAGE15_PASS=00030; STAGE15_UNEXPECTED_FAILURES=00000.
- STAGE15_HEAP_MEASURED=YES after an actual BIG-INTEGER-SERVICE call with operation HEAP-LIVE; the receiver WS-HEAP was corrected to PIC 9(18) COMP-5, matching WS-LEN.
- STAGE15_HEAP_LIVE_POST_RELEASE=00000000000000000000.
- RESULT=PASS_STAGE15_MIXED_CHUNK_ARITHMETIC_DISCOVERY_NATIVE.
- STAGE15_NATIVE_GATE=PASS.
- Defect verdict: NO_DEFECT_REPRODUCED_IN_THIRTY_MIXED_CHUNK_CALLS. This is bounded evidence; it proves neither universal correctness nor integration of the five-field calendar.

## Prior invalid/failed runs kept as evidence
- 41211355528: 30 arithmetic checks passed, but its printed heap value came from an initialized constant, so that memory result was invalid.
- 41222100281: malformed CI YAML, 0 jobs.
- 41222216293: 15/16 jobs succeeded; Stage15 compile failed at source line 228 with -Werror=possible-truncate, no Stage15 native test was executed.
- Fixed test-only receiver width at 749375f41eb5be83a380306d658128984c916919; no change to production, main or merge.
