# Rust+Azərbaycan-dili — Stage04 malformed Cargo metadata fail-closed QA (2026-11-18)

- PROJECT_ID: `PC-BRANCH-RUST-AZERBAIJANI`
- Branch: `Rust+Azərbaycan-dili`
- Verified parent HEAD: `3543e764489f20dd67c5616b7b05286b4198f574`
- Scope: historical-witness eligibility harness; no day-tag production code, oracle, historical witness, Stage05, main, or merge change.

## Reproduced defect and boundary
`tomllib.loads` accepts TOML values such as `lib = "bad"`, `package = "bad"`, and `[package] name = 12`. The prior manifest handling immediately called `.get()` and `.replace()` without validating the resulting types, raising `AttributeError` rather than the structured fail-closed `RuntimeUnverified` verdict. An isolated source-equivalent reproduction observed **3/3 AttributeError** on those exact malformed manifests; no historical Rust execution or historical RED is claimed.

## Patch contract
1. Parse Cargo.toml, then require `lib` and `package` (when present) to be TOML tables and package name to be a string before dereferencing.
2. On malformed shapes, return `RuntimeUnverified` and CLI JSON exit code 3 with `callability_status=RUNTIME_UNVERIFIED`, `source_pin_eligible=true` after prior successful source-pin verification, `callable_numeric_function_verified=false`, `callable_day_tag_route_verified=false`, `observed_runtime_red=false`, `stage04_closure=NOT_CLAIMED`.
3. New single unittest with **three independent subtests**, using synthetic Git provenance and archive-injected manifests; no historical snapshot replacement, no Cargo needed for these negative cases.
4. CI strict callability count increments 15 to **16** (with three malformed-metadata subcases); provenance remains 13, TSV 6, Rust Native 34 and direct differential 15. Full exact-SHA CI is **NOT VERIFIED** at authoring and must be judged from completed job logs, not queue state.

## Acceptance and non-acceptance
- Accept this *harness patch* only after exact-commit CI has completed successfully and test transcript names/counts and relevant Native/differential gates are checked. No prior PASS is inherited by this changed code SHA.
- Stage04 is still **OPEN/NOT_CLAIMED**, CURRENT_STAGE=4, LAST_COMPLETED_STAGE=3. Only a genuinely authenticated pre-Stage04 callable Rust production day-tag with observed Rust runtime RED against an independent normative oracle can satisfy the outstanding Stage04 historical-evidence gate. Archived Python RED is not Rust RED. No Stage05 or merge.
