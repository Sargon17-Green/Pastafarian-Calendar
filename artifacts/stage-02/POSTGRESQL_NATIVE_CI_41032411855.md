# SQL+தமிழ் — Stage 2 Core Native PostgreSQL evidence (2026-10-30)

## Scope and provenance

- Workflow: `.github/workflows/sql-tamil-stage02-core-native.yml`
- Run: [41032411855](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41032411855)
- Trigger: `push`; branch `SQL+தமிழ்`; event source commit `8dbe132b175a5d464ee64612d550a11d23177404`.
- Checkout in the native job log: `8dbe132b175a5d464ee64612d550a11d23177404`.
- Job: `123985046839`, `PostgreSQL 17 — Stage 2 production core and isolation`; conclusion `success`.
- PostgreSQL and psql versions printed by job: **17.11**.
- Evidence artifact: [12967040391](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41032411855/artifacts/12967040391), name `sql-tamil-stage02-core-native-41032411855`, size **1012 bytes**, 3 log files, retention 90 days.
- Artifact SHA-256 **as reported by GitHub Actions upload and the GitHub API**: `95bb516f109228a75ae656de2b1ad647f904879c4f2d59132ef2bb463f75293d`. This record does not claim an independent local checksum recomputation.

## Exact Native verification

Production-only database, without loading the test reference `sql/test/10_normative_reference.sql`:

1. `sql/00_schema.sql`
2. `sql/01_source_language_catalog.sql`
3. `sql/02_monster_bootstrap.sql`
4. `sql/03_stage02_production_core.sql`
5. `sql/test/50_stage02_production_core_tests.sql`
6. `sql/test/40_production_isolation.sql`

The job log explicitly contains `INSERT 0 37`, assertion count `37`, and `production_core_37_of_37 = 1`, with `ON_ERROR_STOP=1` and `set -euo pipefail`.

The same log contains four isolation assertion inserts and `production_isolation_4_of_4 = 1`. All required workflow steps, including artifact upload, completed successfully. **Stage 2 production core Native: 37/37 PASS. Production-reference isolation: 4/4 PASS. Total verified in this run: 41/41.**

## Claims deliberately excluded

- This proves only the first production computation slice (exact integer division/modulus, SAVE, day counts and work counts) and isolation, **not** the full five-component Pastafarian calendar.
- `calendar_date_spaghetti` still returns zero rows. No Stage 2 full implementation PASS, differential PASS, complete calendar PASS, or overall project completion is claimed.
- Stage 1's 66/66 Native evidence belongs to a separate workflow/run and is not counted in this 41/41.

## Next bounded engineering task

Advance the next independently implemented production computation from the canonical contract after `work_counts`; define isolated production tests and a bounded Native workflow before claiming a further PASS. Do not merge to `main`; keep normative reference isolated and preserve the exact integer approach.
