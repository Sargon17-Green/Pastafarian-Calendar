# Stage56 — external canonical source provenance (QA-only)

PROJECT_ID: PC-BRANCH-PHP-MALAY
Scope: source identification, context binding and reproducible external reference export. This is not a new stage, not a PHP production provider, not a B5 real-year profile, and not Stage56 acceptance.

## Independently inspected inputs (2026-11-21)

- PHP feature branch: `Sargon17-Green/Pastafarian-Calendar`, `PHP+Bahasa-Melayu`, HEAD `597b4bfe58cdedd33b31d0fabdc52ae556e259bf` at inspection. Its complete `src/` inventory has `YearStructureSlices56`, the weaving counter/ranker, and `DateTuplePatch23`, which invokes an injected `yearStructureProvider`. No autonomous PHP production year-structure provider or immutable anchor exporter was identified.
- Independent public canonical reference: `Sargon17-Green/pastafari-calendar`, `main` at `cc2cf0b422757a5e7c33218ce30cffa8f99c6786` at inspection. Python `implementations/python/pastafari_calendar/core.py` Git blob SHA-1 `e99f6a6b2413bed2f972ef24360a466df59e34cd` contains `CalculationState.get_year_5000`, `previous_year`, `next_year`, `get_structure`, and `build_year_structure`. JavaScript `browser/pastafari-calendar-fast.js` Git blob SHA-1 `014eca6908ed726c6c760204580bf18119015bbc` contains `getYear5000` and `buildYearStructure`.
- Both independent public-source implementations compute Year5000 from the **calculation day**. For Python, `get_year_5000()` enumerates candidates at `calculation_jdn` and selects with `get_sauce(calculation_jdn)`. The JS implementation likewise calls `enumerateYear5000Candidates(this.calculationJdn)` and chooses with `getSauce(this.calculationJdn)`. There is no context-free, globally unique Year5000 anchor. A claim of a universal constant anchor would be incorrect.
- External Python `Year.start_jdn` is the first included day (opening gate + 1); the PHP B5 input's `open_gate_day` denotes the exclusive opening gate. Hence the exporter uses `start_jdn - 1`. The external Python weaving uses zero-based month IDs; the exporter explicitly changes them to 1-based IDs. Neither conversion makes Python into the PHP production source.

## Work product and trust boundaries

`tools/stage56_export_external_canonical_reference.py` exports one *reference scenario* for years 4999, 5000 and 5001 from a clean, exact-commit checkout of the external canonical Python implementation. It requires explicit `--calculation-jdn`, `--source-commit`, `--canonical-repo`, and `--output`. It verifies remote origin, exact HEAD, clean checkout, Git committed-byte identity against on-disk source, Git blob SHA-1 and SHA-256 for both Python and JS, year-boundary adjacency, month lengths and 1-based first/last occurrence invariants. Output JSON is deterministic, contains full context/source metadata and an anchor digest, and is pinned by an out-of-band `.sha256` companion file.

Its `source.kind` is deliberately `external_canonical_reference`, and its status is `EXTERNAL_REFERENCE_NOT_PHP_PROVIDER`. The existing PHP B5 preflight intentionally rejects it as a production provider export. Never relabel the JSON, invent `src/*.php` authorship, or use the external file as a substitute for verified PHP provider output. Inspecting two implementations is not a completed JS-versus-Python semantic differential.

Reference invocation on an independently obtained **separate clean checkout** of the pinned canonical commit (output outside the checkout):

```sh
timeout 3600s python3 tools/stage56_export_external_canonical_reference.py \
  --canonical-repo /path/to/clean/canonical-checkout \
  --source-commit cc2cf0b422757a5e7c33218ce30cffa8f99c6786 \
  --calculation-jdn=-13334246 \
  --output /outside-checkout/stage56-canonical-reference.json
```

`-13334246` is the Python engine's `FOUNDATION_JDN`, chosen only as an explicit reproducible example, **not** as a universal calendar anchor. The bound of 3600 seconds applies to this external-reference extraction example only; it does not replace the separate 900-second external timeout and 512MiB limit for each of the three PHP B5 profiles. Capture real exit codes, stdout/stderr, time, output SHA and source bytes. Never mark export or profile PASS before observing them.

## Actual verification performed now

- GitHub connector: branch HEAD matched the tracker; prior B5 run `44811159245` had 30/30 completed/success jobs on that SHA; dedicated B5 job `136547739055` completed/success. No duplicate run or full-year profile was dispatched.
- Local Python: `py_compile` succeeded on this new tool. `--help` completed. Deliberately nonexistent canonical checkout was rejected with exit code 2 and did not produce JSON. No genuine 4999/5000/5001 export or Native execution is claimed.
- B5 remains synthetic-preflight accepted only. Year source provenance for the **PHP** production path remains unverified; no cutlet/month weaving performance bound on actual years is demonstrated. No PATCH22/PATCH23 integration, main merge, or publication.

## Next authorized gate

1. Review and independently test the external Python versus JavaScript semantics for an explicitly bound `calculation_jdn`; execute the source-commit-locked external reference exporter with actual output/exit/log/sha evidence.
2. Implement or authenticate an **independent PHP production** YearStructureProvider plus the same calculation-day-bound Year5000 anchor; keep the PHP source's Git bytes and source commit pinned. Do not copy or line-translate the reference implementations.
3. Produce genuine PHP source-bound year exports (not the external reference), verify source bytes and anchor independently, and only then run 4999/5000/5001 PHP8.3/64 count/rank/unrank processes separately at 900s/512MiB with full artifacts.
