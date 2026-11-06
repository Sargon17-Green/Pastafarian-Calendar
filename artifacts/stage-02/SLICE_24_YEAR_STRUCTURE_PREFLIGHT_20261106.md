# SQL+தமிழ் — Slice24 targeted structure/input feasibility preflight (2026-11-06)

**PROJECT_ID:** PC-BRANCH-SQL-TAMIL. **Scope:** branch SQL+தமிழ் only. **Source HEAD verified before commit:** `3d99a2d4d1c15ed00ae9e2279945f08e52064e12`. **Status:** PRELIMINARY STATIC + LOCAL PYTHON PASS; PostgreSQL 17 source-locked input preflight NOT YET ACCEPTED.

## Source inspection (current source SHA)
- Exact source: `sql/test/10_normative_reference.sql` blob `ce17bf6fd166451b6904411c5e29d1b26d92e278` lines 1496–1522. Eight fields: `year_data, cutlet_count, cutlet_partition, cutlet_name_indices, month_count, month_lengths, month_weaving, month_name_indices`.
- Production `year_rec` exists, five numeric fields in the normative order: `sql/16_stage02_year5000.sql` blob `e09afd9bb99a2a576a5bd5808b350d161072e124`. Production `year_structure` type was **not found** in targeted production files 00,03,10,14,16–25, and the current production sequence terminates at 25. This is a missing Slice24 implementation, not evidence of a regression.
- Seven accepted production selectors are declared in files 19–25: `choose_cutlet_count(sauce_result,year_rec)`, `choose_cutlet_partition(numeric,sauce_result,year_rec,integer)`, `choose_cutlet_names(sauce_result,integer)`, `choose_month_count(sauce_result,year_rec)`, `choose_month_lengths(sauce_result,year_rec,integer)`, `choose_month_weaving(sauce_result,integer[])`, `choose_month_names(sauce_result,integer)`. Exact live PG signatures still require CI verification.
- Production `sauce(numeric,numeric)` declared STABLE STRICT in file 10. Normative `build_year_structure` is VOLATILE STRICT; implementation must preserve that contract. The sauce uses `p_calculation_day` and `p_year.open_gate_day + 1`.
- Source domain: year gate span at least 6, day span 252–5778; cutlet count 6–min(17,gate span); cutlet names 1–17; month count ceil(day span/123)–min(47,floor(day span/4)); month lengths each 4–123; month names 1–47. `cutlet_partition` is affected by exact gate boundary and the calculation day.

## Local, executable independent structural oracle
`sql/test/140_stage02_year_structure_preflight.py --self-test` executed with Python 3.13.5:
- 8 complete synthetic eight-field records PASS; day spans 252,294,480,738,1353,2460,4491,5778 and month counts 3,3,5,7,12,20,37,47.
- 64 deliberately invalid record mutations correctly rejected.
- 134 exhaustive small-domain composition cases PASS.
- Full-record deterministic SHA256 generated for each case. No normative SQL fixtures copied. Synthetic year records are **not** claimed reachable, or suitable as actual PostgreSQL differential golden outputs.

## PostgreSQL feasibility requested (CI)
`sql/test/141_stage02_year_structure_input_preflight.sql`:
1. Check five-field `year_rec` order and all 7 selector signatures in PG catalog.
2. Call existing `year5000(foundation_day())` for an actual reachable baseline; derive 4 next years and 3 previous years with the already accepted navigation functions.
3. Add two distinct boundary-day input pairs. Require 10/10 source-generated valid input records, including 8 navigation cases and 2 boundary days.
4. Emit all actual `calculation_day`, `year_rec` fields, durations, gate counts, admissible month count bounds, and largest reachable duration for subsequent stress-selection and 8 independent complete-field fixtures.

Workflow `.github/workflows/sql-tamil-stage02-year-structure-preflight.yml` runs the independent Python, exact SHA checkout and ordered production sql/00..25 in PostgreSQL 17; 15-minute hard cap; one original artifact ZIP with original logs/version/source SHA256. No normative schema is loaded in this preflight job. No claim about a PostgreSQL pass until the completed job, source SHA, logs and artifact are verified.

## NEXT
Read the automatic push run for the preflight commit. Verify original PG17 logs, 10 actual reachable inputs, catalog signatures, original ZIP SHA256/CRC. If it fails, diagnose from actual logs and repair branch-only. Once feasible, construct independently sourced *actual* full-record goldens for >=8 reachable input pairs; add production `year_structure` in ordered file 26, `build_year_structure` with seven selectors and VOLATILE STRICT semantics; test >=25 Native, >=8 isolation, >=8 full-field differential, exact SHA CI/artifacts. No main/merge/publish and **no Slice24 acceptance yet**.
