# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium Gradum 25 evolutionis continet. Linea implementationis ab initio ex solo specimine normativo mandati aedificata est. Nulla implementatio aliena, nullus exitus alienus, nulla summa cryptographica aliena et nulla probatio differentialis inter implementationes adhibita est.

## Status praesentis gradus

Gradus 25 est `PATCH 12`; status repositorii exspectatus est `GREEN`.

Gradus 24 cicatricem `oldNextBowlFixedName(id)` exposuit: helper vetus IDs craterum per annulum numericum fixum sequitur et `orderAt46Latch` ignorat. Gradus 25 hunc helper non delet nec mutat. Via reparativa eum prius realiter vocat et output eius legacy servat; deinde queried ID intra latch Gradus 23 invenit et successorem circularem eius positionis reddit.

## PATCH 12 — successor circularis intra orderAt46Latch

Cicatrix historica intacta manet:

```text
oldNextBowlFixedName(id)
1 -> 2
2 -> 3
3 -> 4
4 -> 5
5 -> 6
6 -> 1
```

Helper novus semanticus est:

```text
nextBowlThroughOrderAt46Latch(orderAt46Latch, queriedBowlId)
```

Primum queried ID intra sex positiones latch quaerit. Deinde elementum proximum reddit; si ID in ultima positione est, index circulariter ad primam positionem redit. IDs extra 1..6 reiciuntur, et absentia ID intra latch invariantiam violat.

## Via activa

```text
BaseMonsterManager::executeLegacyNextBowl
-> BaseDispatcher::dispatchPatchedOrderAt46Latch
-> Patch11OrderAt46LatchHandler
-> orderAt46Latch semel scriptum
-> BaseDispatcher::dispatchPatchedNextBowl
-> Patch12NextBowlHandler
-> LegacyNextBowlAdapter::nextFixedName
-> oldNextBowlFixedName
-> Patch12NextBowlWrapper::repair
-> nextBowlThroughOrderAt46Latch
```

`Patch12NextBowlHandler` servat `legacyNextBowlOutput` ante correctionem, memorat positionem queried crateris intra latch, deinde `patchedNextBowlOutput` e successore circulari format. `requirePatch12Ready` iterum sine oracle productionis comprobat helper legacy intactum, latch a Patch 11 servatum, positionem repertam et output circularem rectum.

Via separata `executeUnpatchedNextBowlDiagnostic` Patch 11 parat sed deinde solum `Discovery12NextBowlHandler` et `oldNextBowlFixedName` exsequitur. Sic cicatrix Gradus 24 physice et exsecutabiliter manet.

## Regressiones

`tests/stage_24_discovery_12_tests.cpp` non mutatus est. Contra codicem Gradus 24 pristinum adhuc tres discrepantias exactas et exitum `1` reddit. Contra Gradum 25 eadem probatio transit pro omnibus sex IDs.

`tests/stage_25_patch_12_tests.cpp` separatissime comprobat:

- annulum numericum legacy exactum 1→2→3→4→5→6→1;
- viam diagnosticam unpatched quae eundem output legacy servat;
- viam activam PATCH 12 pro omnibus sex IDs;
- positionem queried ID intra latch;
- wrap ab ultima positione ad primam;
- rejectionem IDs 0 et 7;
- tres cicatrices legacy divergentes in witness Fundationis.

Pro Fundatione latch est `[4,5,2,3,6,1]`. ID 1 in positione sexta est; output correctus est 4, id est prima positio latch.

Omnes regressiones Graduum 1–25 transeunt.

## Quod consulto nondum adest

Nullus `biasedLegacyPick`, nullus rejection ante electionem, nullus `Patch13`, nullus `patch13Applied`, nullus `wideDetour` et nullus codex posterior additus est. Gradus 26 debet esse `DISCOVERY 13` tantum.

## Lingua computationis

Omnis codex exsecutus huius lineae est C++. Integra arbitraria per `boost::multiprecision::cpp_int` tractantur. Nullus interpres externus, FFI, ambitus exsecutionis alienus aut generator in alia lingua adhibetur.

## Catalogus linguae fontis

Catalogus Neo-Latinus in `include/pastafari/source_language_catalog.hpp` congelatus manet. Semantica ordinis per `canonicalIndex` tantum definitur; textus presentationis computationem non mutat.
