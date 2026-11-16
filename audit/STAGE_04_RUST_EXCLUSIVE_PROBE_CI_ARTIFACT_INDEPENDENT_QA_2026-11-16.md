# Stage04 Rust Azerbaijani — completed CI artifact independent QA (2026-11-16)

## Scope and immutable identity
- PROJECT_ID: `PC-BRANCH-RUST-AZERBAIJANI`
- Branch: `Rust+Azərbaycan-dili`
- Code SHA verified as branch HEAD **before** this audit: `d5b66f055a52a3552e6d5f42c7ecb647ba6936c5`
- Stage04 workflow run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43767257468 — `completed/success`, attempt 1, exact code SHA, job `132975053698`.
- Names Lock run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43767257608 — `completed/success`, attempt 1, exact code SHA, job `132975054434`.
- Evidence artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43767257468/artifacts/14183288081
- Artifact name: `rust-az-stage04-discovery02-baseline`; compressed size **20,254 bytes**.
- ZIP SHA-256 computed from downloaded bytes: `9554de8ae6fb65f8b8c05aa173a9df40966ae03548eadebd44fe639a7a5e135b`, matching GitHub Actions digest verbatim.
- Toolchain captured in artifact: rustc 1.100.0; cargo 1.100.0.

## Independent byte and evidence inspection
A bounded standalone Python validator inspected the actual ZIP, rather than inferring correctness from GitHub's green badge. Result: **194/194 assertions PASS**, process exit 0. No source from the project was imported/executed by this validator.

Checks covered:
1. Exact downloaded size and SHA-256 versus the provider digest; ZIP CRC integrity; 17 unique flat safe member names and bounded member sizes.
2. Exact PROJECT_ID and code SHA in `sha.txt`; native `exit.txt=0`; required evidence files present.
3. Independent parsing/counting of executed Python control tests: **13/13 callability**, **13/13 provenance**, **6/6 four-column TSV protocol**, each with no failed/skipped/error result.
4. Native Rust `stdout.txt`: nine test-result lines (including two zero-test targets), **34 total tests passed, zero failed**; archived synthetic fixture reports `RED=8 CONTROL=7 UNEXPECTED=0`.
5. Identity and claim consistency of `stage04_source_pin.json`, `stage04_old_rust_callability.json` and gate result files.
6. `stage04_direct_runtime_report.json` independently cross-checked against **all 15 TSV data rows**: four columns exactly, contiguous indexes, day/oracle/candidate equal per row, report patched/candidate equals oracle for each row, and RED vs CONTROL classification independently recounted as **8 RED / 7 CONTROL / 0 unexpected**. These are cross-source consistency checks; the validator did **not** recompute the underlying mathematical oracle.
7. Main/individual result fields consistently say `STAGE04_CLOSURE=NOT_CLAIMED`; pinned source is source-only (`SOURCE_ONLY_NO_SUPPORTED_SIGNATURE`), `callable_day_tag_route_verified=false`, `observed_runtime_red=false`.

The local audit validator was exercised against the downloaded artifact and has SHA-256 `ad14ccfaf55fa56bad2df5e552af4a71ffe9944082e1e82e016f62cb9b6fc9c5`. Independent QA here means ZIP integrity and cross-evidence consistency, **not** independent re-execution of every Rust mathematical calculation or historical Rust runtime witness.

## Gate decision
- The exclusive-create synthetic test-probe guard in the code SHA has completed its natural push CI successfully; two focused regression tests are among the 13 callability controls.
- Current code CI gates verified: 13 callability, 13 provenance, 6 TSV, native Rust 34, direct Python–Rust differential 15; Names Lock green on the exact SHA. No CI was manually redispatched.
- **Stage04 remains OPEN / NOT_CLAIMED. CURRENT_STAGE=4, LAST_COMPLETED_STAGE=3.**
- The pinned pre-Stage04 Rust source is not an authenticated executable production day-tag witness, and the available archived Python RED must **not** be relabeled a historical Rust runtime RED.
- **NEXT**: require genuinely *new*, independently authenticated **pre-Stage04 callable Rust production day-tag route** and a **reproduced runtime RED against an independent oracle**. Do not rescan already exhausted history, open Stage05, merge to main, or claim closure without this evidence.

This is an **audit-only** change: no production code, source fixtures, release policy, or Stage gate is modified.
