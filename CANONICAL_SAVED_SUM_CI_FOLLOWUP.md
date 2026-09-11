# Canonical saved-sum correction — CI follow-up R2

Date: 2026-09-11
Repository: `Sargon17-Green/Pastafarian-Calendar`
Branch: `Celeritas-per-Sepulcra`
Base/observed HEAD for this follow-up: `1f4ab5e001d7578093846dc4cae981aa21654538`
Parent containing the canonical production correction: `53772e13ed6d25d20164bc4f903b930bca8531f0`

## Scope

This follow-up does **not** change the canonical production algorithm. The active Stage 56 production correction already uses the saved stirring-order number `R = SAVE(S + 149*r)` both for permutation selection and in `u`.

R2 repairs CI assumptions and historical witnesses exposed after that semantic correction.

## CI observations after the production correction

At `53772e13ed6d25d20164bc4f903b930bca8531f0`:

- `Sepulcra calida et atlas annorum` completed successfully.
- `Cicatrix HTTP Celeritas v1` reached a healthy server and then failed on stale raw-sum Foundation assertions.
- `Vigilia diuturna — C++ + Latina Nova` had Stage 56 gcc/clang O1/O2/O3, sanitizers, historical regressions, and the saved-sum differential jobs pass. Its acceleration job failed on one stale raw-sum nearby witness.
- `Comparatio decem milium` stopped first on a stale Patch40 public-path witness, before its matrix could run.

The later full 100-shard log bundle was from commit `1afa327ce6e84602c75ed670f8aa6f8cdff34f0f`, before the corrected production `src/monster.cpp` had landed. Its 100/100 failures are therefore not evidence against the corrected production implementation. The logs did expose two workflow-design problems: semantic identity was still gated against historical `C++&Latina`, and historical baseline execution could time out on shard 44.

The current base HEAD `1f4ab5e001d7578093846dc4cae981aa21654538` is an automatic child of `53772e...` and changes only the regenerated two-day seed and year-almanac seed.

## R2 changes

1. HTTP workflow Foundation assertions now use the canonical saved-sum witness `[5000,10,503,20,56]`.
2. The acceleration smoke witness for `c=-15048173, t=-15048172` now uses `[5000,17,457,36,84]`.
3. The Patch40 probe keeps its two deterministic direct `+1/-1` adversarial tests. The obsolete public Shard-83 raw-sum integration witness is retained only as an explanatory historical comment; the shortcut metric is required to be exactly two hits from those direct tests.
4. The 10,000-pair workflow no longer treats historical `C++&Latina` output as semantic authority. Candidate output is compared exactly against an independent canonical saved-sum oracle. `C++&Latina` remains a performance/cross-check baseline only.
5. The historical performance runner remaps shards 44 and 83 away from known pathological baseline inputs while preserving 10,000 distinct `(c,t)` pairs.
6. `tools/canonical_saved_sum_vector_runner.cpp` supplies the independent saved-sum reference for the 10,000-pair matrix. It constructs canonical structures using the normative reference sauce/selection and the already-audited fast weaving reference.

## Tests actually run locally for R2

- YAML parse: PASS for all three modified workflows.
- Patch40 direct probe: `PATCH40_EXSEQUIAE_REIECTIONIS_LATAE=PASS hits=2`.
- Candidate vs independent canonical oracle, 100 pairs each:
  - shard 0: `100/100_MATCH`
  - shard 44: `100/100_MATCH`
  - shard 83: `100/100_MATCH`
- Pair-generation uniqueness: `10000/10000` distinct `(c,t)` pairs.
- Earlier during preparation, before the final verification pass, shards 50 and 99 also matched the independent oracle for 100/100 pairs. The final combined verification command hit its local 120-second execution limit before re-running shard 99, so that final re-run is not claimed as a fresh PASS.
- Base Git blob verification: the five modified pre-existing files matched the current branch content inherited by `1f4ab5e...`; the new canonical runner is absent from the base HEAD as expected.

## Prepared but not run here

These require the uploaded R2 branch / GitHub runner environment and are therefore intentionally **not** recorded as PASS:

- the complete 100-shard / 10,000-pair GitHub Actions matrix with the new independent oracle;
- the complete long soak workflow after the R2 witness repairs;
- the live HTTP workflow after its R2 witness repair;
- the final performance verdict against historical `C++&Latina` across all available baseline shards.

## Historical evidence policy

Old raw-sum logs and witnesses are not deleted or rewritten as if they had never existed. Where retained, they are historical evidence only and do not override the canonical saved-sum semantics.
