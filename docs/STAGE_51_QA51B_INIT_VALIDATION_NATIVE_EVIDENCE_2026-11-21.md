# Stage51 QA51-B — direct INIT-TEXT Native verification (2026-11-21)

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Authorized branch: `COBOL+简体中文`
Tested source HEAD: `fade4d5a91716da8205ea4b359cd22635bd8e3c7`
Evidence type: exact-SHA natural GitHub Actions push run, Native job, source inspection, independent ZIP integrity check.
Scope: Stage51 post-acceptance QA51-B direct service validation; **not** Stage52 or production change.

## Source and scope integrity

- Branch head was read via GitHub's branch API and matched the tested SHA.
- `test/stage51_discovery_tests.cob` blob: `488c6545daca119b601d6576b113b944bab2324f`; its `PROBE-INIT-VALIDATION` paragraph directly calls `BIG-INTEGER-SERVICE` with `INIT-TEXT` and three parser-invalid inputs on each Stage51 case. Expected exact statuses: `1#` (len 2) -> 44; empty input (len 0) -> 43; `-` (len 1) -> 44. After every rejection it checks scratch descriptor, distinct live outputs, preserved input, and unchanged measured live heap. This is **not allocator-fault injection**.
- `.github/workflows/canonical-names-lock.yml` blob: `750d82bfd82dbadafc3a6556235b00257f619238`; the existing Stage51 job requires `INIT_VALIDATION_REJECTS=75`, `INIT_VALIDATION_GATE=PASS`, previous counters, and the original Stage51 success gate.
- No production, main, merge, publication, or new stage changes are claimed.

## Exact-SHA CI and Native results

- Push run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44896001461
- Run attempt 1, `completed/success`, event `push`, head `fade4d5a91716da8205ea4b359cd22635bd8e3c7`.
- Jobs API: total_count=52, all 52 jobs `completed/success`, all tied to the same exact head SHA.
- Stage51 Native job ID `136821669515`, `completed/success`: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44896001461/job/136821669515
- Log: `STAGE51_RUNS=00025`, `STAGE51_PASS=00025`, `STAGE51_INIT_VALIDATION_REJECTS=00075`, `STAGE51_INIT_VALIDATION_GATE=PASS`, `STAGE51_INVALID_SIGN_REJECTS=00025`, `STAGE51_OCCUPIED_REJECTS=00025`, `STAGE51_PRESERVED_AFTER_REJECT=00125`, `STAGE51_UNEXPECTED_FAILURES=00000`, `STAGE51_HEAP_LIVE_POST_RELEASE=00000000000000000000`, `STAGE51_HEAP_MEASURED=YES`, `STAGE51_NATIVE_GATE=PASS`, and `RESULT=PASS_STAGE51_FIVE_SAME_SIGN_CANCELLATION_NATIVE`.
- The earlier Stage51 125 initial-owner, 100 input-rebuild, 100/100 survivor, 125 snapshot, 25 restore/cleanup and balanced five-slot counters were preserved. The independent arithmetic planning oracle remains `250/250`; it is not a Native result.
- The Native log contains nonfatal `_FORTIFY_SOURCE redefined` warnings. These did not fail this execution and are not evidence of successful fault injection.

## Independent artifact integrity check

- Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44896001461/artifacts/14704756833
- Name: `cobol-stage51-five-live-same-sign-cancellation-evidence`; artifact ZIP size 793 bytes.
- GitHub-reported SHA-256: `2ce4df21c7b9c3e97e75cd9acadbe10e8b3f9d0ab76ad06fbbd890de98f10618`.
- ZIP downloaded independently and hashed locally: **same SHA-256**.
- ZIP CRC validation: **PASS**. Single embedded member: `stage51-native.log` (5610 uncompressed bytes, CRC `f3866755`).
- Embedded `PROJECT_ID=PC-BRANCH-COBOL-SIMPLIFIED-CHINESE` and `HEAD=fade4d5a91716da8205ea4b359cd22635bd8e3c7` both match.
- This proves the downloaded artifact's integrity and scoped log identity, not comprehensive service-failure coverage.

## Gate verdict and remaining QA

**QA51-B direct INIT-TEXT invalid-input validation: NATIVE VERIFIED AND ACCEPTED** on tested SHA `fade4d5a91716da8205ea4b359cd22635bd8e3c7`.

The historical formal Stage51 acceptance is preserved. The evidence in this report does **not** demonstrate failures of allocator/mid-operation service, internal `PATCHED-DISTANCE` cleanup paths, `TO-TEXT`, `FREE-A`, or `HEAP-LIVE`. No such fault is invented, and Stage52 is not authorized. A docs-only follow-up commit has no independently claimed exact-new-SHA Native result.

**NEXT:** continue QA51-B source-grounded feasibility analysis for supported deterministic failures not yet covered. Establish a safe, measurable non-corrupting failure witness with an independent oracle, if one exists, and design isolated test-only probes only within current authorization. If none is available through the existing ABI, record the lack of an authorized injection seam and the specific untested path; do not claim a PASS or change production, Stage52, main, merge, or release.
