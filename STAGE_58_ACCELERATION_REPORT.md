# Stage 58 — remembered acceleration scars

## Intent

Stage 58 es un layer de performance **pos** li archaeology existent. Li public `package.json` version resta intentionalmen `0.0.57-stage-57-corrective`, pro conservar li observable compatibility contract verificat per li suite historic. It ne rescri null Discovery, null Patch e null Stage 54/56/57. Li rule es intentional: quand un calcul historic es custosi, li old route resta executable e Stage 58 memora su intermediates, checkpoints o backends por evitar repetir li sam dolor computational.

Li API public resta identic: `calendarDateSpaghetti(calculationDay,targetDay)` e `calendarDateSpaghettiWithContext(calculationDay,targetDay)` continua retornar li sam quin fields semantic. Li routes historic Stage 55/56 resta exportat separatmen.

## Bottlenecks observat

1. `Stage54GateRegistry` expandeva gates sequentialmen e chascun gap demandava sauce + selection.
2. Li year resolver recomensava desde Year 5000 e reconstruiva adjacent years ja conosset.
3. `sauceWithScars*` repetiva sauce por inputs exact egal; Patch 11 duplicava 46 drops + 12 post-stirs por conservar li scar.
4. `VirtualLegacyList` e, plu gravmen, `LegalMonthWeavingDP` reconstruiva backends identic. Profiling del witness principal monstrat que `LegalMonthWeavingDP.unrank1` dominava li CPU per clones repetit de `remaining`.
5. Selection/rejection recalculava li sam deterministic stream/N in ghosts semanticmen repetit.
6. Li cache historic de structure resta intentionalmen keyed solmen per `year.number`; Patch 19 deve continuar guardar it.

## Layers adjunt

- `Stage58BoundedRememberingScar`: LRU-like scar con eviction explicit.
- `Stage58WeakRememberingScar`: weak-valued scar; si `WeakRef` ne existe in li runtime, li optimization es silentmen desactivat invez de mutar semantics o impedir module-load.
- `Stage58SharedGateCheckpointScar`: gates e gaps remembered per sauce-provider, con 4096 slots per table. Li `Stage54GateRegistry` individual continua materialisar su propri Map sequentialmen.
- `Stage58RememberedYearDetourManager`: Year 5000, adjacent transitions e bounded anchors. Forward e backward histories es separat, nam adjacent-year construction ne es invertibil.
- Sauce memories separat por Stage 54 e Stage 56; generation-tag guards conta eventual mismatch invez de mixturar resultates.
- Patch-11 remembered replay: li traversal legacy real es executet; li traversal semantic duplicat usa scars ja productet invez de recalcular 46 drops + 12 post-stirs.
- Weak backend reuse por `VirtualLegacyList` e `LegalMonthWeavingDP`.
- `unrank1Stage58RememberedTraversal`: sibling del `unrank1` historic; usa li sam `_legalMove` e `_countCompletions`, ma muta temporalmen un slot e fa rollback invez de clonar `remaining` por chascun candidate.
- Exact selection/rejection memo con 4096 entries; li dispatcher legacy resta intact.
- Full-fingerprint semantic structure cache de 32 entries **supra** li cache historic bad-key. Li bad-key lookup e Patch 19 guard continua esser executet/observabil.

## Invariants ne ruptet

- Null `BigInt` es convertet a `Number` por li semantics.
- `oldJumpGuess` resta diagnostic, ne authority.
- Sequential gate expansion e `findYearByWalkPatch` resta li algorithms historic.
- Stage 54, 56 e 57 conserva registries/managers separat.
- `legacyStage54Patch26RoundTripGuard`, li Stage 57 ghost e li Stage 56 historic failure witness resta activ.
- Li bad key `year.number` ne es correctet in loco.
- `sauceWithOrderAt46Latch`, `selectionDispatcherWithWideDetour`, `LegalMonthWeavingDP.unrank1` e li constructors historic resta exportat e executable.
- Null API public o shape del five-field result es cambiat.

## Benchmark

Environment: Node.js v22.16.0. Li table usa single-run engineering measurements sur li sam host; it ne pretende esser un statistical microbenchmark. Warm scenarios usa li sam Stage 57 manager; li far-retro e routes historic es process-isolat por evitar pressure de V8 del witness precedent.

| Scenario | Ante Stage 58 ms | Stage 58 ms | Speedup | Reduction | Canonical |
|---|---:|---:|---:|---:|---|
| Stage 57 cold single | 20371.367 | 15732.753 | 1.29× | 22.8% | PASS |
| Stage 57 identical repeat | 4.205 | 0.705 | 5.96× | 83.2% | PASS |
| Sam year, target +1 | 3.837 | 0.321 | 11.95× | 91.6% | PASS |
| Sam year, target -1 | 3.776 | 0.221 | 17.09× | 94.1% | PASS |
| Sam calculation-day, +2500 | 3.961 | 0.413 | 9.59× | 89.6% | PASS |
| Neighbor year retro, -2500 | 7994.777 | 5664.486 | 1.41× | 29.1% | PASS |
| Far avante, +12000 | 4695.496 | 3571.076 | 1.31× | 23.9% | PASS |
| Far retro, -12000 (fresh process) | 28517.259 | 22675.463 | 1.26× | 20.5% | PASS |
| Stage 54 historic cold | 27575.810 | 22555.254 | 1.22× | 18.2% | PASS |
| Stage 56 historic cold | 19090.659 | 16363.735 | 1.17× | 14.3% | PASS |

Omni 10 comparationes conserva exactmen li sam canonical five-field result.

### Cache/reuse evidence

