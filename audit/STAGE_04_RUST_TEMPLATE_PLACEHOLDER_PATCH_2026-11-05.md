# Stage04 Rust+Azərbaycan-dili — fixture-token substitution PATCH (2026-11-05)

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Branch: Rust+Azərbaycan-dili
Verified parent: `45ecdba64646dcf08d36acdd0c225b3dc4307e54`
Scope: tools-only bug fix, bounded regression and corresponding Stage04 CI expected-count update. No production source, main, merge, Stage05 or Stage04 closure.

## Reproduced actual template defect
Before this patch, test_body() interpolated CRATE/SYMBOL **before** FM/FF/FP.
A valid symbol `old_FM_probe` became `old_-15055672_probe` inside the emitted Rust binding; this is invalid Rust. The failure was reproduced as a string-level check before patching. It does not demonstrate any historical Rust RED.

## Minimal correction and controlled checks
Replace numeric tokens in the static template **before** injecting the validated crate and symbol names. Add a bounded unittest with four identifier variants (FM, FF, FP and FM_FF_FP); each checks the exact binding and the three numeric day arguments. Keep the nine preexisting tests and update the existing workflow to require ten controls. The separate local source-equivalent template preflight verified all four variants and the existing original fixture (5/5 checks), but this does not constitute the full CI or native run.

## Evidence and acceptance boundaries
- Parent HEAD must match the verified live Rust branch; atomic commit changes only the template, its test, this workflow and this audit record.
- New CI must complete with callability 10/10, no skips; provenance 13/13, TSV 6/6, Rust Native 34/34, direct differential 15/15 and Names Lock remain distinct acceptance checks.
- The actual pre-Stage04 Rust production witness is still SOURCE_ONLY. A semantic day-tag route and Rust-runtime RED are NOT_PROVEN. Stage04 stays OPEN, CURRENT_STAGE=4, LAST_COMPLETED_STAGE=3; no Stage05.
