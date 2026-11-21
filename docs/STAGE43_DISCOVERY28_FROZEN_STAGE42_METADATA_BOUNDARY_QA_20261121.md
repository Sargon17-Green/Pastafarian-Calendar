# Stage43 / Discovery28: frozen Stage42 metadata snapshot boundary QA (2026-11-21)

PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG
Branch: PowerShell+Tagalog
Audited exact source SHA: 6cc87ae8159c017b39318936275a3f9b906e4a32
Stage status: Stage42 sealed; Stage43 RESEARCH_ONLY / NOT_ACTIVATED / NOT_SEALED.
Change scope: documentation only. No executable test, workflow, parser, metadata, oracle or protected-branch modifications.

## 1. Exact-SHA hosted CI acceptance

- Run https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44922836040: attempt 1, completed/success, exact head_sha 6cc87ae8159c017b39318936275a3f9b906e4a32.
- All 17 returned jobs completed/success. All 17 decoded job logs were inspected. The logs contain 17 artifact finalization records; 17 GitHub run artifacts match their reported names, IDs and SHA-256 ZIP upload digests (17/17 parity). Digests are GitHub-provided log/API metadata, NOT a separately downloaded/rehashed ZIP sample.
- Stage43 hosted Windows PowerShell 5.1 job 136902390280: 240 endpoints, 160 target pairs, 216 seal pairs, 23 guards; 2215/2215 assertions, failed=0; BOUNDED_ORACLE_PASS; NOT_ACTIVATED and STAGE_SEAL=NOT_CLAIMED. Artifact 14714217851 / SHA256 2fcdf04527e810174e823dddd9715d2badcf700356515ede391c794be5cdfb89.
- Stage42 job 136902390386: 1657/1657, failed=0, SEALED_RECHECK_PASS. Artifact 14714322359 / SHA256 093e52d4b0fa72cb7822a2b482f3c22211a342ad0077c7be2e87a70bc6ceebdc.
- Stage41 job 136902390185: 481/481, failed=0, SEALED_RECHECK_PASS. Artifact 14714193526 / SHA256 6b8e289549f000df8284b8c6e251400e386b23075af318b15dff3a14e24936f1.
- Stage29/30 plus finalizer job 136902390263: Stage01 73/73, Stage30 96/96; Stage23 finalizer twice exit=0, stderr=0, ALREADY_FINALIZED=True, before/after SHA256 0E54874D8D8412185FA9F81F75A5528C820A76BD13C5D61657857AC438E013AF; artifact 14714561317 / ZIP digest 651bc4704cd54d53953e0334b32ab165b4630aa0ed19b7fb7779844166f36940.
- Canonical verify job 136902389901 succeeded. This CI acceptance concerns the audited docs-only SHA and preflight, not Stage43 activation or lifecycle sealing. No duplicate CI was dispatched.

## 2. Grounded source and frozen research-snapshot contract

- DEVELOPMENT_STAGE.md blob a3f53b67e4445bdc835179cd484fe27b3e2648f7: 728 nonempty assignments with 728 distinct keys, five blank lines, all valid key shapes, current state CURRENT_STAGE=42 / CURRENT_DISCOVERY=27 / LAST_COMPLETED_STAGE=42. There are no Stage43 keys.
- A metadata value contains non-ASCII Unicode characters (NATURAL_LANGUAGE); a proposed ASCII-only value parser would falsely reject this actual baseline. Restrict key syntax, not legitimate Unicode value text.
- Stage43 test source blob 52460ba05442f509f98f45da74ee54840462d922 uses 9 positive case-sensitive full-line membership predicates; workflow blob 554f9d07908350fa375f54e8aa34fec31671ec67 uses 4. Positive membership does not enforce absence, unique keys or total-map consistency.
- **Independent static snapshot oracle** for this narrow research-only phase: allow LF or CRLF, an optional BOM only at document start, extra blank lines and optional terminal newline. Every nonempty line must be KEY=VALUE with KEY matching [A-Z][A-Z0-9_]*, permitting Unicode in VALUE but rejecting U+0000/U+FEFF and malformed line separators. Keys must be unique and the resulting 728 key/value pairs must equal the audited sealed-Stage42 snapshot. This is an intentionally frozen regression oracle, NOT a recommendation to hardcode all 728 keys in a general mutable production parser. Future versioned metadata schemas and phase transitions require their own policy and authorization.
- The independent JavaScript in-memory oracle was authored and evaluated against exact source content here. No synthetic input was written to the repository and no Windows PowerShell mutation test was run.

## 3. Boundary matrix (model results, NOT Native)

