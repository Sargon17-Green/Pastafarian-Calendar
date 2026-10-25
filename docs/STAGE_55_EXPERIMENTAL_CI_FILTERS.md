# Stage 55 — GitHub Actions exact coverage and run cost

The heavy `matlab-stage55-native.yml` remains the **mandatory**
production-vs-independent-oracle Stage 55 acceptance workflow.

Its original `push.paths` included all `src/**` and `tests/**`,
with selective exclusions for preexisting standalone experiments.
When new independent experimental algorithms were added in late
October 2026, the new paths were not yet excluded. Each experiment
push needlessly triggered another 180-minute-cap Stage 55 heavy
runner, although none of the production compatibility routes, legacy
DAG, or independent oracle changed.

The current workflow extends the **explicit** list of excluded
experimental-only helpers and tests. Each experimental method has
(or is covered by) its own native MATLAB R2026a workflow. The
critical include globs for `src/**`, `tests/**`,
`DEVELOPMENT_STAGE.md`, and `docs/STAGE_55_FINAL_AUDIT.md`
remain intact for nonexcluded production and acceptance work.
Unconditional manual `workflow_dispatch` also remains, so the
full original audit can still be run at any moment.

**No weaker Stage 55 gate**: exclusions are only CI scheduling
filters. They neither change `run_stage55_final_audit` nor its
heavy 26-patch production/oracle differential, and they never allow
`LAST_COMPLETED_STAGE=55` absent the full required native PASS.

Existing queued/in-progress heavy runs are left untouched, not
misreported as passed or canceled. Stage 55 remains pending.
