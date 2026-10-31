# SQL+தமிழ் Stage 2 — Slice 12 PostgreSQL native gate

- Source branch: `SQL+தமிழ்`; source commit: `b16e4893d37dced05885ee2dcc52138c63dbc804`.
- Workflow: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41197009920 (run attempt 1, completed/success, job `124525112220`, completed 2026-10-31T12:01:31Z).
- PostgreSQL: `17.11 (Debian 17.11-1.pgdg13+2)`.
- Assertions: 26/26 native, 4/4 production-only isolation, 14/14 differential; total **44/44**. Observed `native_26_of_26=1`, `isolation_4_of_4=1`, `differential_14_of_14=1`. Individual count checks returned expected rows and `bool_and(ok)` in the job log.
- Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41197009920/artifacts/13042105723 ; 4 entries `native.txt`, `isolation.txt`, `differential.txt`, `versions.txt`, 1167 ZIP bytes.
- Artifact independent SHA-256: `5c9c7f35f1a030d5789f534d74852244ab09b2a4bcb6139d804624dd7d49463d`, calculated from downloaded ZIP and matched GitHub's digest exactly.
- Exact source SHA confirmed from job log and artifact `versions.txt` and workflow head_sha; branch HEAD matched this source before evidence commit.

**Scope:** proves this Slice 12 gate only; Stage 2 not completed. No Windows user-native dependency. No main/merge. Next: bounded year-5000 gate-bound candidate selection with independent oracle, defined cost limit and small fixed case tests; do not infer a full-calendar PASS from this narrow evidence.
