# SQL+தமிழ் — Slice25 linear prefix-gate preflight correction
**PROJECT_ID:** PC-BRANCH-SQL-TAMIL  
**Date:** 2026-11-20  
**Parent HEAD:** `10e757d55bb8c7006cc24268e35ffe5f32982317`  
**Run under analysis:** https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44633897681

## Observed original PG17.12 outcome
On the exact parent source the eight-job natural push is terminal: **2 successful** (`anchor` with 6 Python ordinal cases; `next_1` with 5), **1 failed** (`prev_3`) and **5 cancelled**. All eight original job logs were inspected. Every job completed the 9411 cutlet/day and 22890 month-position Python self-tests; all eight uploaded artifact digests match GitHub metadata. The original ZIP bytes/CRC **have not been independently checked**, and the structural eight-year gate is **NOT ACCEPTED**.

The failed `prev_3` job built a year structure in 44.052459 s, and then `preflight.sql:223` exceeded its 12-minute statement_timeout during cutlet-prefix JSON generation. `next_2` likewise hit statement timeout in the same location before its cancellation. `anchor` and `next_1` did finish ordinal oracle generation, but those successes cannot establish the eight-year acceptance gate.

## Root cause and scoped repair
The source-locked `gate_day(i)` definition sums **every gap from index zero** to `i`. The old preflight emitted each cutlet boundary by independently invoking this function for each prefix, redundantly re-evaluating many common gaps. This is a QA extraction performance problem, **not evidence that the normative date values differ**.

The only SQL change is to `sql/test/146_stage25_calendar_date_preflight.sql` in the `cutlet_prefix_gates` JSON expression. It computes each gap from `open_gate_index+1` to `close_gate_index` once in a MATERIALIZED CTE, then takes cumulative sums and selects the exact cutlet prefix indices. The identity is:
- if `i>0`, `gate_day(i)-gate_day(i-1)=positive_gate_gap(i)`;
- if `i<=0`, `gate_day(i)-gate_day(i-1)=negative_gate_gap(1-i)`;
- at offset zero the gate day is copied from the accepted source year record.

This handles years wholly below or above zero, and crossings through zero. It does not change any production SQL, normative reference, Tamil catalogs, independent Python oracle, CI matrix, selected 29 test targets, run-time budget or acceptance marker. The expensive `anchor` boundary selection still invokes the original `gate_day`, so a successful preflight checks one selected internal boundary independently; the Python oracle also checks both year endpoints and monotonically increasing gaps.

## Precommit synthetic identity and static checks
- Independently recomputed direct foundation sums and one-pass incremental sums for **18480** index, width, and offset combinations: all equal, including crossings through zero (synthetic arithmetic, **NOT PostgreSQL Native**).
- Exactly three `__YEAR_CASE__` substitutions; exactly one structural success marker; exactly one changed JSON cutlet-prefix block; no production files modified.
- PostgreSQL 17 Native acceptance **NOT YET EVIDENCED** for this change.

## NEXT
Check the natural push run on the new exact commit, then inspect all eight *original* PG17.12 job logs and ZIP archive bytes including GitHub/upload/raw SHA256, CRC, eight distinct year structures, 29 source-locked cases and independently generated Tamil five-field outputs. If the linear cumulative scan still exceeds 15 minutes, repair the demonstrated hot path in a separately bounded experiment. Production `find_target_year` remains a separate expensive selector and requires its own proven optimization/equivalence tests before the `calendar_date` production implementation and Native ≥40 / isolation ≥8 / differential ≥24 gates. No main/merge/publication.
