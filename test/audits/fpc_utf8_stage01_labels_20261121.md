# Object Pascal Portuguese UTF-8 label-output diagnostic — bounded QA

Project: PC-BRANCH-OBJECT-PASCAL-PORTUGUESE
Branch: Object-Pascal+Português
Audited HEAD (before fix): 85e29e6edc4e5900f5557302acfedf37d1e2f699
Scope: test/stage01_tests.pas lines 151–153, its output stream, and the Stage 1 native log only. This is test-harness output encoding, not evidence of arithmetic corruption.

## Independently checked evidence, 2026-11-21

- Exact-SHA native run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44910634160
- Native job: 136865492754, completed/success, FPC 3.2.2, on the audited HEAD.
- Names Lock run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44910634146
- Names Lock job: 136865492847, completed/success, same SHA.
- Native artifact 14709388933: ZIP size 4048 bytes, ZIP CRC PASS; independently measured ZIP SHA256 bbdbdcac703d8f73ce7ea7929a835627ce53daca109aac3283dff8493a6498a3. This matches both artifact metadata and uploader log.
- Thirty native summaries and all suite exit statuses report success; 46/46 original Stage 1 tests, 0 failed. The published log does NOT attest that diagnostic-label bytes are UTF-8.
- Compiler warnings: line 151 positions 48 and 59; line 153 positions 52 and 63. Each pair describes an implicit AnsiString->UnicodeString conversion and potentially lossy UnicodeString->AnsiString conversion.
- SOURCE bytes are UTF-8 and test/stage01_tests.pas declares {$MODE OBJFPC}{$H+}{$CODEPAGE UTF8} under FPC. AssertEqualText/AssertTrue names are plain "string" (AnsiString in this mode). The affected names are concatenations of Portuguese literals and IntToStr(I). Pass prints Writeln('OK: ', Name). Test verdicts depend on integer/BigInt comparisons, not on the emitted label bytes.
- **Observed raw-byte defect:** in the artifact's stage01-native-fpc.log, "taça" has 74 61 E7 61 (ISO-8859-1-style, not UTF-8 74 61 C3 A7 61), and "contém" has 63 6F 6E 74 E9 6D instead of UTF-8 63 6F 6E 74 C3 A9 6D. The raw log is not UTF-8 decodable. The decoded GitHub job-log view renders U+FFFD.
- A Python byte-level oracle on the ORIGINAL artifact reported 12 missing UTF-8 lines and 12 legacy single-byte matches (24 errors), across 2 label families x identifiers 1..6. A synthetic positive control with only those bytes transcoded passed 12/12; this positive control is *not* native verification.

## Bounded fix and acceptance contract

- Pascal: SetTextCodePage(Output, CP_UTF8) once before test execution, under FPC; this uses the documented RTL file-text encoding contract, without touching production units or numeric algorithms.
- Python: test/verify_stage01_utf8_labels.py independently forms exact UTF-8 expected lines for both human-reviewed Portuguese labels, 1..6. Every line must occur once in the RAW combined native log; the corresponding legacy ISO-8859-1 byte sequence must not occur. Exit 0 only for 12/12 with zero legacy matches.
- Workflow: after the existing 30-suite runner completes, invoke the Python byte-level oracle on evidence/stage01-native-fpc.log, preserving artifact upload even on failure. No separate dispatch; the existing branch push trigger may execute this modified SHA.
- Out of scope: other 29 suites' console encoding, host-agnostic FPC Unicode behavior, historical Oct 12/13 original Stage 1 source-patch provenance, and final Stage 1 acceptance.
- Evidence required to accept fix: completed exact-SHA native job and Names Lock success, oracle log "12/12", all existing test suite exit codes zero, uploaded artifact with verified SHA-256 and ZIP CRC. Before those checks, local static/source change and an old-log oracle failure do NOT constitute Native PASS.

FPC RTL reference: https://www.freepascal.org/docs-html/rtl/system/settextcodepage.html
