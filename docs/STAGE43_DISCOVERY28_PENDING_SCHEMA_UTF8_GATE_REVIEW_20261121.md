# Stage43 / Discovery28: pending-schema migration review and strict UTF-8 gate plan

PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG  
Branch: PowerShell+Tagalog  
Review date: 2026-11-21  
Reviewed HEAD: 650243d526fd4bb990e134da29f45f1db4763663  
Scope: documentation-only review. No stage activation, metadata edit, parser, test, workflow, oracle, source, or main change is authorized or performed here.

## 1. Exact-SHA CI and repository identity

The branch ref `PowerShell+Tagalog` resolved to HEAD `650243d526fd4bb990e134da29f45f1db4763663`. Comparing `27d23eb0911ffbc80103ca6c58d6a0e15634b299..PowerShell+Tagalog` reports ahead 2 / behind 0 and one changed path: this Stage43 research document (70 added lines at the reviewed HEAD). The reviewed source files were read at that branch ref:

- `DEVELOPMENT_STAGE.md`, blob `a3f53b67e4445bdc835179cd484fe27b3e2648f7`
- `tests/Stage43.Tests.ps1`, blob `52460ba05442f509f98f45da74ee54840462d922`
- `.github/workflows/canonical-names-lock.yml`, blob `554f9d07908350fa375f54e8aa34fec31671ec67`

Run [44937451359](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44937451359) is bound to that exact HEAD. All 17 returned jobs are `completed / success`. The run API lists 17 non-expired artifacts; all 17 artifact IDs, names and GitHub ZIP digests match upload records in the decoded job logs. There are 16 artifact-producing jobs: one job uploaded two artifacts, while the verify job uploaded none. This is log/API digest parity, not an independent download and re-hash of the ZIP files.

Relevant exact-SHA results:

- Stage43 job `136947085175`: 240 endpoints, 160 target pairs, 216 seal pairs, 23 guards; 2,215 assertions passed, 0 failed; `BOUNDED_ORACLE_PASS`, `NOT_ACTIVATED`, `NOT_CLAIMED`. Artifact `14721632590`, ZIP digest `sha256:4b7fe110a6da2706984c8d4fcace2717a190531e528583abcec66c4725c834bf`.
- Stage42 job `136947085221`: 1,657/1,657, 0 failed, `STAGE42_NATIVE=SEALED_RECHECK_PASS`. Artifact `14722475354`, ZIP digest `sha256:0944670307caac370b5a406ae5793a4a91ecf3859d4485545db950bdd1288ecc`.
- Stage41 job `136947085193`: 481/481, 0 failed, `STAGE41_SEAL_RECHECK=PASS`. Artifact `14720614894`, ZIP digest `sha256:2507a4283a1707a1528c4da7b8f5128122dbb1e9b171b69b24e290e726e176d5`.
- Windows PowerShell 5.1 predecessor/finalizer job `136947085224`: Stage01 73/73 and Stage30 96/96; Stage23 finalizer ran twice, both exit 0, both `ALREADY_FINALIZED=True`, both stderr lengths 0. SHA256 before, after run 1 and after run 2 was identical: `0E54874D8D8412185FA9F81F75A5528C820A76BD13C5D61657857AC438E013AF`. This job uploaded two artifacts: `14722115182` and `14721941066`.

The run confirms the Stage42 predecessor recheck on the current documentation HEAD; it does not activate or seal Stage43. The metadata field `STAGE42_SEAL_COMMIT_NATIVE_RECHECK=PENDING_NEW_SHA` still appears in `DEVELOPMENT_STAGE.md` (line 706). That field was not rewritten in this documentation-only task. It is a metadata-reconciliation item, not evidence that the current Stage42 recheck failed.

## 2. Independently inspected Stage42 metadata snapshot

At blob `a3f53b67e4445bdc835179cd484fe27b3e2648f7`, the file contains:

