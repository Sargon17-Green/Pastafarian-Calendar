# Canonical saved-sum correction — CI follow-up and closure evidence

Date: 2026-09-11  
Repository: `Sargon17-Green/Pastafarian-Calendar`  
Branch: `Celeritas-per-Sepulcra`  
Closure-preparation base HEAD: `d8903923bbc7d93545830e301dc2d68013b1c56d`  
Canonical production correction parent: `53772e13ed6d25d20164bc4f903b930bca8531f0`  
Generation-4 hot-cache commit: `1f4ab5e001d7578093846dc4cae981aa21654538`

## Scope

The canonical Stage 56 production correction uses the saved stirring-order number
`R = SAVE(S + 149*r)` both for permutation selection and as the additive operand
inside `u`. The raw-bowl-sum variant is historical/test-only and is not active
production semantics.

R2 did not change that production algorithm. It repaired CI assumptions and
historical witnesses that were exposed after the semantic correction. This
closure update changes status/evidence documentation only; it introduces no
new stage and no production, workflow, or test algorithm change.

## Historical CI observations after the production correction

At `53772e13ed6d25d20164bc4f903b930bca8531f0` the hot-cache/atlas workflow
completed successfully, while three other workflows exposed stale raw-sum-era
CI assumptions: Foundation assertions in HTTP, one nearby acceleration witness,
and a Patch40/public-path plus historical-baseline design assumption in the
10,000-pair comparison.

The later 100-shard log bundle from
`1afa327ce6e84602c75ed670f8aa6f8cdff34f0f` predated the corrected production
`src/monster.cpp`; its failures were therefore not treated as evidence against
the corrected production implementation. They were useful for identifying the
obsolete requirement that candidate output be semantically identical to the
historical `C++&Latina` branch.

## R2 corrections

1. HTTP Foundation assertions use the canonical saved-sum witness
   `[5000,10,503,20,56]`.
2. The acceleration witness for `c=-15048173, t=-15048172` uses
   `[5000,17,457,36,84]`.
3. Patch40 retains two deterministic direct `+1/-1` adversarial shortcut tests;
   the obsolete Shard-83 public-path witness is no longer a mandatory route.
4. The 10,000-pair workflow compares production exactly against an independent
   canonical saved-sum oracle. Historical `C++&Latina` remains only a
   performance/cross-check baseline.
5. Historical baseline pathological shards 44 and 83 are remapped while the
   generated set remains 10,000 distinct `(c,t)` pairs.
6. `tools/canonical_saved_sum_vector_runner.cpp` supplies the independent
   saved-sum reference used by that matrix.

## Local verification performed before upload

- YAML parse: PASS for all three R2-modified workflows.
- Patch40 direct probe: `PATCH40_EXSEQUIAE_REIECTIONIS_LATAE=PASS hits=2`.
- Candidate vs independent canonical oracle: 100/100 matches for shards 0, 44,
  and 83; shards 50 and 99 also matched 100/100 during preparation.
- Pair-generation uniqueness: `10000/10000` distinct `(c,t)` pairs.
- A final combined local command reached the environment's 120-second limit
  before repeating shard 99; that interrupted repeat was never represented as
  a fresh PASS.

## GitHub verification after R2 upload

The complete R2 branch was present at
`d8903923bbc7d93545830e301dc2d68013b1c56d`. The relevant GitHub Actions runs
then completed successfully:

- `Cicatrix HTTP Celeritas v1`, run `34593183275`: **SUCCESS**. The HTTP unit
  suite passed, the real server built, the canonical Foundation witness passed,
  health/busy/async transport paths passed, and the implicit Kisurra/Venus
  low-memory smoke stayed below its configured 450 MB ceiling.
- `Vigilia diuturna — C++ + Latina Nova`, run `34593183324`: **SUCCESS**. The
  final verdict recorded success for tree/provenance guard, historical
  regressions, Stage 55 audit, Stage 56 gcc/clang O1/O2/O3 matrix, acceleration
  scars, canonical differential checks, ASan+UBSan, and the repeated soak. Its
  final log emitted `VIGILIA_SOAK=PASS` and `STATUS_POST_RUN=SOAK_GREEN`.
- `Comparatio decem milium — canon saved-sum + celeritas`, run `34593183271`:
  **SUCCESS**. Candidate semantics were gated by the independent saved-sum
  oracle; the historical branch remained a performance/cross-check baseline.
  The Patch40 build-time probe also passed with exactly two direct hits.

## Generation-4 hot cache and atlas

`Sepulcra calida et atlas annorum`, run `34585290224`, completed successfully
from the canonical correction commit. All eight atlas shard jobs and the
finalizer passed. The finalizer composed generation 4 with:

- base engine day `739870`;
- eight shards;
- coverage `50000` days behind and `300000` days ahead;
- calculation days `C` and `C+1`;
- `165` compiled almanac entries.

The finalizer also passed the HTTP suite, `HOT_ATLAS_BROWSER_WITNESSES=PASS`,
and `GENERATED_CACHE_BEFORE_BUSY=PASS`, then committed the generated two-day
seed and year-almanac as
`1f4ab5e001d7578093846dc4cae981aa21654538`.

## Closure disposition

The saved-sum semantic correction and its CI follow-up are confirmed green.
No further production correction is known or prepared, `NEXT_STAGE=NONE`, and
Stage 57 was not created. The repository-transfer files `DELTA_README.md`,
`DELTA_MANIFEST.json`, and the R2-only `SHA256SUMS.txt` are transfer artifacts,
not final repository-signing material; the closure package removes them.

After the documentation-only closure commit is applied, the next action is to
create the final branch release/tag and external release manifests covering the
actual closure HEAD.

## Historical evidence policy

Old raw-sum logs and witnesses are not rewritten as if they never existed.
Where retained, they are historical/superseded evidence only and do not
override the canonical saved-sum semantics.
