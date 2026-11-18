# SQL+தமிழ் — Stage2 Slice25: calendar_date integration contract
**Status:** CONTRACT / DESIGN ONLY (no implementation or Slice25 Native PASS).  
**Date:** 2026-11-18. **PROJECT_ID:** PC-BRANCH-SQL-TAMIL. Branch-only `SQL+தமிழ்`; no main/merge/external publication.  
**Prerequisite:** Slice24 ACCEPTED on `4c71d677eb382eea55eeae2d3ac8da99760d2bd5`, run 44364076198 completed/success, 16/16 original ZIPs verified. Report: `artifacts/stage-02/POSTGRESQL_NATIVE_YEAR_STRUCTURE_44364076198.md`.

## Verified normative interface and typed output
The normative `sql/test/10_normative_reference.sql` blob is `ce17bf6fd166451b6904411c5e29d1b26d92e278`. Its final function is `pastafari_sql_tamil_test.calendar_date(p_calculation_day numeric,p_target_day numeric) RETURNS calendar_result_text`, `VOLATILE STRICT`. `calendar_result_text` fields in order: `year_number numeric`, `cutlet_name text`, `day_in_cutlet numeric`, `month_name text`, `day_in_month numeric`. The existing **production** `calendar_result` type in `sql/00_schema.sql` is **different** (integer cutlet/month indices); never confuse or overwrite the two. Target a new production `calendar_result_text` type if no compatible type exists on live HEAD, and implement a distinct production `calendar_date(numeric,numeric)` with equivalent five-field text result. Re-check HEAD/schema/type/signatures immediately before the source commit.

Dependencies: accepted `find_target_year`, `build_year_structure`, `gate_day`, `source_name('CUTLET',index)`, `source_name('MONTH',index)`. The production `source_name` maps canonical indices to existing Tamil names in `sql/01_source_language_catalog.sql`; do not rewrite text, indices or source catalog.

## Deterministic semantics to implement independently
For a reachable target day in the selected year, traverse the year structure's cutlet gap partition in order. Let `p_i` be partition entries, `P_0=0`, `P_i=sum(p_1..p_i)`. Cutlet `i` is selected iff
```
gate_day(open_gate_index+P_(i-1))+1 <= target_day <= gate_day(open_gate_index+P_i)
```
Set `first_day=gate_day(open_gate_index+P_(i-1))+1`, `day_in_cutlet=target_day-first_day+1`. Let `offset0=target_day-(open_gate_day+1)`, `month_id=month_weaving[offset0+1]`, and `day_in_month` be the number of occurrences of `month_id` in the weaving prefix through `offset0+1`. Resolve the Tamil names through `source_name` with `cutlet_name_indices[i]` and `month_name_indices[month_id]`. Return the five typed fields. Preserve reference's STRICT null behavior and VOLATILE volatility until independently verified otherwise. Do not import the normative SQL body, stateful weave caches, or fixtures.

## Targeted preflight before implementation (required)
1. Read exact live branch HEAD and confirm Slice24 report, source lock, production and normative signatures. Inspect `sql/00_schema.sql`, `sql/01_source_language_catalog.sql`, the accepted year search, gate-day and year-structure files only. Measure potential `find_target_year` and `build_year_structure` latency on PostgreSQL 17; no unbounded random or giant range.
2. Construct **at least 24 reachable day cases across ≥8 distinct year inputs** from the eight accepted Slice24 fixtures, including first and last day of a year, interior days, cutlet boundary ±1, month first occurrence and month repeated occurrence where feasible. Discard a case if boundary construction proves it unreachable rather than guessing a number. Source-lock the selected `calculation_day,target_day` pairs and show how each was obtained.
3. Write an **independent Python ordinal oracle**: from pre-recorded eight-field year structure and independently constructed partition prefix gates, find cutlet ordinal, weaving prefix occurrence count and Tamil text from a read-only canonical source map. Must not invoke `calendar_date`, use normative SQL as a fixture generator, or copy the SQL implementation. Include exhaustive small synthetic sequences to check cutlet interval uniqueness and month occurrence logic; enumerate exact counts and negative/boundary tests.
4. Preflight expected performance with a per-case timeout; shard heavy cases so each PostgreSQL 17 job has `timeout-minutes: 15`. Derive expected year and month spans from actual accepted data, not estimates.

## Slice25 acceptance gates
- **Native PG17:** ≥40 named assertions, ≥24 reachable inputs from ≥8 years, five exact result fields per case, Tamil catalog integrity/valid indices, day-index positivity/range, repeatability, production type/signature, STRICT/null semantics. Every named flag `ok=t`, explicit `all_green=1`, no partial PASS.
- **Independent oracle:** ≥24 exact five-field expected outputs, small synthetic exhaustive tests, and independently reproduced first/last cutlet and month ordinal boundary checks. Record provenance and exact counts.
- **Isolation:** ≥8 named production-only assertions across fresh PostgreSQL databases with zero `pastafari_sql_tamil_test` schema dependency; no test reference/function called in production path.
- **Differential:** ≥24 complete typed five-field comparisons with normative `calendar_date` across distinct reachable inputs and boundaries; compare text and numerics with `IS NOT DISTINCT FROM` and per-field flags, never hashes alone.
- **CI/source evidence:** workflow natural push on exact SHA and branch, PostgreSQL 17 version, `git rev-parse HEAD == GITHUB_SHA`, `psql -At -X -v ON_ERROR_STOP=1`, each job capped at 15 minutes; preserve `test.sql`, original results, oracle transcript, source SHA256 and generated SQL SHA256, versions and original GitHub ZIP per job. Compare ZIP raw SHA256 with both GitHub digest and upload logs, verify CRC and provenance.
- **Acceptance:** only completed/success jobs and independently examined original logs and artifact bytes. On evidenced failure, repair branch-local root cause, never duplicate manual CI while a natural push run is active.

## NEXT
Perform **Slice25 exact type/signature, reachable-day and performance discovery** on current `SQL+தமிழ்` HEAD; then implement only after the bounded independent oracle/preflight and immutable fixture contract are established. No explicit user approval needed for these engineering choices. This contract is not evidence of a Slice25 implementation or pass.
