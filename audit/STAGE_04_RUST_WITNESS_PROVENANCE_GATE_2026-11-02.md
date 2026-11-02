# Stage04: bounded historical Rust witness provenance gate

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Branch: Rust+Azərbaycan-dili
Stage: CURRENT_STAGE=4; LAST_COMPLETED_STAGE=3; BootstrapOnly; closure OPEN

This gate tests SOURCE eligibility only. It must never claim a historical Rust
day-tag defect or expected-red based on source eligibility, a synthetic fixture,
the tests/support normative oracle, or an independent Python release.

## Inputs and output

- CLI: tools/stage04_rust_witness_provenance.py
- Inputs: repository, exact 40-hex witness commit, src/**/*.rs path and blob
  SHA; Stage3-closure, first-Stage4-commit and current Rust-branch HEAD SHA.
- Source gate: actual blob equals SHA at that revision; commit is ancestor of
  Stage3 closure; Stage3 closure is ancestor of Stage4 introduction; Stage4
  introduction is ancestor of the current branch HEAD.
- Rejected: non-Rust path, tests/support, divergent ancestor lines, post-Stage3
  candidate added for Stage4, incorrect SHA, malformed/traversal path.
- Output JSON: source_pin_eligible; historical_day_tag_route_proven=false;
  observed_runtime_red=false; stage04_closure=NOT_CLAIMED. Exit 2 on
  inadmissible source (no inferred runtime claims).

## Executed local validation and CI acceptance

Nine isolated unit tests with temporary synthetic Git commit histories passed
locally on 2026-11-02 (9/9). They exercise one eligible historical source pin,
eight exclusions and validation controls; synthetic tests are NOT a Rust legacy
RED. No new Rust Native execution was performed locally.

Existing Stage04 GitHub Actions workflow now runs the nine bounded checks,
then validates the actual historical Stage3 src/lib.rs blob at
716e5a6f335b1a15464029b446edb468f3a8482c:
8a813ba020c9101276007148c93cb00ae7836644. This tests an eligible SOURCE
pin, NOT a day-tag route: Stage3 lib.rs was BootstrapOnly. Git checkout is
depth-bounded at 100 commits. Evidence artifact includes a JSON verdict and
nine-test log. The prior six exact-TSV tests remain a separate gate.

Stage04 acceptance remains gated on a NEW pinned Rust production day-tag
historical implementation, actual callable old-version execution, concrete
input/output, an independent normative comparison and observed runtime RED.
None has been established by this QA. No Stage05 or main/merge. Maintain
Stage3 SAVE regression and Stage04 Native gates.

CI outcomes on the newly committed workflow must be assessed from completed
run/job logs, not from local test success or queued/in_progress state.
