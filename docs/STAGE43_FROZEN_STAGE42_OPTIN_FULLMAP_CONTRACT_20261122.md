# Stage43 research: opt-in frozen Stage42 full-map comparator

PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG
Branch: PowerShell+Tagalog
Source baseline: Git blob a3f53b67e4445bdc835179cd484fe27b3e2648f7
Previous exact-SHA CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44996950662

## Scope and lifecycle

Adds two isolated files: src/FrozenStage42MetadataComparator.ps1 and
tests/FrozenStage42MetadataComparator.Tests.ps1. The comparator is not imported
by Stage43, any workflow, or the existing Stage01 regression runner. The tests
are stand-alone, opt-in and not counted by the existing CI. No change to
DEVELOPMENT_STAGE.md, production code paths, normative oracle or Stage43 seal.

## Contract

Input: arbitrary candidate byte array and local repository root.
Expected baseline: immutable Stage42 Git blob (not the mutable checkout file).
Use binary git cat-file retrieval to preserve UTF-8 bytes on Windows PS 5.1.
Both inputs go through the existing strict UTF-8 lexical parser.
Accept candidate only if every one of the 728 unique keys and all values are
ordinally equal to the sealed Stage42 map. A single initial BOM, uniform CRLF,
empty lines and missing terminal LF may be accepted because those do not change
the map. Reject missing, additional or altered values even at equal cardinality,
duplicate keys, malformed UTF-8, controls and mixed line endings.

Result: Success, ReasonCode, Key, ParsedReason and PinnedGitBlob. Refuse to
compare on missing Git object or an invalid baseline. No filesystem mutation.
This is an optional defensive research API, not a Stage43 activation gate.

## Verification

Command from the repository root on Windows PowerShell 5.1:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/FrozenStage42MetadataComparator.Tests.ps1

Tests: six permitted formatting cases and fourteen negative cases, including
same-cardinality replacement, altered value, extra equals, duplicate keys,
malformed lines, mixed endings, standalone CR, BOM and malformed UTF-8.
Capture stdout/stderr, process exit code, Git HEAD and the pinned blob SHA.
No Native or differential PASS is claimed before this command actually runs.

## Limits

Previous push CI is completed/success on the old SHA with 17/17 jobs and 17
same-SHA artifacts. Existing Stage43 research: 2215/2215, NOT_ACTIVATED,
NOT_CLAIMED. The standalone Node model from prior checkpoint is still not
executed in CI. The new opt-in PowerShell tests are also not yet executed.
NEXT: validate actual tests on Windows PS5.1 or approved matching checkout;
triage any failures without changing stage policy; only then consider separately
authorizing a Stage43-specific integration.
