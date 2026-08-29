# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium Gradum 27 evolutionis continet. Linea implementationis ab initio ex solo specimine normativo mandati aedificata est. Nulla implementatio aliena, nullus exitus alienus, nulla summa cryptographica aliena et nulla probatio differentialis inter implementationes adhibita est.

## Status praesentis gradus

Gradus 27 est `PATCH 13`; status repositorii est `GREEN`.

Gradus 26 cicatricem `biasedLegacyPick(x,N)=regularMod(x-1,N)+1` exposuit et eam ante rejectionem statim vocavit. Gradus 27 helper ipsum non mutat. Handler novus primum eandem vocationem legacy vere exsequitur et exitum eius servat, deinde rejectionem brevem in eodem `LegacyAnswerRing` applicat.

## PATCH 13 — rejectio ante selector legacy

Pro familia brevi `1<=N<=M_OLD`:

```text
acceptanceLimit = floor(M_OLD/N)*N
offset = 0
x = ringAnswer(stream,offset)
while x > acceptanceLimit:
    offset = offset + 1
    x = ringAnswer(stream,offset)
output = biasedLegacyPick(x,N)
```

Quia `M_OLD` et `N` positiva sunt, in C++ expressio `(M_OLD/N)*N` eundem `floor(M_OLD/N)*N` reddit.

Rejectio non mutat originem annuli. Omnia responsa candidata per eandem functionem `ringAnswer` eodem `first` et eodem `directionStep` derivantur. `biasedLegacyPick` non vocatur pro responsis reiectis; postquam primum `x<=acceptanceLimit` inventum est, idem helper historicus in illo `x` accepto vocatur.

## Cicatrix servata

Via activa Patch 13 prius vocat:

```text
LegacyBiasedSelectionAdapter::selectBeforeRejection
-> ringAnswer(stream,0)
-> biasedLegacyPick
```

Exitus hic in `legacyOutputBeforePatch` servatur. Postea `Patch13RejectionWrapper` rejectionem facit et per `LegacyBiasedSelectionAdapter::selectAcceptedAnswer` eundem `biasedLegacyPick` vocat.

Via diagnostica `executeUnpatchedBiasedSelectionDiagnostic` Gradum 26 intactum exercet et output directi modulo reddit.

## Via activa

```text
BaseMonsterManager::executeLegacyBiasedSelection
-> Patch 11: orderAt46Latch
-> Patch 12: successor circularis next-bowl
-> BaseDispatcher::dispatchPatchedBiasedSelection
-> Patch13BiasedSelectionHandler
-> LegacyBiasedSelectionAdapter::selectBeforeRejection
-> Patch13RejectionWrapper::repair
-> ringAnswer in eodem annulo donec x<=acceptanceLimit
-> LegacyBiasedSelectionAdapter::selectAcceptedAnswer
-> biasedLegacyPick
```

`requirePatch13BiasedSelectionReady` sine oracle productionis verificat limites `1..M_OLD`, formulam acceptance limit, originem accepted answer ex eodem annulo, absentiam responsi prioris acceptabilis et output finalem per helper legacy.

## Regressiones

`tests/stage_26_discovery_13_tests.cpp` byte pro byte non mutatur. Contra codicem Gradus 26 pristinum adhuc tres discrepantias et exitum `1` reddit. Contra Gradum 27 eadem regressio transit.

`tests/stage_27_patch_13_tests.cpp` tres witnesses Fundationis exercet. In omnibus:

```text
N = first-1
acceptanceLimit = N
offset acceptus = 1
acceptedAnswer = N
legacyOutputBeforePatch = 1
output patched = N
```

Probatio etiam `N=M_OLD` sine rejectione, `N=0` reiectum et `N>M_OLD` reiectum in via brevi comprobat. Via diagnostica legacy manet directa modulo.

Omnes regressiones Graduum 1–27 transeunt.

## Quod consulto nondum adest

Nullus dispatcher wide, nullus `wideDetour`, nullum `space=M^places`, nullae digits wide et nullus PATCH 14 in productione adest. Gradus 28 debet esse `DISCOVERY 14`: legacy path brevis assumptionem `N<=M_OLD` servabit et casum `N>M_OLD` consulto exponet sine correctione wide.

## Lingua computationis

Omnis codex computationalis huius lineae C++ est. Integra arbitraria per `boost::multiprecision::cpp_int` tractantur. Oracle, generator fixture, probationes et utilities computationales huius lineae C++ sunt.

## Catalogus linguae fontis

Catalogus Neo-Latinus in `include/pastafari/source_language_catalog.hpp` congelatus manet. Semantica ordinis per `canonicalIndex` tantum definitur; textus presentationis computationem non mutat.
