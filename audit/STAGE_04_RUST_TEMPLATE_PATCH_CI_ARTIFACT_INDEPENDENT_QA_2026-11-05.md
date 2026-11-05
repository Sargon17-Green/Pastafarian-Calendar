# Rust+Azərbaycan-dili — Stage04 exact CI and independent artifact audit (2026-11-05)

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Branch: `Rust+Azərbaycan-dili`
Code-PATCH SHA: `053b86cf78b6385e20bcc1ee6d919cbac2855126`
Parent (previous audit HEAD): `45ecdba64646dcf08d36acdd0c225b3dc4307e54`
CURRENT_STAGE=4; LAST_COMPLETED_STAGE=3; **Stage04 OPEN**.
No Stage05, no production code change, no merge or main mutation.

## Reproduced regression and scope

The original test harness replaced FM/FF/FP **after** interpolating a Rust symbol. A valid identifier `old_FM_probe` became invalid `old_-15055672_probe`. The branch-only patch changes the order of interpolation, adds a bounded test over FM/FF/FP/FM_FF_FP symbol cases, and raises the callability gate from 9 to 10, without weakening semantic/provenance requirements.
The source-equivalent local string-level preflight passed 5/5 before commit; this alone is NOT a Rust Native result.

## Exact completed workflow evidence

- [Stage04 CI run 41978968419](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41978968419), job `127084365221`: `completed/success`, exact code SHA `053b86cf78b6385e20bcc1ee6d919cbac2855126`.
- [Canonical Names Lock run 41978972737](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41978972737), verify job `127084379270`: `completed/success`, exact same code SHA.
- Logs independently read: cargo fmt PASS; provenance 13/13; TSV 6/6; callability 10/10 **zero skipped**; Rust Native 16+3+4+2+3+3+3 = **34/34**; direct Python↔Rust 15 rows; historical Python old-rule RED=8, CONTROL=7, UNEXPECTED=0; patch 15/15; candidate 15/15. Every Stage04 job step completed successfully.
- Rust historical Stage3 source still returns `SOURCE_ONLY_NO_SUPPORTED_SIGNATURE`; historical `callable_numeric_function_verified=false`, `callable_day_tag_route_verified=false`, `observed_runtime_red=false`, `stage04_closure=NOT_CLAIMED`. Python historical RED ≠ executed historical Rust RED.

## Independently downloaded artifact — 56/56 checks PASS

[CI artifact 13392593599](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41978968419/artifacts/13392593599) (`rust-az-stage04-discovery02-baseline`).
The downloaded ZIP is 20,159 bytes, 17 distinct entries, CRC PASS. Recomputed SHA-256:

`2ddc7bae270aabeae74a6ffc817430d462bd66520de3d76fda5f584440902d78`

This independently matches the `sha256:` digest returned by GitHub. Using Python standard-library ZIP, JSON, CSV and arbitrary-precision integers, **56 independent named assertions passed, zero failed**. Assertions checked ZIP identity/safety, exact `PROJECT_ID` and code SHA, exit code 0, non-closure markers, exact historical commit/path/blob and SOURCE_ONLY verdict, 13/6/10 unittest counts and OK/no skips, seven native-suite counts and sum 34, 15 unique TSV rows and JSON equivalence, stage/differential metadata, classification, and independent recomputation of all 15 values.

Independent normative oracle with `F=-15055671`:
`normative(d) = 2*abs(d-F) + (1 if d>=F else 0)`.
Archived Python old rule:
`legacy(d) = 2*abs(d-F)`.
For all 15 rows, independently reproduced `legacy`, `oracle`, `patched`, `candidate`, and RED/CONTROL labels. Exactly 8 RED + 7 CONTROL; zero unexpected.

These counts are **artifact QA assertions**, not 56 Rust Native tests or new historical Rust witnesses. Full Stage04 acceptance remains **NOT CLAIMED**.

## NEXT

Do not rerun successful Stage04 or Names Lock on `053b86cf78b6385e20bcc1ee6d919cbac2855126`. Preserve this exact source/CI/artifact audit. Only genuinely **new**, pre-Stage04 ancestry/blob/checkout-verified Rust production day-tag source may proceed to independently proved semantics, bounded Native execution and comparison with the independent oracle. Do not repeat the already exhausted history search. Do not declare Rust historical RED without observing it; do not advance to Stage05.
