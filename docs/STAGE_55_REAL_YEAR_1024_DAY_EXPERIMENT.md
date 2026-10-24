# Stage 55 — 1024 real-year post-opening days: exact inverse checkpoint

**Branch:** \`MATLAB+Polski\`. **Status:** experimental native test
pending; no change to \`main\`, canonical engine, or normative oracle.

## Native test

\`tests/run_stage55_real_year_1024_inverse_checkpoint.m\`
runs on the 45 month lengths selected by the production calendar
for year 5000, but starts from \`R=L-1\`, **after each month was
opened exactly once**. Thus there are 4199 (not 4244) days remaining.

The exact middle rank \`F/2+1\` of that all-open suffix requires a
6745-digit BigInt. The test:

1. Unranks **1024 contiguous days** using independently native-tested
   common-denominator exact child blocks and asserts precisely 3175
   days remain.
2. Computes the contiguous rank interval of that same 1024-day prefix,
   preserving every digit and verifying \`rank-lo+1=residualRank\`
   and \`hi-lo+1=residualCount\`.
3. Compares the first 96 days' rank interval with an alternative exact
   **rational** child-block algorithm, not merely the shared
   common-denominator implementation.
4. Saves the 3175-day rank, count and frontier to a portable JSON
   checkpoint with BigInt stored solely as decimal strings, restores
   through an **independent full suffix recount**, then processes 32
   more exact days in both the generic Lazy Joint and independent
   all-open chunk engines, comparing the complete cursors.

The test is isolated from the known-expensive historical Stage55
production DAG and has an explicit 55-minute job timeout.

[Native CI run 40125274755](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40125274755)
on commit \`c3d6aee46b4c96afc399a22744d96d58e8dfb1ba\`.
Do not report **PASS** until all expected \`STAGE_55_REAL_YEAR_1024_*\`
markers are present in the actual MATLAB logs.

## Scope restriction

Even a complete success here will establish a substantial exact
rank/inverse/checkpoint chain **within the already-open suffix**,
not full unranking of an arbitrary interior rank from the original
4244-day unopened state. The final five-component independent
\`normative_oracle\` differential is still absent. Formally:
\`LAST_COMPLETED_STAGE=54\`; \`STAGE_55_COMPLETE=NO\`.