| ID | Isolated input change | Strict expected | Static snapshot oracle | Existing test membership | Existing workflow membership |
| --- | --- | --- | --- | --- | --- |
| C00 | Untouched baseline | ALLOW | ALLOW | ALLOW | ALLOW |
| C01 | CRLF line endings | ALLOW | ALLOW | ALLOW | ALLOW |
| C02 | Leading UTF-8 BOM | ALLOW | ALLOW | ALLOW | ALLOW |
| C03 | Additional empty line | ALLOW | ALLOW | ALLOW | ALLOW |
| C04 | Omit final newline | ALLOW | ALLOW | ALLOW | ALLOW |
| X01 | Duplicate CURRENT_STAGE (identical) | REJECT | REJECT | ALLOW | ALLOW |
| X02 | Duplicate CURRENT_STAGE (conflict) | REJECT | REJECT | ALLOW | ALLOW |
| X03 | Duplicate TOTAL_STAGES (identical) | REJECT | REJECT | ALLOW | ALLOW |
| X04 | Duplicate TOTAL_STAGES (conflict) | REJECT | REJECT | ALLOW | ALLOW |
| X05 | Conflicting CURRENT_DISCOVERY | REJECT | REJECT | ALLOW | ALLOW |
| X06 | Conflicting LAST_COMPLETED_STAGE | REJECT | REJECT | ALLOW | ALLOW |
| X07 | Contradict Stage42 seal | REJECT | REJECT | ALLOW | ALLOW |
| X08 | Append Stage43 pending state | REJECT | REJECT | ALLOW | ALLOW |
| X09 | Append Stage43 sealed state | REJECT | REJECT | ALLOW | ALLOW |
| X10 | Append Stage43 unknown proof key | REJECT | REJECT | ALLOW | ALLOW |
| X11 | Append synthetic unknown key | REJECT | REJECT | ALLOW | ALLOW |
| X12 | Append lowercase key | REJECT | REJECT | ALLOW | ALLOW |
| X13 | Append comment | REJECT | REJECT | ALLOW | ALLOW |
| X14 | Append malformed no-equals line | REJECT | REJECT | ALLOW | ALLOW |
| X15 | Append extra equals in value | REJECT | REJECT | ALLOW | ALLOW |
| X16 | Append leading-space key | REJECT | REJECT | ALLOW | ALLOW |
| X17 | Append trailing-space key | REJECT | REJECT | ALLOW | ALLOW |
| X18 | Append zero-width character in key | REJECT | REJECT | ALLOW | ALLOW |
| X19 | Append embedded U+0000 | REJECT | REJECT | ALLOW | ALLOW |
| X20 | Append BOM away from first byte | REJECT | REJECT | ALLOW | ALLOW |
| X21 | Append contradictory Stage43 states | REJECT | REJECT | ALLOW | ALLOW |
| R01 | Delete required CURRENT_STAGE | REJECT | REJECT | REJECT | REJECT |
| R02 | Replace required CURRENT_STAGE | REJECT | REJECT | REJECT | REJECT |
| R03 | Delete required Stage42 seal | REJECT | REJECT | REJECT | REJECT |
| R04 | Replace required Stage42 seal | REJECT | REJECT | REJECT | REJECT |
| R05 | Change non-workflow value TOTAL_STAGES | REJECT | REJECT | REJECT | ALLOW |
| R06 | Delete non-workflow key TOTAL_STAGES | REJECT | REJECT | REJECT | ALLOW |
| R07 | Append lone CR terminator | REJECT | REJECT | ALLOW | ALLOW |
| R08 | Lowercase CURRENT_DISCOVERY key | REJECT | REJECT | REJECT | REJECT |

Summary: 34/34 expected dispositions matched the new independent snapshot oracle (5 legal formatting controls, 29 reject cases). Of the 29 invalid variants, the existing test membership model falsely accepted 22, the workflow membership model falsely accepted 24, and both falsely accepted 22. X-series append-only inputs are particularly important; the R-series confirms that deletion/replacement of mandatory lines can be detected while other metadata changes remain unchecked. These are simulations of exactly source-derived membership predicates, not real mutated runs or observed CI failures.

## 4. Engineering boundary and next authorized action

- This documentation does not activate/seal Stage43 and does not authorize changes in src/, oracle/, tests/, .github/workflows/, DEVELOPMENT_STAGE.md, or main.
- Before any separately authorized executable fail-closed parser, define a versioned schema for known keys and legal phase-specific values; prove exact-case uniqueness, contradiction rejection, Unicode value preservation, CRLF/BOM handling and negative-case detection. Never equate shape-valid metadata or bounded preflight PASS with Native lifecycle acceptance.
- Current workflow Stage43 artifact upload uses if-no-files-found: warn, which is acceptable only as research evidence; a required activation/seal artifact would need mandatory fail-closed behavior under separate authorization.
- NEXT (within current scope): independently review the migration rules from frozen sealed-Stage42 research metadata to a potential Stage43 pending schema and document precise accept/reject boundaries without modifying executable gates. Check future automatic CI on this documentation-only commit's exact SHA without duplicate dispatch.
