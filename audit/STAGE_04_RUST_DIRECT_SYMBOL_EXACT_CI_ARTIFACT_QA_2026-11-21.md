# Stage04 Rust Azerbaijani — exact-SHA CI, independent artifact QA, and evidence count correction

- PROJECT_ID: `PC-BRANCH-RUST-AZERBAIJANI`
- Branch: `Rust+Azərbaycan-dili`
- Validated code/test parent SHA: `3e8981bef3399351be9f105f7aadad04b1753030`; no production Rust files changed in this correction
- Stage04: `OPEN/NOT_CLAIMED`; `CURRENT_STAGE=4`; `LAST_COMPLETED_STAGE=3`

## Live branch and completed CI

The live branch was compared with `3e8981bef3399351be9f105f7aadad04b1753030` and found identical (ahead=behind=0), and its branch lookup returned exactly this SHA.
- Stage04 run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44828521856 — completed/success, push attempt 1, job `136607185810` completed/success. Decoded job logs show checkout `3e8981bef3399351be9f105f7aadad04b1753030` and successful individual verification/Native/differential steps.
- Canonical Names Lock: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44828521859 — completed/success, push attempt 1, job `136607186047`; decoded logs show the same exact checkout and a successful canonical names verification step.

## Independently downloaded and validated artifact

- Stage04 artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44828521856/artifacts/14677505256
- ZIP size: **20,508 bytes**, SHA-256: `6fffe7bd8731cb57233a12325af9ffbe4c1860225305a81a3f1809c4b3af2a61`, matching GitHub's recorded digest and job log.
- ZIP validation: **17 entries; decompression and CRC pass for all 17**. Embedded `sha.txt` matches PROJECT_ID and the exact parent SHA; `exit.txt=0`.
- Independently parsed `stage04_callability_tests.txt`: **19/19** tests, including three direct-symbol negative/positive controls; `stage04_provenance_tests.txt`: **16/16**; `stage04_tsv_protocol_tests.txt`: **6/6**.
- `stdout.txt` has Rust cargo native test groups with pass counts `[0,0,16,3,4,2,3,3,3]`, totaling **34/34**, zero failures, on GitHub's Linux runner (`rustc 1.100.0`).
- Independently parsed `stage04_rust_rows.tsv` as exactly 15 indexed records with four columns; cross-checked against all 15 JSON cases in `stage04_direct_runtime_report.json`. A fresh arbitrary-precision Python oracle, independent of the archived function/import, uses foundation day `F=-15055671`: for `delta=day-F`, tag=`-2*delta` for negative delta, otherwise `2*delta+1`. All **15/15** TSV oracle and candidate rows equal independently computed values; all **15/15** JSON oracle, patched, candidate rows agree. Archived Python legacy differs on **8 RED** cases, matches on **7 CONTROL**, with 0 unexpected. This is **not** an observed historical Rust RED.
- Independent cross-check used parsed contents, explicit numeric integer conversion (including >2,000 decimal digits), contiguous row indexes, row/day/offset equivalence, parity, classifications and CRC. No historical Rust production source was copied as an oracle.

## Actual evidence defect and narrowly scoped correction

The Stage04 workflow's callability test step correctly required `Ran 19 tests` and completed successfully. The same workflow nevertheless hardcoded `STAGE04_CALLABILITY_QA=16_PASS` in `evidence/stage04_callability_result.txt`. Thus the count in the summary artifact was **stale and internally inconsistent**; 16_PASS is not an accurate count for this run.

This commit changes the single workflow summary value from `16_PASS` to `19_PASS` while preserving the wording `synthetic Rust positive only`, all guards, runtime tests, source pins, and the Stage04 not-claimed policy. This report is a second audit-only file. The original artifact stays immutable; its defect is documented, not retroactively edited.

The newly changed workflow SHA requires its own completed/log evidence before its CI may be called successful. There is **no new historical production Rust day-tag entrypoint and no observed historical numeric Rust RED**; Stage04 cannot be accepted. No merge, main, Stage05, or policy change.
