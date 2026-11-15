# SQL+தமிழ் — Stage2 Slice24 PG17 reachable-input preflight acceptance

PROJECT_ID: PC-BRANCH-SQL-TAMIL. Evidence reviewed 2026-11-15.
Tested branch: SQL+தமிழ். Exact tested SHA: ce5b79846467751a17fbf7af52476ec3539171c5.
GitHub run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42390557293
Job preflight 128457043201; attempt 1; completed/success. PostgreSQL 17.11.

Original job log directly inspected. Seven selector signatures 7/7 and year_rec fields 5/5 passed; the current gate_day matches the previously accepted Slice14 foundation golden; actual reachable inputs 10/10, navigation 8/8, boundary days 2/2. Exact records: anchor, boundary_open/close, next_1..4, prev_1..3. Largest observed span 5681 days (prev_3/year 4997), not a proven global maximum. Navigation completed after 00:14:19.942085.

Independent local ZIP audit: artifact 13581607899 downloaded, 2451 bytes, SHA-256 5eac2781d63854eced1be6bd1910483504d23bef5dfa602622765fa06f3650b5. Independently computed hash agrees with GitHub artifact metadata and job upload digest. All four ZIP entries passed CRC; versions.txt source SHA is exact. The 8 synthetic Python records, 64 negative mutations and 134 small compositions passed; these are structural tests, NOT goldens from actual year inputs.

Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42390557293/artifacts/13581607899

Acceptance scope is ONLY the source-locked input preflight. Slice24 production function, full native integration and differential checks have not passed. No Stage2-wide PASS, main merge or release.

Next: add ordered production year_structure and build_year_structure (VOLATILE STRICT), create complete field-by-field real-input fixtures independently from prior accepted selectors, production-only isolation and PostgreSQL 17 differential against normative SQL, each with source-locked bounded CI and independently audited original artifacts. At least eight real distinct input cases, 25 native checks, eight isolation and eight full-record differential required for final Slice24 acceptance.
