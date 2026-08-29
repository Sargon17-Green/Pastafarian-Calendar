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


## PATCH 15 — latus negativum quaestionis portae restitutum

Gradus 31 cicatricem Discovery 15 non delet. `oldGateQuestionDay(n)=FOUNDATION_DAY_OLD+n` manet intactus, et `Discovery15GateQuestionHandler` adhuc `signedStep` in `abs(signedStep)` convertit ante vocationem helperis. Via patched primum totam hanc viam legacy exsequitur et output positivum in `legacyOutputBeforePatch` servat.

Deinde `Patch15NegativeGateQuestionWrapper` tantum signum semanticum restituit:

```text
si signedStep < 0:
    output = FOUNDATION_DAY_OLD - abs(signedStep)
aliter:
    output = legacyOutputBeforePatch
```

Ita zero et gradus positivi byte-semantice viam legacy servant; gradus negativus solus ad latus antecedens Fundationis divertitur. Via activa est:

```text
BaseMonsterManager::executeLegacyGateQuestionDay
-> BaseDispatcher::dispatchPatchedGateQuestion
-> Patch15GateQuestionHandler
-> Discovery15GateQuestionHandler
-> abs(signedStep)
-> LegacyGateQuestionAdapter::ask
-> oldGateQuestionDay
-> legacyOutputBeforePatch
-> Patch15NegativeGateQuestionWrapper
-> output semanticus
```

`executeUnpatchedGateQuestionDayDiagnostic` viam Discovery 15 solam retinet. `tests/stage_30_discovery_15_tests.cpp` expected values non mutat; solum output semanticum activum aestimat, dum magnitudinem legacy adhuc exigit. Eadem versio testis contra Gradum 30 pristinum tres discrepantias negativas et exitum 1 reddit; contra Gradum 31 transit.

`tests/stage_31_patch_15_tests.cpp` quattuor gradus negativos, tres non-negativos, output legacy ante patch, viam diagnosticam, statum invocationi proprium et conservationem viae non-negativae probat. Omnes regressiones Graduum 1–31 transeunt.

Nullus `LEGACY_YEAR_MAX`, nullus `REAL_YEAR_MAX_PATCH`, nullus PATCH 16 et nullus codex Gradus 32 praemature additus est.


## DISCOVERY 16 — ceiling legacy anni 5781 candidatos nimis longos admittit

Gradus 32 cicatricem historicam obligatoriam expresse creat et in via productionis vere adhibet:

```text
LEGACY_YEAR_MAX=5781
```

`legacyYearCandidateAllowed(gates,openIndex,closeIndex)` computat numerum intervallorum portarum et longitudinem candidatam. Via legacy admittit candidatum tantum si:

```text
gapCount >= 6
252 <= candidateLength <= LEGACY_YEAR_MAX
```

`legacyYearCandidatesBeforeSort` candidatas admissas ordine inputuum materialisat. `legacyStableLengthOnlyYearCandidates` deinde copiam facit et stable sort tantum per longitudinem applicat. Nullum criterium secundarium pro porta aperiente hoc gradu adest.

`LegacyYearCandidateAdapter::select` familiam sortatam ad mechanismum selectionis iam emendatum mittit: via brevis Patch 13 pro magnitudine intra M, wideDetour Patch 14 si familia maior esset. Ergo candidata supra 5778 non tantum in memoria diagnostica manent; ad familiam selectionis vere perveniunt.

Via monstri est:

```text
BaseMonsterManager::executeLegacyYearCandidateDiscovery
-> Patch 15 gate path
-> Patch 11 orderAt46Latch
-> Patch 12 next-bowl
-> BaseDispatcher::dispatchLegacyYearCandidates
-> Discovery16LegacyYearCandidateHandler
-> LegacyYearCandidateAdapter::prepareForSelection
-> stable sort per longitudinem solam
-> LegacyYearCandidateAdapter::select
```

### Witness limitis

Familia probationis communem portam apertam et quinque clausuras habet cum longitudinibus 5778, 5779, 5780, 5781 et 5782. Ordo inputuum acceptabilium consulto non est sortatus:

