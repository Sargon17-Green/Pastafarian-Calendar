# Stage55 Year5000: full-length edge projection contract (bounded)

PROJECT_ID: `PC-BRANCH-MATLAB-POLSKI`. Authorized branch `MATLAB+Polski`.
This is a new bounded verification gate under Stage55, NOT a new stage.
`LAST_COMPLETED_STAGE=54` must remain unchanged; no main/merge/release.

## Scope and required input

- Exact fixture Git blob: `a1383b111a88203b0d652b8f0a0e9af1a8b75f25` in `tests/fixtures/stage55_year5000_appendix_a_metadata.json`. This preexisting metadata derives from an audited production trace and is NOT independently rederived by this test.
- 45 months / 4,244 days, Julian-day index range `[-15057702, -15053459]`, six cutlets. Ordinal positions are 1..4244. Every month label occurs exactly its recorded month length; both first and last appearances are increasing by month label.
- Two legal *extremal* full words, FIRST (lexicographic rank 1) and LAST (the maximum rank). The independent Python author derives these by choosing the least/greatest legal next symbol at each opening/closure frontier; MATLAB uses a closed-form first word and last word. Two tiny engines explore six small families exhaustively in Python. No arbitrary-rank middle word is claimed.
- Optional `--word-json` accepts one complete 4,244-symbol JSON word and validates multiplicities and first/last occurrence ordering. This gives the same independent projection method a future input interface for a separately certified canonical middle-rank word. It does NOT identify that canonical word by itself.

## Output contract

For each word, exactly 4244 data rows plus one fixed ASCII header, LF-only and no BOM:

`POSITION,YEAR,CUTLET_INDEX,CUTLET_DAY,MONTH_INDEX,MONTH_DAY`

The five calendar fields after POSITION are the year number, cutlet name index, 1-based day in cutlet, month name index, and 1-based *occurrence count* of the month within the full weave prefix. Full naming indices resolve against the immutable Polish `sourceLanguageCatalog`. This avoids comparing lossy transliterations of Unicode names. The real native route must also build and check the five-field tuple with full original Polish strings.

- Python oracle uses independent direct prefix counts and cutlet cumulative ranges (`bisect`), not MATLAB selector or `MonthDayCompatibilityRoute` output; exact decimal CSV serialization and SHA-256 of full bytes.
- MATLAB R2026a constructs both words without querying Python, executes `pastafari.MonthDayCompatibilityRoute.call` for *every* position of each word, asserts PATCH_25 trace, month index and day count, constructs real-name tuple, and writes the same ASCII rows.
- Native executes two independent identical passes for each word. Its two passes and both Python outputs must compare byte-for-byte with `cmp` for all 4,244 records, including position 1 and 4244 and all cutlet boundaries. The test also requires positions 0 and 4245 rejected with the production error ID for each word.
- Gate acceptance requires completed exact-SHA workflow run and job with success, MATLAB marker, Python marker, `cmp`, native and Python logs, manifest, source/fixture SHAs, artifact digest/CRC, archival readback. A queued or in-progress run is not PASS. No duplicate dispatch.

## What this cannot prove

This bounded gate does **not** derive the 45 month lengths independently, does not construct the canonical *middle-rank* 4244-symbol weave, does not run the complete production `finalMonsterIntegration` year chain, and is not the full cross-engine soak or final Stage55 acceptance. It is strictly stronger than the previously certified 48 edge/boundary *point* samples: it checks all positions, five fields, and repeatability for both complete extremal words.

NEXT after bounded gate: obtain and independently verify a pinned-SHA canonical middle-rank full weave, run this oracle with `--word-json` against a production-derived full row stream, then obtain independent complete-year and stability-soak evidence. Do not infer final-stage PASS from these edge checks.
