# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium Gradum 19 evolutionis continet. Linea implementationis ab initio ex solo specimine normativo huius mandati aedificata est. Nulla implementatio aliena, nullus exitus alienus, nulla summa cryptographica aliena et nulla probatio differentialis inter implementationes adhibita est.

## Status praesentis gradus

Gradus 19 est `PATCH 09`; status repositorii exspectatus est `GREEN`.

Gradus 18 ostendit tres fusiones crateres fixos `1,2,3` legere, quamquam ordo permutationis iam aliud craterum ordinem definire potest. Helper legacy consulto non mutatus est:

```text
legacyPoursToFixedBowlIds(drop,index,oldBowls,stoneRow)
```

Is adhuc crateres fixos `1,2,3` legit et exitum pravum observabilem reddit ubi tres primae positiones non sunt identitas.

## PATCH 09 — bowlAlias permanens

Emendatio novum interpretem positionum retinet:

```text
bowlAlias[position] = order[position]
```

In C++ sex elementa in array zero-based servantur, sed valor cuiusque cellae est ID crateris one-based `1..6`.

Omnis lectio crateris ad tres fusiones emendatas per `bowlAtAliasedPosition` transit. Itaque positiones `1`, `2`, `3` primum per `bowlAlias` ad crateris ID convertuntur et deinde solum crater ille ex `oldBowls` legitur.

`poursThroughBowlAlias` formulas servat:

```text
pour1 = SAVE(drop^2 + wheat  * bowlAtAliasedPosition(...,1) + 3*i)
pour2 = SAVE(drop^2 + barley * bowlAtAliasedPosition(...,2) + 5*i)
pour3 = SAVE(drop^2 + salt   * bowlAtAliasedPosition(...,3) + 7*i)
```

## Via activa

```text
BaseMonsterManager::executeFixedPours
-> BaseDispatcher::dispatchPatchedFixedPours
-> Patch09BowlAliasHandler
-> LegacyFixedPourAdapter::compute
-> legacyPoursToFixedBowlIds              [cicatrix vere vocata]
-> Patch09BowlAliasWrapper::repair
-> poursThroughBowlAlias
-> installBowlAlias
-> bowlAtAliasedPosition
```

`executeUnpatchedFixedPoursDiagnostic` viam Gradus 18 separatam retinet et sine PATCH 09 tres fusiones veteres exponit.

## Regressiones

`tests/stage_18_discovery_09_tests.cpp` immutatus manet. Contra codicem Gradus 18 pristinum adhuc tres discrepantias et exitum `1` reddit. Contra Gradum 19 idem executable transit: `drop=241` tres discrepantias in helper legacy adhuc demonstrat, sed nullam discrepantiam in output viae activae.

`tests/stage_19_patch_09_tests.cpp` omnes 720 residua permutationis probat. In omnibus casibus `bowlAlias == order`; tres IDs ad fusiones sunt prima tria elementa ordinis; omnis lectio crateris per alias eundem valorem ac lectio per ID normativum accipit; omnes tres fusiones viae activae cum formula test-only normativa concordant. Helper legacy in 714 ex 720 casibus adhuc saltem unam fusionem divergentem habet.

Omnes regressiones Graduum 1–19 transeunt.

## Quod consulto nondum adest

Nullum `vaultOld`, nullum `pending`, nullus `Patch10`, nullus status `patch10Applied` et nulla emendatio contaminationis in-place craterum praemature addita est.

## Lingua computationis

Omnis codex exsecutus huius lineae est C++. Integra arbitraria per `boost::multiprecision::cpp_int` tractantur. Nullus interpres externus, FFI, ambitus exsecutionis alienus aut generator in alia lingua adhibetur.

## Catalogus linguae fontis

Catalogus Neo-Latinus in `include/pastafari/source_language_catalog.hpp` congelatus manet. Semantica ordinis per `canonicalIndex` tantum definitur; textus presentationis computationem non mutat.
