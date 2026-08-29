# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium Gradum 11 evolutionis continet. Linea implementationis ab initio condita est ex solo specimine normativo in mandato incluso. Nulla implementatio aliena, nullum output alienum, nullus hash alienus et nulla probatio differentialis trans implementationes adhibita est.

## Status praesentis gradus

Gradus 11 est `PATCH 05`. Repositio retrograda septem guttarum occultarum ex Gradu 10 consulto integra manet. `buildHiddenWithBackwardStorage(calculationDay, targetDay, stones)` adhuc valores physice ordine `hidden7, hidden6, ..., hidden1` servat.

Correctio non vertit seriem et non mutat storage. Addita est functio:

```text
hiddenByNearness(backwardStorage, k)
```

Ea `k` inter 1 et 7 requirit, deinde locum unum-basatum `8-k` computat et ex repositione retrograda legit. Ita omnis lectio semantica guttae occultae per proximitatem transit per mapping historicum, dum layout vetus physice idem manet.

Via auctoritative huius gradus transit per:

```text
BaseMonsterManager::executeHiddenDrops
-> BaseDispatcher::dispatchPatchedHiddenStorage
-> Patch05HiddenStorageHandler
-> LegacyHiddenStorageAdapter
-> buildHiddenWithBackwardStorage              [storage retrogradum manet]
-> Patch05HiddenNearnessWrapper
-> hiddenByNearness                            [slot = 8-k]
-> patchedHiddenNearness                       [visio semantica 1..7]
```

Via diagnostica `executeUnpatchedHiddenStorageDiagnostic` adhuc `Discovery05HiddenStorageHandler` exercet et eandem seriem retrogradam sine mapping exponit.

## Quid regressiones demonstrant

`tests/stage_10_discovery_05_tests.cpp` eadem septem inputs et eadem expected values normativi servat. Gradus 10 eam initio ita scripserat ut sex discrepantias expresse requireret; talis clausula regressionem post patch viridem fieri vetabat. Condicio exitus igitur ad formam historicam correctam mutata est:

- sex discrepantiae significant vitium Gradus 10 et exitum `1`;
- nullae discrepantiae significant correctionem PATCH 05 et transitum;
- alius numerus discrepantiarum est defectus inopinatus.

Forma correcta contra codicem Gradus 10 pristinum iterum currens exactas sex discrepantias et exitum `1` produxit. Ergo expected values, storage audit et vis defectus non debilitata sunt.

Post PATCH 05 eadem regressio transit omnibus septem guttis. Probatio nova `tests/stage_11_patch_05_tests.cpp` praeterea demonstrat:

- `legacyOutput[8-k]` adhuc exactum valorem hidden `k` continet;
- `hiddenByNearness` omnibus `k=1..7` cum norma congruit;
- indices extra 1..7 reiciuntur;
- via auctoritative signum `patch05Applied` servat;
- via diagnostica sine patch sex discrepantias veteres adhuc exhibet.

## Cicatrix legacy et stratum monstri

Gradus 11 addit `patchedHiddenNearness`, `patch05Applied`, `Patch05HiddenNearnessWrapper`, `Patch05HiddenStorageHandler`, validationem `requirePatch05Ready`, dispatchationem patch separatam et viam diagnosticam legacy. `legacyHiddenBackward` non convertitur, non reordinatur et non superimponitur.

Validator mapping `8-k` iterum computat ut invariantiam confirmet; non vocat oracle et non eligit inter responsiones diversas. Omne state semanticum contextui invocationis proprium manet.

## Quod consulto nondum adest

Nullum codicem DISCOVERY/PATCH 06 introduximus. Absunt `legacyPrior`, `priorPatch`, `dropStore` et status emendationis sextae. Historia guttarum visibilium nondum constructa est.

## Lingua computationis

Omnis codex exsecutus huius lineae est C++. Integra arbitraria per `boost::multiprecision::cpp_int` tractantur. Nullus interpres externus, FFI, runtime alienus aut generator in alia lingua adhibetur.

## Catalogus linguae fontis

Catalogus Neo-Latinus in `include/pastafari/source_language_catalog.hpp` congelatus manet. Ordo normativus per `canonicalIndex` tantum definitur; textus linguae fontis non participat ranking, unranking, cache semanticum aut electionem.

## Probationes

Omnes regressiones usque ad Gradum 11 virides sunt:

```text
OMNES_PROBATIONES_BOOTSTRAP_TRANSEUNT
REGRESSIO_DISCOVERY_01_TRANSIIT
REGRESSIO_PATCH_01_TRANSIIT
REGRESSIO_DISCOVERY_02_TRANSIIT
REGRESSIO_PATCH_02_TRANSIIT
REGRESSIO_DISCOVERY_03_TRANSIIT
REGRESSIO_PATCH_03_TRANSIIT
REGRESSIO_DISCOVERY_04_TRANSIIT
REGRESSIO_PATCH_04_TRANSIIT
REGRESSIO_DISCOVERY_05_TRANSIIT
REGRESSIO_PATCH_05_TRANSIIT
```

Gradus proximus est `DISCOVERY 06`; nullum eius codicem hic gradus continet.
