# Stage 11 / DISCOVERY08 — కనిపించే 46 చుక్కల స్వతంత్ర పునరావృత్తి

## Previous gate (2026-10-31)
Stage10 [Actions 41193463674](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41193463674) completed/success, 11/11 jobs at be8f4dff83f2acb4a2fc73436f2e1ec1f0477eec. GNAT13 compile/bind/link and STAGE10_DISCOVERY07_ASSERTIONS= 326 observed in job 124514787378. This accepts only the previous bounded counts, 46×5 stones and 8×7 hidden-drop recurrences; Stage11 has a separate native gate.

## I/O and independent reference
Inputs are eight literal pairs of calculation and target day: equal, +1, -1, Tablets equal, short positive step, reversed 400-day step, distant forward/reverse and far negative/positive. For each pair use the Stage10-validated Work_Counts, Stone_Table and Hidden_Drops as input values. The output is the full array of 46 Visible_Drops, compared individually against the production Build_Visible_Drops. The test-only oracle does NOT call production Build_Visible_Drops, Prior_Value, Visible_Grinds, Save or Square to compute expected values.

The oracle keeps a seven-cell FIFO queue ordered oldest-to-newest, seeded with Hidden(7),...,Hidden(1). For each visible index, read lagged entries at offsets 1, 3 and 7 (queue positions 7, 5 and 1); construct the initial weighted sum modulo M in 1-based residue space; execute eleven separately declared coefficient-vector grinds with an independent five-way stone cycle; append the new value and evict the oldest queue element. This is a different dependency/indexing implementation from production's negative-slot lookup, so the first seven positions and transition to previous visible values are exercised. No cross-language code or fixture used.

Reference reduction: R(x) = 1 + ((x - 1) mod (2^127 - 1)). All values must remain in [1,M]. Each mismatch prints the pair number, visible slot, expected and observed decimal Big_Integer; out-of-range values fail too. **Exactly 8×46=368 comparisons** (with bounds validated inside every comparison), marker STAGE11_DISCOVERY08_ASSERTIONS= 368.

## Acceptance / limits
Ubuntu 24.04 / GNAT 13, 15-minute bounded job native-stage11-discovery08 running sh ./run_stage11_discovery08.sh. Require verify and native-stage11-discovery08 completed/success for the same commit, compile/bind/link and actual marker 368 in the job log before PASS. Queued/in_progress is neither PASS nor a blocker. This does not independently verify upstream Stage10 semantics, a complete Sauce result, Calendar_Date, or the five final calendar components. No production code changes, main merge or external publication. An actual mismatch must be reproduced and recorded before opening a PATCH.

## Native acceptance (2026-10-31)
[Actions 41196519882](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41196519882) completed/success on 5db0a575044254df2c3a63a50e904fe3320a8e32, 12/12 jobs including verify and [native job 124523671270](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41196519882/job/124523671270). GNAT 13 compile/bind/link and STAGE11_DISCOVERY08_ASSERTIONS= 368 observed. Scope strictly bounded as above.
