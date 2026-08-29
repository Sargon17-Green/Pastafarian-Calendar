# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium Gradum 18 evolutionis continet. Linea implementationis ab initio ex solo specimine normativo huius mandati aedificata est. Nulla implementatio aliena, nullus exitus alienus, nulla summa cryptographica aliena et nulla probatio differentialis inter implementationes adhibita est.

## Status praesentis gradus

Gradus 18 est `DISCOVERY 09`; status repositorii exspectatus est `EXPECTED_RED`.

Post PATCH 08 ordo sex craterum iam recte e `drop` derivatur. Novum vitium historicum tamen apparet in tribus fusionibus: codex veteris viae ordinem rectum computat, sed lecturas craterum adhuc quasi positiones 1, 2, 3 essent identicae crateribus cum ID 1, 2, 3 facit.

Routine legacy est:

```text
legacyPoursToFixedBowlIds(drop,index,oldBowls,stoneRow)
```

Ea ordinem per eandem conventionem PATCH 08 obtinet, sed tres formulas fusionis legunt semper:

```text
oldBowls[1]
oldBowls[2]
oldBowls[3]
```

sensu ID crateris, id est indices C++ `0`, `1`, `2`. Ordo computatus nondum ad has lecturas applicatur.

## Via activa

```text
BaseMonsterManager::executeFixedPours
-> BaseDispatcher::dispatchLegacyFixedPours
-> Discovery09FixedPourHandler
-> LegacyFixedPourAdapter::compute
-> legacyPoursToFixedBowlIds
```

Contextus huius viae servat `drop`, indicem guttae, sex crateres veteres, ordinem sex craterum, tres IDs fixos `1,2,3`, ordinem lapidis et tres exitus fusionis. Validator confirmat tantum structuram defectus legacy; nullam correctionem semanticae facit.

## Regressio DISCOVERY 09

`tests/stage_18_discovery_09_tests.cpp` duos casus separat.

Pro `drop=1`, ordo est identitas `[1,2,3,4,5,6]`. Hic vitium latent: crateres fixi `1,2,3` forte iidem sunt ac tres crateres positi in primis tribus positionibus, ergo nulla discrepantia apparet.

Pro `drop=241`, ordo est `[3,1,2,4,5,6]`. Norma tres fusiones e crateribus `3,1,2` legere iubet, dum legacy adhuc `1,2,3` legit. Cum crateribus veteribus distinctis et lapide distincto, tres discrepantiae exactae apparent. Regressio consulto exitum `1` reddit.

Omnes regressiones Graduum 1–17 transeunt.

## Quod consulto nondum adest

Nullus `bowlAlias`, nullus `Patch09`, nullus status `patch09Applied` et nulla translatio `position -> order[position]` ad lecturas fusionum introducta est. Item nullus `vaultOld`, nullum `pending` et nulla logica PATCH 10 praemature adest.

## Lingua computationis

Omnis codex exsecutus huius lineae est C++. Integra arbitraria per `boost::multiprecision::cpp_int` tractantur. Nullus interpres externus, FFI, ambitus exsecutionis alienus aut generator in alia lingua adhibetur.

## Catalogus linguae fontis

Catalogus Neo-Latinus in `include/pastafari/source_language_catalog.hpp` congelatus manet. Semantica ordinis per `canonicalIndex` tantum definitur; textus presentationis computationem non mutat.
