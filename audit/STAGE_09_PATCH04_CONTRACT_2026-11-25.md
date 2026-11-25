# Stage09 / PATCH04 — immutable-snapshot stone correction contract

PROJECT_ID=PC-BRANCH-RUST-AZERBAIJANI
BRANCH=Rust+Azərbaycan-dili
STAGE=9
KIND=PATCH04
CURRENT_PATCH=PATCH04
STAGE09_SCOPE=SNAPSHOT_STONE_PATCH04
PREREQUISITE_STAGE08=ACCEPTED
STAGE09_ACCEPTED=NO
STAGE10=NOT_STARTED
HISTORICAL_PRE_STAGE03_RUST_RED=NOT_CLAIMED
FULL_CALENDAR=BOOTSTRAP_ONLY
CONTRACT=FROZEN

## Scope

PATCH04 adds a production wrapper that preserves the actual historical mutator call and its output, then replaces the five corrected fields using only one immutable snapshot of the previous corrected row. The Stage08 mutator and its 46-row sequential table are not edited or deleted.

For a previous row S=(w,b,s,m,r), row index i:
1. old = clone(S)
2. legacy_garbage = clone(S); invoke the real mutate_stones_wrong(i, &mut legacy_garbage)
3. corrected = [
   SAVE(old.w*old.w + 3*old.b + i),
   SAVE(old.b*old.b + 5*old.s + old.w),
   SAVE(old.s*old.s + 7*old.m + old.b),
   SAVE(old.m*old.m + 11*old.r + old.s),
   SAVE(old.r*old.r + 13*old.w + old.m)
]
4. return corrected and legacy_garbage as separate owned values.

No corrected formula reads a field after mutation. The production path calls the real historical mutator on a clone; no test oracle is used in production.

## Table contract

The Rust representation uses 46 logical rows numbered 1..46, without an extra sentinel row. Row 1 in both tables is [17,29,43,71,101]. Rows 2..46 are built from the previous corrected row, with exactly 45 wrapper calls.

- corrected_rows: 46×5 = 230 components; all 230 equal the independent snapshot oracle.
- legacy_garbage_rows: 46×5; row i>=2 is the sequential mutator result on a clone of corrected row i-1. Across 225 compared cells, exact classification is 180 RED and 45 MATCH.
- discovery04 legacy rows remain separately available from the Stage08 observation. Against the corrected oracle, their 225 compared cells retain 224 RED and 1 MATCH.
- Row 2 corrected = [378,1073,2375,6195,10493].
- Row 2 legacy garbage = [378,1434,3780,9932,25047].
- Row 3 legacy garbage = [146106,1309310,6993300,45486748,157489175].

## Context, ownership and guards

1. The real route is PATCH02 -> DISCOVERY03 -> PATCH03 -> DISCOVERY04 -> PATCH04.
2. PATCH04 requires one completed Stage08 observation, 46 legacy rows, and the previous stage metrics.
3. All 45 patch calls and both tables are built in local variables. The context is updated once, only after the complete 46-row result has been built and shape-checked.
4. The historical mutator input is not modified by the wrapper. Its garbage output and corrected output are separate owned arrays.
5. Re-entry is rejected without changing context. Missing Stage08 evidence is rejected without changing context.
6. Row indices outside 2..=46 are rejected. Independent invocations are deterministic and do not share mutable rows.
7. The Stage08 legacy table remains unchanged and its 224/1 RED/MATCH result is retained.
8. calendar_date_spaghetti remains BootstrapOnly; no full calendar is enabled.

The explicit guard count is five: invalid row 1, invalid row 47, duplicate PATCH04 handler call, missing Stage08 observation, and full-calendar BootstrapOnly guard.

## Independent oracles and required gates

The Rust test-only oracle independently computes the snapshot table and the sequential garbage/legacy tables with BigInt. The separate Python arbitrary-precision oracle recomputes all three tables and verifies all 230 corrected cells, 225 garbage cells, 225 preserved Stage08 legacy cells, duplicate/missing coverage, and exact classifications.

Required Native markers:
- 230/230 corrected GREEN
- 225 garbage cells: 180 RED / 45 MATCH
- 225 preserved Stage08 legacy cells: 224 RED / 1 MATCH
- 45 historical mutator calls; 5 guards
- BootstrapOnly preserved

The Native workflow must run cargo fmt and cargo test --all-targets, then independently run the Stage06, Stage07, Stage08 and Stage09 Python oracles. Whole-stage closure remains NOT_CLAIMED in the run artifact until a separate exact-SHA artifact audit verifies run/job/log/SHA, artifact digest, ZIP CRC, PROJECT_ID/SHA, exit 0 and all raw cell outputs. Only then may LAST_COMPLETED_STAGE advance to 9.

Stage08 remains accepted and unchanged. Stage09/PATCH04 is the only new stage in this contract. Stage10/DISCOVERY05, main, merge, and release are not started.
