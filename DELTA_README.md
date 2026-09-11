# Celeritas-per-Sepulcra — canonical saved-sum correction delta

This ZIP is an overlay delta for **only**:

- repository: `Sargon17-Green/Pastafarian-Calendar`
- branch: `Celeritas-per-Sepulcra`
- base HEAD: `8ce28c991a02994ea60c4a74854959717725144c`

The observed branch HEAD matched the expected HEAD when the correction was prepared.

## Semantic change

Before this delta, active Stage 56 chose the post-stir permutation using `R = SAVE(S + 149*r)` but incorrectly put raw `S` into `u`. After this delta, all 12 final post-stirs use the canonical saved value `R` both for permutation selection and inside `u`, with all six bowls calculated from one old snapshot and committed together.

The raw-sum version remains only as explicit historical/test mutant material. Old raw-sum PASS reports are retained but marked superseded.

## Applying the delta

1. Verify the checkout is exactly at `8ce28c991a02994ea60c4a74854959717725144c` on `Celeritas-per-Sepulcra`.
2. Verify `SHA256SUMS.txt`.
3. Copy the repository-relative payload files from this archive over the checkout.
4. `DELTA_README.md`, `DELTA_MANIFEST.json`, and `SHA256SUMS.txt` are package metadata; they are **not** repository payload and should not be committed unless intentionally desired.

There are **no deletions**, so `DELETE_PATHS.txt` is intentionally absent.

## Payload summary

- changed repository files: 19
- new repository files: 3
- deleted repository files: 0

The authoritative lists and SHA-256 values are in `DELTA_MANIFEST.json`.

## Verification summary

Actually run and PASS: Stage 56 saved-sum core (including exact discriminator and all 12 post-stirs), independent oracle comparison, static audit, cache/recovery, five principal E2E witnesses, six additional workflow E2E witnesses, a two-context Stage55/Stage56 sanity cross-check, HTTP/Pair-Tomb tests after cache invalidation, YAML parsing, and the updated evidence guard.

Not claimed as current PASS: a fresh one-command `g++ -O2` rebuild (environment timeout during `monster.cpp` compilation), local hot-seed regeneration (timeout before first record), Clang matrix, sanitizer matrix, and the complete historical Stages 1–55 matrix. See the manifest and `CANONICAL_SAVED_SUM_CORRECTION_EVIDENCE.md` for exact details.

The old compiled hot seed/almanac values are not shipped as truth: they are invalidated to safe misses and generation 4 rebuild logic is included.

No commit or push was performed. No Stage 57 was created.