```text
ante sortem: 5781, 5779, 5778, 5780
post sortem: 5778, 5779, 5780, 5781
```

5782 ceiling legacy excedit et repudiatur. 5779, 5780 et 5781 tamen familiam sortatam et selectionem attingunt, quamvis norma finalis longitudines supra 5778 non admittat. Haec tres discrepantiae unicum rubrum intentionale huius gradus constituunt.

`tests/stage_32_discovery_16_tests.cpp` etiam verificat `LEGACY_YEAR_MAX==5781`, minimum sex gate gaps, conservationem ordinis raw ante sortem, stable sort length-only, vocationem realem selectionis et candidatum electum ex ipsa familia sortata.

Omnes regressiones Graduum 1–31 denuo compilatae et exsecutae sunt; omnes transeunt.

### Quod consulto nondum adest

Nulla constans separata 5778 in productione, nullus early reject pro longitudine supra 5778, nullus PATCH 16 et nullus tie repair secundarius huius gradus adsunt. Gradus 33 / PATCH 16 solus filter separatum ante sortem et selectionem introducere debet, `LEGACY_YEAR_MAX=5781` intacto relicto.


## PATCH 16 — ceiling realis 5778 post cicatricem legacy et ante ordinationem

Gradus 33 constantem historicam non mutat:

```text
LEGACY_YEAR_MAX=5781
```

`legacyYearCandidateAllowed`, `legacyYearCandidatesBeforeSort`, `legacyStableLengthOnlyYearCandidates` et `Discovery16LegacyYearCandidateHandler` manent cicatrices separatae. Via diagnostica `executeUnpatchedYearCandidateDiscoveryDiagnostic` eas adhuc exercet et demonstrat familiam legacy `5778,5779,5780,5781` ad selectionem veterem pervenire.

Correctio nova constantem separatam addit:

```text
REAL_YEAR_MAX_PATCH=5778
```

`yearCandidateAfterFootnotePatch` primum `legacyYearCandidateAllowed` vere vocat. Si helper legacy candidatum repudiat, nihil ulterius fit. Si helper legacy admittit, longitudo exacta materialisatur; demum candidata cum `candidateLength>REAL_YEAR_MAX_PATCH` ad `rejectedBeforeSort` movetur. Ergo 5779, 5780 et 5781 post acceptance legacy observabilia manent, sed nullam ordinationem semanticam neque selectionem attingunt.

`YearCandidateCeilingPatchWrapper` quattuor familias invocationi proprias servat:

```text
legacyPreSort
rejectedBeforeSort
semanticPreSort
semanticSorted
```

Solum `semanticPreSort` ad `legacyStableLengthOnlyYearCandidates` traditur. Sic cicatrix ordinationis veteris per longitudinem solam manet, sed overlong candidates iam ante ipsam ordinationem semanticam remoti sunt. Nullum criterium secundarium per opening gate hoc gradu adicitur.

Via activa est:

```text
BaseMonsterManager::executeLegacyYearCandidateDiscovery
-> Patch 15
-> Patch 11
-> Patch 12
-> BaseDispatcher::dispatchPatchedYearCandidates
-> Patch16YearCandidateCeilingHandler
-> YearCandidateCeilingPatchWrapper
-> legacyYearCandidateAllowed
-> REAL_YEAR_MAX_PATCH filter
-> ordinatio stabilis per longitudinem solam
-> LegacyYearCandidateAdapter::select
```

### Regressio Discovery 16 post patch

Eadem familia limitis cicatricem legacy directe adhuc demonstrat:

```text
legacy ante ordinationem: 5781,5779,5778,5780
legacy ordinata:          5778,5779,5780,5781
```

Via activa autem dat:

```text
semantica ante ordinationem: 5778
semantica ordinata:          5778
familia selectionis:         1
```

Eadem versio probationis contra fontem Gradus 32 pristinum adhuc 5779..5781 ad selectionem transmittit et exitum 1 reddit; contra Gradum 33 transit.

### Probatio contra anticipationem Patch 17

