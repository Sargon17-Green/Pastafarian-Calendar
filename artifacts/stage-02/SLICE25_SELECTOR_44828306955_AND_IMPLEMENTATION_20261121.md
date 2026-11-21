# SQL+தமிழ் — Slice25 full selector evidence and production implementation

PROJECT_ID: PC-BRANCH-SQL-TAMIL. Date: 2026-11-21. Branch SQL+தமிழ்; parent SHA 7e0212b0b2b91008dc99cfecb3d5db19984129c7.
Scope: branch-only Slice25 calendar_date production source + reproducible static evidence script. No main, merge or release.

## Source-fresh completed evidence
- Run 44828306955 attempt1 completed/success on exact parent SHA, 8/8 PostgreSQL 17.12 jobs, 40/40 exact year-rec fields, 48/48 invalid-input flags, 8 baseline green. Elapsed milliseconds: anchor 128632.762; next_1 220121.591; next_2 and prev_2, etc. verified in original job logs and ZIP member postgres-results.txt. Range 128632.762–717353.953ms.
- All eight original ZIPs downloaded, SHA256 compared to GitHub artifact digest and upload-step original log; ZIP CRC 8/8, GITHUB_SHA 8/8, 36-entry source manifests consistent, generated input.sql SHA 8/8. Artifact IDs: anchor 14676817785; next_1 14677874097; next_2 14676504077; next_3 14679335067; next_3_next 14678407370; prev_2 14677403807; prev_3 14674993611; prev_3_prev 14675079416.
- Stage1 run 44828306973 completed/success; native reference 52, heavy 3, isolation 4. Names Lock run 44828307001 completed/success, job 136606462227 and original log.
- Earlier structural PG17 run 44701320191 completed/success had 8 original structural ZIPs. They were independently re-downloaded and compared SHA256/CRC 8/8. The branch's 161_stage25_calendar_date_static_evidence.py re-derived all five text/numeric fields for 29/29 cases across eight years, 145/145 fields, using original year structure, prefix gate days, independent ordinal scan, read-only Tamil catalog (64 keys), and cross-comparison with original oracle.jsonl.
- The existing 29 source-locked fixtures in sql/test/151_stage25_calendar_date_locked_goldens_44701320191.jsonl are derived from actual reachable PostgreSQL year structures. Do not treat static equivalence as production execution.

## Production source and algorithm
- sql/27_stage02_calendar_date.sql creates a new production calendar_result_text type, separate from legacy calendar_result, and a VOLATILE STRICT calendar_date(numeric,numeric).
- The production function validates integral ±60000-day input; calls accepted production find_target_year and build_year_structure; checks the partition, name and weaving invariants; selects a unique cutlet using one increasing gate-gap accumulation from open_gate_index; scans the month weaving prefix to find the occurrence ordinal; and resolves Tamil text through production source_name. It references no test schema and creates no persistent mutable state.
- The function is independently structured, not a copy of normative SQL; no production SQL was executed in this local preparation environment because PostgreSQL server/psql were unavailable. Source-change and static oracle evidence are NOT Native or differential PASS.

## Pending gates / NEXT
- On the resulting branch HEAD, build an exact-source Slice25 PostgreSQL 17 workflow with individually bounded 15-minute jobs, preserving original logs, test SQL, source/generated SHA256, versions and original artifacts. Check performance before large sharding; long original selector cases ran as long as 717 seconds, so full calendar_date may exceed the statement/job limits.
- Native >=40 named assertions across >=24 reachable days / >=8 years; explicit five fields, bounds, STRICT/invalid, determinism, type/catalog integrity.
- Production-only isolation >=8 named assertions in fresh databases with zero test-schema dependencies.
- Differential >=24 exact five-field typed comparisons to normative calendar_date on reachable locked inputs, no hashes alone, and independent ordinal/source-map oracle.
- Verify exact SHA for each completed run/job/log and original ZIP upload/GitHub/raw SHA256 + CRC. Only then consider Slice25 accepted. queued/in_progress are NOT PASS. Do not dispatch duplicate runs, merge or publish.
