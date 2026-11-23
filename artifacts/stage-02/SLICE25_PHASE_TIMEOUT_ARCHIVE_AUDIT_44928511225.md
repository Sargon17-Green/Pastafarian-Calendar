# SQL+தமிழ் Slice25 — original phase ZIP evidence audit and bounded follow-up

PROJECT_ID: PC-BRANCH-SQL-TAMIL
Branch: SQL+தமிழ்
Parent HEAD locked before change: ceca7b97547ed84d28cef604953cde531b91cce6
Audit date: 2026-11-23
Scope: QA-only analysis of an existing finished run; NO PostgreSQL re-dispatch, production modification, main/merge/release, or Slice25 acceptance.

## Original completed evidence, verified independently

* Previously instrumented one-case run 44928511225, job 136919794548, source 59e139f56502721228e2fc5b0fa97ca72fbd1140, **completed/failure**. Its original ZIP artifact #14718837632 (20,093 bytes, 10 entries) independently matches SHA-256 616889c1b0beb9a62e8e43869cce0b19ee97388c065c4afdb1d04e91c0ef8b90 from GitHub artifact metadata and upload job log; ZIP CRC 10/10 PASS. SHA-256 of the three generated SQL ZIP members matches the preserved source-sha256 manifest; 8 selected exact production Git blob locks match. The independent 29-case / 8-year fixture generator's **static** audit was 87/87, not a completed Native five-field test.
* PostgreSQL 17.12, source/branch/fixture lock: PROJECT_ID correct; calculation_day=-15055671, target_day=-15072356; expected independent five fields: 4996 / வெண்கலம் / 302 / தவளை / 50. No five-field notices or green marker.
* Original timed phase notices: target_year ENTER/EXIT **1/1**, elapsed **694470.435 ms** (approximately 96.45% of 720,000 ms statement cap); sauce ENTER/EXIT **1/1**, elapsed **6203.125 ms**; 46 bowl_round enter/exit, total **2163.268 ms**; 12 post_stir_round enter/exit, total **293.610 ms**; stone 414/414 total **2078.212 ms**; save 414/414 total **43.810 ms**. The 46/12/414/414 values are **counts**, not independent passes. Nested times must never be added as disjoint fractions of total runtime.
* The last emitted completed phase is sauce EXIT for target -15074037. The terminal SQL error is statement_timeout during **negative_gate_gap → gate_gap_signed → sauce → visible_drops → one_visible_drop → stone_value → stone_state → save_value → floor_div**, inside the later calendar-date gate-scan assignment. Thus this instrumented source spent almost its entire statement budget in find_target_year; the observed terminal stack is not proof of a sauce/bowl-round correctness defect or a global algorithmic bottleneck.
* Distinct exact documentation-HEAD regression runs are now completed: Stage1 run 45083124102/job 137395540997 **success**, original ZIP #14778393194 SHA-256 b5fadb65187b35747168d7111c33a3e42db68fa3b71ccce45fc515ff665c0b11, 1,387 bytes/3 members, raw SHA==GitHub/upload and CRC PASS; PG17.12 ordinary 52, saved sum 7, heavy 3, clean isolation 4 (job log). Names run 45083124143/job 137395540747 **success**, same SHA ceca7b97547ed84d28cef604953cde531b91cce6; no artifact.
* Existing **focused one-stone** run 45076535299 remains ACCEPTED on a3120f901eb7d9a65231fed00081ed3eee39786d; it does not cover this failed path. Full Slice25 remains **NOT ACCEPTED**.

## Permanent executable audit

sql/test/176_stage25_timeout_evidence_audit.py audits only exact original 44928511225 ZIP bytes. It independently checks full ZIP SHA/CRC, project/SHA/branch/fixture/PG version, 3 generated SQL member hashes, 8 production Git blob locks, existing oracle audit marker, balanced phase notices, expected timeout stack, and **absence** of field PASS/green. Its local synthetic self-test (one valid and three mutated cases) is **4/4 PASS** and actual-original-ZIP audit exited **0**. These are **static/archival QA passes**, not PostgreSQL Native PASS. SHA-256 of tested local script: f057aae7676c4b6a0bfde2ad1919918dd8e49ed8ae5c85eb5e41c11e8e9fe109. Command:
python3 sql/test/176_stage25_timeout_evidence_audit.py --self-test --archive path/to/original-14718837632.zip --output phase-summary.json

## NEXT: distinct bounded diagnosis, not blind rerun

1. Keep source SHA lock, independent original 29-case fixture and five exact fields; **do not replay the old 720s calendar_date call**. First design an isolated **fixed-year / gate-scan** QA probe avoiding find_target_year in the timed section by supplying the previously independently validated target year_rec from the locked Slice24 evidence. Do not fabricate year_rec. Time separately a bounded prefix of negative_gate_gap calls, numeric gate-step count, and sauce/visible_drops if reached. Cap at 60 seconds per diagnostic segment, log partial progress and explicit exit status; do not treat incomplete phases as PASS.
2. The next run must pin actual Git source/tree SHA, fixture SHA, PostgreSQL version, original SQL hashes and source hashes; log independent oracle comparisons for all five fields only if the entire target completes; test unmodified-source equivalence separately, without a full 56-job matrix. Include original ZIP and verify byte-level SHA256/CRC before any acceptance decision.
3. No existing accepted one-stone, Stage1, or Names job needs dispatch for its already-tested SHA. No production/main/merge/release changes. D=פתוחה, G=READY. No local user execution required. No /Pending_User_Execution cleanup (no new user-run results).
