# Stage04 Rust+Azərbaycan-dili — corrected source-scope CI and independent artifact QA (2026-11-21)

PROJECT_ID: `PC-BRANCH-RUST-AZERBAIJANI`  
Authorized branch: `Rust+Azərbaycan-dili`  
Exact tested source/test SHA: `59998ab31a7fa26e64d967d91d3111f270e4f3d0`  
Current stage: 4; last completed stage: 3. **Stage04 OPEN / NOT_CLAIMED.**

## Verified GitHub execution (no manual re-dispatch)

- Stage04 push workflow: [run 44890496492](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44890496492), attempt 1, `completed/success`, exact `head_sha=59998ab31a7fa26e64d967d91d3111f270e4f3d0`; job `136805038553` `completed/success`. Decoded log shows exact-SHA checkout, all verification steps successful, and artifact finalized.
- Canonical Names Lock push workflow: [run 44890496501](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44890496501), attempt 1, `completed/success`, same `head_sha`; job `136805038627` `completed/success`. Decoded job log confirms checkout of exact SHA and successful canonical-names verification.
- Callability Python controls: **19/19**; historical provenance gates: **16/16**; four-column TSV protocol: **6/6**.
- Native Cargo/Rust test result groups: **16 + 3 + 4 + 2 + 3 + 3 + 3 = 34/34** (successful, without failures); differential cross-runtime report: **15/15** candidate and patched checks, archived Python oldDayTag classification **8 RED + 7 CONTROL, 0 unexpected**.
- These figures are scope-specific; the Rust Native result belongs to the current source/test harness, not to the historical production day-tag.

## Independently rechecked artifact bytes

[Artifact 14701619578](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44890496492/artifacts/14701619578), `rust-az-stage04-discovery02-baseline`:

- Downloaded ZIP length: **20,513 bytes**, SHA-256 `91150bb877782e07cf52f8d8eab10f2e74e26deb1a485c4573d71ceec580d8f1`; matches GitHub Actions reported artifact digest and upload log.
- ZIP opened, **17/17 entries passed CRC**; embedded `exit.txt` equals `0`.
- `sha.txt` embeds the exact PROJECT_ID and tested SHA; source-pin and callability JSON agree on historical witness commit `716e5a6f335b1a15464029b446edb468f3a8482c`.
- Recalculated independently from integer offsets, without using candidate or archived Python functions: let `F = -15055671` and `d = day - F`; expected integer tag is `-2*d` if `d < 0`, otherwise `2*d+1`. Independently parsed the 15 TSV rows and the 15 JSON case records; all **15/15** TSV oracle, candidate, JSON patched, JSON candidate and offsets agree with this formula. JSON archived-legacy classifications recomputed to **8 RED / 7 CONTROL** when compared to `2*abs(d)`. Report metadata checks: 15 rows, 15 patch OK, 15 candidate OK, 0 unexpected, result PASS, closure NOT_CLAIMED.
- Re-read evidence text: `stage04_callability_result.txt` states `STAGE04_ACTUAL_OLD_RUST_CALLABLE_DAY_TAG=NOT_PROVEN`, and provenance text states `STAGE04_HISTORICAL_RUST_ROUTE=NOT_PROVEN`; both say `STAGE04_CLOSURE=NOT_CLAIMED`.

## Deliberate limits / next gate

This is completed **CI + current Rust Native test suite + direct differential + independent artifact QA**, not accepted Stage04. The only 8 RED observations belong to archived Python `oldDayTag`; **no historical production Rust callable numeric day-tag or observed historical Rust numeric RED** has been established. Historical `src/lib.rs` witness is BootstrapOnly, and a test-only oracle is not production callability. Do not promote Stage04, start Stage05, create a replacement historical witness, or rewrite historical evidence.

NEXT: with the corrected source-scope gate verified, conduct a new *bounded and independently sourced* provenance/callability investigation only if a previously unexamined real historical Rust production path or admissible original artifact is identified. If no new witness exists, preserve `NOT_PROVEN` explicitly; do not turn success of synthetic probes into historical RED. No duplicate CI on the same tested SHA. Audit-only record; no production Rust file change, main/merge or publication.

## Evidence links

- [Exact source/test correction](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/59998ab31a7fa26e64d967d91d3111f270e4f3d0)
- [Prior static source-scope report](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/59998ab31a7fa26e64d967d91d3111f270e4f3d0/audit/STAGE_04_RUST_SOURCE_SCOPE_RAW_ATTR_MACRO_QA_2026-11-21.md)
- [Stage04 run](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44890496492) and [Names Lock run](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44890496501)
- [Artifact](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44890496492/artifacts/14701619578)
