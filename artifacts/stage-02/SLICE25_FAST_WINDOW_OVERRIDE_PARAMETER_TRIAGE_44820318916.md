# SQL+தமிழ் — Slice25 QA override: PostgreSQL parameter-name failure and targeted repair
Date: 2026-11-21. PROJECT_ID=PC-BRANCH-SQL-TAMIL. Authorized branch: `SQL+தமிழ்`.
Tested source commit: `694b5b18398907855160934bbe491d72cbe4b715`; tree: `b07aa5bac48acc0a0fbae3540d354b111320c9ec`.
CI run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44820318916 (attempt 1, completed/failure).

## Verified observed failure — not an algorithm verdict
All eight completed jobs on the exact tested source ran PostgreSQL 17.12, generated the matching case input, passed the 29-golden/8-year source-input lock and the 4644-case synthetic check. Every original job log reports:
```
psql:/work/sql/test/160_stage25_fast_window_override_qa.sql:47: ERROR:  cannot change name of input parameter "p_calculation_day"
HINT:  Use DROP FUNCTION pastafari_sql_tamil.year5000_gate_window(numeric) first.
Process completed with exit code 3.
```
This is an override DDL signature failure **before** any 5-field or six-invalid-input selector assertions. Verified field checks from this run: 0/40; verified invalid checks: 0/48; selector performance: not measured. Never interpret this as 8 actual selector-algorithm mismatches. Every failed job uploaded an evidence artifact. The following SHA256 values are GitHub artifact metadata, **not** downloaded-byte/CRC verification:

| Case | Job ID | Artifact ID | GitHub ZIP SHA256 |
|---|---:|---:|---|
| next_2 | 136579219957 | 14670804015 | `90b48ee8ee1edb030ef183d0dd34a5e7a6feb128dc909f51d5a879529f73d079` |
| prev_3 | 136579220137 | 14672632002 | `ecdc6b832f6018629d049ddf0138cd17e88ba4d976ad86b0fc4138c38eb31b22` |
| prev_2 | 136579220163 | 14672188927 | `b16b2b4eaefa3826a6f44992cd63f82461f3d8938e8ad403d85082874f0a87d0` |
| anchor | 136579220235 | 14670688950 | `a96111c552091798ff389284ba20c84c105773d985e13cbbda3773e4c880bf52` |
| next_3 | 136579220251 | 14670589263 | `9c8f492cbf6c4c6456111c543245d2c3939a1852b3b09bcab11eb62d3006f329` |
| next_3_next | 136579220302 | 14673126432 | `23d60456a292576d49a8da4eb2ae0e10c3c8a26db58ce8af413751e2809f4c37` |
| prev_3_prev | 136579220309 | 14671103535 | `d2bc22ba5331b3440f07cb5a7877eeb4476e4d61ea9945e19af1228fa7e7c8fd` |
| next_1 | 136579220427 | 14671794512 | `5f58cdb5ef03df0c8f4ff802c887cf9dcb4857fef2f94448caeae51fd1c16067` |

Related completed exact-SHA checks: Stage1 https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44820318809 (job 136579219318, completed/success, artifact 14672258637, GitHub SHA256 010bd2872a48c3f5b7e31bae23630c5aad8b833c2d813f7d37154b306b88e608); Names Lock https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44820318738 (job 136579218624, completed/success). ZIP contents/CRC not independently checked in this revision.

## Root cause and minimal source-only repair
Existing production `sql/16_stage02_year5000.sql` defines `pastafari_sql_tamil.year5000_gate_window(p_calculation_day numeric) RETURNS TABLE(first_gate_index numeric, gate_days numeric[])`. The QA-only `sql/test/160_stage25_fast_window_override_qa.sql` attempted `CREATE OR REPLACE` with parameter name `p_day`. PostgreSQL prohibits changing named input parameters during replacement at the same identity `(numeric)`.

Keep `CREATE OR REPLACE FUNCTION`; change `p_day` to `p_calculation_day` in the QA function declaration and all four body references (5 source tokens total), preserving both output names, types, volatility, STRICT and executable body structure. No `DROP FUNCTION` because the test is substituting a compatible definition; no production modification. Leave all eight source-locked year cases and the 12-minute statement timeout unchanged.

Static source assertions before commit: existing production signature matched; 5/5 identifier substitutions; 0 residual `p_day` identifiers; exact return-row signature unchanged. These are static checks, **not** PostgreSQL Native PASS.

Also correct the earlier original run 44811758812 manifest count from 31 to 32 source SHA lines in the existing QA plan. The new eight-case workflow's source manifest uses 9 QA entries + 27 production files, so it is a distinct manifest shape (36 lines); do not conflate their counts.

## Gates / next verification
- Source-fresh native full-selector: still NOT ACCEPTED. A natural branch push should start the existing 8-case workflow; confirm the exact new commit SHA, all eight completed jobs and their original logs. Do not dispatch duplicate workflow runs.
- Require 8/8 selector cases, exact 40/40 five-field flags, 48/48 invalid flags, bounded timings, same PostgreSQL and generated source locks, plus ZIP metadata=upload-log=downloaded-raw SHA256 and ZIP CRC per artifact.
- Stage1 and Names Lock on any new SHA must be checked separately; previously completed success is only for `694b5b18398907855160934bbe491d72cbe4b715`.
- Full Slice25 `calendar_date` remains **unimplemented**; production Native>=40, isolation>=8, differential>=24 and independent ordinal/text oracle remain pending. No main/merge/release.
