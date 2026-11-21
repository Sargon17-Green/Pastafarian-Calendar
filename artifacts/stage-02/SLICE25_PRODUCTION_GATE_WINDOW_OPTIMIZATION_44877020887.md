# SQL+தமிழ் — Slice25 production gate-window bounded optimization

PROJECT_ID: PC-BRANCH-SQL-TAMIL. Source branch: SQL+தமிழ். Parent SHA: 725216deddab7636dd53aa4401476687bf3ae6fb. Branch-only; no merge/main/release.

## Verified input evidence
- Completed exact-SHA production smoke [44877020887](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44877020887): job 136763857980 completed/success on PostgreSQL 17.12. Source-locked 5/5 typed fields and 5/5 invalid inputs, GREEN=1, runtime SLICE25_SMOKE_ELAPSED_MS=703835.717 (11m 43.835717s). Original ZIP artifact 14697935400: GitHub metadata = upload log = independently downloaded bytes SHA256 65b83651033bb0fc6f08171a98c3a1e637de78be1462d5fc2c4a95e6aa48a73c; CRC passed; versions and results inspected. No full Slice25 PASS.
- Stage1 [44877020829](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44877020829) job 136770615227 completed/success, PG17.12; original ZIP 14696849280 metadata/upload/actual SHA256 9771d25c9ac7039e6e95c721fc829f0c7938dc069da80fd1e24665c80dfe939a; CRC passed; original reference/isolation results inspected. Names Lock [44877020775](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44877020775) job 136763857760 completed/success.
- Earlier exact-SHA fast-window QA [44828306955](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44828306955) completed/success across 8/8 PG17.12 jobs with 40 exact selector fields and 48 invalid assertions, ZIP SHA256/CRC checked at that time. QA replacement function is in sql/test/160_stage25_fast_window_override_qa.sql; no independent new production performance result is claimed here.

## Actual branch-only engineering change
- Replace only production sql/16_stage02_year5000.sql `year5000_gate_window`'s slow separate `gate_index_at_or_before`, `gate_index_at_or_after`, and `gate_day(lo)` calls with the already QA-tested function's two directional sentinel walks and a single sorted indexed window. Preserve `year5000`, candidate ranking, names and gate-gap primitives unchanged.
- Independent reproducible synthetic Python gate-window index oracle sql/test/163_stage25_window_bound_oracle.py: seeded 1200 integer cases, gaps bounded 42..963, varied exact gates and adjacent days, compares independent bisect-defined index interval and array to simulated sentinel walk; 1200/1200 passed locally. This is STATIC, not PostgreSQL or Native.
- Update existing Slice25 smoke workflow to trigger on production sql/16 edits and to execute and source-lock the synthetic oracle before PostgreSQL. Natural smoke on new SHA is required; no dispatch duplication.

## Mandatory unaccepted gates / NEXT
- Read current branch HEAD and natural new-SHA run/job/PG17 log and original artifact ZIP + CRC/hash, confirm source-lock 163, 5/5 fields, 5/5 invalid, 1200/1200 static and measured latency.
- Regression risk: this updates an earlier accepted primitive, so re-verify affected Slice16/year5000 and Slice25 selector behavior on new SHA before treating it as unchanged; prior successes are historical evidence, not a new-SHA PASS.
- Continue Slice25 Native >=40 / >=24 reachable days / >=8 years; independent 29 source-locked five-field oracle cases across 8 years; production-only fresh-DB isolation >=8; typed five-field normative differential >=24, with individual jobs <=15 minutes. Stage25 NOT ACCEPTED.
