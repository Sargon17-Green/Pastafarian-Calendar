# Stage43 research: isolated frozen Stage42 fail-closed QA (2026-11-23)

PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG
Branch: PowerShell+Tagalog
Predecessor SHA: 4872319234b9126e23f8dd1e639e74430b36b78e
Baseline Git blob: a3f53b67e4445bdc835179cd484fe27b3e2648f7

## Research scope (no stage promotion)

This patch changes only the opt-in frozen Stage42 comparator and adds an
independent negative test script. No workflows, DEVELOPMENT_STAGE.md, sealed
metadata, Stage43 production path, normative oracle, or main branch are changed.
The existing 20-case Windows PS5.1 opt-in comparator suite remains historical
evidence for the predecessor SHA, not a PASS for this new code revision.

## Measurable contract

Inputs: arbitrary candidate byte array (including null/empty) and repository
root (including empty/invalid values). The immutable baseline is loaded by
binary git cat-file of the exact pinned blob, never from the working tree.
Output: structured Success/ReasonCode/Key/ParsedReason/PinnedGitBlob.

Only a strictly parsed candidate with an exactly equal 728-entry frozen key
and value map is accepted. Formatting-only BOM, CRLF, blank lines, and final
LF differences may be accepted as previously specified. Root or git retrieval
failures return BASELINE_UNAVAILABLE; malformed or throwing baseline parsing
returns BASELINE_INVALID. Invalid candidate syntax or candidate parser
exceptions return CANDIDATE_LEXICAL_INVALID (PARSER_EXCEPTION on exception).
Null input returns INVALID_INPUT. Caller candidate bytes are cloned before
parsing and checked for immutability in the negative suite.

The standalone negative suite defines sixteen independent oracle expectations:
two positive baseline/restoration cases and fourteen negative cases covering
null, empty, invalid roots (missing, file, non-Git, quoted, empty), unreadable
Git blob, invalid UTF-8 and missing keys in the baseline, incorrect Stage42
baseline seal state, injected baseline parser exception, injected candidate
parser exception, and modified candidate bytes. Each case verifies reason code,
the pinned blob identifier, and candidate non-mutation.

## Execution and evidence gate

Run in an exact checkout of the new commit using Windows PowerShell 5.1:

powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/FrozenStage42Comparator.FailClosed.Tests.ps1

Record exact HEAD, baseline blob SHA, stdout, stderr, exit code and 16 case
results. Run the existing 20-case comparator suite only on the changed source
SHA if a regression gate is required; do not reuse the prior PASS as proof.
Test-file inclusion in GitHub is STATIC ONLY until a real PS5.1 process runs.
This standalone test is not wired to automatic CI.

Stage43 stays NOT_ACTIVATED / NOT_CLAIMED. No differential or full-stage
acceptance is authorized by this research patch.
