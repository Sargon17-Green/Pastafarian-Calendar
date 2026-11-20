# Rust+Azərbaycan-dili — Stage04 canonical-boundary PATCH: completed CI and independently checked artifact (2026-11-20)

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI  
BRANCH: Rust+Azərbaycan-dili  
TESTED_CODE_SHA: 08d1eba8f2d0ebaafb23cb562008c4f3aced5903  
CURRENT_STAGE=4; LAST_COMPLETED_STAGE=3; STAGE04_CLOSURE=NOT_CLAIMED

## Source and CI identity (completed runs)

- Stage04 workflow: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44734470550 ; job 136282261125; completed / success. Decoded job log fetch and checkout show the exact 40-hex tested SHA.
- Canonical Names Lock: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44734470528 ; job 136282261098; completed / success. Decoded job log fetch and checkout show the identical SHA. The canonical name verification step also concluded success.
- Branch comparison against `Rust+Azərbaycan-dili` before recording this audit: identical (ahead=0, behind=0).
- Changed code from preceding PATCH: provenance gate canonical Stage03/Stage04 checkpoint identities, forged-later-checkpoint negative regression, test-fixture boundary mocking, 13→14 workflow count, audit contract; no production Rust edit. Original patch contract: [canonical-boundary hardening](STAGE_04_RUST_CANONICAL_BOUNDARY_PIN_HARDENING_2026-11-20.md).

## Bounded CI gates from completed job and raw evidence

| Gate | Verified result | Evidence |
| --- | --- | --- |
| Historical Rust provenance regression | 14/14 | `stage04_provenance_tests.txt`; includes forged later-stage boundaries rejection |
| Rust callability controls | 16/16 | `stage04_callability_tests.txt`; synthetic positive **only** |
| Four-column TSV protocol | 6/6 | `stage04_tsv_protocol_tests.txt` |
| Rust Native baseline and regression suites | 34/34 | `stdout.txt`; sum of individual successful suite counts |
| Direct Rust/Python comparisons | 15/15 candidate and 15/15 patch | `stage04_rust_rows.tsv`, `stage04_direct_runtime_report.json` |
| Canonical Names Lock | completed/success | job 136282261098 and decoded checkout / verify logs |

### Independent artifact verification

Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44734470550/artifacts/14628677552  
Artifact ID 14628677552, uploaded 2026-11-20 12:34 UTC; file size 20,382 bytes; SHA-256 `b4065750bae3c235e2dbf7b87896753581cfe08f3f316936b37fb51a1d5e16dd`.

The actual downloaded ZIP bytes were checked independently with Python standard-library `hashlib`, `zipfile`, `csv`, and `json`:

1. SHA-256 and byte size match GitHub artifact metadata: 2/2. ZIP central directory lists 17 unique entries; `testzip()` verifies all 17 CRCs; no corrupt entry.
2. `sha.txt` contains exactly the target PROJECT_ID and 40-hex tested SHA; `exit.txt` is zero.
3. Three unit-test transcripts record 14, 16, 6 tests respectively; each contains precisely the matching number of `... ok` and ends in `OK`. Native `stdout.txt` test-suite counts total 34 with zero failures.
4. The 15 four-column TSV records and 15 JSON case records were matched row-by-row by index and signed day, with independent integer recomputation using the archived foundation constant `F = -15055671`. Independent formula: `legacy(day)=2*abs(day-F)`, `normative(day)=legacy(day)+int(day>=F)`. Every TSV oracle and candidate, JSON oracle/patch/candidate, and archived legacy value equalled its appropriate independently recomputed value: **15/15**. Classification recomputed rather than trusted from the report: **8 RED and 7 CONTROL**, zero unexpected. This is an independent computation over the **archived Python function** and Rust Stage04 diagnostic candidate, not a production historical Rust RED.
5. Source-pin and callability JSONs were parsed as data and checked for project and historical witness identity, `stage04_closure=NOT_CLAIMED`, `observed_runtime_red=false`, `historical_day_tag_route_proven=false`. Callability remains `SOURCE_ONLY_NO_SUPPORTED_SIGNATURE`; `callable_day_tag_route_verified=false`.
6. Exit and result files agree: diagnostic QA and cross-runtime comparison are successful, **Stage04 closure is still NOT_CLAIMED**.

Historical witness remains anchored to commit `716e5a6f335b1a15464029b446edb468f3a8482c`, file `src/lib.rs`, Git blob `8a813ba020c9101276007148c93cb00ae7836644`; this production source returns `BootstrapOnly` and exposes no callable production numeric day-tag route in the verified history. The 8 historical RED values are attributed to archived **Python** `oldDayTag`, never to original Rust production.

## Acceptance and next action

- PATCH CI and artifact checks: **accepted for the exact tested code SHA**.
- Stage04 overall: **OPEN / NOT_CLAIMED**. No historical production Rust callable day-tag was executed and compared independently; do not mark Stage04 PASS, open Stage05, merge, or publish.
- NEXT: retain the historical-source eligibility gate and only revisit Stage04 closure if a genuinely NEW, ancestry-pinned **production Rust** callable route can be demonstrated executing numeric outputs that disagree with an independent normative oracle. Otherwise do not manufacture a RED or repeat the completed historical surveys. The new audit-only commit may have its own automatic Names Lock; establish its result from completed job/log evidence rather than extrapolating code-SHA PASS.