Probe additivum duas candidatas longitudinis 490 in ordine inputuum `openIndex 2,0` ponit. Post PATCH 16 ordo idem `2,0` manet. Hoc demonstrat filter 5778 ante ordinationem recte insertum esse, sed tie repair per opening gate nondum exsistere.

Omnes regressiones Graduum 1–33 transeunt. Nullus `sortEqualLengthRunsByOpeningGate`, nullus PATCH 17, nullus `patch17Applied` et nullus `oldJumpGuess` in productione adsunt.


## DISCOVERY 17 — tie in anno 5000 sub stable sort per longitudinem solam

Gradus 34 viam candidatorum anni 5000 separatam addit post correctionem ceiling Gradus 33. `legacyYear5000TiePreparation` singulum par portarum per `yearCandidateAfterFootnotePatch` transit, ergo `LEGACY_YEAR_MAX=5781` et filter semanticus `REAL_YEAR_MAX_PATCH=5778` manent in effectu. Deinde candidatus tantum retinetur si:

```text
GATE[open] < calculationDay <= GATE[close]
```

Familia sic parata adhuc per cicatricem `legacyStableLengthOnlyYearCandidates` ordinatur. Nulla clavis secundaria ad opening gate adhibetur.

Via activa est:

```text
BaseMonsterManager::executeLegacyYear5000TieDiscovery
-> Patch 15
-> Patch 11
-> Patch 12
-> BaseDispatcher::dispatchLegacyYear5000Tie
-> Discovery17Year5000TieHandler
-> LegacyYear5000TieAdapter
-> legacyYear5000TiePreparation
-> legacyStableLengthOnlyYearCandidates
-> selectio iam emendata
```

### Witness tie

Portae testis distant 50 dies. `calculationDay` est 225 dies post portam basis. Tres pares consulto hoc ordine traduntur:

```text
(openIndex,closeIndex) = (4,10), (0,6), (2,8)
```

Omnes tres sex intervalla habent, longitudinem 300 habent, ceiling 5778 servant et diem calculationis continent. Ordo inputuum opening indices est:

```text
4,0,2
```

Quia omnes longitudines aequales sunt, stable sort legacy per longitudinem solam eundem ordinem servat:

```text
4,0,2
```

Regula normativa post futura correctione intra run aequalis longitudinis opening gate maturiorem anteponit, unde ordo expectatus est:

```text
0,2,4
```

Tres positiones omnes discrepant. Regressio Gradus 34 hunc numerum exactum exspectat et exitum 1 reddit. Selectio ipsa vere vocatur cum familia magnitudinis 3; defectus igitur non est familia vacua neque ceiling, sed sola ordinatio tie.

Omnes regressiones Graduum 1–33 denuo compilatae et exsecutae sunt; omnes transeunt.

### Quod consulto nondum adest

Nulla functio `sortEqualLengthRunsByOpeningGate`, nullus comparator secundarius, nullus PATCH 17 et nullus `patch17Applied` adsunt. Stable sort length-only manet cicatrix productionis. Gradus 35 solus debet post hunc primum sort invenire runs aequalis longitudinis et solum singulos runs per opening gate maturiorem ordinare; non licet in sort duarum clavium mundum reficere.


## PATCH 17 — runs aequalis longitudinis tantum per opening gate reparantur

Gradus 35 stable sort historicum per longitudinem solam non substituit. `legacyYear5000TiePreparation` et `Discovery17Year5000TieHandler` prius currunt sicut in DISCOVERY 17; familia legacy iam length-sortata, answer stream, ordinalis et candidatus legacy electus in contextu servantur.

Post hanc cicatricem, helper novus:

```text
sortEqualLengthRunsByOpeningGate(gates, lengthSorted)
```

listam iam length-sortatam a sinistra ad dextram percurrit. Pro quolibet run contiguo cui eadem `length` est, tantum slice illius run per `GATE[openIndex]` ascendentem stable-sortat. Elementa extra run non moventur. Itaque hoc non est global sort mundus per `(length, openingGate)`.

Via activa est:

