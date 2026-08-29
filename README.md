# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium Gradum 26 evolutionis continet. Linea implementationis ab initio ex solo specimine normativo mandati aedificata est. Nulla implementatio aliena, nullus exitus alienus, nulla summa cryptographica aliena et nulla probatio differentialis inter implementationes adhibita est.

## Status praesentis gradus

Gradus 26 est `DISCOVERY 13`; status repositorii exspectatus est `EXPECTED_RED`.

Gradus 25 next-bowl semanticum iam e successore circulari `orderAt46Latch` derivat. Gradus 26 addit cicatricem historicam selectoris modulo directi: `biasedLegacyPick(x,N)` facit tantum `regularMod(x-1,N)+1`. Via Discovery 13 hunc helper in primo responso annuli statim vocat, ante quam ulla acceptatio vel rejectio fiat.

## Correctio oracle testium reperta hoc gradu

Dum answer ring contra Appendix A verificabatur, inventum est `tests/reference/normative_reference.cpp` duas formulas craterum a textu Appendix A discrepare. In circuitu guttae visibilis et in post-commotione, Appendix A primum totum mixtum `s` format et deinde `square(s)` servat. Oracle vetus solum craterem ipsum quadraverat et additamenta extra quadratum reliquerat.

Productionis `stirBowlsThroughVaultOld` et post-commotiones iam lecturam Appendix A rectam habebant. Ergo sola copia test-only correcta est. Generator C++ bootstrap fixture denuo exsecutus est; mutati sunt sex valores craterum Fundationis et duo valores interrogationis Fundationis. Omnes probationes priores post hanc correctionem denuo compilatae et exsecutae sunt.

## DISCOVERY 13 — biased modulo ante rejectionem

Cicatrix nova est:

```text
biasedLegacyPick(x,N) = regularMod(x-1,N)+1
```

Helper nullum acceptance limit computat et nullum offset annuli quaerit.

Answer ring productionis ex statu reali iam reparato construitur:

```text
Patch 11 -> finalBowls + orderAt46Latch
Patch 12 -> nextBowlId circularis
answerRingThroughPatchedNextBowl -> first + directionStep
ringAnswer(stream,0) -> primus responsus
biasedLegacyPick(first,N) -> electio legacy immediata
```

Formulae answer ring sunt exactae Appendix A:

```text
first = SAVE(square(bowls[queried]+seal+181) + 179*bowls[next] + seal)
directionNumber = SAVE(square(first+seal+1+193) + 193*first + 197*bowls[6])
directionStep = +1 si directionNumber mod 2 = 1, aliter -1
answerAt(k) = 1 + regularMod(first-1 + directionStep*k, M_OLD)
```

## Via activa

```text
BaseMonsterManager::executeLegacyBiasedSelection
-> BaseDispatcher::dispatchPatchedOrderAt46Latch
-> Patch11OrderAt46LatchHandler
-> BaseDispatcher::dispatchPatchedNextBowl
-> Patch12NextBowlHandler
-> Discovery13BiasedSelectionHandler
-> answerRingThroughPatchedNextBowl
-> LegacyBiasedSelectionAdapter::selectBeforeRejection
-> ringAnswer(stream,0)
-> biasedLegacyPick
```

`requireLegacyBiasedSelectionReady` comprobat Patch 11 et Patch 12 iam parata esse, directionem esse ±1, primum responsum esse `ringAnswer(stream,0)`, et output legacy exactissime directum modulo esse. Validator nullam rejectionem efficit.

## Regressio

`tests/stage_26_discovery_13_tests.cpp` tres annulos reales Fundationis exercet:

- crater 1, sigillum 1;
- crater 2, sigillum 21;
- crater 3, sigillum 31.

In omnibus tribus `directionStep=-1`, `N=first-1`, et `N>M_OLD/2`. Ergo `limit=floor(M_OLD/N)*N` in norma test-only esset `N`: primus responsus `N+1` reiciendus est, proximus responsus in eodem annulo est `N`, et electio normativa est `N`. Cicatrix tamen `biasedLegacyPick(N+1,N)=1` statim reddit.

Tres discrepantiae exactae inveniuntur; regressio consulto exitum `1` reddit. Omnes regressiones Graduum 1–25 transeunt.

## Quod consulto nondum adest

In productione nulla formula `limit=floor(M_OLD/N)*N`, nullus progressus ad responsum acceptabilem, nullus `patchedSmallPick`, nullus `SelectionRejectionPatchWrapper`, nullus `Patch13`, nullus `patch13Applied`, nullus `wideDetour` et nullus codex posterior adest. Gradus 27 debet esse `PATCH 13` tantum.

## Lingua computationis

Omnis codex computationalis huius lineae C++ est. Integra arbitraria per `boost::multiprecision::cpp_int` tractantur. Oracle, generator fixture, probationes et utilities computationales huius lineae C++ sunt.

## Catalogus linguae fontis

Catalogus Neo-Latinus in `include/pastafari/source_language_catalog.hpp` congelatus manet. Semantica ordinis per `canonicalIndex` tantum definitur; textus presentationis computationem non mutat.
