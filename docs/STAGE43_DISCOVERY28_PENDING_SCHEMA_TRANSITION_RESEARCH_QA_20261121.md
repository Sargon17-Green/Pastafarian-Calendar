# Stage43 / Discovery28: sealed-Stage42 to hypothetical Stage43-pending schema transition QA

PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG
Branch: PowerShell+Tagalog
Date: 2026-11-21
Audited base HEAD: 27d23eb0911ffbc80103ca6c58d6a0e15634b299
Audited DEVELOPMENT_STAGE.md blob: a3f53b67e4445bdc835179cd484fe27b3e2648f7
Audited Stage43 test blob: 52460ba05442f509f98f45da74ee54840462d922
Scope: RESEARCH-ONLY, documentation-only. The Stage43 pending schema below is a *proposal for later authorization*, not an approved lifecycle transition. Nothing activates, seals or changes Stage43.

## 1. Exact-SHA CI disposition, 44928026718

Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44928026718
- Trigger push, attempt 1, HEAD 27d23eb0911ffbc80103ca6c58d6a0e15634b299, status completed, conclusion success.
- 17/17 returned jobs completed/success. Decoded logs of all 17 jobs inspected; 17 artifact-finalization records in those logs and 17 non-expired artifacts in the run API, with matching names, IDs and GitHub-provided ZIP SHA256 digests. This is log/API parity, NOT independently downloaded ZIP rehashing.
- Hosted Windows PowerShell 5.1 Stage43 job 136918318668: 240 endpoints, 160 target pairs, 216 seal pairs, 23 structural guards; 2215/2215 assertions, 0 failed, BOUNDED_ORACLE_PASS; artifact 14718231654, GitHub ZIP digest sha256:b7c7367411bc331e82e4cdf9a913fef71da0907dea650c595a0e6fcaaac668b3. This is RESEARCH_ONLY and NOT_ACTIVATED/NOT_SEALED, not Stage43 lifecycle acceptance.
- Stage42 sealed recheck job 136918318488: 1657/1657, failed 0, SEALED_RECHECK_PASS; artifact 14716199673, digest sha256:eaa4ee1f2b48c1fe70f3ac22a55133c1a961f4cadfe133b930cc8526d7c759d5.
- Stage41 sealed recheck job 136918318548: 481/481, failed 0, SEALED_RECHECK_PASS; artifact 14716394408, digest sha256:7638457a05af8dcbae2f6e3e5793d9e1ea8fdd19a9c2e4b867ddaf33ccd59c88.
- Windows predecessor/finalizer job 136918318525: Stage01 73/73, Stage30 96/96. Stage23 finalizer run 1 and run 2: exit code 0, stderr length 0, ALREADY_FINALIZED=True and unmodified SHA256 0E54874D8D8412185FA9F81F75A5528C820A76BD13C5D61657857AC438E013AF before and after both invocations; finalizer artifact 14716164359, GitHub ZIP digest sha256:75d44ceac557385f19f6b25a2c80955060fac504a798c01aa93c9c2453152329.
- Canonical lock verify job 136918318529 completed/success. No duplicate dispatch.

## 2. Grounded predecessor and conditional target schemas

A strict, source-derived frozen profile S42 contains 728 distinct ASCII keys, 728 nonempty assignments and 5 blank lines, without Stage43 keys. Its known discriminator values are:
- TOTAL_STAGES=55
- CURRENT_STAGE=42
- CURRENT_KIND=DISCOVERY
- CURRENT_DISCOVERY=27
- LAST_COMPLETED_STAGE=42
- STAGE42_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED
- NATURAL_LANGUAGE contains legitimate non-ASCII Unicode. Do not use ASCII-only values.
All other existing 722 key-value pairs and the historical Stage42 record must remain unchanged in this *frozen snapshot* profile. This is a phase-bound regression oracle, not a general extensible production schema.

**Draft only, S43_PENDING_PROPOSAL:** begin with the same 728-pair snapshot, change exactly CURRENT_STAGE from 42 to 43 and CURRENT_DISCOVERY from 27 to 28, and add exactly one new key STAGE43_RUNTIME_VERIFICATION=PENDING_NATIVE (729 unique keys total). CURRENT_KIND=DISCOVERY, LAST_COMPLETED_STAGE=42 and the entire sealed Stage42 record stay unchanged. This is one measurable candidate, **not authoritative**: policy may require a different activation vocabulary, evidence keys or transition process. No runtime component may treat this proposal as approved.

Immutable S42 and proposed S43 are disjoint state profiles: an input must match exactly one authorized schema version. No fallback from failed parsing to substring search, no accepting a hybrid, no silently accepting unknown future proof keys or treating a stage count as a seal. In particular the historical value STAGE42_SEAL_COMMIT_NATIVE_RECHECK=PENDING_NEW_SHA is retained verbatim here; this research does not reinterpret it or silently promote it to PASS.

