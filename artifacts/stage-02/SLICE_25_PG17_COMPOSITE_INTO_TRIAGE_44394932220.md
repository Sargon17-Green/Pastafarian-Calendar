# SQL+தமிழ் — Slice25 PG17 composite INTO triage (run 44394932220)

**PROJECT_ID:** PC-BRANCH-SQL-TAMIL. **Branch:** `SQL+தமிழ்`. **Source lock:** `56c82755a58d7a017ff97e6e8d5b822dabbe9248` (live branch HEAD confirmed before patch). **2026-11-19**.

## Completed run evidence
Natural push [run 44394932220](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44394932220), attempt 1: `completed/failure` on exact locked source and branch. All 8/8 original jobs `completed/failure` in PostgreSQL 17 before reachable-case extraction. All 8 original job logs inspected. Each gives `psql:/work/slice25-preflight-evidence/preflight.sql:194: ERROR: "v_year" is not a scalar variable`, followed by exit code 3. No Native calendar_date comparison, no 29 actual cases, no Slice25 acceptance. The SQL reported line 194 is the end of the compiled PL/pgSQL DO block; offending statement is lines 75–78 of the source input.

The independent Python preflight self-test ran successfully in every job: `slice25_selftest_cutlet_days=9411 PASS`, `slice25_selftest_month_positions=22890 PASS`. These checks are synthetic, not PG17 oracles against real records.

All 8 upload logs report the artifact archive SHA256 below, and each matched the corresponding GitHub artifact metadata digest (8/8). **Original ZIP bytes/CRC were not independently downloaded or verified in this triage**. Do not claim full artifact verification.

| Case | Job ID | Artifact ID | Upload-log / GitHub metadata ZIP SHA256 |
| --- | ---: | ---: | --- |
| prev_2 | 135122193550 | 14472409665 | `6253d334d099e7dd82cffe764b3a1d648f8431fdd014337e1b289e9c359de6bf` |
| next_3 | 135122193949 | 14473458359 | `b92af1648a1b28919b7fdf6bbbebf7653bfc0767d0e902bb69d37412e14a371b` |
| next_2 | 135122193970 | 14472479575 | `b82a64a138ba3b4f25123eecf72c95399756f26d14e04d3a0afc98c21e88dc1b` |
| next_3_next | 135122194081 | 14474337930 | `1ada382ffd7b732abe37745ed8ee273ca4a69e084175b0e9e0401b760d5c7c89` |
| prev_3 | 135122194094 | 14474768129 | `7d20470d81e339d8fab7a4b3539485ae382b179dbb8594f5d40facd48c98a626` |
| next_1 | 135122194102 | 14473908188 | `3a97c0ad1f28fe1c00eb055db9b19ab766b0e8e618e91aa8b916d8099b36a58d` |
| prev_3_prev | 135122194128 | 14473393966 | `4387bb8967505525e592bd064cb73070dab8f9f13838a1d9a7d67d1b1fecc634` |
| anchor | 135122194295 | 14473399481 | `d2d824932e8940befff74820a787a313cfa308f7f895aa50d38689c24881a499` |

## Root cause and corrective change
The preflight DO block declared `v_year pastafari_sql_tamil.year_rec` (composite) and attempted a mixed scalar/composite PL/pgSQL target list: `SELECT calculation_day,year_data INTO STRICT v_calculation_day,v_year`. PostgreSQL rejects `v_year` as a scalar target. This reproduces the same composite INTO class of PostgreSQL parsing failure corrected in accepted Slice24 QA, and does **not** implicate production year arithmetic.

Changed only `sql/test/146_stage25_calendar_date_preflight.sql`: one `SELECT calculation_day INTO STRICT v_calculation_day`, followed by `SELECT (year_data).* INTO STRICT v_year`, both with the same `year_id` predicate. Preserved `STRICT` in both statements and did not modify production SQL, Oracle, accepted Slice24, or the eight-case workflow matrix. Static check: exactly one old pattern removed; exactly one `SELECT (year_data).*` introduced; initial/replacement line delta +5.

## Acceptance status / next evidence
This is **a source-level QA repair only**; PostgreSQL 17 Native has not yet verified the corrected query. The resulting natural-push workflow is the only intended verification route; require completed exact SHA, original 8 logs and artifact bytes/CRC, 8 distinct year records and all 29 reachable target cases with independent Python oracle. If successful, source-lock immutable fixtures and implement production `calendar_date` followed by Native >=40, isolation >=8, differential >=24. No main/merge/publication.
