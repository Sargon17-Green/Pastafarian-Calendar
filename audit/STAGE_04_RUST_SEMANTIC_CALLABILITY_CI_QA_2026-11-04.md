# Stage04 Rust+Azərbaycan-dili — semantic callability patch, CI and independent artifact QA

Date: 2026-11-04
PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Branch: `Rust+Azərbaycan-dili`
Verified code HEAD: `1c07f970bbe2e6ebc1d71fa0247f6bdff858215c`
Initial three-file semantic fix: `c5d20127d7b1c15e94b91d8d21e2c8bd611a2472`
Targeted stale-assertion fix: `1c07f970bbe2e6ebc1d71fa0247f6bdff858215c`
No production implementation change; no main merge or Stage05.

## Scope and reproduced failure

The historical gate's synthetic callable test could previously set
`callable_day_tag_route_verified=true` merely by executing a pinned
`fn(&BigInt) -> BigInt`, without independent evidence that it implements
production day-tag semantics. The targeted patch now distinguishes
`callable_numeric_function_verified` (a typed numeric symbol was actually
executed) from `callable_day_tag_route_verified` (requires distinct
source-pinned semantic proof). The latter remains false in this gate.

First patch CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41870218494
completed/failure, with exactly 8 of 9 callability tests passing. Its
artifact 13343263151 showed the one failed assertion passed the obsolete
`old_day_tag` name to `test_body` after the synthetic fixture became
`old_numeric_probe`. Rust Native and differential steps were skipped in
that failed run. Fixed just that argument on the branch.

## Exact corrected-SHA results

- Stage04: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41870660454
  — job 126716496028, completed/success, exact HEAD `1c07f970bbe2e6ebc1d71fa0247f6bdff858215c`.
- Canonical Names Lock: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41870660216
  — completed/success, exact HEAD `1c07f970bbe2e6ebc1d71fa0247f6bdff858215c`.
- CI controls: rustfmt PASS; source provenance 13/13; strict TSV protocol 6/6;
  native Rust callability unit controls 9/9, zero skipped; historical pinned
  Stage3 verdict `SOURCE_ONLY_NO_SUPPORTED_SIGNATURE`.
- Rust Native test totals: 16+3+4+2+3+3+3 = **34 passed, 0 failed**.
- Direct-runtime Python/Rust differential: 15 rows, archived Python old rule
  RED=8 CONTROL=7 UNEXPECTED=0; patched values 15/15 and current Rust
  candidate 15/15 equal the independent normative oracle. **These are
  not historical Rust runtime RED cases.**

Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41870660454/artifacts/13343099675
GitHub digest: `sha256:e0d4789a22f34bbe038d6c0294e1ae14527d71daef29fb9255d98f8cbb3de4e6`.
Downloaded ZIP: 20112 bytes, 17 distinct members; independent Python stdlib
ZIP CRC check PASS and independent rehashed SHA-256 **identical** to GitHub.

## Independent read-only QA on downloaded artifact: 30/30 PASS

Thirty separately evaluated assertions, not merely textual copying of the
CI summary, covered: ZIP CRC, count/uniqueness, byte size, SHA-256, exact
archive checkout SHA and exit code, the nonclosure marker; 9/13/6 unittest
counts and no skips/failures; independent source pin and historical
`SOURCE_ONLY`/false numeric callable/false semantic route/false RED verdict;
Native stdout totals; TSV schema and 15 unique ordered indices; exact
TSV-to-runtime-JSON identity; and all 15 BigInt values recomputed using

`F = -15055671; normative(d)=2*abs(d-F)+(1 if d>=F else 0)`

against the archived Python old rule `2*abs(d-F)`. Recounted 8 RED,
7 CONTROL, zero unexpected, patched/candidate 15/15, and retained
`stage_closure=NOT_CLAIMED`.

The synthetic positive establishes only executable numeric callability;
the actual pinned pre-Stage4 Rust source still lacks a supported callable
historical day-tag signature. `callable_numeric_function_verified=false`,
`callable_day_tag_route_verified=false` and `observed_runtime_red=false`
for the historical source. **Stage04 remains OPEN**;
`CURRENT_STAGE=4`, `LAST_COMPLETED_STAGE=3`. No Stage04 closure, no
Stage05 and no main/merge.

NEXT: preserve exact completed CI and the 30/30 artifact audit. Only a
genuinely *new* pre-Stage4, ancestry/blob/checkout-verified Rust production
witness could justify bounded execution and independent semantic/numeric
comparison. Do not rerun this successful CI on the same code SHA or repeat
previously exhausted history searches without new evidence.