```text
BaseMonsterManager::executeLegacyYear5000TieDiscovery
-> Patch 15
-> Patch 11
-> Patch 12
-> BaseDispatcher::dispatchPatchedYear5000Tie
-> Patch17Year5000TieHandler
-> Discovery17Year5000TieHandler
-> familia et selectio legacy servantur
-> Year5000TiePatchWrapper
-> sortEqualLengthRunsByOpeningGate
-> selectio denuo cum eodem answer stream
```

Via `executeUnpatchedYear5000TieDiagnostic` DISCOVERY 17 sine PATCH 17 adhuc exercet.

### Witness anni 5000

Familia legacy trium candidatorum longitudinis 300 manet:

```text
4,0,2
```

Post secondum passum localem PATCH 17 fit:

```text
0,2,4
```

Unus run aequalis longitudinis agnoscitur. Ordinalis selectionis ante et post patch est idem `2`, quia answer stream et magnitudo familiae non mutantur; candidatus tamen ex ordine reparato sumitur.

Probe additivum helperi listam non length-sortatam `300(open 4), 200(open 0), 300(open 2)` tradit. Quia duo 300 non sunt contigui, output manet `4,0,2`; hoc demonstrat helperem non candidatos aequalis longitudinis per totam familiam regruppare nec globalem two-key sort simulare.

Regressio DISCOVERY 17 eadem expectatione opening gate nunc transit. Eadem versio probationis contra fontem Stage 34 pristinum adhuc tres discrepantias et exitum 1 reddit. Omnes regressiones Graduum 1–35 transeunt.

Nullus `oldJumpGuess`, nullus PATCH 18 et nullus codex saltus annorum praemature additur.


## DISCOVERY 18 — oldJumpGuess per divisorem 365 annum activum determinat

Gradus 36 cicatricem historicam saltus ab anno 5000 introducit sine correctione futura. Recordum minimum `LegacyYearAnchor` numerum anni, primum diem anni et ultimum diem servat. Helper legacy est:

```text
oldJumpGuess(anchor,targetDay)
= anchor.number + floorDiv(targetDay-anchor.firstDay,365)
```

Quia divisio `cpp_int` versus zero truncat, helper pro delta negativo residuum inspicit et quotientem uno minuit, ut vera `floorDiv` cum divisore positivo 365 servetur.

Via activa est:

```text
BaseMonsterManager::executeLegacyYearJump
-> BaseDispatcher::dispatchLegacyYearJump
-> Discovery18LegacyYearJumpHandler
-> LegacyYearJumpAdapter::guess
-> oldJumpGuess
```

`Discovery18LegacyYearJumpHandler` guess veterem non ut telemetry sed ut `outputYearNumber` activum ponit. Validator eandem formulam legacy iterum computat et requirit ut output activus exacte guess sit. Nulla ambulatio per `nextYear` aut `previousYear` in production hoc gradu adest.

### Witness ex anno 5000 Fundationis

Oracle C++ localis test-only annum 5000 pro die Fundationis construit. Hic anchor habet:

```text
number=5000
firstDay=-15057702
lastDay=-15053459
length=4244
```

Quattuor target dies probantur. Primus dies anchoris control est et 5000 recte reddit. Reliqui tres defectum detegunt:

```text
firstDay+365  -> old guess 5001, sequential 5000
lastDay       -> old guess 5011, sequential 5000
next.firstDay -> old guess 5011, sequential 5001
```

In primis duobus casibus ambulatio normativa nullum transitum anni facit; in tertio unum `nextYear` facit. Regressio igitur tres discrepantias exactas exigit et exitum 1 reddit.

Omnes regressiones Graduum 1–35 denuo compilatae et exsecutae sunt; omnes transeunt.

### Quod consulto nondum adest

Nullus `findYearByWalkPatch`, nullus `patchedNextYear`, nullus `patchedPreviousYear`, nullus `ignoredGuess`, nullus PATCH 18 et nullus cache Patch 19 adest. Gradus 37 solus debet `oldJumpGuess` servare sed ad telemetry relegare atque annum target anno post annum determinare.


## PATCH 18 — oldJumpGuess ad telemetry relegatus, annus sequentialiter inventus

