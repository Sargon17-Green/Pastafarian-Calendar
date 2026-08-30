# Gradus 56 correctivus — testimonia raw bowl sum

Hoc documentum Gradum 55 historicum non rescribit. Gradus 55 clausuram originalis lineae 55 graduum retinet; Gradus 56 est correctio post clausuram propter discrepantiam semanticam post primam commotionem post guttam 46.

## Discrimen exactum

Cicatrix A1 historica manet physice et exsequitur:

```text
rawBowlSum = summa(oldBowls)
savedOrderNumber = SAVE(rawBowlSum + 149*stir)
order = permutation(savedOrderNumber)
u_legacy = old[bowl] + 3*old[previous] + 5*old[next]
         + savedOrderNumber + stir + position^2
```

Detour Gradus 56, post realem executionem cicatricis, ex eodem snapshot legit:

```text
rawBowlSum = summa(oldBowls)
savedOrderNumber = SAVE(rawBowlSum + 149*stir)
order = permutation(savedOrderNumber)
u_correctum = old[bowl] + 3*old[previous] + 5*old[next]
           + rawBowlSum + stir + position^2
```

In utroque:

```text
new[bowl] = SAVE(u^2 + 7*old[previous]*old[next])
```

Sex crateres semper ex uno `oldBowls` leguntur et simul in exitum novum committuntur. `savedOrderNumber` manet unicus fons permutationis; detour guardat aequalitatem `rawBowlSum`, `savedOrderNumber` et permutationis inter computationem cicatricis et computationem correctam. Solum operandum in `u` mutatur.

## Forma spaghetti servata

`stage56LegacySavedOrderOperandScar` computat prius exitum veterem. `stage56RawBowlSumPostStirDetour` servat `oldResult`, deinde `correctedResult`, `rawBowlSum`, `savedOrderNumber`, ordines, indicem commotionis et flag applicationis. `sauceWithStage56RawBowlSumDetour` hoc par cicatrix-detour exacte duodecies vocat.

`BaseMonsterContext` statum invocation-localem Gradus 56 tenet, inter alia exitum veterem, exitum correctum, summam crudam, numerum ordinis servatum, indicem commotionis, numerum vocationum cicatricis, numerum applicationum et flag applicationis.

Via historica `calendarDateSpaghettiThroughStage55` semanticam clausam Gradus 55 retinet. Via publica finalis `calendarDateSpaghetti` Gradum 56 petit et cache structurale separatum habet. In constructione structurae anni ghost `structureSaucePatch` historicus adhuc currit ante recomputationem corrected sauce. Nullus oracle nec runtime alterius linguae in productione adhibetur.

## Testimonium discriminatoris et 12 commotiones

Probatio `tests/stage_56_raw_bowl_sum_corrective_tests.cpp` confirmat in duobus contextibus sauce realibus:

```text
legacyScarCallCount = 12
appliedCount        = 12
applied             = true
```

Pro omnibus 12 commotionibus probatis:

```text
rawBowlSum != savedOrderNumber
oldResult != correctedResult
legacyOrder == correctedOrder
correctedResult == formula C++ localis independenter recomputata
```

Audit staticus separatam probationem habet quae formulam veterem cum `+ savedOrderNumber` physice praesentem requirit et detour cum `+ rawBowlSum` separatam requirit.

## Sauce — Foundation

Pro:

```text
calculationDay = -15055671
targetDay      = -15055671
```

ordo guttae 46 est:

```text
[4,5,2,3,6,1]
```

Sex crateres finales corrigendi sunt:

```text
1 = 67068226522203060890658143482200172502
2 = 156830781782038036265833091137164500083
3 = 27860245395513113590943202859639481773
4 = 154958270957687565769906933601352753179
5 = 83762519477527209919484977230999195024
6 = 154633989471499313687998830839607736513
```

Hi sex valores et ordo guttae 46 congruunt cum oracle C++ locali correcto, qui formulam raw-bowl-sum independenter a productione recomputat.

## Sauce — c=t=-15048173

Pro:

```text
calculationDay = -15048173
targetDay      = -15048173
```

ordo guttae 46 est:

```text
[3,4,6,5,2,1]
```

Sex crateres finales corrigendi sunt:

```text
1 = 117774601791306122049402151598700069949
2 = 25984316916056421874135403969605614983
3 = 143826773047381553934876475558335320216
4 = 59571312657074816751803206901536426066
5 = 65620015217119503197726025514221700116
6 = 28674863197150075414624507047786307945
```

Etiam hic sex valores et ordo guttae 46 congruunt cum oracle C++ locali correcto.

## Quattuor witnesses canonici externi

Comparatio fit per indices canonicos, non per nomina translata. Omnes quattuor valores dati a testimonio externo reproducuntur exacte:

```text
(c,t)=(-15055671,-15055671) -> (5000,4,762,12,105)
(c,t)=(-15048173,-15048173) -> (5000,12,21,47,57)
(c,t)=(-15048173,-15048172) -> (5000,12,22,18,58)
(c,t)=(-15048173,-15048174) -> (5000,12,20,7,58)
```

Ita witnesses canonici externi sunt `4/4 PASS`.

## Testimonium externum directe inspectum

Commit testimonialis `d5cfe77ef7950a9a67ff0e6814833a3eedacae8a` directe per GitHub lectus est. In `browser/pastafari-calendar-fast.js` post-commotio duodecies `bowlSum = sum(oldBowls)` computat; `orderNumber = keep(bowlSum + 149*round)` permutationem eligit, sed formula `u` operandum `+ bowlSum` crudum accipit. Haec inspectio est testimonium formulae tantum: codex externus non copiatus, non importatus et non ad runtime productionis adhibitus est.

Numeri craterum infra a C++ locali independente, ex statu ante divergence iam congruenti et eadem formula raw-bowl-sum, reconstructi sunt; production eos exacte reproducit. Quattuor tuples canonici externi quoque exacte reproducuntur. Ita comparatio cross-engine est witness staticus formulae + reconstructio numerica independens, non fallback nec oracle externus runtime.

## Regressiones historicae

Fontes probationum historicorum Graduum 1–55 manent byte pro byte ut in clausura Gradus 55. Adapter probatorius `tests/stage_56_historical_path_compat.hpp` solum tempore compilationis nominis publici regressionum ad `calendarDateSpaghettiThroughStage55` dirigit. Sic regressiones historicae semanticam veterem exercent sine mutatione fontium suorum.

Resultatus finales regressionum et tempora servantur in `STAGE_56_LOCAL_TEST_LOG.txt` post completionem totius sweep.
