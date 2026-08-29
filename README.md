# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium Gradum 10 evolutionis continet. Linea implementationis ab initio condita est ex solo specimine normativo in mandato incluso. Nulla implementatio aliena, nullum output alienum, nullus hash alienus et nulla probatio differentialis trans implementationes adhibita est.

## Status praesentis gradus

Gradus 10 est `DISCOVERY 05`. Correctio lapidum Gradus 9 manet integra et viridis. Novum vitium historicum nunc in septem guttis occultis introductum est: valores ipsi recte computantur, sed repositio legacy eos ordine retrogrado servat, id est `hidden7, hidden6, ..., hidden1`.

`buildHiddenWithBackwardStorage(calculationDay, targetDay, stones)` septem valores per formulas normativas huius gradus computat. Sed valor pro proximitate `k` in loco physico `8-k` ponitur. Nulla mappa accessus adhuc hanc ordinationem corrigit.

Via auctoritative huius gradus transit per:

```text
BaseMonsterManager::executeHiddenDrops
-> BaseDispatcher::dispatchLegacyHiddenStorage
-> Discovery05HiddenStorageHandler
-> buildStonesThroughLegacyBuilder             [PATCH 04 iam viridis]
-> LegacyHiddenStorageAdapter
-> buildHiddenWithBackwardStorage
-> makeHiddenLegacyValue                       [valor rectus]
-> legacyHidden[8-k]                           [repositio retrograda vitiosa]
```

Via activa Gradus 10 ipsam repositionem retrogradam quasi ordinem proximitatis exponit. Hoc consulto facit regressionem novam rubram.

## Quid regressiones demonstrant

Probatio nova `tests/stage_10_discovery_05_tests.cpp` computationem localem C++ cum `buildHiddenDrops` oraculi eiusdem lineae comparat. Eadem probatio separatim demonstrat relationem structuralem:

```text
legacyOutput[8-k] == expectedHidden[k]
```

pro omnibus septem guttis. Ergo valores non corrumpuntur; solum loci eorum invertuntur.

Cum repositio retrograda directe quasi `hidden1..hidden7` exponitur, sex positiones discrepant. Gutta media `k=4` fortuito eundem locum retinet sub inversione septem elementorum. Exitus novae regressionis est:

```text
REGRESSIO_DISCOVERY_05_DEFECIT: 6 discrepantiae normativae ex ordine retrogrado inventae sunt
```

## Cicatrix legacy et stratum monstri

Gradus 10 addit `HiddenDrops`, `legacyHiddenBackward`, `legacyHiddenBackwardReady`, `LegacyHiddenStorageAdapter`, `Discovery05HiddenStorageHandler`, `LegacyHiddenReport`, validationem promptitudinis et dispatchationem separatam. Omne hoc state ad invocationem unam pertinet. Metrics et branch trace exitu semantico non participant.

## Quod consulto nondum adest

Nulla correctio PATCH 05 introducta est. In particulari absunt `hiddenByNearness`, mappa accessus `8-k`, `Patch05` et omnis status emendationis quintae. Series ipsa non convertitur nec reordinatur post constructionem.

## Lingua computationis

Omnis codex exsecutus huius lineae est C++. Integra arbitraria per `boost::multiprecision::cpp_int` tractantur. Nullus interpres externus, FFI, runtime alienus aut generator in alia lingua adhibetur.

## Catalogus linguae fontis

Catalogus Neo-Latinus in `include/pastafari/source_language_catalog.hpp` congelatus manet. Ordo normativus per `canonicalIndex` tantum definitur; textus linguae fontis non participat ranking, unranking, cache semanticum aut electionem.

## Probationes

Regressiones usque ad Gradum 9 virides sunt; regressio Gradus 10 consulto rubra est:

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
REGRESSIO_DISCOVERY_05_DEFECIT  [EXPECTED_RED]
```

Gradus proximus est `PATCH 05`; nullum eius codicem hic gradus continet.
