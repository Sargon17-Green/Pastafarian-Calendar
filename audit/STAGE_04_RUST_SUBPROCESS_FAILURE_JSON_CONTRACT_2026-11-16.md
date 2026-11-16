# Stage04 Rust Azerbaijani — historical subprocess failure contract (2026-11-16)

- PROJECT_ID: `PC-BRANCH-RUST-AZERBAIJANI`
- Branch: `Rust+Azərbaycan-dili`
- Verified parent branch HEAD: `2892696ff749504d552d7169b33283ac21d4a8a3`
- Completed parent audit-only Names Lock: [run 43939523031](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43939523031), attempt 1, completed/success, job 133552988983 verify completed/success.
- Scope: Stage04 historical Rust witness **gate hardening**, not a new witness or a production-day-tag change.

## Reproduced failure class
The pinned callability CLI invokes `verify_pin`, which can raise `subprocess.TimeoutExpired` (Git timeout) or `OSError` (Git executable/access failure). Before this patch its `main` exception branches handled only `ProvenanceError` and `RuntimeUnverified`; both OS exception classes escaped instead of emitting a machine-readable NOT_CLAIMED result. An isolated source-equivalent try/except reproduction returned `TimeoutExpired ESCAPED_BOTH_HANDLERS` and `OSError ESCAPED_BOTH_HANDLERS` (2/2). This is **not** a reproduction of any historical Rust runtime RED.

## Change and bounded regression contract
1. Treat either exception as `RUNTIME_UNVERIFIED`, return exit code 3, emit one JSON object, with `source_pin_eligible=false`, both callable fields false, `observed_runtime_red=false`, and `stage04_closure=NOT_CLAIMED`.
2. Add two CLI-boundary tests injecting respectively `TimeoutExpired` and `OSError`, asserting parsed JSON and non-acceptance. These tests are independent of Git/Cargo availability and cannot establish historical Rust callability.
3. Update the Stage04 CI callability gate from 13 to 15 expected tests; retain existing provenance (13), TSV (6), Native Rust and differential gates, including strict no-skips rule.
4. Do not claim Stage04 completion from a green CI: **CURRENT_STAGE=4, LAST_COMPLETED_STAGE=3, Stage04 OPEN/NOT_CLAIMED**.

## Evidence status at authoring
- Parent code SHA `d5b66f055a52a3552e6d5f42c7ecb647ba6936c5` retains completed earlier Stage04 CI (13 callability, 13 provenance, 6 TSV, 34 Native, 15 differential).
- This patch's newly changed test/workflow/native verdicts are **not established until the exact new SHA finishes GitHub Actions**.
- Historical pre-Stage04 callable Rust production day-tag and observed runtime RED remain **NOT_PROVEN**. No Stage05, main, merge or publication.
