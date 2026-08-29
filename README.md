# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium Gradum 15 evolutionis continet. Linea implementationis ab initio ex solo specimine normativo huius mandati aedificata est. Nulla implementatio aliena, nullum output alienum, nullus hash alienus et nulla probatio differentialis inter implementationes adhibita est.

## Status praesentis gradus

Gradus 15 est `PATCH 07`; status repository exspectatus est `GREEN`.

Vitium Gradus 14 non deletum est. Tabula legacy undecim ordines reales in locis `0..10` adhuc servat, et `legacyGrindRow(grind)` numerum semanticum `1..11` directe ut indicem physicum adhibet. Diagnosticum sine patch igitur adhuc ordines 2..11 et absentiam pro molitione 11 exponit.

Super hanc cicatricem addita est tabula separata duodecim locorum:

```text
index 0  -> [0,0,0,0,NONE]
index 1  -> [3,5,7,11,WHEAT]
...
index 11 -> [37,41,43,47,WHEAT]
```

Sentinella in indice 0 est permanens et non removenda. Indexing calleris non mutatur: molitio `g` adhuc indicem physicum `g` petit.

## Via activa

`BaseMonsterManager::executeGrindRow` transit per:

```text
BaseMonsterManager::executeGrindRow
-> BaseDispatcher::dispatchPatchedGrindIndex
-> Patch07GrindIndexHandler
-> LegacyGrindTableAdapter::read
-> legacyGrindRow                 (cicatrix vere exercetur)
-> Patch07SentinelGrindWrapper
-> grindRowWithSentinel           (idem index directus in tabula sentinella)
```

Handler primum exitum legacy servat, deinde eodem numero molitionis tabulam cum sentinella legit. `requirePatch07Ready` COPY_VALIDATION separatim repetit lectionem tabulae sentinellae et confirmat exitum patch; oracle testium in productione non vocatur.

`executeUnpatchedGrindDiagnostic` viam Gradus 14 adhuc exercet.

## Regressio Gradus 14

`tests/stage_14_discovery_07_tests.cpp` eadem undecim expected values servat. Solum printer enum habet ramum `default`, quia PATCH 07 enum technicum `NONE` addit pro sentinella. Contra codicem Gradus 14 pristinum regressio adhuc undecim discrepantias et exitum `1` producit. Contra Gradum 15 eadem regressio omnes undecim molitiones concordantes invenit.

## Regressio PATCH 07

`tests/stage_15_patch_07_tests.cpp` confirmat:

- sentinellam exactam `[0,0,0,0,NONE]` in indice 0;
- undecim ordines normativos exacte in indicibus 1..11;
- tabulam legacy 0..10 et displacementem veterem adhuc exsistere;
- viam productionis patched omnes molitiones 1..11 recte reddere;
- diagnosticum sine patch exitum legacy non occultare.

Omnes regressiones Graduum 1–15 transeunt.

## Quod consulto nondum adest

Nullus `oldPermutationUnrank0`, nullus `Patch08`, nullus detour rank et nulla logica permutationis Gradus 16 introducta est.

## Lingua computationis

Omnis codex exsecutus huius lineae est C++. Integra arbitraria per `boost::multiprecision::cpp_int` tractantur. Nullus interpres externus, FFI, ambitus exsecutionis alienus aut generator in alia lingua adhibetur.

## Catalogus linguae fontis

Catalogus Neo-Latinus in `include/pastafari/source_language_catalog.hpp` congelatus manet. Semantica ordinis per `canonicalIndex` tantum definitur; textus presentationis computationem non mutat.
