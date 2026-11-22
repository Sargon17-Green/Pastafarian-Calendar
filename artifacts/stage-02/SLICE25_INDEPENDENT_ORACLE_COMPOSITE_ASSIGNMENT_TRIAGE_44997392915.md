# SQL+தமிழ் — independent stone/bowl oracle: composite assignment failure and QA-only repair

PROJECT_ID: PC-BRANCH-SQL-TAMIL
Branch: SQL+தமிழ்
Failed source SHA: 7bb44278aeae3e013e453444f2c7821211ff5374
Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44997392915
Job: 137131268372 (completed/failure, attempt 1, PostgreSQL 17.12)
Original artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44997392915/artifacts/14744916825

## Original immutable evidence (2026-11-22)
- Job checkout fetched exact 7bb44278aeae3e013e453444f2c7821211ff5374 on SQL+தமிழ்.
- Independent Python static oracle model PASS (46 stone states × 5 fields; 32 bowl cases). This is not Native PASS.
- Source SQL 00..08 loaded successfully: SOURCE_LOAD_EXIT=0; source-blobs.txt contains nine Git blob IDs.
- Generated SQL sha256: 03bd63ef060c2567f5f19daf45b3db62d08e01acdfa6e08423e3a1ada71475cc.
- Oracle execution: ORACLE_EXIT=3; PostgreSQL psql at independent_stone_bowl.sql:167 reported `invalid input syntax for type numeric: "(17,29,43,71,101)"`, inside the first stone comparison. Outer workflow step exit 4.
- Original artifact ZIP #14744916825 downloaded: SHA-256 `4eae47b7a1e0969626c44873af1519c74f9b13f397c71dccb7ef5ee43f52941b`, identical to GitHub artifact metadata and upload-job digest; all ZIP CRC entries valid. Original oracle.log, exits.txt, versions.txt, generated SQL and source-blobs preserved.
- Root cause: `SELECT pastafari_sql_tamil.stone_state(i) INTO v_stone` routes one composite-valued column into the first numeric field of a PL/pgSQL composite record. It fails before any of the promised 230+32 comparisons; it is a QA harness assignment error, not a production-oracle mismatch.

## Narrow repair
- Replace only the PL/pgSQL statement generator by `v_stone := pastafari_sql_tamil.stone_state(i);`, which assigns the composite expression to the composite-typed variable as a whole.
- Harden independent Python self-test: exactly 46 direct composite assignments and no `INTO v_stone` in emitted SQL.
- No changes to the independently specified math model, numerical fixtures, source locks, production SQL, CI workflow configuration, or test count.
- Verify new code and commit blob SHA, and let existing push-triggered exact-SHA workflows run naturally. Do not manually duplicate dispatch.

## Other same-source results
- Stage1: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44997392828, job 137131268364 completed/success, PG17.12: normative 52, saved-sum 7, production isolation 4. Original artifact #14744872156 SHA-256 `646314bc1e0d62cea2da719c89fd56058320ccd0e04400da3dd4a34d579e1aac`, GitHub metadata/upload log match, ZIP CRC valid.
- Names: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44997393072, job 137131269164 completed/success (source lock checked in original job log). No result artifact listed.

## Gates and next
- Failed old Native oracle is NOT ACCEPTED; the fixed SHA requires its own completed run, job log, original ZIP digest/CRC, source-lock check and SOURCE_LOAD_EXIT=ORACLE_EXIT=0, with 230/230 stone and 32/32 bowl markers before it can be accepted.
- Stage1 and Names are accepted only for the old SHA above; do not claim they passed on a new commit until checked.
- After independent Native PASS, build QA-only one-stone-state-per-bowl candidate, compare against independent oracle plus 46 valid positions/invalid inputs, and conduct controlled timing. Full Slice25/differential remain NOT ACCEPTED; no main, merge, or release.
