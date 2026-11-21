# Stage04 Rust+Azərbaycan-dili — original Git tree vs `git archive` integrity (2026-11-21)

PROJECT_ID: `PC-BRANCH-RUST-AZERBAIJANI`  
Authorized branch: `Rust+Azərbaycan-dili`  
Starting HEAD: `4e9641a827abc2c3df9e11d54c607252f8a50ebc`  
Code commit: `b69bf905f0861fd32e877dd7dd926ecfce5b729f`  
Regression commit: `6e81098c9666e340cb48989a5f59ca9f169b8714`  
CURRENT_STAGE=4; LAST_COMPLETED_STAGE=3; **Stage04 OPEN / NOT_CLAIMED**.

## Newly reproduced integrity gap

`git archive` is not necessarily a byte-for-byte historical Git tree: repository `.gitattributes` can apply `export-subst` to rewrite source and `export-ignore` to omit tree entries. The prior `archive()` verified tar path safety and extraction, not exported content against original Git object SHAs. Therefore a later Cargo execution over such an export would not by itself prove execution of the *pinned original production tree*.

Isolated local Git 2.47.3 / Python 3.13.5 synthetic evidence (not historical Rust):
- 3 tracked tree files, 2 exported files when `secret.txt export-ignore` is configured; absence independently observed.
- `src/lib.rs export-subst` changes `$Format:%H$` to the commit SHA; original and exported bytes demonstrably differ.
- Independent stand-alone tree verifier outcomes: normal archive `PASS`; substitution `BYTE_MISMATCH`; omission `ENTRY_MISMATCH`.

## Concrete branch-only remediation

In `tools/stage04_rust_callability_eligibility.py`, `_verify_archived_tree()` runs *before* probe installation. It enumerates original commit tree members via bounded `git ls-tree -r -z --full-tree`, requires regular Git blob entries, compares the complete exported-file path set, and recomputes each `blob <length>\\0<bytes>` SHA-1. Missing, extra, nonregular, duplicated, or byte-modified entries cause `RuntimeUnverified`; no historical RED or acceptance is asserted.

In `tools/tests/test_stage04_rust_callability_eligibility.py`, the existing reserved-probe-preservation test now also checks a normal exact archive and two negative controls: export-subst and export-ignore. This extends an existing unittest without changing the workflow's fixed 19-test expectation. No production Rust source, stage counter, or historical fixture is modified.

## Verification and limitations

Both code and test commits were individually fetched back; each changes exactly one intended file, and the authorized branch matched test commit `6e81098c9666e340cb48989a5f59ca9f169b8714` at compare readback. Local isolated reproduction verifies the *risk and proposed algorithm*; it is not a completed run of the committed test file. The GitHub commit-status and PR-filtered workflow-run queries provided no completed push-run/job/log evidence for the new SHA at inspection. **No new-SHA CI, Native, differential, artifact, or stage acceptance is claimed.**

The pre-Stage04 production Rust `calendar_date_spaghetti` remains `BootstrapOnly`; no original callable production numeric day-tag, observed Rust numeric RED, or original compiled release artifact is newly proven. The archived Python 8 RED/7 CONTROL classification is not Rust RED.

## NEXT

Resolve any automatically triggered Stage04 and Names Lock push workflows for exact new code/test SHA using run, job, decoded checkout logs and artifact; do not dispatch duplicates. Repair only evidenced failures. Keep Stage04 OPEN/NOT_CLAIMED until an independently authenticated original pre-Stage04 Rust production route and real numeric runtime witness satisfy the existing gate. No Stage05, main, merge, or publication.
