# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium Gradum 29 evolutionis continet. Linea implementationis ab initio ex solo specimine normativo mandati aedificata est. Nulla implementatio aliena, nullus exitus alienus, nulla summa cryptographica aliena et nulla probatio differentialis inter implementationes adhibita est.

## Status praesentis gradus

Gradus 29 est `PATCH 14`; status repositorii est `GREEN`.

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


## DISCOVERY 14 — assumptio legacy N<=M in selectione lata

Via brevis Patch 13 manet recta pro familiis `1<=N<=M_OLD`, sed nondum habet modum familiae latae. Gradus 28 hanc limitationem non corrigit. `LegacyShortOnlyWideSelectionAdapter` eundem `Patch13RejectionWrapper` ad familiam `N>M_OLD` vere mittit; guard brevis defectum Neo-Latinum reddit et output semanticum non gignitur.

Via activa huius gradus est:

```text
BaseMonsterManager::executeLegacyWideSelectionAssumption
-> Patch 11: orderAt46Latch
-> Patch 12: successor circularis next-bowl
-> BaseDispatcher::dispatchLegacyWideSelectionAssumption
-> Discovery14WideAssumptionHandler
-> LegacyShortOnlyWideSelectionAdapter::attempt
-> Patch13RejectionWrapper::repair
-> defectus, quia N>M_OLD
```

`tests/stage_28_discovery_14_tests.cpp` tres familias latas probat: `M_OLD+1`, `M_OLD^2`, `M_OLD^3`. Answer ring productionis cum oracle C++ locali concordat, sed via activa in omnibus tribus output non habet, dum `reference::chooseRankWide` rank normativum definit. Ergo status huius gradus consulto `EXPECTED_RED` est.

Nullus dispatcher `N<=M / N>M`, nullus `wideDetour`, nullum `space=M^places`, nullae digits base-M, nullus numerus wide et nulla rejectio super numero wide in productione huius gradus adsunt. Haec omnia reservantur Gradui 29 / PATCH 14.


## PATCH 14 — dispatcher brevis/latus et wideDetour

Gradus 28 demonstravit viam short-only familiam `N>M_OLD` repudiavisse. Gradus 29 cicatricem illam non delet. `Patch14WideSelectionHandler` primum `LegacyShortOnlyWideSelectionAdapter::attempt` vere vocat et exitum vel defectum eius separat servat. Deinde dispatcher semanticus unam tantum viam eligit:

```text
si N<=M_OLD:
    via brevis Patch 13
si N>M_OLD:
    wideDetour
```

Via brevis nullas digits wide legit et eundem output rejectionis brevis servat. Via lata minimum numerum locorum invenit:

```text
places = minimum k cum M_OLD^k >= N
space = M_OLD^places
digits[j] = ringAnswer(stream,j), j=0..places-1
wide = 1 + sum((digits[j]-1)*M_OLD^j)
acceptanceLimit = floor(space/N)*N
```

Omnes digits semel ante rejectionem leguntur et in `Patch14WideDetourSelection` servantur. Post compositionem nullus `ringAnswer` iterum vocatur. Dum `wide>acceptanceLimit`, idem numerus compositus in spatio `1..space` per `directionStep` movetur:

```text
wide = 1 + regularMod(wide-1+directionStep, space)
```

Cum primum numerus acceptabilis inventus est, `LegacyBiasedSelectionAdapter::selectAcceptedAnswer` eundem `biasedLegacyPick` historicum vocat. Ergo selector legacy manet, sed rejectio lata aequam massam in spatio composito applicat.

### Cicatrix Gradus 28 servata

`executeUnpatchedWideSelectionDiagnostic` adhuc `Discovery14WideAssumptionHandler` et `LegacyShortOnlyWideSelectionAdapter` exercet; pro familia lata output deest et defectus short-only manet. Via activa Patch 14 eundem conatum ante correctionem facit et campos `legacy*BeforePatch` servat.

`tests/stage_28_discovery_14_tests.cpp` tantum ad observabilitatem ante/post patch accommodata est. Eadem versio testis contra fontem Gradus 28 pristinum adhuc tres discrepantias exactas et exitum 1 reddit; contra Gradum 29 transit.

### Regressio PATCH 14

`tests/stage_29_patch_14_tests.cpp` tres familias latas `M_OLD+1`, `M_OLD^2`, `M_OLD^3` contra oracle C++ locale probat. Pro singulis verificat minimum `places`, `space`, digits semel lectas, compositionem wide, acceptance limit, rejectionem super eodem numero composito et output finalem.

Casus `N=M_OLD` demonstrat dispatcher viam brevem servare sine ulla digit wide. Witness rejectionis latae construit `N=wide2-1`; quia `directionStep=-1`, numerus initialis est `N+1`, limes est `N`, unus tantum gradus rejectionis fit et output finalis est `N`. `wideDigitReadCount` ante et post rejectionem manet 2.

Omnes regressiones Graduum 1–29 transeunt.

### Quod consulto nondum adest

Nullus `oldGateQuestionDay`, nullus signed-step gate detour, nullus PATCH 15 et nullus `LEGACY_YEAR_MAX` in productione adsunt. Gradus 30 debet esse `DISCOVERY 15`: helper legacy `oldGateQuestionDay(n)=FOUNDATION_DAY_OLD+n` latus positivum semper rogabit quando caller signum gradus negativi amittit; nulla correctio negativa eo gradu addetur.


## DISCOVERY 15 — gradus negativus signum ante quaestionem portae amittit

Gradus 30 helper historicum expresse introducit:

```text
oldGateQuestionDay(n)=FOUNDATION_DAY_OLD+n
```

Helper ipse formulam suam directe servat et etiam argumentum negativum, si directe datum sit, ad latus antecedens Fundationis traducere potest. Cicatrix huius gradus in caller est. `Discovery15GateQuestionHandler` `signedStep` in magnitudinem absolutam convertit ante `LegacyGateQuestionAdapter::ask`; adapter deinde `oldGateQuestionDay(magnitude)` vere vocat.

Ita `signedStep>=0` accidentaliter cum die normativo concordat, sed `signedStep<0` signum amittit et quaestionem ad latus positivum mittit. Via activa est:

```text
BaseMonsterManager::executeLegacyGateQuestionDay
-> BaseDispatcher::dispatchLegacyGateQuestion
-> Discovery15GateQuestionHandler
-> abs(signedStep)
-> LegacyGateQuestionAdapter::ask
-> oldGateQuestionDay
```

`tests/stage_30_discovery_15_tests.cpp` casus `0,+1,+17,-1,-17,-123456` probat. Tres casus non-negativi concordant. Tres negativi exactas discrepantias reddunt; exitus testis consulto est 1.

Omnes regressiones Graduum 1–29 transeunt.

Nullus PATCH 15, nullus wrapper qui diem negativum restituit, nullus `LEGACY_YEAR_MAX` et nullus codex Gradus 31 vel 32 praemature adest.
