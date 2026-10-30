# SQL+தமிழ் — Stage 2 Slice 3 PostgreSQL Native and differential verification

- Verified 2026-10-30 against code SHA `92ddc5b4fa1ccbd89405ea55b07ea4779674b3d0`, branch `SQL+தமிழ்`.
- GitHub Actions run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41087167102
- Job ID: `124171237443`; conclusion `success`; PostgreSQL `17.11`.
- Native hidden-drop assertions: **38/38 PASS** (a CHECK-constrained table and an explicit `count(*)=38 AND bool_and(ok)` gate).
- Production isolation: **4/4 PASS**, no reference namespace in production setup.
- Independent differential: **28/28 PASS** in a separate PostgreSQL database.
- Workflow artifact ID `12993230550`: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41087167102/artifacts/12993230550
- Artifact ZIP SHA-256: `6314556a06127b3d9cc25b9a743d0968be001c290f8df527372eebbe6c639466`. Downloaded ZIP digest independently matched. Its `native.txt`, `isolation.txt`, `differential.txt` and `versions.txt` were inspected, including the source SHA.
- The existing earlier stone Native 23/23+4/4 and Stage 2 core 37/37+4/4 are separate evidence; not rerun for this report.
- Scope: **Slice 3 only.** Stage 2 is incomplete, and `calendar_date_spaghetti` still deliberately returns no calendar date.
