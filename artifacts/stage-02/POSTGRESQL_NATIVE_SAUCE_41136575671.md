# SQL+தமிழ் Stage 2 Slice 8 — Native PostgreSQL sauce integration evidence

## Provenance
- Branch: `SQL+தமிழ்`.
- Source/workflow commit: [`eb3521ce4eb4b69b57d671a17922d7f632c60702`](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/eb3521ce4eb4b69b57d671a17922d7f632c60702).
- [GitHub Actions run 41136575671](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41136575671): `completed/success`; job `sauce-slice8`, ID `124340397210`, `completed/success`.
- Native runtime: PostgreSQL **17.11** (Debian 17.11-1.pgdg13+2), from `versions.txt` in downloaded ZIP.
- [Artifact 13017391854](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41136575671/artifacts/13017391854), `sql-tamil-slice8-sauce`, four files: `native.txt`, `isolation.txt`, `differential.txt`, `versions.txt`.
- ZIP SHA-256 independently computed on downloaded artifact: `7e6213e133be8e63e37823d1ce12427f12aa516281c353d7e6a40da8abb48554`, matches the GitHub artifact digest.

## Verified gate counts — from completed job and extracted logs

| Gate | Observed insertion/count | Final SQL assertion |
| --- | ---: | ---: |
| Native: 18 independent twelve-round golden values + 3 bounds + 8 invalid + 2 complete sauce shapes + 3 metadata | **34 / 34** | `native_34_of_34 = 1` |
| Production isolation in production-only DB | **4 / 4** | `isolation_4_of_4 = 1` |
| Differential: 3 twelve-round chains × 6 elements, plus 2 complete sauce cases × (6 bowls + 6 drop-46 order values) | **42 / 42** | `differential_42_of_42 = 1` |
| **Total** | **80 / 80** | all three gates passed |

The separate differential database was `sql_tamil_sauce_differential`, with normative reference loaded there only. Production `sql/10_stage02_sauce.sql` composes 46 ordered `bowl_round` computations, then 12 `post_stir_round` computations, retaining the bowl order from drop 46 separately. The production function does not refer to the test schema. Its full-sauce output is a partial Stage 2 internal result, **not a complete calendar date**.

## Independent oracle
Before CI, a separate exact-integer Python factoradic model checked four existing one-round vectors (24 numbers) with no discrepancy. The model then generated the 18 full twelve-round golden elements used in the new Native test. This oracle is independent of PostgreSQL. The two full-sauce differential cases compare against the reference implementation that resides solely in the isolated test database; they do not replace a full-calendar differential gate.

## Files and boundaries
- Production: [`sql/10_stage02_sauce.sql`](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/eb3521ce4eb4b69b57d671a17922d7f632c60702/sql/10_stage02_sauce.sql).
- Native: [`sql/test/96_stage02_sauce_native.sql`](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/eb3521ce4eb4b69b57d671a17922d7f632c60702/sql/test/96_stage02_sauce_native.sql).
- Differential: [`sql/test/97_stage02_sauce_differential.sql`](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/eb3521ce4eb4b69b57d671a17922d7f632c60702/sql/test/97_stage02_sauce_differential.sql).
- Workflow: [`sql-tamil-stage02-sauce-native.yml`](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/eb3521ce4eb4b69b57d671a17922d7f632c60702/.github/workflows/sql-tamil-stage02-sauce-native.yml).

**Acceptance:** Slice 8 Native + isolation + differential PASS on the cited source SHA. This does **not** constitute Stage 2, `calendar_date_spaghetti`, or whole-calendar PASS. No merge to `main` was performed.

## NEXT
Define and implement the next production slice connecting `sauce_result` to the six-bowl answer stream in the independently verified Stage 2 contract, with bounded Native and separate differential gates. Do not rerun the already-passed Slice 8 suite on the unchanged source SHA.
