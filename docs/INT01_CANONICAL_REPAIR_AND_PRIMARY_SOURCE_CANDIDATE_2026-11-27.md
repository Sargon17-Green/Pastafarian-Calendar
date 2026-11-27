# INT-01 canonical repair evidence and primary-source candidate

PROJECT_ID=PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
2026-11-27; parent 87fdc6032ab07ab6dadc17945a7914597205ca0d
TESTED_SHA=7b12fe744b47a7d50aa31a75fbb74121d944e9d8

## Canonical CI complete
Run https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45954394882, attempt 1, push, completed/failure. REST jobs?per_page=100 returned all 57, 56 success and 1 failure. Stage15 job 140357409056 failed in dependency installation: Microsoft Ubuntu noble repository HTTP403, apt exit100, compile skipped, no Stage15 artifact. Not arithmetic failure. Stage55 job 140357409069 success metadata; no fresh acceptance claim from metadata alone.

QA51-B repaired job https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45954394882/job/140357409093 completed/success; log confirms source-lock checks, oracle, temporary instrumentation, strict compile, seven scenarios and artifact upload. Artifact https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45954394882/artifacts/15178507660: downloaded 123192 bytes, SHA256 841327478ec1a80a9b24da82530e94dd1d3ff32a7bcd953fa0701be2fc005f68 matches REST and upload log, ZIP CRC good, 18 members, all 17 manifest byte lengths and SHA256 matched. HEAD exact tested SHA, historical accepted SHA 324bdfad73a9e5aec8f7ad15ae588875d0a2226f. Native test-build stdout 7/7, 62 assertions, unexpected=0, heap final=0, gate PASS_TEST_BUILD_ONLY; exit0 stderr0; result explicitly production_source_modified=false, full_calendar_integration_tested=false. Compile log contains C preprocessor _FORTIFY_SOURCE redefinition warnings; successful gate, not claim warning-free C compilation. Three excluded paths still NOT_TESTED. No rerun.

## Newly located primary-text candidate (NOT SOURCE LOCK)
English publication https://the-scroll-of-the-appointed-times.blogspot.com/2026/08/The-Scroll-of-the-Appointed-Times.html found by targeted public search on title. Search index retrieved First, Seventeenth, Eighteenth and Final Tablet passages. Full page retrieval failed (cache miss). No complete bytes, revision ID or authoritative Appendix A/inverse text verified. Do not claim source lock or implement normative production gate/year yet.

Candidate first-tablet anchors, independently checked using Gregorian integer arithmetic (floor division for negative years). Astronomical signed year = 1 minus historical BCE year. For y,m,d, let z=y-1; RD=365z+floor(z/4)-floor(z/100)+floor(z/400)+floor((367m-362)/12)+correction+d, correction=0 for Jan/Feb, -1 after Feb in leap years, -2 otherwise. Candidate foundation F=-15055671; offset t=RD-F; tag=2t+1 for t>=0 else -2t. This is preliminary reference arithmetic, not COBOL execution or a complete normative fixture set.

| signed Gregorian date | RD | tag |
|---|---:|---:|
| -41221-12-21 | -15055672 | 2 |
| -41221-12-22 | -15055671 | 1 |
| -41221-12-23 | -15055670 | 3 |
| -762-06-07 | -278522 | 29554299 |
| 0-12-31 | 0 | 30111343 |
| 1-01-01 | 1 | 30111345 |

Candidate gate gaps 42..963 days, year span 252..5781 days and at least six gate intervals; interval convention opening gate exclusive, closing inclusive. Candidate text describes sequential year construction; do not assume random-access prefix sums or monotone closed-form oracle. For fixed working date, candidate year and unique cutlet name plus valid cutlet day identify at most one civil date; verify remaining month fields for consistency. This is an inferred property to verify against locked full text, not an authoritative inverse contract.

NEXT: obtain full original publication (prefer author-exported HTML/text or immutable revision), hash exact bytes and reconcile Appendix A and inverse semantics; then promote candidate fixtures and implement approved production components. No Stage56/main/merge/release, no reopening excluded paths. Docs only, no Native claim for child, skip CI.
