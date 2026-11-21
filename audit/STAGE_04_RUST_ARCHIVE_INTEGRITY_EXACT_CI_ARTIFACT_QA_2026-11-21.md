# Stage04 Rust Azerbaijani — exact-SHA archive integrity CI/artifact QA (2026-11-21)

Project ID: `PC-BRANCH-RUST-AZERBAIJANI`
Branch: `Rust+Azərbaycan-dili`
Scope: independent QA evidence for the previously committed archive byte/membership guard; **not** Stage04 acceptance.

## Exact revision and job-level observations
- Tested code/test commit: `6e81098c9666e340cb48989a5f59ca9f169b8714` (includes `b69bf905f0861fd32e877dd7dd926ecfce5b729f` source patch and `6e81098c` regression patch).
- Stage04 automatic push run [44896130285](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44896130285), attempt 1, completed/success, job `136822061426`, exact checkout seen in decoded logs.
- Canonical Names Lock automatic push [44896130342](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44896130342), completed/success, job `136822061523`, exact code SHA checkout and verify success.
- Audit-only starting HEAD `09eba6911573328aa40b662a3c17cc126a2957c4`: Names Lock automatic push [44896180459](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44896180459), completed/success, job `136822216149`, exact audit-only SHA checkout and verify success.
- These results were discovered via exact `head_sha` and `event=push` API query; PR-only run lookup and empty combined commit status had not demonstrated absence of push CI. No duplicate workflow dispatch.

## Independent artifact bytes and content verification
- [Stage04 artifact 14703787631](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44896130285/artifacts/14703787631) downloaded from the completed run and inspected as a ZIP.
- ZIP byte count **20,529**; independently computed SHA-256 `a418632639be42b939a53472fc6fff8595052b1ad49f24298a8a0efb81381afc`; matches GitHub artifact digest and job upload log.
- ZIP has **17 members**; ZIP CRC **17/17** passed; `exit.txt=0`; `sha.txt` names the exact tested SHA and Project ID; `result.txt` explicitly states `STAGE04_CLOSURE=NOT_CLAIMED`.
- Bounded test evidence: callability Python **19/19**, pinned provenance Python **16/16**, TSV protocol Python **6/6**, Rust Native tests summed across suites **34/34**, direct Python/Rust numeric differential **15/15**.
- Independently parsed all 15 TSV rows and evaluated a piecewise big-integer oracle with origin `F=-15055671`: `tag(d) = 2*(F-d)` when `d<F`, otherwise `2*(d-F)+1`. Independent exact-integer recomputation matched both reported oracle and Rust candidate **15/15**, including 1024-bit-scale cases. This independent calculation does not reuse the candidate output as its expected value.
- Differential labels **8 RED, 7 CONTROL, 0 UNEXPECTED** refer to *archived Python* `legacy_day_counts.py`, not observed pre-Stage04 Rust production output.

## Distinct evidence categories and limits
- Current Rust Native and differential: **PASS for the tested synthetic/current candidate SHA only**.
- Archive integrity regression and provenance eligibility: **PASS for the exact tested code/test SHA**; they assert the integrity of the original Git tree when creating a probe.
- A historical Rust `src/lib.rs` source witness is present at `716e5a6f335b1a15464029b446edb468f3a8482c` (blob `8a813ba020c9101276007148c93cb00ae7836644`), but the original `calendar_date_spaghetti` returns `BootstrapOnly`. `stage04_old_rust_callability.json` says `SOURCE_ONLY_NO_SUPPORTED_SIGNATURE`, callable numeric route false, and observed runtime RED false.
- **Stage04 OPEN/NOT_CLAIMED**, `CURRENT_STAGE=4`, `LAST_COMPLETED_STAGE=3`. No historical Rust numeric RED or production callable day-tag established. No Stage05, main, merge, or policy change.

## NEXT
Search *only with new evidence* for an original, pre-Stage04 Rust production compiled asset or genuinely uninspected callable entry point. Demand commit/tree/blob provenance, Cargo target reachability, actual compiler/runtime invocation and independently evaluated numeric baseline before claiming a historical Rust RED. Otherwise retain Stage04 OPEN/NOT_CLAIMED and do not loop through previously exhausted historical source inventories.
