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

## 2026-11-03: strict Stage3-to-Stage4 chronology PATCH (Rust branch only)

The bounded source validator used `merge-base --is-ancestor`, which accepts
identical commits. Prior to this patch, the source gate's `stage3_closure ->
stage4_introduction` relation was therefore non-strict despite the distinct
historical stage boundary required by this contract. This is a source-eligibility
QA issue, **not evidence of any historical day-tag runtime defect**.

The predicate now rejects `stage3_closure == stage4_introduction`. Two bounded
synthetic-history regression/control cases establish (1) rejection of identical
Stage3/Stage4 boundaries and (2) acceptance when the genuine Stage4 introduction
itself is the branch HEAD. The CI provenance gate expects **11/11** tests,
including prior nine. The historical production Rust day-tag route remains
unproven and Stage04 closure remains NOT_CLAIMED until a genuine callable,
pre-Stage4 Rust implementation produces observed runtime RED under an independent
oracle. GitHub CI results must be read from completed job logs; merely committing
this patch does not establish CI PASS.

## 2026-11-03: checkout-HEAD identity QA PATCH (Rust branch only)

The prior validator checked that the supplied branch-head SHA descended from
Stage4 introduction, but it did **not** bind this caller-supplied SHA to the
actual Git checkout. In an isolated four-commit Git fixture, the ancestor check
accepted the Stage4 commit while checkout HEAD was a later commit. This is a
source-provenance false-positive risk, **not** a historical Rust day-tag bug.

The validator now requires `git rev-parse HEAD == --branch-head`. The
workflow separately checks the intended Rust+Azərbaycan-dili GitHub ref name
and checks out the exact event SHA. Two negative tests reject a stale ancestor
and a future descendant; the prior introduction-as-HEAD positive control now
actually checks out that introduction commit before verifying it. Total bounded
provenance cases: **13**. No historical production Rust day-tag route, observed
runtime RED, Stage4 closure, Stage5, or merge is claimed by this change.
