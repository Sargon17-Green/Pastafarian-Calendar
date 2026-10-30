# SQL+தமிழ் — Stage 2 Slice 4: 46 visible drops, Native and differential QA

Verified on 2026-10-30 against **code SHA** `114e185adde2a0d7feeaac57d9bb7fa8ac00323e` on the unmerged `SQL+தமிழ்` branch.

## Implemented source
- `sql/06_stage02_visible_drops.sql`: 46 ordered visible drops, each with 11 exact SAVE grinds; preceding visible drops resolved by index and non-positive predecessors via seven hidden drops.
- `sql/test/80_stage02_visible_drop_tests.sql`: **51/51 Native PASS**, including 32 fixed BigInt fixture assertions across four input orientations, vector sizes, SAVE bounds, null/invalid inputs, SQL-only purity, and incomplete-calendar invariant.
- `sql/test/81_stage02_visible_differential.sql`: **184/184 exact comparisons PASS** against the normative reference, with 46 results for each of four input orientations.
- `.github/workflows/sql-tamil-stage02-visible-native.yml`: isolated PostgreSQL 17 databases, bounded 20-minute job and strict `count(*) AND bool_and(ok)` quality gates.

## CI evidence
- Workflow run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41091834656
- Job ID: `124187418697`; status `completed`, conclusion `success`.
- PostgreSQL `17.11`; run checked exact **code SHA** `114e185adde2a0d7feeaac57d9bb7fa8ac00323e`.
- Native: **51/51 PASS**; production isolation: **4/4 PASS**; differential: **184/184 PASS**.
- Artifact `12994901386`: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41091834656/artifacts/12994901386
- ZIP SHA-256: `0ca7f2c6356a19baa9a73c0c410f4a41d190157d74088e2abc7370aea8f95323` — independently recomputed from downloaded ZIP. `native.txt`, `isolation.txt`, `differential.txt`, and `versions.txt` inspected.

## Status and next required unit
Slice 3 had already passed in run 41087167102. Slice 4 is **PASS** at its stated gates, **not** all of Stage 2. The public entry `calendar_date_spaghetti` still deliberately emits zero rows; no full 5-component calendar date is claimed.

The next production dependency is the normative six-bowl computation: validate the bowl rank permutation (`bowl_order_from_number`, `bowl_order_from_drop`) and first bowl values (`initial_bowls`) without referencing the test namespace. Follow with independent integer fixtures and isolated PostgreSQL 17 Native/differential QA. Do not merge to main or mark Stage 2 complete until its downstream gates are satisfied.
