# SQL+தமிழ் — Stage 2 stone Native evidence (run 41040652056)

Date: 2026-10-30. Branch: `SQL+தமிழ்`. Verified commit: `2ff10689af6305160070e530b2d8809fe8fee734`.

- PostgreSQL 17.11 on GitHub Actions, status **completed / success**, job 124012313205.
- Stone assertions: **23/23**, exact native fail-closed count check `stone_23_of_23 = 1`.
- Production isolation assertions: **4/4**, exact native fail-closed count check `isolation_4_of_4 = 1`.
- Original GitHub Actions artifact ID: **12972251291**, [run](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41040652056).
- Original ZIP SHA-256, independently checked against GitHub artifact digest: `512b44c2045a057d52e34a605fbb8241384b39d7f74488ece4f365e76fa9cfcb`.
- Original ZIP files: `stones.txt`, `isolation.txt`, `versions.txt`; preserved unmodified at `artifacts/stage-02/POSTGRESQL_NATIVE_STONES_41040652056.zip`.

This records **stone Native** only. It is not proof of `hidden_drop`, differential conformance, or full five-component calendar production.

## Stage 2 slice 3: independent preflight, not Native

`sql/05_stage02_hidden_drop.sql` implements the seven coefficient rows and seven exact `SAVE` grinds in the production schema, without calling `pastafari_sql_tamil_test`. Four input pairs × seven outputs = 28 fixed integer golden values, independently computed with Python bigint prior to SQL authoring. The new native workflow must verify 38 assertions, 4 production isolation checks and 28 differential checks in a **separate database** before this slice can be marked Native PASS. Do not infer PostgreSQL PASS from independent numeric preflight.
