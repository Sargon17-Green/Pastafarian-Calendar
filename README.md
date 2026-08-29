# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium Gradum 24 evolutionis continet. Linea implementationis ab initio ex solo specimine normativo mandati aedificata est. Nulla implementatio aliena, nullus exitus alienus, nulla summa cryptographica aliena et nulla probatio differentialis inter implementationes adhibita est.

## Status praesentis gradus

Gradus 24 est `DISCOVERY 12`; status repositorii exspectatus est `EXPECTED_RED`.

Gradus 23 ordinem guttae 46 in `orderAt46Latch` semel scripto servavit. Gradus 24 hunc latch rectum non mutat. Vitium novum in ipsa quaestione next-bowl introducitur: helper legacy non quaerit positionem crateris interrogati in latch, sed successor numericum fixum per IDs craterum adhibet.

## DISCOVERY 12 — successor numericus fixus crateris

Cicatrix nova est:

```text
oldNextBowlFixedName(id)
1 -> 2
2 -> 3
3 -> 4
4 -> 5
5 -> 6
6 -> 1
```

`oldNextBowlFixedName` nullum `orderAt46Latch` accipit et nullam positionem quaerit. `LegacyNextBowlAdapter` hunc helper directe vocat.

Via activa tamen prius Patch 11 vere exsequitur. Eodem `BaseMonsterContext` primum `dispatchPatchedOrderAt46Latch` currit, quo latch unius scripturae paratur. Deinde `dispatchLegacyNextBowl` ad `Discovery12NextBowlHandler` transit. Handler latch validum in contextu servat, sed adapter legacy solum `queriedBowlId` videt.

## Via activa

```text
BaseMonsterManager::executeLegacyNextBowl
-> BaseDispatcher::dispatchPatchedOrderAt46Latch
-> Patch11OrderAt46LatchHandler
-> orderAt46Latch semel scriptum
-> BaseDispatcher::dispatchLegacyNextBowl
-> Discovery12NextBowlHandler
-> LegacyNextBowlAdapter::nextFixedName
-> oldNextBowlFixedName
```

`requireLegacyNextBowlReady` comprobatur Patch 11 iam applicatum esse, latch exactissime semel scriptum esse, latch in Discovery 12 non mutatum esse, et output legacy e successore numerico fixo provenire. Nullus oracle testium in productione vocatur.

## Regressio

Pro Fundatione, latch realis a via Patch 11 est:

```text
[4,5,2,3,6,1]
```

Successor circularis huius latch et successor numericus fixus comparantur pro omnibus sex crateribus interrogatis. Tres casus accidentaliter concordant et tres discrepant:

```text
queried 1: normativus 4, legacy 2
queried 2: normativus 3, legacy 3
queried 3: normativus 6, legacy 4
queried 4: normativus 5, legacy 5
queried 5: normativus 2, legacy 6
queried 6: normativus 1, legacy 1
```

Ergo regressio Gradus 24 consulto exitum `1` reddit cum tribus discrepantiis exactis. Eadem probatio cicatricem directam separatim servat, ita ut PATCH 12 postea possit output activum corrigere sine `oldNextBowlFixedName` delendo.

## Probationes

Omnes regressiones Graduum 1–23 denuo compilatae sunt contra header et productionem Gradus 24 et omnes transeunt. `tests/stage_24_discovery_12_tests.cpp` solum est rubrum exspectatum.

## Quod consulto nondum adest

Nullus lookup positionis `queriedBowlId` intra `orderAt46Latch`, nullus successor circularis productionis, nullus `Patch12`, nullus `patch12Applied`, nullus `NextBowlPatchWrapper` et nullus `biasedLegacyPick` additus est. Gradus 25 debet esse `PATCH 12` tantum.

## Lingua computationis

Omnis codex exsecutus huius lineae est C++. Integra arbitraria per `boost::multiprecision::cpp_int` tractantur. Nullus interpres externus, FFI, ambitus exsecutionis alienus aut generator in alia lingua adhibetur.

## Catalogus linguae fontis

Catalogus Neo-Latinus in `include/pastafari/source_language_catalog.hpp` congelatus manet. Semantica ordinis per `canonicalIndex` tantum definitur; textus presentationis computationem non mutat.