Gradus 37 cicatricem saltus `/365` servat sed potestatem semanticam ei aufert. `oldJumpGuess` manet intactus et `Discovery18LegacyYearJumpHandler` adhuc vere currit ante correctionem; eius output in `oldGuess` servatur, sed `guessUsedAsOutput=false` post patch fit.

`Patch18YearWalkWorkspace` est state semanticum invocationi proprium, non cache persistens. A porta Fundationis indice 0 incipit et portas necessarias tantum producit. Intervalla portarum per sauce productionis iam emendatum, bowl 1, next-bowl circularis et seal 1 eliguntur. Nullum oracle productionis adhibetur.

Anchor `LegacyYearAnchor` ad recordum `Patch18YearRecord` resolvitur: `firstDay-1` debet esse opening gate exacta et `lastDay` closing gate exacta. `patchedNextYear` a closing gate anni noti incipit, candidatos cum saltem sex gap et longitudine 252..5778 colligit, eos stable-sort per longitudinem servat, deinde sauce in opening gate cum seal 11 atque selectione Patch 13/14 utitur. `patchedPreviousYear` eandem structuram retro cum seal 12 facit.

`Patch18SequentialYearWalkWrapper` ab anchor anno 5000 incipit. Dum target post closing gate est, unum `patchedNextYear` facit; dum target non post opening gate est, unum `patchedPreviousYear` facit. Terminatio requirit `openGateDay < targetDay <= closeGateDay`.

Via activa est:

```text
BaseMonsterManager::executeLegacyYearJump
-> BaseDispatcher::dispatchPatchedYearWalk
-> Patch18SequentialYearWalkHandler
-> Discovery18LegacyYearJumpHandler
-> oldJumpGuess                 [telemetry]
-> Patch18SequentialYearWalkWrapper
-> Patch18YearWalkWorkspace
-> patchedNextYear / patchedPreviousYear
```

Via `executeUnpatchedYearJumpDiagnostic` cicatricem Gradus 36 separatam servat et oldJumpGuess adhuc ut output reddit.

Regressio Gradus 36 byte-for-byte non mutata est. Contra Stage 36 pristinum adhuc tres discrepantias et exitum 1 reddit; contra PATCH 18 transit. Probatio Gradus 37 quinque casus exercet: nullum transitum, unum et duo `nextYear`, unum et duo `previousYear`. In omnibus quinque oldJumpGuess a numero normativo differt sed in telemetry servatur; summa graduum forward est 3 et backward 3.

Omnes regressiones Graduum 1–37 transeunt.

### Quod consulto nondum adest

Nullus cache annorum persistens, nulla map keyed tantum per year number, nullus `calculationDayFingerprint`, nullus guard cache et nullus PATCH 19 adest. Workspace portarum tantum invocationi proprium est et post manager invocationem perit.

## DISCOVERY 19 — cache anni keyed tantum per `year.number`

Gradus 38 cache persistens in `BaseMonsterManager` introducit. Clavis map est tantum `year.number`. Value tamen iam formam historicam plenam habet:

```text
calculationDayFingerprint
openGate
closeGate
value
```

`LegacyYearNumberOnlyCacheAdapter::getOrPut` nullum horum trium guardorum legit ad HIT decernendum. Si eadem clavis numeri anni iam exstat, entry vetus statim redditur. Via activa annum currentem primum per PATCH 18 sequentialiter resolvit, ex eo request entry currentem format, deinde per `Discovery19YearNumberCacheHandler` cache legacy consulit. Sic defectus est in reuse cache, non in ambulatione anni.

Witness est annus 5001 cum eodem target die et calculationDay Fundationis, Fundationis+1, +2 et +3. Numerus anni et opening gate manent iidem; closing gate cum calculationDay mutatur. Prima invocatio MISS facit et entry Fundationis servat. Tres invocationes sequentes eadem clave 5001 HIT faciunt et closing gate vetus reddunt. Regressio tres HIT stale exactos exspectat et consulto exitum 1 reddit.

Omnes regressiones Graduum 1–37 transeunt.

### Quod consulto nondum adest

