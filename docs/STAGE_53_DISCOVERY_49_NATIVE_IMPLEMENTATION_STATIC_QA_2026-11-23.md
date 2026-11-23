# Stage53 / DISCOVERY49 — implementation and static QA handoff (2026-11-23)

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
BRANCH: COBOL+简体中文
SOURCE_PARENT_HEAD: 99281fa98c10eb5d4e5f47ae920bd7cd8e4b9f15
CONTRACT: docs/STAGE_53_DISCOVERY_49_CANONICAL_ZERO_FIVE_LIVE_CONTRACT_2026-11-23.md

## Changes, bounded scope
- New **test-only**, branch-owned GnuCOBOL harness at test/stage53_discovery_tests.cob; Git blob 0f60a2b22291de86ce6599118411612ed537434b. The code calls the existing BIG-INTEGER-SERVICE and MONSTER-DISTANCE ABI only; it does not change production or use fault injection.
- One added strict job in .github/workflows/canonical-names-lock.yml, blob 6dcdf6004a5326d1f338273530006ca4491e224f. Existing Stage1–52 jobs remain in place; 54 total jobs expected. This is NOT a Stage52 rerun launched manually.
- This report and append-only DEVELOPMENT_STAGE.md status.

## Independent, measurable contract
For n in {3,9,128,320,8192} and j in 1..5, let M=10^(n-1)+j+5, s=(-1)^j. C_k=s*k, T=s*M, k=0..4. Expected original decimal output: M-k+1. Preserve five independently owned outputs, reject occupied output with status 175, release/reinitialize inputs as T'=0, C'=-s*M, release exactly one result, and replace it using C'_k=-s*(M+k). Expected replacement: M+k+1. Restore the original selected result and verify all four survivor descriptors and all five final exact decimal strings.

The zero spellings are 0, +000, -000, 8192 zero digits, and '-' followed by 8191 zero digits; each is parsed through INIT-TEXT, and canonical zero is asserted as sign/chunks 0 and null head/tail. Nonzero 8192-digit signed values use unsigned-length INIT-TEXT and then descriptor sign, respecting the declared 8192-byte limit.

Static code-inspection only: 21 declared paragraphs; no unresolved PERFORM paragraph targets; longest source line 69 characters; targeted API strings match existing same-branch Stage52 harness. These checks do NOT establish that GnuCOBOL compiles the new harness, its runtime assertions pass, or heap measurements are valid. Neither a native binary nor its log has been examined at this point.

## Native acceptance gates (all required)
- Natural completed GitHub Actions run on the exact implementation commit: expected 54 successful jobs, not queued/in_progress or a historical SHA.
- GnuCOBOL 3.1.2 strict flags including -Werror, compile timeout 300s and executable timeout 120s, job budget 20 minutes.
- 25/25 cases, 125 initial outputs, 50 canonical zero parses, 25 occupied rejects, 125 preserved originals, 100 surviving after freeing, 100 surviving after replacement, 25 replacements, 25 restorations, 25 cleanups, 25 heap samples; slot balance 5 each; unexpected failures=0 and measured live heap=0.
- Planning oracle remains a separate PASS_NOT_NATIVE gate: 250 arithmetic comparisons, 500 symmetries, 50 zero checks, five 8192-digit cases, conceptual ownership counters. No model success can substitute for native execution.
- Read completed run/job/log and download Stage53 artifact; verify exact embedded PROJECT_ID and HEAD, ZIP SHA256 and CRC, raw markers, exit status and all counters independently before acceptance.

QA51-B four injected-service failure paths remain explicitly NOT TESTED and OUT OF SCOPE. Stage52 is the last accepted stage; full calendar integration remains unavailable. No protected branch, main, merge, release, or local-user-execution action is authorized here.
