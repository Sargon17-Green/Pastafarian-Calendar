# SQL+தமிழ் — Slice25 PostgreSQL selector performance triage

**Project:** PC-BRANCH-SQL-TAMIL  
**Branch:** SQL+தமிழ் (branch-only, no main/merge/publication)  
**Date:** 2026-11-20  
**Failed run:** https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44613358925  
**Exact tested source SHA:** `1cb9d9d7d0cd7587ef20b820d4155920680ee998`  
**New status:** Slice25 full preflight and production **NOT ACCEPTED**.

## Completed original log inspection

The natural push workflow reached a terminal state. Its eight distinct PG17.12 jobs were **2 completed/failure** (`anchor`, `prev_2`) and **6 completed/cancelled** (`next_1`, `next_2`, `next_3`, `prev_3`, `prev_3_prev`, `next_3_next`). This was not a successful run. Eight original job logs were inspected.

All eight jobs reported `slice25_selftest_cutlet_days=9411 PASS` and `slice25_selftest_month_positions=22890 PASS` in Python. Each original job upload log published a SHA-256 matching its GitHub artifact metadata (8/8). **Original ZIP archive bytes and CRCs were not independently downloaded/checked; no artifact-integrity acceptance claim follows from the metadata agreement.**

The prior PL/pgSQL composite INTO error did not recur in the two failed jobs. Their actual blocking error was PostgreSQL `canceling statement due to statement timeout`, `psql` exit code 3, at `preflight.sql:199`, inside the `find_target_year` call chain.

| Failed year case | build_year_structure | First completed find_target_year probe | End |
| --- | --- | --- | --- |
| anchor | 00:00:31.373393 | anchor_cutlet_boundary: 00:06:42.749527 | second probe exceeded 12-minute SQL statement budget |
| prev_2 | 00:00:18.939415 | prev_2_first: 00:09:18.873539 | second probe exceeded 12-minute SQL statement budget |

The six cancelled jobs each completed the Python self-tests and reached the year-structure build, but did not finish `find_target_year` before cancellation. Their logs cannot establish PostgreSQL structural preflight acceptance.

## Scope-limited QA repair

The original preflight called the expensive target-year selector for each of 29 year-day cases, while the structural oracle requires only authoritative reachable year records, valid in-year target bounds, distinct targets and an independent ordinal evaluation. This repeated selector work prevented even generating the structural fixtures.

The **QA-only** change removes the repeated selector loop from `sql/test/146_stage25_calendar_date_preflight.sql`. The SQL still constructs eight distinct accepted/adjacent year records, selects first/middle/last days plus cutlet and month-occurrence boundaries (29 total expected), checks target membership and uniqueness, and emits full year records, cases and 64 canonical Tamil name-catalog entries. Existing separate Python script `150_stage25_calendar_date_oracle.py` is unchanged and remains the independent ordinal oracle. A visible `slice25_selector_deferred` NOTICE records the scope restriction. The success marker and workflow guard are renamed to `SLICE25_STRUCTURAL_PREFLIGHT_GREEN=1` to **prevent mistaking this structural-only pass for selector/production acceptance**.

The only files changed on this new commit are the scoped SQL fixture, its own GitHub workflow and this evidence report. The earlier `find_target_year` production source and normative reference are untouched. No preflight or PostgreSQL PASS is asserted for the new code until completed results and original artifact bytes are independently verified.

## Local precommit static checks

The old selector loop was found exactly once, `v_found` and `r` unused declarations removed, all three source `__YEAR_CASE__` substitutions remain, no executable `pastafari_sql_tamil.find_target_year(` call remains in this structural-only preflight, source and workflow flags match, 29-case construction/count validation and independent Python oracle invocation remain intact, PostgreSQL 17 job budget remains 15 minutes, and the prior all-green marker is absent. These are static checks, **not native tests**.

## NEXT / gates still open

1. Let the automatic push run (if created) finish; inspect eight original logs and ZIPs. Verify 8 distinct year records and exactly 29 actual reachable day cases against the independent Python oracle, with SHA256/CRC/source locks. Structural fixtures are not accepted until this evidence exists.
2. Diagnose and optimize the **production** `find_target_year` path on exact source SHA. The verified 6m43s and 9m19s single-probe runtimes make full 24-case Native/differential coverage infeasible without an algorithmic performance change. Create separately bounded performance experiments and verify semantic equivalence before a production patch. Never classify the absent selector verification as GREEN.
3. Only after both structural oracle and selector performance are evidenced, implement the distinct Tamil-text `calendar_result_text`/`calendar_date` interface and its ≥40 Native, ≥8 isolation, ≥24 differential gates per the locked Slice25 contract.

No new staged results or acceptance claims are made by this report.
