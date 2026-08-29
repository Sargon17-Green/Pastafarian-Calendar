# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium Gradum 20 evolutionis continet. Linea implementationis ab initio ex solo specimine normativo huius mandati aedificata est. Nulla implementatio aliena, nullus exitus alienus, nulla summa cryptographica aliena et nulla probatio differentialis inter implementationes adhibita est.

## Status praesentis gradus

Gradus 20 est `DISCOVERY 10`; status repositorii exspectatus est `EXPECTED_RED`.

Gradus 19 relationem `bowlAlias[position]=order[position]` ad tres fusiones recte instituit. Hic gradus vitium proximum separat: subsystema veteris commotionis sex crateres in eodem obiecto legit et statim scribit.

## DISCOVERY 10 — contaminatio scripturae immediatae

Helper legacy novus est:

```text
legacyStirBowlsInPlace(bowls,index,drop,stoneRow,order,firstThreePours)
```

Pro positionibus `1..6` ordinis, helper ID crateris praesentis, prioris et sequentis determinat. Formula ipsa coefficientes normativos servat, sed omnes lectiones fiunt ex eodem `bowls` quod eadem iteratio successive mutat. Statim post calculum cuiusque positionis valor novus in craterem scribitur.

Ita prima positio adhuc valores omnes veteres legit. Positiones posteriores autem craterem prius scriptum ut vicinum legere possunt et mutationem intra eundem circuitum propagant.

## Via activa

```text
BaseMonsterManager::executeInPlaceBowlStir
-> BaseDispatcher::dispatchLegacyInPlaceBowlStir
-> Discovery10InPlaceBowlHandler
-> LegacyInPlaceBowlAdapter::stir
-> legacyStirBowlsInPlace
```

`BaseMonsterContext` input craterum, guttam, indicem, lapidem, ordinem, tres fusiones et output mutatum separat. Comprobator productionis vocationem legacy in copia inputis repetit ut determinismum viae probet; output alternum normativum non suppeditat.

## Regressio

`tests/stage_20_discovery_10_tests.cpp` duos ordines probat: `drop=1` cum ordine identitate et `drop=241` cum ordine non identitate. Formula test-only normativa omnes sex lecturas ex una copia immutabili inputis facit et sex scriptiones in obiectum output separatum ponit.

In utroque casu prima cratera quae scribitur cum norma concordat, quia nulla scriptura prior in eodem circuitu facta est. Reliquae quinque craterae discrepant. Summa exacta est decem discrepantiae:

```text
drop=1   -> 5 discrepantiae
drop=241 -> 5 discrepantiae
summa    -> 10 discrepantiae
```

Regressio Gradus 20 igitur consulto exitum `1` reddit. Omnes regressiones Graduum 1–19 transeunt.

## Quod consulto nondum adest

Nullum snapshot craterum separatum, nullum spatium scripturae separatum, nullus `Patch10`, nullus status `patch10Applied` et nullum commit sex craterum aggregatum hoc gradu introductum est.

## Lingua computationis

Omnis codex exsecutus huius lineae est C++. Integra arbitraria per `boost::multiprecision::cpp_int` tractantur. Nullus interpres externus, FFI, ambitus exsecutionis alienus aut generator in alia lingua adhibetur.

## Catalogus linguae fontis

Catalogus Neo-Latinus in `include/pastafari/source_language_catalog.hpp` congelatus manet. Semantica ordinis per `canonicalIndex` tantum definitur; textus presentationis computationem non mutat.
