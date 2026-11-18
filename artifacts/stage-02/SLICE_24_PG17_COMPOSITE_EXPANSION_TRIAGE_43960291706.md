# Slice24 PostgreSQL 17 — composite year_rec row-target repair
Project: PC-BRANCH-SQL-TAMIL | Branch: SQL+தமிழ்

## Source lock and observed result

- Parent commit / live branch HEAD before patch: `597629b6f29dbb4c7c5db5560e9e98dd91f3dc41`.
- Original natural push workflow run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43960291706
- Run source SHA and branch were checked against original artifact metadata and checkout logs.
- **16/16 jobs completed/failure**: 8 native, 8 differential; each failed before assertions with exit code 3.
- All 16 original job logs were inspected (not inferred from the summary).
- Native SQL generated `test.sql:62` / inline DO statement line 10; differential `test.sql:28` / inline DO statement line 8.
- Error in each case: `invalid input syntax for type numeric: "(<five year_rec fields>)"`. Examples:
  - anchor: `(5000,-4,4,-15057703,-15053459)`
  - prev_2: `(4998,-19,-12,-15064992,-15061829)`.
- One error pattern in all 16 logs, not a demonstrated production-selector defect. No results from the 29 native assertions, 9 differential comparisons, or Python oracle can be accepted for this failed run.

## Inspected job IDs
Native: `133625556293`, `133625556756`, `133625556761`, `133625556870`, `133625556909`, `133625556944`, `133625556994`, `133625557026`.
Differential: `133625556838`, `133625556901`, `133625556918`, `133625556920`, `133625556965`, `133625556968`, `133625557016`, `133625557288`.

## Root cause and branch-only repair

In both QA templates, `SELECT x.y INTO STRICT y` tries to store one composite-valued SQL column into the first numeric field of the PL/pgSQL composite row target. Both templates declare `y pastafari_sql_tamil.year_rec` with five fields. Change **only** that assignment to:

```sql
SELECT (x.y).* INTO STRICT y FROM slice24_cases x WHERE x.id=v_case_label;
```

The `(x.y).*` expansion produces the five columns of the composite value, while `INTO STRICT` continues to require exactly one matching input row. Keep `slice24_cases.id` primary-key uniqueness. Production SQL `sql/26_stage02_year_structure.sql`, normative reference, fixtures, workflow and oracle are unchanged.

## QA scope and acceptance status
- Static source QA: 2/2 exact one-line targeted replacements; 2/2 preserved `INTO STRICT` cardinality; 2/2 preserved file line counts.
- Existing fixture labels (not independently reexecuted here): anchor, boundary_open, boundary_close, next_1, next_2, next_3, prev_2, prev_3.
- Git objects and branch HEAD to be read back after pushing the atomic commit.
- PostgreSQL Native execution on this repaired commit **NOT YET PROVEN** at report authoring time; natural push CI and downloaded original artifacts must be verified.
- The 16 original artifact metadata entries have digests and matching head SHA, but byte-level checksums / ZIP CRC and generated test-file SHA verification for this failed run have **not** been performed by this repair. Do not count it as PASS.
- NEXT: inspect completed natural-push run on the new commit; verify all 16 job logs and original 16 ZIPs with metadata/upload/bytes/CRC; 8×29 native checks, 8 Python actual-structure checks, 8×9 differential checks and >=8 isolation checks. Repair any independently evidenced error; no manual workflow duplicate, no main/merge/publish.

Generated: 2026-11-18.