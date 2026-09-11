# Canonical saved-sum correction evidence — 2026-09-11

## Scope and authority

Repository: `Sargon17-Green/Pastafarian-Calendar`  
Branch: `Celeritas-per-Sepulcra`  
Expected and observed base HEAD: `8ce28c991a02994ea60c4a74854959717725144c`.

The correction applies only to the 12 final post-stirs. For each stir `r = 1..12`, all six outputs are computed from one immutable six-bowl snapshot and committed together:

```text
S = sum(oldBowls)
R = SAVE(S + 149*r)
permutationRank = 1 + ((R - 1) mod 720)
permutation = lexicographic permutation(permutationRank)

u = old[B] + 3*old[P] + 5*old[N] + R + r + position^2
new[B] = SAVE(u^2 + 7*old[P]*old[N])
```

The superseded mutant selected the permutation with `R` but added raw `S` inside `u`. That raw-sum interpretation is not canonical and is retained only in test/reference code as an explicit mutant discriminator.

## Production correction

`src/monster.cpp` previously recomputed the Stage 56 detour with `+ rawBowlSum`. The active Stage 56 compatibility entry point now delegates to the saved-sum implementation and returns that canonical result. Historical public identifiers containing `RawBowlSum` are kept for ABI/history, but production no longer uses raw `S` as the post-stir additive operand.

The persistent semantic fingerprint changed from `STAGE56_RAW_BOWL_SUM` to `STAGE56_CANONICAL_SAVED_SUM_2026_09_11`, so previously cached semantic structures are rejected.

## Exact discriminator

For `oldBowls = [1,2,3,4,5,6]` and `r = 1`:

```text
S = 21
R = SAVE(21 + 149) = 170
rank = 170
order = [2,4,1,3,6,5]

saved-sum result = [43348,43821,49771,36114,57684,55801]
raw-sum mutant  = [3565,3740,5518,1695,8365,7674]
```

The production witness equals the saved-sum result and differs from the raw-sum mutant. This prevents a test suite from passing merely because both production and expected data share the same old bug.

## Independent and per-stir differential evidence

`tests/stage_56_raw_bowl_sum_corrective_tests.cpp` keeps its historical filename but now compares production against `tests/reference/normative_reference.cpp::sauce`, whose default path is the saved-sum oracle. The explicit `sauceRawBowlSum` / `postStir12RawBowlSum` functions remain test-only mutant material.

For two distinct `(calculationDay,targetDay)` contexts, the test compares final bowls and drop-46 order against the independent saved-sum oracle. It also reconstructs every one of the 12 post-stirs independently and checks the production witness at each stir. Result: `12/12 PASS`.

## Secondary Stage 55 cross-check

As a non-authoritative sanity check, the corrected public Stage 56 path was compared directly with the historical saved-sum Stage 55 path for Foundation and for `c=t=-15048173`. Both five-field outputs matched exactly (`2/2 PASS`). This does not define the semantics; it is secondary evidence after the Scroll formula and the independent saved-sum oracle.

## Public E2E witnesses

The corrected public path produced and passed these five principal witnesses:

```text
(-15055671,-15055671) -> (5000,10,503,20,56)
(-15048173,-15048173) -> (5000,17,456,33,87)
(-15048173,-15048172) -> (5000,17,457,36,84)
(-15048173,-15048174) -> (5000,17,455,41,97)
(-15055672,-15055670) -> (5000,15,1,20,15)
```

Six additional workflow witnesses also passed:

```text
(-15048173,-15048171) -> (5000,17,458,11,103)
(-15048173,-15048170) -> (5000,17,459,15,100)
(-15048173,-15048169) -> (5000,17,460,33,88)
(-15048173,-15048168) -> (5000,17,461,14,93)
(-15048173,-15048167) -> (5000,17,462,21,95)
(-15048173,-15048166) -> (5000,17,463,44,79)
```

The former Foundation raw-sum witness `(5000,4,762,12,105)` is preserved only inside documents explicitly marked historical/superseded.

## Cache, ownership, and recovery

A dedicated production-manager test passed all of the following:

- cold calculation followed by warm cache hit;
- `A -> B -> A` history neutrality;
- fresh-instance parity;
- injected recoverable failure followed by successful retry;
- retry exhaustion leaving no contaminated Stage 56 cache entry;
- clean retry after exhaustion producing the canonical result.

The HTTP / Pair Tomb suite also passed after invalidating the compiled seed and almanac, including cold miss, warm hit, bypass/disable behavior, manual hot seed/almanac paths, protocol/JSON/JSONP/CORS checks, and pair-tomb behavior.

## Generated caches

The pre-correction two-day seed and year almanac embed semantic outputs without the persistent fingerprint, so keeping their old entries active would be unsafe. This delta therefore invalidates them as safe misses and advances their generation marker to 4. The generation workflow is updated so generation 4 is rebuilt from corrected production, and the scheduled fast-skip is allowed only when the generation is 4 and the almanac contains at least 80 generated entries.

A local attempt to regenerate the two-day seed did not finish within the execution window and emitted no record. No stale raw-sum entry was reused or represented as regenerated.

## Historical evidence handling

The old Stage 56 raw-sum test log, corrective evidence, byte audit, and development-history section are retained for provenance but prominently marked `HISTORICAL — SUPERSEDED` / `DO NOT TREAT AS CURRENT PASS`. Current CI guards use `CANONICAL_SAVED_SUM_CORRECTION_TEST_LOG.txt` instead of treating the old raw-sum PASS as present truth.

## Tests actually run

Current saved-sum correction evidence includes:

- Stage 56 core discriminator/oracle/per-stir/ownership/public-Foundation test: PASS;
- Stage 56 static audit: PASS;
- Stage 56 cache/recovery test: PASS;
- five principal E2E witnesses: 5/5 PASS;
- six additional workflow E2E witnesses: 6/6 PASS;
- HTTP / Pair Tomb suite with invalidated compiled caches: PASS.

A fresh single-command `g++ -O2` rebuild was attempted but the environment terminated the command while compiling the very large `src/monster.cpp`; the only emitted diagnostic was an existing missing-field-initializer warning. That attempt is **not** counted as a successful rebuild. The binaries used for the tests above were compiled from the corrected source after its last source edit; workflow-only edits occurred afterward.

Clang matrix, sanitizer matrix, and the complete historical Stages 1–55 regression matrix were not rerun locally during this correction. They remain prepared in GitHub Actions and are listed as unverified for this delta rather than claimed as current PASS.

No commit or push was performed, and no Stage 57 was created.
