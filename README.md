# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium Gradum 17 evolutionis continet. Linea implementationis ab initio ex solo specimine normativo huius mandati aedificata est. Nulla implementatio aliena, nullus exitus alienus, nulla summa cryptographica aliena et nulla probatio differentialis inter implementationes adhibita est.

## Status praesentis gradus

Gradus 17 est `PATCH 08`; status repositorii exspectatus est `GREEN`.

Vitium Gradus 16 manet physice intactum. `oldPermutationUnrank0(rank0)` adhuc solum rank zero-based `0..719` accipit. Via diagnostica veterem errorem adhuc demonstrat: ordinalis one-based 1 directe ut rank0 1 permutationem sequentem legit, et ordinalis 720 tamquam rank0 720 reicitur.

Correctio auxiliatorem legacy non mutat. Additur catena praescripta:

```text
oneBased = regularMod(drop-1,720)+1
legacyRank0 = oneBased-1
order = oldPermutationUnrank0(legacyRank0)
```

## Via activa

`BaseMonsterManager::executePermutationOrder` nunc ad `executePermutationFromDrop` delegat. Via emendata transit per:

```text
BaseMonsterManager::executePermutationFromDrop
-> BaseDispatcher::dispatchPatchedPermutationRank
-> Patch08PermutationRankHandler
-> LegacyPermutationAdapter::unrank0            [vocatio legacy prior]
-> Patch08PermutationRankWrapper::resolve
-> regularMod(drop-1,720)+1
-> legacyRank0 = oneBased-1
-> LegacyPermutationAdapter::unrank0
-> oldPermutationUnrank0
```

`Patch08PermutationRankHandler` primum exitum legacy pravum re vera computat et in relatione retinet. Deinde `Patch08PermutationRankWrapper` eundem `drop` ad ordinalem one-based canonicum redigit, unum subtrahit et auxiliatorem zero-based iterum vocat. `executeUnpatchedPermutationDiagnostic` viam Gradus 16 separatam conservat.

## Regressio DISCOVERY 08

`tests/stage_16_discovery_08_tests.cpp` immutatus manet. Contra Gradum 16 pristinum quinque discrepantias et exitum `1` reddit. Contra Gradum 17 eadem quinque ordines `1`, `2`, `3`, `719`, `720` recte recipiunt et regressio transit.

Hoc confirmat patch productionis, non mutatio valores exspectatos, defectum sanavisse.

## Regressio PATCH 08

`tests/stage_17_patch_08_tests.cpp` separat:

- cicatricem `oldPermutationUnrank0(0..719)` et reiectionem rank0 720;
- viam diagnosticam sine patch pro ordinalibus 1 et 720;
- catena exacta `drop -> oneBased -> legacyRank0 -> oldPermutationUnrank0`;
- reductionem modularem pro `drop=721`, `drop=0`, `drop=-1` et `drop=1441`;
- conservationem exitus legacy ante patch in relatione;
- signum `patch08Applied` et indices emendati observabiles.

Omnes regressiones Graduum 1–17 transeunt.

## Quod consulto nondum adest

Nullus `bowlAlias`, nullus `Patch09`, nullus status `patch09Applied`, nulla logica fusionum et nulla lectio crateris per positionem alias introducta est. Gradus 18 nondum incohatus est.

## Lingua computationis

Omnis codex exsecutus huius lineae est C++. Integra arbitraria per `boost::multiprecision::cpp_int` tractantur. Nullus interpres externus, FFI, ambitus exsecutionis alienus aut generator in alia lingua adhibetur.

## Catalogus linguae fontis

Catalogus Neo-Latinus in `include/pastafari/source_language_catalog.hpp` congelatus manet. Semantica ordinis per `canonicalIndex` tantum definitur; textus presentationis computationem non mutat.
