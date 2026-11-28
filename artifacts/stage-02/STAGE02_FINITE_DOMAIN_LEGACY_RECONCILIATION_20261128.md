# Stage02 finite absolute-domain and legacy-entrypoint reconciliation — 2026-11-28

PROJECT_ID: PC-BRANCH-SQL-TAMIL  
Branch: `SQL+தமிழ்`  
Evidence source SHA: `6041b88515da06d956767061504722b0093d06d3`  
Parent of evidence SHA: `6a6ef610c46ed774b84a10d7853a76f8999988dd`

This is a documentation-only reconciliation. It does not change production SQL, the normative oracle, stage policy, or the legacy entrypoint.

## 1. Exact source change and nonfinite regression

The evidence SHA changes exactly two files:

- `sql/16_stage02_year5000.sql`: the materialized `base` CTE now explicitly rejects `NaN`, `Infinity`, and `-Infinity` before either recursive gate walk, then retains the integral-value check. The finite integral domain is unchanged.
- `.github/workflows/sql-tamil-stage02-nonfinite-input-audit.yml`: the source lock is updated to the new Git blob and the regression rationale is recorded.

The natural-push Native diagnostic completed successfully:

- Run [46147244115](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46147244115), job `140985895108`, exact branch and SHA.
- 24/24 invalid cases returned the intended rejection with exit code 0 and a committed read-only transaction: eight cases each for NaN, +Infinity, and -Infinity.
- Coverage per special value: `year5000_gate_window`, `year5000`, and `find_target_year` / `calendar_date` with calculation input, target input, and both inputs.
- Production load exit: 0. Test schema absent (`ISOLATION=0`). The workflow checked all 28 locked production Git blobs using `git hash-object`.
- Artifact `15263747830`; raw ZIP SHA-256 `cbb9bd21e07ef2f52e0257ba8b346ee75618561e5eeac8cd8967d27730939417`; ZIP CRC 57/57 and internal SHA manifest 56/56.

## 2. Same-SHA automatic regression evidence

All listed jobs completed with conclusion `success` on `SQL+தமிழ்` at the exact evidence SHA. Their logs identify that SHA and branch; artifact IDs and upload digests match GitHub metadata.

| Scope | Run | Jobs | Native / isolation / differential or smoke evidence |
|---|---:|---:|---|
| Slice14 year5000 | [46147244147](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46147244147) | 6 | 23 + 4 + 25 = 52 |
| Slice15 adjacent year | [46147244164](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46147244164) | 6 | 36 + 4 + 4 = 44 |
| Slice16 target year | [46147244252](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46147244252) | 7 | 18 + 4 + 5 = 27 |
| Slice17 cutlet count | [46147244163](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46147244163) | 6 | 20 + 4 + 4 = 28 |
| Slice18 cutlet partition | [46147244148](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46147244148) | 14 | 53 + 4 + 8 = 65 |
| Slice19 cutlet names | [46147244156](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46147244156) | 10 | 42 + 4 + 8 = 54 |
| Slice20 month count | [46147244192](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46147244192) | 10 | 36 + 4 + 8 = 48 |
| Slice21 month lengths | [46147244230](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46147244230) | 10 | 43 + 5 + 8 = 56 |
| Slice25 current-source smoke only | [46147244232](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46147244232) | 1 | 5 result-field checks + 5 invalid-input checks = 10 |
| Stage01 current-source regression | [46147244227](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/46147244227) | 1 | 52 ordinary + 7 saved-sum + 3 heavy-reference + 4 isolation = 66 |

Across these runs and the nonfinite diagnostic: 72 completed jobs and 72 original ZIP artifacts were examined. All 72 raw ZIP SHA-256 values match GitHub artifact digests; all 72 ZIP CRC checks pass; all 72 version records identify the exact evidence SHA. The 58 case/golden payload-manifest checks in the slice artifacts pass, as do the nonfinite artifact's 56 internal manifest entries. No failure rows or failed table flags were found in the examined artifacts.

