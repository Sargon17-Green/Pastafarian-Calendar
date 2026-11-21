# SQL+தமிழ் — Slice25 matrix timeout triage and isolated DP streaming candidate

**Project:** `PC-BRANCH-SQL-TAMIL`  
**Source ref:** branch `SQL+தமிழ்`, verified HEAD `62c07e286b537cd3969bc35399b1f160250dafb0` at investigation; no main/merge/release.  
**Original exact-source run:** https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44896020377  
**PG version in original logs:** PostgreSQL 17.12.  
**Record date:** 2026-11-21.

## Verified failure evidence (NOT full Slice25 acceptance)

API `actions/runs/44896020377/jobs?per_page=100` returned **all 56 jobs** in one response. Observed 36 `completed/success`, 2 `completed/failure`, 4 `in_progress`, and 14 `queued` at investigation snapshot. No uncompleted job was counted as PASS. The workflow-run endpoint lagged behind individual job states; use per-job evidence, not its `queued` summary, until it settles.

1. `native:prev_3_prev_middle`, job `136821729378`, `completed/failure`, generated `test.sql:38`: PostgreSQL `statement_timeout` at **12 minutes**, stack `calendar_date → build_year_structure → choose_month_weaving → month_weaving_ranked`, inside the last PL/pgSQL function's IF. Exact original SHA was fetched by checkout; generator 87/87, static 56/56 and corpus 29/29 passed **before** PostgreSQL timeout. No five-field green assertions were emitted for this job. Original uploaded artifact ID `14706721044`; upload job log SHA256 `1a230d95330f66b0e89005bf91cddae8c15c7c9cf78e711ddc3a2179543e7d3a` (original ZIP bytes/CRC not independently verified at this point).
2. `differential:prev_3_prev_last`, job `136821730236`, `completed/failure`, `test.sql:63`: PostgreSQL `statement_timeout` at **12 minutes**, context `SQL function floor_div during startup`. This is **not proof** that `floor_div` itself is the dominant cost: differential evaluates production **and** the normative reference within one `DO` statement, consuming the same 12-minute statement budget. Generator 87/87, static 56/56 and corpus 29/29 passed. Upload job log SHA256 `ade465a45fb1ae4fd6902ddb1d9d85a7cbd4217ddef0bb3d03c9674c660bdb43`; original ZIP bytes/CRC not independently verified.

Comparison from original completed logs: `native:prev_3_last` finished its full five-field check in 485,917.759 ms and `native:anchor_last` in 156,216.073 ms. These observations are **not** controlled same-input performance measurements and must not be interpreted as such. `prev_3_prev` corresponds to year 4996; its locked middle, first and last cases are kept unchanged.

## Testable performance hypothesis

The accepted production `sql/24_stage02_month_weaving.sql` computes each DP row using a recursive CTE that repeatedly evaluates `previous_row[t+h+1]` on a variable-width PostgreSQL `numeric[]` array. Repeated subscripting of variable-width array elements can entail traversing preceding values. This supplies a plausible **array access** cost over a large DP, but a per-phase PG profiler has **not** yet isolated the true dominant operation. No claim of proven speedup is made.

The candidate changes **only the isolated test-session copy of this DP block**: it generates the same exact binomial coefficient `C(t+h-2,h-2)` via the same integer recurrence, enumerates `previous_row` once with `unnest ... WITH ORDINALITY`, joins on `ordinal=t+h`, and obtains ordered prefix sums using `sum(numeric) OVER (ORDER BY t ROWS UNBOUNDED PRECEDING)`. It preserves the full original function signature, unranking logic, other SQL, and the independent goldens.

## Math and safety contract

For `h ≥ 2` and `0 ≤ t ≤ T`, the old DP row is

`F_new(t) = Σ_{x=0}^t F_previous(x+h-1) × C(x+h-2,h-2)`

with 1-based array indices. The candidate gives the same summand through the ordinality equality `ordinal=x+h`. PostgreSQL `numeric` remains exact; no floating-point division or approximate comparison is introduced. All unranking, cutlet/month naming, and accepted production files remain untouched.

A standalone Python test in `sql/test/166_stage25_month_weaving_dp_stream_candidate.py` checked **840/840** length vectors (340 exhaustive short vectors + 500 seeded vectors) against a separate `math.comb` summation oracle. A single-substring source lock and reverse-transform equality also passed. This is **local arithmetic/static evidence only**, not PostgreSQL Native or runtime performance evidence.

## Actual next gate

A **two-job** PostgreSQL 17 diagnostic in `.github/workflows/sql-tamil-stage02-slice25-dp-stream-candidate.yml` checks:

- `native:prev_3_prev_middle` — five fields against locked goldens, `statement_timeout=12min`, 15-minute job bound.
- `differential:prev_3_prev_last` — five fields against locked goldens **and** five typed fields against independent normative SQL, same bounds.

Each job verifies exact Git SHA/ref, locks the original production `sql/24` blob SHA `a48f611d205763ee5dc7c21da7ddf1c9cfa20e8c`, produces an isolated candidate *without modifying source*, preserves SQL/logs/hashes/version/artifact even on failure, and runs PG offline. No full 56-job re-dispatch; this workflow reacts only to its own diagnostic QA files.

**Gate policy:** Even if both diagnostic jobs pass, this establishes only two isolated candidate checks. It does not accept the full Slice25 56-job matrix, does not justify merging, and does not establish production speedup until matched-source measurements and the complete required regression gates succeed. Do not alter the accepted Slice22 source before candidate measurements and semantic regression evidence. Original 56-job run remains independent and should continue without duplicate dispatch.
