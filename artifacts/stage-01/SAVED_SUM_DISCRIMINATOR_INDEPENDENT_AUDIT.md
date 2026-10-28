# Saved-sum discriminator — independent arithmetic audit (SQL+தமிழ்)

Audit date: 2026-10-28.
Repository/branch: `Sargon17-Green/Pastafarian-Calendar`, `SQL+தமிழ்`.
Audited HEAD before this evidence-only commit: `b8691868cf29b5f7ced52d7c518656029fbcafec`.
Source: `sql/test/25_saved_sum_discriminator.sql` (blob `28a1a36f05afed1c1d4feffc585b54e657a44f00`).
Reference function: `sql/test/10_normative_reference.sql` / `pastafari_sql_tamil_test.post_stir_round`.

## Independent integer calculation

Using arbitrary-precision integer arithmetic independently of PostgreSQL:

- `M = 170141183460469231731687303715884105727`
- `SAVE(x) = 1 + ((x - 1) mod M)`, with Euclidean remainder
- `old_bowls = [1, 2, 3, 4, 5, 6]`, `stir = 1`
- `raw_sum = 21`; `saved_sum = SAVE(21 + 149) = 170`
- The 1-based lexicographic unrank of `((170 - 1) mod 720) + 1` is `[2, 4, 1, 3, 6, 5]`.

For each bowl `id`, let `pos` be its 1-based position in the above permutation and `prev_id`, `next_id` the cyclic neighbors. The test defines
`u(id, s) = old[id] + 3*old[prev_id] + 5*old[next_id] + s + stir + pos^2`
and
`out(id, s) = SAVE(u(id,s)^2 + 7*old[prev_id]*old[next_id])`.

Independent exact arithmetic yields:

| Quantity | Expected |
| --- | --- |
| `u(1, saved_sum)` | `208` |
| `u(1, raw_sum)` | `59` |
| `out(id, saved_sum)`, id 1..6 | `[43348, 43821, 49771, 36114, 57684, 55801]` |
| `out(id, raw_sum)`, id 1..6 | `[3565, 3740, 5518, 1695, 8365, 7674]` |

Thus the five **constant/algorithm witnesses** in the SQL discriminator agree with an independent exact-integer calculation. This is a *static arithmetic audit*, not a PostgreSQL execution result.

## Limits and outstanding evidence

1. The seven assertions in `sql/test/25_saved_sum_discriminator.sql` have **NOT** been executed as part of this audit. Native PostgreSQL result: **UNVERIFIED**. The existing 59/59 PASS evidence in `artifacts/stage-01/POSTGRESQL_EXECUTION_LOG.txt` predates and does not include this file.
2. Assertions 6 and 7 call `pastafari_sql_tamil_test.post_stir_round`; this is in the **test/reference namespace**, not the production implementation. They can discriminate a mutant of the normative reference, but must **not** be advertised as proof of production correctness.
3. At the audited HEAD, `pastafari_sql_tamil.calendar_date_spaghetti` in `sql/02_monster_bootstrap.sql` deliberately returns no rows. Do not interpret the reference result as a working production date conversion.
4. `README.md` documents the original Stage 1 load order only and does not include `sql/test/25_saved_sum_discriminator.sql`. Do not silently count 7 more Native PASS cases.
5. This audit changes no SQL, no mathematical rules, no stage status, and no production isolation policy.

## Next permitted verification (separate disposable TEST database)

After creating a clean **test-only** PostgreSQL database, run, in this exact order, with `psql -X -v ON_ERROR_STOP=1 -d <test_db> -f <path>` for each file:

1. `sql/00_schema.sql`
2. `sql/01_source_language_catalog.sql`
3. `sql/02_monster_bootstrap.sql`
4. `sql/test/10_normative_reference.sql`
5. `sql/test/25_saved_sum_discriminator.sql`

Capture the PostgreSQL server/client versions, each exit code, and the assertion count. Only after a real run with no errors may the seven SQL assertions be labelled Native PASS. Run the production-isolation checks in a **different** clean database containing production SQL only. Native 7/7 does *not* close the production implementation gap.

No new Stage, PR merge, or `main` change is authorized by this audit.
