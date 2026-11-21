# SQL+தமிழ் Slice25 — exact-SHA PG17.12 year-gap artifact forensic QA

**Project:** `PC-BRANCH-SQL-TAMIL`  
**Branch:** `SQL+தமிழ்`  
**Tested source SHA:** `1313785d7d1e0f779e32f77dcb53e72afd809473`  
**Completed run:** [44947014984](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44947014984), job `136976436808` — **failure**, PG17.12.  
**Original artifact:** [14723209075](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44947014984/artifacts/14723209075), ZIP SHA-256 `a457b4c4b61ff369f4b36c8050a931d6ea200b8ca3894c04615488801b57d756`, 7,383 bytes, 11 members, CRC check 11/11 passed (no failed member). Original downloaded ZIP was inspected, not just workflow UI.

## Distinct checks and evidence

| Gate | Actual observation |
|---|---|
| Source-locked static | 6/6 Git blob locks; 8/8 independent historical boundary records; reversible aliases PASS, seen in `static.txt` and step 3 |
| Production SQL 00–27 and QA alias load | Step 5 completed SUCCESS; `load.log` |
| Signed negative gap `p_n=1` | `gap.log` shows `SQL_TAMIL_S25_GAP_EQUIVALENCE=1/1 PASS`, `DO`, one traced `sauce` 7309.053 ms, enclosing `negative_gate_gap` 7313.172 ms |
| Year navigation `(-15055671,-15072356)` | `navigation.log` contains `statement_timeout`, no `SQL_TAMIL_S25_YEAR_BOUNDARY=3/3 PASS`, no verified year record |
| Exact-SHA Stage1 | [44947014979](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44947014979) completed SUCCESS, separate gate |
| Exact-SHA names lock | [44947014989](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44947014989) completed SUCCESS, separate gate |
| Whole Slice25 / five-field / differential | **NOT ACCEPTED**; this run is diagnostic only |

## Non-overlapping timing decomposition

Parsed precisely from the *original* `navigation.log`, using `SQL_TAMIL_S25_ENTER`/`EXIT` tags:

| Trace name | ENTER | EXIT | Completed durations (ms) |
|---|---:|---:|---:|
| `year5000` | 1 | 0 | unavailable |
| `positive_gate_gap` | 11 | 11 | nested in gate windows |
| `negative_gate_gap` | 13 | 13 | nested in gate windows |
| `gate_gap_signed` | 24 | 24 | nested in gap wrappers |
| `sauce` | **25** | **24** | **175226.028 ms** |

The 24 *completed* sauce calls had median 7297.972 ms, minimum 7277.402 ms, maximum 7346.516 ms. Their accumulated duration was 175.226 s of a 180 s SQL statement budget. The 25th sauce ENTER (`-15055671`) has no EXIT; it was cancelled during `qa_year5000`, with PostgreSQL stack `floor_div -> save_value -> stone_state -> stone_value -> bowl_round -> sauce`. The counts establish substantial cumulative cost from repeated sauce calls, **not** a proven isolated defect in `floor_div`, nor a verified general asymptotic bound.

**No duration double-counting:** `gate_gap_signed`, positive/negative wrappers, and `sauce` are nested. Their totals must not be added. The diagnostic evidence isolates a repeated expensive path; it does not prove a safe replacement or output equivalence for the year.

## Evidence-quality defect in the workflow

`exits.txt` is absent from the original 11-member ZIP even though the workflow includes a `printf GAP_EXIT/NAV_EXIT` command. The GitHub job shell is invoked with `bash -e -o pipefail`; `set -uo pipefail` **does not disable `-e`**. Consequently a nonzero `psql` navigation command exited before explicit exit-code recording and before the diagnostic `tail` commands. The SQL error is still directly verified from `navigation.log`, which was uploaded via `always()`; do not infer an unrecorded `NAV_EXIT` numeric value. Future work must handle expected probe failures with `set +e` and capture both statuses before failing deliberately.

## Engineering NEXT — no identical rerun

1. Design a *new*, smaller, source-locked bounded test to isolate one representative `sauce` call and instrument `bowl_round` / `stone_value` / `stone_state` / `save_value`, with SQL timeout and immutable full logs. The nested timing attribution needs careful separation; the current PostgreSQL context is **not** a timing profile for each inner function.
2. Specify input `(calculation_day=-15055671,target_day=-15055672)` (known signed-offset -1) and compare production output exactly to a separately designed, source-independent oracle before proposing performance-related production edits. Historical boundary records are oracle only for year endpoints, not full sauce arrays; a separate sauce oracle must be defined.
3. Apply the workflow `-e` control correction when adding materially new probe coverage. Preserve both exit codes, source-lock and SHA manifest, raw notice logs, ZIP SHA256 and CRC, and negative-case behavior.
4. Do not repeat the 180 s year test unchanged; do not launch full 56-job matrix; do not edit production, merge, main, or publish. Continue with D=פתוחה, G=READY.

**Classification:** source-locked static PASS; gap Native 1/1 PASS; year Native FAIL/timeout; whole Slice25 and differential **NOT ACCEPTED**. This report is a forensic QA artifact; no additional PG execution is asserted.