- 733 logical lines, 728 non-empty assignments and 5 empty lines;
- 728 distinct keys, with no duplicate keys;
- no malformed assignment lines and no empty values;
- all keys satisfy the ASCII grammar `[A-Z][A-Z0-9_]*`;
- the value of `NATURAL_LANGUAGE` is legitimately non-ASCII: `U+05D8 U+05D2 U+05DC U+05D5 U+05D2 / Filipino`. Values must therefore not be restricted to ASCII.

The current phase markers are `TOTAL_STAGES=55`, `CURRENT_STAGE=42`, `CURRENT_KIND=DISCOVERY`, `CURRENT_DISCOVERY=27`, `LAST_COMPLETED_STAGE=42`, and `STAGE42_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED`. No Stage43 key is present. The Stage42 historical record includes `STAGE42_SEAL_COMMIT_NATIVE_RECHECK=PENDING_NEW_SHA`; this review preserves that value verbatim.

## 3. Conditional S42 -> S43 proposal: arithmetic and invariants

The existing proposal is internally count-consistent if, and only if, it is later authorized:

1. Start from the exact 728-key S42 map.
2. Change only `CURRENT_STAGE=42` to `CURRENT_STAGE=43`.
3. Change only `CURRENT_DISCOVERY=27` to `CURRENT_DISCOVERY=28`.
4. Add `STAGE43_RUNTIME_VERIFICATION=PENDING_NATIVE`.
5. Remove no key.

That produces 729 unique keys: 726 existing key/value pairs remain unchanged, 2 existing values change, and 1 key is added. `TOTAL_STAGES`, `CURRENT_KIND`, `LAST_COMPLETED_STAGE=42`, `CURRENT_PATCH=14`, all Stage42 evidence and the entire historical Stage42 record remain unchanged.

Important semantic boundary: changing `CURRENT_STAGE` and `CURRENT_DISCOVERY` is an actual stage transition under the existing metadata convention. `PENDING_NATIVE` is a runtime-verification state; it is not authorization to activate the stage and is not a PASS. The hypothetical S43 map must not be accepted by a production gate merely because its text is well-formed. Until separate authorization exists, S42 is the only authorized schema. A test may model the S43 proposal conditionally, but the production allowlist must remain S42-only.

The old Stage42 pending-recheck marker must not be silently promoted or rewritten as part of the S43 transition. If policy later decides that run 449374 resolves that marker, record that as a separate, explicit metadata reconciliation before changing the frozen Stage42 history.

## 4. What the current Stage43 gates do—and do not—prove

The Stage43 workflow at lines 939-940 uses `Get-Content -Encoding UTF8` and checks four exact line memberships: current stage, current discovery, last completed stage and Stage42 runtime verification. `tests/Stage43.Tests.ps1` begins with the same line-oriented read and checks nine exact memberships.

These are predecessor-presence checks, not complete metadata parsers. They do not establish:

- uniqueness of keys (an identical or conflicting duplicate line can coexist with the required line);
- absence of unknown or unauthorized extra keys;
- completeness of the 728-key S42 set;
- equality of every value in the Stage42 historical record;
- strict rejection of malformed UTF-8 bytes;
- preservation or validation of LF versus CRLF, because line-oriented reading discards the original line terminators;
- rejection of an interior BOM or prohibited Unicode separators.

The current checked-in metadata is structurally clean according to the inventory above. These observations identify a future transition-gate gap; they do not establish a current source corruption or invalidate the completed Stage43 numerical preflight.

## 5. Recommended strict UTF-8 / Windows PowerShell 5.1 design (plan only)

A future executable gate should accept raw bytes, not a string already produced by `Get-Content`.