## 3. Independent static oracle contract

Input: UTF-8 metadata *text* representing a complete document, with an optional leading U+FEFF, LF or CRLF line terminators, optional terminal newline and blank lines. Reject mixed LF/CRLF in one file (a proposed fail-closed policy), standalone CR, U+FEFF away from the start, C0 controls other than line feed, DEL, U+0085, U+2028 and U+2029. Parse each nonempty line as KEY=VALUE split at the first equals sign. KEY must exactly match [A-Z][A-Z0-9_]*; reject duplicates before building the map. Preserve every Unicode VALUE code point literally without case folding or normalization. A key or value may not be silently trimmed; full values are checked against the expected phase-specific immutable map. Reject missing, changed or extra key/value pairs. A value containing an additional equals character should be handled by split-at-first-equals, then compared exactly, rather than incorrectly transformed.

Output: ALLOW only for the exact applicable S42 (presently authorized frozen snapshot) or for the explicitly hypothetical S43 target *when/if independently authorized*. Otherwise REJECT with a reason and no metadata write. Inputs with Cyrillic or visually similar letters in keys fail the ASCII-key grammar. Allow CRLF and an optional *leading* BOM; reject an interior BOM.

Actual raw bytes were not decoded in this static exercise. A future executable gate must separately test strict UTF-8 decoding (throwOnInvalidBytes, no replacement-character substitution), exact BOM bytes, malformed encodings, filesystem read behavior and PowerShell 5.1 compatibility. No Byte-level/Native result is claimed here.

## 4. Executed static source-model QA (not Native)

A fresh in-memory JavaScript checker was written against DEVELOPMENT_STAGE.md fetched at the exact source HEAD, deriving the map from the actual 728 assignments without importing an algorithm or fixture from another branch. It executed **72/72 modeled cases**:
- S42: 6 formatting/Unicode legal controls and 26 negative cases (32/32).
- Conditional S43 proposal: the same 6 legal controls and 26 negative cases (32/32).
- Cross-phase transition negatives: only stage discriminator changed; only discovery discriminator changed; pending key missing; premature LAST_COMPLETED_STAGE=43; prematurely sealed Stage43; duplicate pending key; unauthorized new Stage43 proof key; broken Stage42 predecessor seal (8/8).
- Negative suite also covers identical/conflicting duplicates, missing required keys, changed evidence values, unknown keys, lowercase and confusable non-ASCII key, blank line with a space, misplaced BOM, lone CR, mixed newline styles, U+0000, Unicode U+2028/U+2029, visual zero-width mutation of NATURAL_LANGUAGE, formatting whitespace, changed TOTAL_STAGES and comments.
- QA discovered a *harness-only defect*: initial control-character validation rejected legitimate CRLF before normalization (70/72). After explicitly detecting mixed newline styles, normalizing CRLF and checking remaining prohibited controls, the in-memory suite returned 72/72. This was not a production PowerShell defect, nor proof of a future executable parser.

Current tests/Stage43.Tests.ps1 use 9 exact case-sensitive line-membership predicates for the Stage42 prerequisite; the historical workflow check uses 4. Positive membership does not ensure uniqueness, key-set completeness or absence of contradictory extra entries, as previously recorded in the frozen Stage42 boundary QA. None of the 72 proposed model cases was run as a mutated PowerShell/CI fixture.

## 5. Acceptance gates and next authorization boundary

| Gate | Status |
| --- | --- |
| Existing exact-SHA hosted CI, Stage43 bounded independent-oracle preflight | ACCEPTED on 27d23eb; research only |
| Stage42 / Stage41 sealed Native rechecks | PASS in this completed CI |
| Source-derived snapshot and proposed pending-map in-memory checks | 72/72 model PASS; NOT Native |
| Raw UTF-8 strict byte decoding / actual PowerShell parser negative cases | NOT RUN; future executable authorization needed |
| Stage43 activation, pending transition and lifecycle acceptance | NOT AUTHORIZED / NOT ACTIVATED / NOT SEALED |
| Executable parser/tests/workflow/DEVELOPMENT_STAGE.md changes | OUT OF CURRENT SCOPE |

NEXT in present docs-only scope: independently review phase-migration invariants and provide an explicit approval decision on transition vocabulary/required evidence before any executable implementation. If approved later, the first executable work must test negative mutations in Windows PowerShell 5.1 and prove strict artifact requirements before claiming a lifecycle PASS.

No src/, oracle/, tests/, workflow, DEVELOPMENT_STAGE.md or main modifications occurred as part of this documentation-only step.
