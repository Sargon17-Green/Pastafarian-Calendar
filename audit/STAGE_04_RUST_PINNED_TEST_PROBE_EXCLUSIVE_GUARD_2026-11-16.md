# Rust+Azərbaycan-dili — Stage04 pinned-snapshot probe collision guard

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Branch: `Rust+Azərbaycan-dili`
Parent HEAD pinned before this change: `897b8b37e8c05486da697362e16565513f3162e6`.
CURRENT_STAGE=4; LAST_COMPLETED_STAGE=3; Stage04 **OPEN / NOT_CLAIMED**.

## Reproduction and scope

A bounded isolated Python reproduction of the old fixed-path `Path.write_text()` flow created a pre-existing `tests/stage04_callability_gate.rs` with a sentinel, then wrote the generated probe to the same path: `REPRO_FIXED_PATH_OVERWRITE=True`, `original_survives=False`. This is a **synthetic harness file-integrity failure**, not evidence of any historic production Rust RED.

## Narrow fix

`install_probe()` creates the generated `tests/stage04_callability_gate.rs` **exclusively** with `open("x")`, refusing a pre-existing path, preserving bytes and returning `RUNTIME_UNVERIFIED` through the existing callability error boundary. It also converts other probe-creation I/O errors into `RuntimeUnverified`. It does not modify the pinned production function or oracle.

Two independent focused regression cases were added: (1) pre-existing historical sentinel is retained and rejected; (2) successful first probe creation is exact, and a second attempt refuses replacement with unchanged bytes. Callability test workflow expected count changes **11 → 13**, with CI evidence capture preserved.

This commit affects only the Stage04 QA harness, its Python tests, the Stage04 workflow gate, and this audit. **No Native or GitHub CI PASS is claimed by this audit before completed workflow logs are inspected.** Previous code SHA `455ffef83378761d421a1e4d64cf5f1ca45051de` has already passed 34 Rust Native, 15 differential, and 199 independent ZIP checks; do not rerun that SHA.

## Still outstanding

The historical pre-Stage04 Rust production day-tag callable route and observed Rust runtime RED remain **NOT_PROVEN**. This test-path guard is not a semantic witness. Preserve CURRENT_STAGE=4 and LAST_COMPLETED_STAGE=3; no Stage05, main, merge, or historical-rescan claim.