1. Read one immutable byte snapshot with `[System.IO.File]::ReadAllBytes()`. Parse and, if required, hash that same byte array; do not re-read the file between validation and use.
2. Permit either no BOM or exactly one UTF-8 BOM (`EF BB BF`) at byte offset 0. Remove only that leading BOM before decoding. A second or interior BOM must be rejected.
3. Decode with an explicit strict decoder equivalent to `[System.Text.UTF8Encoding]::new($false, $true)`. Catch `DecoderFallbackException`; never accept replacement-character substitution as successful decoding.
4. Accept LF or CRLF, but require one consistent convention per file. Reject standalone CR and mixed LF/CRLF. Normalize CRLF to LF only after the original convention has been validated.
5. Reject C0 controls other than normalized LF, DEL, U+0085, U+2028, U+2029 and any interior U+FEFF. CR is permitted only as the CR component of CRLF. Tabs and whitespace-only lines are not blank lines.
6. Treat zero-length lines as formatting-only and ignore them. For every non-empty line, split at the first `=`; require a non-empty key matching `[A-Z][A-Z0-9_]*`; reject duplicate keys before inserting into a map. Compare keys and values ordinally, without trimming, case folding or Unicode normalization. Preserve Unicode values literally. Additional `=` characters belong to the value and are compared as-is.
7. Compare the complete parsed map against one immutable, phase-specific expected map. Reject missing, changed, duplicate, unknown or extra keys. Do not fall back to substring membership checks after parse failure and do not accept a hybrid of S42 and S43.
8. Return a reason-coded ALLOW/REJECT result. REJECT must have no metadata side effect. A later authorized transition should write through a temporary file and an atomic replacement, then read back and verify the resulting schema and hash.

Windows PowerShell 5.1-specific cautions:

- `Get-Content -Encoding UTF8` is unsuitable as the byte-integrity boundary: it exposes decoded lines, not the original bytes or line-ending convention.
- Windows PowerShell 5.1's `Set-Content -Encoding UTF8` writes a UTF-8 BOM. Any future writer must choose its BOM policy explicitly and verify the emitted bytes; do not assume PowerShell 7 behavior.
- Keep the implementation within .NET Framework APIs available to Windows PowerShell 5.1. The explicit `UTF8Encoding(bool, bool)` constructor and `File.ReadAllBytes` are suitable primitives; do not rely on newer runtime-only helpers without a native compatibility check.

## 6. Text-model QA performed for this review

A fresh in-memory JavaScript model was built from the exact 728 key/value pairs at the reviewed source blob. The conditional S43 map was derived locally from that map, not copied from another branch. It contains 729 keys, with 726 unchanged pairs, two changed discriminators and one added pending key.

The text-level checker passed 30/30 modeled cases, including S42 LF/CRLF and leading-BOM controls; S43 rejection before authorization and acceptance only when allowlisted; duplicate, missing, changed and unknown keys; malformed key syntax; whitespace-only lines; mixed and standalone line endings; interior BOM; prohibited controls and Unicode separators; premature completion/green status; and split-at-first-equals behavior.

This is static in-memory text-model QA only. It is not a raw-byte UTF-8 decoder test, not Windows PowerShell 5.1 execution, not Native CI, not differential QA, and not Stage43 lifecycle acceptance. Invalid UTF-8 byte sequences and the actual PowerShell 5.1 decoder remain NOT RUN.

## 7. Recommendation and authorization boundary

- Keep the current S42 metadata and production allowlist unchanged.
- Keep the 729-key S43 map as a conditional proposal only. Do not activate, seal or write it without separate authorization.
- Before executable work, freeze the exact authorization signal and the immutable expected-map source. The parser must not authorize S43 by inspecting the proposed S43 fields themselves.
- The first separately authorized executable increment should be the isolated strict-byte parser plus Windows PowerShell 5.1 negative fixtures. Only after those tests pass should any workflow or metadata transition be considered.
- The current completed CI and this document do not grant permission to edit `DEVELOPMENT_STAGE.md`, tests, workflow, parser, oracle, source, or main.

No executable file, test, workflow, oracle, stage metadata, lifecycle state or protected branch was changed by this review.
