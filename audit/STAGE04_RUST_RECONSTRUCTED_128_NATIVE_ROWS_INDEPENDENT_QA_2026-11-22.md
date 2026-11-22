# Rust Azerbaijani reconstructed Stage04 — 128 observed Native outputs vs independent oracle

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Date: 2026-11-22
Branch: reconstruction/rust-az-stage03-daytag-red-20261121
Code/test commit: 07a8e7b4b2e90cdc42886dd88c6b754fd5ebb085
Parent: 35bda9d2a62a17b4c0afe00ea1eb7ce875bdfbb5
Scope: reconstructed-branch test instrumentation and audit only. ORIGINAL_STAGE04=OPEN/NOT_CLAIMED.

## Instrumentation and source verification

The sole code/test change at the tested SHA was in `tests/reconstruction_stage03_daytag_red.rs`: each deterministic signed-BigInt case prints
`RECONSTRUCTED_RUST_DAYTAG_DIFF_CASE_INDEX=<i> DAY=<decimal> ACTUAL=<decimal> ORACLE=<decimal>`
before checking equality. The actual value is returned by the compiled Rust production MonsterManager/Dispatcher route in this **2026 reconstruction**, not the original pre-Stage04 production code. The existing workflow captures `cargo test --all-targets -- --nocapture` stdout to `evidence/stdout.txt` and uploads `evidence/`; no workflow or production Rust source was edited in this commit.

GitHub compare `35bda9d2..07a8e7b4`: ahead=1, behind=0, one modified test file (+6/-1). Live reconstruction ref was identical to the tested SHA on post-write readback. Original `Rust+Azərbaycan-dili` branch stayed at `9dc029ec81fa1d6538113a4cc9c56ad41f160bb7`.

## Completed exact-SHA Native evidence

- Automatic push run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45067993657
- Job: `137348363963`, status `completed`, conclusion `success`; checkout/Stage03+RED-ancestor gate, Native regression step, artifact upload all concluded success.
- Checked out SHA in decoded job log: `07a8e7b4b2e90cdc42886dd88c6b754fd5ebb085`.
- Rust test result groups: reconstructed 2/2, Stage01 16/16, Stage02 3/3, Stage03 4/4; total 25/25.
- Artifact: `14772565407`, `rust-az-reconstructed-daytag-green`, 10,443 bytes, GitHub-reported `sha256:16f1397f91c61288a48fcf605ff41dab736ad9453ae31aa91871f08b3bdc726f`. Artifact listing and upload-log digest agree. Its ZIP bytes were **not** independently re-downloaded/re-hashed in this verification, so the digest is attributed to GitHub.

## Independent numeric comparison of actual per-case Rust log output

The existing original-branch test-independent expected fixture:
`audit/fixtures/rust_az_stage04_128_independent_oracle_20261122.tsv`
at original SHA `9dc029ec81fa1d6538113a4cc9c56ad41f160bb7`, blob `2c4a4b02afd47744bffcbe3e5c2dd2fe6177e461`, 128 data rows, previously archived SHA256 `9fb7051a993abe6c37980848ef912c8f5a438c51a782fb7e0d786944a45ffb80`.

A separate JavaScript BigInt check parsed the decoded **observed Native job log** and all 128 independent TSV rows, compared index, input day, observed `ACTUAL`, Rust-reported `ORACLE`, fixture `oracle_tag`, and recomputed external piecewise-integer expected value:
`F=-15055671; P(d)=2*(F-d)` when `d<F`; otherwise `P(d)=2*(d-F)+1`.

- Captured Native per-case rows: 128
- Unique indices: 128, covering exactly 0–127
- Observed Rust day and actual tag vs fixed fixture: 128/128
- Observed Rust ORACLE vs fixed fixture and separately recomputed BigInt formula: 128/128
- Fixture distance vs day: 128/128
- Mismatches: 0
- Additional Native summary `RECONSTRUCTED_RUST_DAYTAG_DIFFERENTIAL=128 GREEN=128 UNEXPECTED=0` appeared, but the per-case reconciliation does **not** depend solely on this summary.

## Exact admission boundary and next

This establishes independent comparison of **all 128 observed Native reconstructed GREEN outputs**, unlike the earlier aggregate-only 128 assertion. It is a completed Native+differential QA result for the **2026 reconstruction**, not a new historical Rust numeric RED witness. The reconstructed RED `108833d0...` remains **after** canonical Stage03 closure `716e5a6f...`; the original Stage04 witness provenance gate requires ancestry at/before closure. No change to that contract is authorized.

Original Stage04: OPEN/NOT_CLAIMED; CURRENT_STAGE=4; LAST_COMPLETED_STAGE=3.
NEXT: user-exclusive policy decision whether to explicitly admit a labelled 2026 RED→GREEN reconstruction in place of the originally required historic Rust witness, or retain the historical condition pending genuinely new eligible evidence. No Stage05, main, merge, original-source edits or policy changes were performed.