The Slice25 run is only a smoke test: its log reports approximately 32.36 seconds for the smoke SQL. It is not the full Slice25 gate and does not replace the contract's independent oracle, multi-year reachability, full Native, isolation, and differential requirements. Stage01's 66/66 is a same-SHA regression, not Stage02 acceptance.

## 3. Finite absolute distance: what is and is not bounded

The new guard closes the observed nonfinite-input failure mode. It does not bound large finite integral inputs.

- `foundation_day()` is `-15055671`.
- `year5000_gate_window(p_calculation_day)` forms the finite output interval `p_calculation_day ± 5778`; the returned gate array is constrained to 15..280 entries.
- The current implementation starts two recursive walks at gate index zero / the foundation and advances using `positive_gate_gap` or `negative_gate_gap` until the relevant bound is crossed. Each gap is sauce-derived. The number of recursive gap evaluations therefore grows with the absolute distance from the foundation; the 15..280 output-array bound is not a bound on the work used to find that array.
- Slice12's `gate_index_at_or_before` is explicitly exhaustive/unbounded; `gate_day` sums gaps with `generate_series` up to the requested index. Slice14's output-window bound must not be described as a total traversal bound.
- Slice14's contract describes finding the lower sentinel and then making one forward walk. The current implementation instead uses two directional walks from the foundation. This is a contract/implementation description mismatch; no wrong finite output has been demonstrated by it.
- Slice16 accepts integral inputs only when `abs(target-calculation) <= 60000`, and its adjacent-year budget is at most 240 moves. The 33,360-gate-position calculation covers at most 240 adjacent transitions at 139 gates each, but omits the initial `year5000(calculation_day)` seed cost. That seed inherits Slice14's unbounded absolute-distance walk. The 60,000-day limit is relative between the two inputs, not an absolute limit from the foundation.
- Existing exact tests 108/109 cover the foundation and its ±5778 window, NULL and fractions, and five nearby differential days. Tests 112/113 cover NULL, fractions, relative ±60001 rejection, budget arithmetic, and five near-foundation differential cases. They do not establish a large finite absolute-domain performance bound.
- The new 24-case diagnostic covers nonfinite rejection only. No large finite probe was run, no timeout was induced, and no absolute cap was introduced.

The current evidence proves the nonfinite guard and bounded local test scopes. It does not prove a uniform runtime bound for all finite integral NUMERIC values.

## 4. Legacy entrypoint and global Stage02 governance

The two production entrypoints remain distinct:

- `sql/02_monster_bootstrap.sql` defines `calendar_date_spaghetti(...)` as a `SETOF calendar_result` function whose query is `SELECT NULL::calendar_result WHERE false`; it returns no rows.
- `sql/27_stage02_calendar_date.sql` defines a separate `calendar_result_text` type and `calendar_date(numeric,numeric)` returning five typed fields. It does not replace the legacy `calendar_result` type or implement `calendar_date_spaghetti`.
- The Slice25 contract requires a distinct text-result API and explicitly says not to overwrite the legacy index-result type. It is still labelled design-only and requires substantially more than the current 10-check smoke.
- `DEVELOPMENT_STAGE.md` still says `CURRENT_STAGE=1` and `LAST_COMPLETED_STAGE=1`. No authoritative global Stage02 acceptance/governance contract was established by this targeted review. The legacy stub is a source fact, not by itself proof that a required test failed.

Accordingly, Stage02 remains NOT ACCEPTED. Neither the smoke test nor the successful Slice14–21 gates imply whole-stage acceptance. No Stage03, main, merge, release, or legacy-entrypoint change is authorized by this report.

## 5. Decisions required before the next implementation step

1. **Absolute finite domain:** either retain all finite integral NUMERIC values and authorize a redesign/resource contract that can support that domain, or explicitly authorize an absolute distance/range limit from the foundation and define the out-of-range result and runtime ceiling. No limit is assumed here.
2. **Legacy/global interface:** clarify whether Stage02 completion requires `calendar_date_spaghetti` to become functional, or whether the distinct five-field text `calendar_date` API is the intended authoritative interface while the legacy stub remains.

Until those decisions are resolved: keep the nonfinite guard, make no production or legacy-entrypoint edits, do not run large finite probes, and do not promote Stage02 or start Stage03.