Nullus guard HIT super `calculationDayFingerprint`, `openGate` aut `closeGate` adest; nullus mismatch ad MISS convertitur; nullus overwrite guarded PATCH 19 adest. Nulla `oldStructureSauce` nec logica PATCH 20 praemature addita est.

## PATCH 19 — guardi actionis supra clavem malam `year.number`

Gradus 39 clavem historicam cache non purgat. `BaseMonsterManager` map persistentem adhuc per `year.number` tantum tenet, et `LegacyYearNumberOnlyCacheAdapter::getOrPut` atque `Discovery19YearNumberCacheHandler` ante correctionem vere currunt. Ita HIT legacy secundum solam clavem adhuc observabilis est.

`Patch19YearCacheGuardWrapper` post lookup legacy tres guardos value comparat:

```text
calculationDayFingerprint
openGate
closeGate
```

Si tres omnes congruunt, HIT legacy etiam HIT semanticus fit et value servatus reutilizatur. Si unus saltem guard differt, HIT legacy reicitur: actio semantica MISS est, request entry current sub eadem clave `year.number` overwrite fit, et value current redditur. Prima MISS sine entry praevia simpliciter value current ponit nec overwrite superfluum notat.

Via activa est:

```text
BaseMonsterManager::executeLegacyYearNumberCache
-> PATCH 18 sequential year walk
-> Patch19YearCacheGuardHandler
-> Discovery19YearNumberCacheHandler
-> LegacyYearNumberOnlyCacheAdapter::getOrPut   [cicatrix]
-> Patch19YearCacheGuardWrapper
-> guard HIT vel MISS + overwrite sub eadem clave
```

`executeUnpatchedYearNumberCacheDiagnostic` viam Stage 38 separatam servat. Ea eandem map key malam adhibet et stale HIT sine guardis adhuc producere potest.

Regressio Gradus 38 post adaptationem metadata tantum contra Stage 38 pristinum adhuc tres stale outputs et exitum 1 reddit; contra PATCH 19 transit. Probatio Gradus 39 primam MISS, HIT exactum trium guardorum, duo mismatch/overwrite consecutiva, HIT post overwrite et diagnosticum stale HIT exercet. Omnes regressiones Graduum 1–39 transeunt.

### Quod consulto nondum adest

Nulla clavis composita cache adest; map non mutatur a `year.number`. Nulla `oldStructureSauce`, nulla structure sauce cum target originali, nullus ghost sauce et nullus PATCH 20 praemature additus est. Gradus 40 debet DISCOVERY 20 tantum introducere.

## DISCOVERY 20 — structure sauce ex target originali

Gradus 40 `oldStructureSauce(calculationDay, originalTargetDay)` introducit. Helper non est token fictus: eandem `sauceWithOrderAt46Latch` productionis cum target originali vere exsequitur.

Via activa annum primum per PATCH 18 et cache guardatum PATCH 19 resolvit. Ex recordo anni `yearFirstDay = openGateDay + 1` derivatur et in report servatur. Tamen `Discovery20StructureSauceHandler` assumptionem historicam consulto servat et `LegacyStructureSauceAdapter` cum `originalTargetDay` vocat.

`LegacyStructureSelectorAdapter` sauce legacy immediate consumit. Token selectoris duas partes observabiles servat: `bowl2` et `orderAt46Latch`. Validator confirmat has partes ex ipsa `oldStructureSauce` venire; nullam sauce novam cum `yearFirstDay` computat.

Witness anni 5000 cum calculationDay Fundationis tres target originales intra eundem annum probat. Sauce normativa structurae semper ex `(calculationDay, yearFirstDay)` venit; sauce legacy pro tribus target distinctis differt et ad selector transit. Tres discrepantiae exactae fiunt. Omnes regressiones Graduum 1–39 transeunt.

### Quod consulto nondum adest

Nullus ghost sauce, nullus selector semanticus separatus, nulla recomputatio `sauce(calculationDay, yearFirstDay)` in production et nullus PATCH 20 adest. Gradus 41 debet oldStructureSauce vere exsequi sed output eius tantum ghost servare; selector tum solam sauce novam ex `yearFirstDay` videre debet.
