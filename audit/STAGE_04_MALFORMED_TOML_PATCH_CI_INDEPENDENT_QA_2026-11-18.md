# Rust+Azərbaycan-dili — Stage04 malformed-TOML PATCH CI and artifact independent QA

- PROJECT_ID: `PC-BRANCH-RUST-AZERBAIJANI`
- Branch: `Rust+Azərbaycan-dili`
- Code/test SHA executed by CI: `d292f66eac36282a0c7074ca51e6729b13a32c6f`
- Parent code PATCH: `d458dd9b7ee34dfe1bfb26323c594a1895ed7938`
- Scope: exact-SHA CI verification and independent artifact validation. This report does not close Stage04 and does not claim historical Rust day-tag RED.

## Exact CI results

Both automatic runs completed successfully on the exact SHA `d292f66eac36282a0c7074ca51e6729b13a32c6f`; the checkout logs independently show that exact commit on branch `Rust+Azərbaycan-dili`.

| Run | Job | Result |
|---|---:|---|
| Stage04 baseline `44374211903` | `135048872139` | completed / success |
| Names Lock `44374211853` | `135048871940` | completed / success |

Stage04 job steps all completed successfully. Verified gates:
- Callability eligibility: **16/16** Python tests, including the three malformed-but-parseable Cargo metadata subcases.
- Provenance: **13/13**.
- TSV protocol: **6/6**.
- Rust native test suites: **34/34** (suite counts 16 + 3 + 4 + 2 + 3 + 3 + 3).
- Direct runtime differential: **15 rows**, with 8 archived-legacy RED, 7 controls, 0 unexpected; patched and current candidate each matched the oracle on all 15 rows.
- Stage04 closure explicitly remained `NOT_CLAIMED`.

Names Lock logs show checkout of the exact SHA and successful canonical-name verification.

## Artifact integrity and independent checks

Artifact:
- Run: `44374211903`
- Artifact ID: `14461378543`
- Name: `rust-az-stage04-discovery02-baseline`
- Size: **20,344 bytes**
- SHA-256: `980d7c0d974981cce9ad8e6a16f54fee3ddf595120f4a16e742d21c6c5720692`
- ZIP members: **17**, CRC test: **17/17 valid**
- `exit.txt`: `0`
- `sha.txt`: exact PROJECT_ID and SHA above.
- Archived Python source Git blob SHA-1 recomputed from the artifact: `405f461b2e2cdd170ded010e6f8046b78d6b4ab6`, matching the pinned source blob.

Independent artifact validation:
- Report JSON: 15/15 rows; TSV: 15/15 rows; each TSV row matches its report row.
- Recomputed the normative day-count formula independently with arbitrary-precision Python integers:
  `F = -15055671`; `day_count(F)=1`; for `day>F`, `2*(day-F)+1`; for `day<F`, `2*(F-day)`.
- Independent oracle recomputation matched the report oracle on **15/15** rows.
- Current Rust candidate values matched that independent oracle on **15/15** rows.
- Archived patch values matched that independent oracle on **15/15** rows.
- Archived Python `oldDayTag` and `dayTagWithFoundationScar` were independently executed from the archived source and matched their report columns on **15/15** rows each.
- The archived Python legacy output differs from the normative oracle on **8/15** rows and agrees on **7/15**. This is the source of the 8 RED / 7 CONTROL classification.

## Historical Rust witness: still not established

The pinned pre-Stage04 Rust source is commit `716e5a6f335b1a15464029b446edb468f3a8482c`, path `src/lib.rs`, blob `8a813ba020c9101276007148c93cb00ae7836644`.

That source exposes `calendar_date_spaghetti(calculation_day: BigInt, target_day: BigInt) -> Result<[String; 5], MonsterError>`, which returns the deliberate `BootstrapOnly` error. It is not a day-tag function and does not expose the callability harness's supported day-tag signature. The exact-run artifact accordingly reports:
- `callability_status=SOURCE_ONLY_NO_SUPPORTED_SIGNATURE`
- `callable_day_tag_route_verified=false`
- `observed_runtime_red=false`
- `stage04_closure=NOT_CLAIMED`

The current `src/discovery02_day_tag_probe.rs` function `candidate_day_tag` is a Stage04 discovery probe; its source comment says it is not connected to the five-component production calendar entry. Likewise, `tests/stage04_discovery02_archived_route.rs` contains a test-only Rust mathematical reconstruction of the archived **Python** `oldDayTag` function. Neither is an authenticated pre-Stage04 Rust production witness.

## Decision and next action

- The malformed-TOML fail-closed harness PATCH and its exact-SHA CI gates are verified successful.
- **Stage04 remains OPEN / NOT_CLAIMED; CURRENT_STAGE=4; LAST_COMPLETED_STAGE=3.**
- No historical Rust callable production day-tag or observed historical Rust runtime RED has been proven.
- Next: consider only a genuinely new, provenance-authenticated pre-Stage04 Rust production day-tag function; compile and invoke that original pinned source, then compare its observed outputs to an independent normative oracle. Do not substitute archived Python behavior, the Stage04 probe, a synthetic fixture, or a post-Stage04 function. No exhausted-history rescan, Stage05, main, or merge.
