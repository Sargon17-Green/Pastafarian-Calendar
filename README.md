# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium Gradum 14 evolutionis continet. Linea implementationis ab initio ex solo specimine normativo huius mandati aedificata est. Nulla implementatio aliena, nullum output alienum, nullus hash alienus et nulla probatio differentialis inter implementationes adhibita est.

## Status praesentis gradus

Gradus 14 est `DISCOVERY 07`; status repository exspectatus est `EXPECTED_RED`.

Vitium historicum nunc in via productionis activa expositum est. Tabula molitionum visibilium undecim ordines reales in ordine recto continet, sed memoria physica a nullo numeratur, locis `0..10`. Vocator legacy autem numerum semanticum molitionis `1..11` directe ut indicem physicum adhibet.

Ita fit:

```text
molitionis 1  -> ordo realis 2
molitionis 2  -> ordo realis 3
...
molitionis 10 -> ordo realis 11
molitionis 11 -> ordo absens
```

Primus ordo realis igitur omnino praeteritur.

## Via activa

`BaseMonsterManager::executeGrindRow` transit per:

```text
BaseMonsterManager::executeGrindRow
-> BaseDispatcher::dispatchLegacyGrindIndex
-> Discovery07GrindIndexHandler
-> LegacyGrindTableAdapter
-> legacyGrindRow
```

`legacyGrindRow(grind)` indicem physicum exacte aequat numero `grind`; nullam translationem facit. Si index 11 petitur, relatio `found=false` reddit et defectum non corrigit.

Contextus invocationis ordinalem petitum, indicem physicum adhibitum, ordinem lectum et signum praesentiae servat. Metrics et branch trace observationes sunt tantum; exitum semanticum non corrigunt.

## Regressio DISCOVERY 07

`tests/stage_14_discovery_07_tests.cpp` undecim ordines normativos ex eodem specimine huius lineae definit et eos cum via activa comparat. Praeterea cicatricem ipsam separat: tabula legacy undecim ordines habet; `legacyGrindRow(1)` secundum ordinem legit; `legacyGrindRow(10)` undecimum; `legacyGrindRow(11)` nihil invenit.

Exitus actualis est undecim discrepantiae ex undecim molitionibus. Hic rubor consultus est.

## Regressiones anteriores

Omnes probationes Graduum 1–13 denuo compilatae et exsecutae sunt; omnes transeunt. Nullum vitium antea correctum regressum est.

## Quod consulto nondum adest

Nulla linea custodiae in loco physico 0 addita est. Vocator legacy non mutatus est nec ad `grind-1` conversus. Nulla emendatio huius numerationis indicum in productione adest, et nullus codex sequentis vitii permutationis introductus est.

## Lingua computationis

Omnis codex exsecutus huius lineae est C++. Integra arbitraria per `boost::multiprecision::cpp_int` tractantur. Nullus interpres externus, FFI, ambitus exsecutionis alienus aut generator in alia lingua adhibetur.

## Catalogus linguae fontis

Catalogus Neo-Latinus in `include/pastafari/source_language_catalog.hpp` congelatus manet. Semantica ordinis per `canonicalIndex` tantum definitur; textus presentationis computationem non mutat.