Sur li Stage 57 cold witness `c=t=-15048173` li route Stage 58 fa 28 sauce computations e 26 gate-gap computations, quam li old route, ma evita li duesim heavyweight DP backend: un `LegalMonthWeavingDP` backend miss + un backend hit. Li fast unrank usa li remembered backend.

Sur li identical repeat, li wall-clock cade a sub-millisecond range, con `year5000Hits=1` e `semanticStructureHits=1`; null sauce, null gate-gap e null DP construction es necessi.

Sur li neighbor retro `-2500`, li route fa solmen 3 sauce computations, un gate-gap e un adjacent-year build. Sur far avante `+12000`, 4 adjacent-year builds es registrat e 4 selection-cache hits es observat.

Li probe special de gates materialisa 26 gates in du registries distinct. Li unesim registry: 26 `gateGap` computations in 115.371 ms. Li duesim registry del sam sauce generation: **0** `gateGap` computations, **26** checkpoint hits e 0.151 ms, durante que su propri legacy `Map` ancor contene 27 cells.

Li sauce probe Stage 56 sur un exact input repetit: 20.373 ms al miss, 0.222 ms al live weak-cache hit; bowls concorda exactmen e `stage58MemoryReplay=true` es explicit.

Li test Stage 58 anc include un short-selection witness con rejection real: li unesim execution conta li rejection iteration; li duesim exact stream/N usa li remembered result e conta ti iteration quam evitabil. Li ordinary benchmark witnesses supra happen haver zero rejection iterations, quel es un measurement real e ne un omission.

## Memory tradeoff

Caches fort es bounded:

- gate days: 4096 per provider;
- gate gaps: 4096 per provider;
- adjacent-year transitions: 1024;
- Year 5000 records: 64;
- authoritative year histories: 16 calculation-days, max 128 records per history;
- semantic structures: 32 per manager;
- selections: 4096;
- stone table: un snapshot.

Heavy values usa weak ownership: Stage 54 sauce 128 key slots, Stage 56 sauce 128, Virtual DP 8, weaving DP 8. Ti limits cap li key scars; li heavy values posse esser collectet.

Li memory probe `node --expose-gc tests/stage-58-memory.js` sur li cold Stage 57 witness monstrat `heapUsed` circa 399.3 MB immediatmen pos li call, ma circa 5.0 MB pos un event-loop turn + GC; weak live values deven zero. Li RSS resta alt (~470 MB) pro que V8 conserva reserved heap pages. Ergo Stage 58 ne elimina li intrinsic peak del combinatorial DP, ma it ne reten ti centenes de MB quam permanent strong cache.

## Verification

`tests/stage-58-acceleration.js` verifica:

- historical Patch-11 sauce contra remembered replay;
- Stage 54/56 sauce-generation separation e live weak hits;
- short, real-rejection e wide selection equivalence;
- Virtual DP backend reuse;
- exhaustive equivalence de `unrank1Stage58RememberedTraversal` contra `unrank1` por omni **1301** ranks de `[4,4,4]`;
- shared gate checkpoints inter du registries sin eliminar lor local Maps;
- direction-tagged year anchors.

Li regression suites de Patch 11/13/14/19/23/24/26, Stage 54 integration, Stage 56 corrective/reference e Stage 57 corrective/reference/historic scar resta GREEN. Li Stage 55 E2E e cross audits anc resta GREEN.

## Bottlenecks conservat intentionalmen

- Li unesim cold structure build continua heavyweight: `LegalMonthWeavingDP` deve computar su exact combinatorial state-space.
- Gate registries continua materialisar local cells sequentialmen, mem si checkpoints rende lor valori quasi gratuit in a nov registry.
- Year traversal continua conceptualmen per adjacent-year transitions; checkpoints cambia solmen li start/reuse, ne li authority.
- Li duplicated ghosts, legacy structure cache, Stage 56 historical sauce e Patch 26 round-trip scar continua existir.
- V8 heap peak durant un large DP resta significativ. Eliminar it exigerea un plu radical representation rewrite, quel ne es justificat sub li artistic compatibility rule de ti linea.

## Raw evidence

- `artifacts/STAGE_58_BASELINE_BENCHMARK.jsonl`
- `artifacts/STAGE_58_AFTER_BENCHMARK.jsonl`
- `artifacts/STAGE_58_BENCHMARK_REPORT.json`
- `artifacts/STAGE_58_GATE_CHECKPOINT_PROBE.json`
- `artifacts/STAGE_58_SAUCE_PROBE.json`
- `artifacts/STAGE_58_MEMORY_PROBE.json`


## Final compatibility revalidation

Durante li final split-run del historic suite, `verify-stage-01.js` detectet du regressiones metadata creat per li unesim packaging draft: li public package version esset incrementat e `CURRENT_STAGE` esset mutat a 58. Ti changes esset observable compatibility changes, ne performance changes. Ili ne esset "fixat" per mutar li test historic. Invez, li public version esset restituit a `0.0.57-stage-57-corrective` e `CURRENT_STAGE=57` / `LAST_COMPLETED_STAGE=57` resta intact. Li Stage58-named classes e report es explicitmen un post-Stage-57 acceleration scar, ne un replacement del authoritative Stage 57 state.

Pos ti correction, omni constituent del `npm test` chain passat in split runs: base tests, Stage-01 verifier, Discoveries/Patches 01..26, Integration 54, Stage 55 core/E2E/cross, Stage 56 corrective/Foundation/near-Foundation/reference, Stage 57 corrective/reference/historical-scar e Stage 58 acceleration. Li split execution es usat solmen por evitar command timeout; null failed assertion resta.
