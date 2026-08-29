# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium Gradum 16 evolutionis continet. Linea implementationis ab initio ex solo specimine normativo huius mandati aedificata est. Nulla implementatio aliena, nullum output alienum, nullus hash alienus et nulla probatio differentialis inter implementationes adhibita est.

## Status praesentis gradus

Gradus 16 est `DISCOVERY 08`; status repository exspectatus est `EXPECTED_RED`.

Vitium huius gradus est conventio rank permutationis. `oldPermutationUnrank0(rank0)` est helper legacy rectus in proprio dominio zero-based `0..719`. Caller autem ordinalem semanticum one-based `1..720` directe ad eundem argumentum mittit, sine subtractione unius.

Ergo ordines `1..719` permutationem sequentem legunt, dum ordinalis `720` tamquam rank0 extra fines reicitur. Helper zero-based ipse non est corruptus: rank0 `0` identitatem `[1,2,3,4,5,6]` et rank0 `719` inversionem `[6,5,4,3,2,1]` reddit.

## Via activa

`BaseMonsterManager::executePermutationOrder` transit per:

```text
BaseMonsterManager::executePermutationOrder
-> BaseDispatcher::dispatchLegacyPermutationRank
-> Discovery08PermutationRankHandler
-> LegacyPermutationAdapter::unrank0
-> oldPermutationUnrank0
```

Handler `legacyPermutationCallerRank1` in `legacyPermutationRank0Input` directe transfert. Si helper rankum accipit, ordo legacy exponitur; si ordinalis 720 ad rank0=720 transit, status absentiae exponitur. Nulla correctio, nullus fallback et nulla lectio oracle in productione fiunt.

## Regressio DISCOVERY 08

`tests/stage_16_discovery_08_tests.cpp` primum ipsam conventionem zero-based helperis verificat. Deinde ordines one-based `1`, `2`, `3`, `719` et `720` per viam activam cum `permutationUnrank1` oraculi C++ localis comparat.

Exitus actualis huius gradus est quinque discrepantiae:

```text
rank 1   : [1,2,3,4,5,6] -> [1,2,3,4,6,5]
rank 2   : [1,2,3,4,6,5] -> [1,2,3,5,4,6]
rank 3   : [1,2,3,5,4,6] -> [1,2,3,5,6,4]
rank 719 : [6,5,4,3,1,2] -> [6,5,4,3,2,1]
rank 720 : [6,5,4,3,2,1] -> ABSENS
```

Regressio exitum `1` reddit, ut DISCOVERY rubrum exspectatum.

Omnes regressiones Graduum 1–15 transeunt.

## Quod consulto nondum adest

Nulla conversio `oneBased = regularMod(drop-1,720)+1`, nulla subtractio ad rank0 legacy, nullus wrapper PATCH 08 et nulla logica pours Gradus 18 introducta est. `oldPermutationUnrank0` manet solum helper zero-based cum caller one-based directo.

## Lingua computationis

Omnis codex exsecutus huius lineae est C++. Integra arbitraria per `boost::multiprecision::cpp_int` tractantur. Nullus interpres externus, FFI, ambitus exsecutionis alienus aut generator in alia lingua adhibetur.

## Catalogus linguae fontis

Catalogus Neo-Latinus in `include/pastafari/source_language_catalog.hpp` congelatus manet. Semantica ordinis per `canonicalIndex` tantum definitur; textus presentationis computationem non mutat.
