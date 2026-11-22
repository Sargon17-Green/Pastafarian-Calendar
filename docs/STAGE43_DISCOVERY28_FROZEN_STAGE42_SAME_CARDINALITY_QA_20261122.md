# Stage43 Discovery28: same-cardinality frozen Stage42 schema QA

PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG
Branch: PowerShell+Tagalog
Review date: 2026-11-22
Reviewed HEAD before this QA commit: 1d9111e1d62467941ff53dd8008bc42ec521c441
Immutable metadata blob: a3f53b67e4445bdc835179cd484fe27b3e2648f7
Scope: standalone STATIC QA and evidence only; NO changes to production parser, existing tests, CI workflows, metadata, normative oracle, Stage43 lifecycle or main.

## 1. Exact-SHA baseline and completed CI

At review time, the live branch was ahead exactly one commit of the previous tracker SHA 7f9c4f4a987c30e956cb16094bf475a3d9d9770f, with no divergence. Its commit 1d9111e1d62467941ff53dd8008bc42ec521c441 modified only the strict metadata parser and its negative tests to preserve CRLF line counting for standalone CR errors. This is the current baseline, NOT a request to rewind the branch.

Existing push run https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44958382309 completed/success at the reviewed exact SHA: 17/17 jobs completed/success. Its Windows PowerShell 5.1 job 137011474790 reported STAGE01_TESTS_PASSED=241, STAGE01_RESULT=PASS; the Stage23 finalizer ran twice with exit 0, already-finalized true, stderr 0 and unchanged SHA256 0E54874D8D8412185FA9F81F75A5528C820A76BD13C5D61657857AC438E013AF. Stage43 research job 137011474679 reported 2215/2215, failed=0, BOUNDED_ORACLE_PASS, NOT_ACTIVATED and NOT_CLAIMED. All 17 artifacts from the run API were non-expired, on that SHA, with reported SHA256 digests. ZIP bytes were not independently downloaded/rehashed. No CI dispatch was sent for this QA.

## 2. Independent oracle contract

Input is the raw UTF-8 Git blob for DEVELOPMENT_STAGE.md pinned to a3f53b67e4445bdc835179cd484fe27b3e2648f7. Read the same pinned blob for every synthetic mutation. The independent model has two distinct layers:

1. **Lexical shape:** optionally one initial BOM; strict UTF-8; uniform LF or CRLF; reject standalone CR, mixed endings, interior BOM, control characters, malformed key grammar and duplicate keys; preserve Unicode values and everything after the first `=`; ignore only genuinely empty lines.
2. **Frozen Stage42 schema:** after lexical acceptance, require exactly 728 unique keys and exact ordinal equality of every key and value to the pinned Stage42 map. Format-only changes (BOM, CRLF, blank lines, terminal newline) are legal. Any extra, missing or changed key/value is rejected, including same-cardinality replacements.

The existing Stage43 workflow uses four full-line membership predicates, which are modeled separately as a diagnostic, not used as the frozen oracle. The existing general PowerShell parser is a *lexical* parser; its OK result alone cannot authorize a lifecycle transition. Baseline CURRENT_STAGE=42, CURRENT_DISCOVERY=27, LAST_COMPLETED_STAGE=42, no STAGE43_* keys. The latest Windows CI did not execute the new standalone model.

## 3. Independently modeled boundary matrix

| Case | Mutation | Frozen oracle | Expected lexical result | Four-line Stage43 membership |
| --- | --- | --- | --- | --- |
| C00-C05 | Unchanged, CRLF, initial BOM, extra blank, no last LF, BOM+CRLF | ALLOW | OK | ALLOW |
| X01 | Change unrelated value, keep 728 assignments | REJECT | OK | ALLOW |
| X02 | Remove an unrelated key; add an unknown one, count still 728 | REJECT | OK | ALLOW |
| X03 | Change CURRENT_PATCH=14 to 15 | REJECT | OK | ALLOW |
| X04 | Append Stage43 pending key | REJECT | OK | ALLOW |
| X05-X06 | Identical/conflicting duplicate assignments | REJECT | DUPLICATE_KEY | ALLOW |
| X07-X08 | Replace Unicode NATURAL_LANGUAGE value or make it empty | REJECT | OK | ALLOW |
| X09 | Append unknown key with empty value | REJECT | OK | ALLOW |
| X10 | Append missing-equals line | REJECT | MALFORMED_LINE | ALLOW |
| X11 | Append standalone CR | REJECT | STANDALONE_CR | ALLOW |
| X12 | Make LF/CRLF mixed | REJECT | MIXED_LINE_ENDINGS | ALLOW |
| X13 | Add an interior BOM | REJECT | INTERIOR_BOM | ALLOW |
| X14 | Insert NUL control | REJECT | FORBIDDEN_CONTROL | ALLOW |
| X15-X16 | Lowercase key or whitespace-only nonempty line | REJECT | MALFORMED_LINE | ALLOW |
| X17 | Append extra equals inside existing unrelated value | REJECT | OK | ALLOW |
| X18 | Change current stage to 43 only | REJECT | OK | REJECT |
| X19 | Delete unrelated key (727 remain) | REJECT | OK | ALLOW |
| X20 | Swap unrelated key for Stage43 pending key, still 728 | REJECT | OK | ALLOW |
| X21 | Remove unrelated key and append duplicate, still 728 lines | REJECT | DUPLICATE_KEY | ALLOW |

The in-memory independent model was evaluated against the live source snapshot before this commit: **27/27 expected dispositions**, consisting of 6 permitted formatting variants and 21 rejected variants. Of the rejected inputs, 11 remained lexically well-formed and 20 retained all four required Stage43 preflight lines. These are **model-predicted behaviors**, not observed PowerShell parser failures. Especially, X01, X02, X03, X07, X08, X17 and X20 demonstrate that preserving 728 assignments cannot substitute for comparing all 728 entries. The existing Stage01 test also pins the committed Git blob SHA, which detects modifications to the committed metadata; that provenance control must not be conflated with the runtime Stage43 four-line membership precondition.

## 4. Reproduction and evidence limits

Source-controlled runner: `qa/frozen_stage42_metadata_same_cardinality_qa.js`. Run from a checkout of this exact branch with `node qa/frozen_stage42_metadata_same_cardinality_qa.js`. It is read-only; checks HEAD:DEVELOPMENT_STAGE.md Git blob against the pinned SHA, reconstructs all 27 cases, and exits nonzero if a modeled expectation fails. It requires Node.js and Git, not PowerShell. This new runner has not been executed in hosted GitHub Actions; prior 27-case calculations used an independent in-memory JS model on the fetched source. This document must not be used to claim new CI, Native, differential or whole-stage acceptance.

## 5. NEXT

Retain the strict parser, its Windows 5.1 regression tests and existing CI acceptance. Next authorized technical increment is to investigate whether a phase-specific fail-closed full-map comparator should be added as a separate opt-in code/test API, using the pinned sealed-Stage42 baseline and the same-cardinality negative cases. Do not wire it into Stage43 activation, change metadata or workflow, promote Stage42 history, or claim Stage43 acceptance without separate authorization. Check the next automatic push CI on its exact SHA; do not rerun previously accepted commits.
