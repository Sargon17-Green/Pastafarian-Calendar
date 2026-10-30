# SQL+தமிழ் — Native PostgreSQL 17 Stage 1 evidence (run 40742033401)

Verification recorded: 2026-10-30. Execution: 2026-10-28 18:12–18:14 UTC.

## Immutable sources

- Repository: `Sargon17-Green/Pastafarian-Calendar`
- Branch tested: `SQL+தமிழ்`
- **Tested commit SHA**: `cac8fba51d2bb2a1a437187a1e58d73ec9fa512f`
- [Workflow at tested SHA](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/cac8fba51d2bb2a1a437187a1e58d73ec9fa512f/.github/workflows/sql-tamil-stage01-native.yml)
- [Actions run 40742033401](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40742033401) — completed, success
- [Job 123005883292](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40742033401/job/123005883292) — completed, success
- [Execution logs artifact 12839284885](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40742033401/artifacts/12839284885), named `sql-tamil-stage01-native-40742033401`
- Artifact archive SHA-256 verified from downloaded ZIP: `9358d51104a564c2d364a00b13e4db2526bc0cdc4082264bd32b561ce931f5f5`
- Artifact contents verified: `versions.txt` (154 bytes), `reference.txt` (3027 bytes), `isolation.txt` (731 bytes). GitHub artifact retention is 90 days; the job log and this report identify the results independently of that expiry.
- Native environment: `postgres (PostgreSQL) 17.11 (Debian 17.11-1.pgdg13+2)`; `psql` 17.11. The PostgreSQL Docker container was started with `--network none`; repository files were mounted read-only.

## Results from the native job log and downloaded artifact

| SQL suite | Native evidence | Result |
| --- | --- | --- |
| `sql/test/20_stage01_tests.sql` (reference DB) | `assertion_count = 52`; `ordinary_52_of_52 = 1` | **52/52 PASS** |
| `sql/test/25_saved_sum_discriminator.sql` (reference DB) | `assertion_count = 7`; `saved_sum_7_of_7 = 1` | **7/7 PASS** |
| `sql/test/30_stage01_heavy_reference.sql` (reference DB) | `year_structure_assertion = 1`; `month_weaving_assertion = 1`; `full_calendar_assertion = 1`; `assertion_count = 3` | **3/3 PASS** |
| `sql/test/40_production_isolation.sql` (clean production DB) | `assertion_count = 4`; `isolation_4_of_4 = 1` | **4/4 PASS** |
| **Total** | All four groups run with `psql -X -v ON_ERROR_STOP=1`; all job stages succeeded | **66/66 PASS** |

Two independently created databases were used in the same isolated PostgreSQL container:
`sql_tamil_reference` loaded production schema and test-only normative reference;
`sql_tamil_production` loaded only `00_schema.sql`, `01_source_language_catalog.sql`, `02_monster_bootstrap.sql`, and then the four isolation assertions.
For suites 52, 7 and 4 the workflow explicitly enforces both the exact row count and `bool_and(ok)` by making a failed assertion terminate the command. The SQL assertion tables use `ok boolean NOT NULL CHECK (ok)`. The three heavy checks visibly returned 1.

## Scope and limits

1. The seven saved-sum discriminator assertions were **actually executed** for the first time in this recorded PostgreSQL CI evidence. Their two implementation-comparison assertions invoke `pastafari_sql_tamil_test.post_stir_round` — **a test/reference function, not a production implementation**. This is strong reference-level regression evidence, not a proof of the full production date algorithm.
2. The production isolation checks verify absence of the test schema in the clean production database, no direct references to the test namespace in production SQL function definitions, SQL-language-only functions, and absence of the specified floating-point functions. They do not prove full production date functionality.
3. The earlier independent arithmetic audit remains a historically valid *pre-execution* report; this document records the subsequently obtained Native result. Do not retroactively alter the audit's original date/status.
4. Stage 1 Native validation is now GREEN for the tested SHA. This is **not** authorization to open Stage 2, merge a PR, or alter `main`. The production routine has previously been identified as a deliberately incomplete/no-row bootstrap and requires a separately approved next stage to implement it.
5. This evidence document makes no changes to the SQL algorithm, tests, workflow, or mathematical contract.

Next development decision: obtain explicit authorization for Stage 2, or carry out any separately approved Stage 1 maintenance only. Do not re-run an already-green CI merely to claim progress.
