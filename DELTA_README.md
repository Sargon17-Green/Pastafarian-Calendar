# SQL + தமிழ் — canonical saved-sum audit delta

Repository: `Sargon17-Green/Pastafarian-Calendar`  
Branch: `SQL+தமிழ்`  
Expected HEAD: `81d9dca5cf025aacda5b719392ee8f95d890d46b`  
Observed HEAD: `81d9dca5cf025aacda5b719392ee8f95d890d46b`

## Result

The branch's only complete Stage-1 calendar/Sauce implementation is the isolated test oracle in `sql/test/10_normative_reference.sql`. Its `pastafari_sql_tamil_test.post_stir_round` already implements the canonical **saved-sum** rule:

- `s = SAVE(sum(oldBowls) + 149*stir)`;
- the permutation is selected from that same `s`;
- the additive term inside every bowl's `u` is that same `s`;
- all six new bowl values read only from the same input `p_bowls` snapshot and are aggregated/committed together.

The Stage-1 production entry point in `sql/02_monster_bootstrap.sql` is intentionally still a bootstrap that returns no calendar result, so there is no separate production/fast/browser/generated Sauce path in this branch to correct.

No current-facing branch document inspected described `K½`, `raw bowl sum`, `rawBowlSum`, or an equivalent raw-sum detour as canonical. Existing Stage-1 execution reports were therefore retained unchanged.

## Why this delta contains one new test

Although the implementation was already canonical, the existing test suite did not contain the explicitly requested saved-sum-vs-raw-sum discriminator. This delta adds only:

- `sql/test/25_saved_sum_discriminator.sql`

It does **not** change implementation semantics, stages, vectors, caches, reports, or historical artifacts.

## Discriminator witness

For `oldBowls = [1,2,3,4,5,6]` and `stir = 1`:

- raw `S = 21`;
- canonical `R = SAVE(S + 149) = 170`;
- permutation rank `170` gives `[2,4,1,3,6,5]`;
- for fixed Bowl 1: position `3`, previous Bowl `4`, next Bowl `3`;
- canonical intermediate `u = 208`;
- raw-sum-mutant intermediate `u = 59`;
- canonical new bowls: `[43348,43821,49771,36114,57684,55801]`;
- raw-sum mutant: `[3565,3740,5518,1695,8365,7674]`.

The new SQL test reconstructs both calculations from one immutable old-bowl array, asserts the intermediate difference, and requires the real `post_stir_round` to equal the saved-sum result and differ from the mutant.

## Audit performed

The current Scroll was re-read before branch inspection. The branch HEAD was revalidated through GitHub and matched the expected SHA exactly. The complete branch tree was inspected for applicable implementation, test, report, cache, generator, browser/API, and documentation surfaces. In this Stage-1 branch there are no browser bundles, generated/obfuscated artifacts, service-worker caches, API routes, semantic cache formats, or production Sauce implementations beyond the isolated SQL oracle.

Static source inspection covered the normative oracle, bootstrap production files, Stage-1 regular/heavy/isolation tests, architecture/history/current README, source-language catalog, and stored PostgreSQL test reports/logs. No reachable raw-sum implementation was found.

An independent integer-arithmetic discriminator was executed in Python in the packaging environment and passed with the exact witness values above.

## Native execution status

`psql`/PostgreSQL is not installed in the current packaging environment. Therefore the new SQL discriminator was **prepared but not executed natively here**. The repository's stored prior PostgreSQL 17.6 results (59/59 PASS at the base HEAD) were inspected but are not claimed as execution of this new test.

To execute the new discriminator after loading the existing oracle:

```text
psql -X -v ON_ERROR_STOP=1 -f sql/test/25_saved_sum_discriminator.sql
```

It must report `assertion_count = 7`; any raw-sum implementation will fail the table CHECK during insertion.

## Regeneration / deletion status

No derived vectors, corpora, checkpoints, hashes, generated artifacts, caches, or service-worker epochs required regeneration because the branch was already saved-sum canonical. No deletions are required. No `HANDOFF_*` file is included.
