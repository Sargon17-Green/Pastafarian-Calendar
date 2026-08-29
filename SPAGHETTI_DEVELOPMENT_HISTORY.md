# Historia evolutionis monstri spaghetti

## Gradus 1 — Initium

Linea C++ et Neo-Latina ab initio constituta est. Nulla implementatio aliena lecta, translata, exsecuta, hash comparata aut adhibita est.

In productione addita est tantum infrastructura generalis: `BaseMonsterContext`, `BaseDispatcher`, `BaseValidationManager`, `BaseMetricsShell` et `BaseMonsterManager`. Haec elementa contextum unius invocationis possident et transitum determinatum per tres status initiales faciunt. Nulla cicatrix historica, nullum vitium legacy, nullus flag specificus emendationis et nullus detour futurus adhuc adest.

Oracle normativum mundum in ambitu probationum separato ex Appendice A scriptum est. Catalogus Neo-Latinus 17 nominum segmentorum et 47 nominum mensium per indices canonicos congelatus est. Fixtures initiales ab eodem oracle locali C++ generatae sunt.

Stratum monstri hoc gradu additum semanticam calendarii nondum definit; tantum disciplinam possessionis contextus, dispatchationis, validationis et observationis parat. Itaque infrastructura addita semantice iners est.

## Gradus 2 — Detectio 01: residuum ordinarium pro SAVE

### Quid putabatur

Stratum arithmeticum primum putabat residuum Euclideum ordinarium satis esse ubicumque valor intra circulum magni numeri servandus erat. Ex hac opinione introducta est functio `oldRemainder(x)`, quae simpliciter `regularMod(x, M_OLD)` reddit.

### Quid repertum est

Regressio nova viam productionis ipsam per `BaseMonsterManager`, `BaseDispatcher`, `Discovery01RemainderHandler` et `LegacyArithmeticAdapter` exercet atque exitum cum `SAVE` oraculi localis comparat. Pro `M`, `2M` et `3M`, functio legacy zerum reddit, dum regula normativa `M` requirit. Pro `M+1` ambae viae unum reddunt. Itaque vitium locale et fines eius manifeste detecti sunt.

### Quid circumventum est

Nihil adhuc circumventum est. Hic gradus correctionem vetat; `oldRemainder` in via activa manet et regressio nova consulto rubra est.

### Cur hoc adhuc aequivalentia normativa non est

Aequivalentia nondum obtinetur in multiplis `M`. Status `EXPECTED_RED` hanc discrepantiam documentat; regressiones Bootstrap anteriores tamen integrae transeunt.

### Stratum monstri hoc gradu additum

Additi sunt adapter arithmeticus legacy, handler proprius detectionis, status arithmetici in contextu et dispatchatio separata. Haec strata non corrigunt valorem nec oracle in productione vocant; tantum exitum legacy per viam productionis manifestum faciunt.

## Gradus 3 — Emendatio 01: SAVE super residuum ordinarium

### Quid putabatur

Vitium Gradus 2 non deletum est. `oldRemainder(x)` adhuc residuum Euclideum ordinarium reddit et pro multiplis exactis `M_OLD` zerum producit.

### Quid repertum est

Discrepantia est localis et exacte definita: residuum ordinarium iam cum `SAVE` concordat quoties residuum non est zerum. Solum classis multiplorum `M_OLD` aliam repraesentationem requirit.

### Quid circumventum est

Addita est `savePatch(x)`, quae `oldRemainder(x)` re vera vocat, exitum in `r` retinet, et tantum si `r == 0` valorem `M_OLD` substituit. `Patch01SaveWrapper` et `Patch01RemainderHandler` hanc emendationem super adapter legacy ponunt. Via diagnostica separata adhuc exitum incorreptum legacy manifestare potest.

### Cur hoc aequivalet normae

`oldRemainder(x)` semper unicum residuum Euclideum `r` cum `0 <= r < M_OLD` reddit. Definitio normativa `SAVE(x) = 1 + regularMod(x - 1, M_OLD)` eandem classem residui repraesentat per valores `1..M_OLD`: si `r != 0`, valor est ipse `r`; si `r == 0`, valor est `M_OLD`. Itaque conditionalis unica emendatio exacte eadem functio est pro omni integro.

### Stratum monstri hoc gradu additum

Additi sunt wrapper emendationis, handler novus, via dispatcher altera, status `patch01Applied`, valor legacy ante emendationem et validatio duplicata quae vetat patch residuum non-nullum mutare. Haec complexitas novam semanticam non fingit; solum cicatricem veterem retinet et transformationem exactam post eam imponit.

## Gradus 4 — Detectio 02: nota diei sine distinctione lateris posterioris

### Quid putabatur

Post primam emendationem arithmeticam systema vetus putabat numerum diei satis definiri duplicando distantiam absolutam a die Fundationis. Ex hac opinione nata est functio `oldDayTag(day) = 2 * abs(day - FOUNDATION_DAY_OLD)`. Formula unum tantum spatium metricum servat et distinctionem inter latera temporis non codificat.

### Quid repertum est

Regressio nova viam productionis per `BaseMonsterManager`, `BaseDispatcher`, `Discovery02DayTagHandler` et `LegacyDayTagAdapter` exercet, deinde valorem cum `dayCount` oraculi localis comparat. In `FOUNDATION` legacy `0` pro `1` reddit; in `FOUNDATION+1` legacy `2` pro `3`; in `FOUNDATION+2` legacy `4` pro `5`. Contra, in `FOUNDATION-1` et `FOUNDATION-2` valores pares `2` et `4` cum norma concordant.

Ita vitium non est simpliciter calculus distantiae falsus. Formula legacy recte describit partem anteriorem, sed diem Fundationis et partem posteriorem in classe pari relinquit ubi norma seriem imparem requirit.

### Quid circumventum est

Nihil adhuc circumventum est. Hic gradus `DISCOVERY` correctionem vetat. `oldDayTag` in via activa manet, eius exitus sine mutatione redditur, et regressio nova consulto rubra est.

### Cur hoc adhuc aequivalentia normativa non est

Pro die Fundationis et omnibus diebus posterioribus formula legacy ab `dayCount` differt. Ideo aequivalentia normativa hoc gradu nondum obtinetur. Regressiones Gradus 1–3 tamen integrae transeunt, atque `PATCH 01` nullo modo regressus est.

### Stratum monstri hoc gradu additum

Additi sunt `LegacyDayTagAdapter`, `Discovery02DayTagHandler`, status `legacyDayTagInput`, `legacyDayTagOutput`, `legacyDayTagReady`, validatio readiness et dispatchatio propria. Haec strata valorem legacy tantum transportant, observant et validant; eum non corrigunt et oraculum in productione non vocant. Ergo complexitas nova vitium historicum manifestat sine contaminatione emendationis futurae.

## Gradus 5 — Emendatio 02: cicatrix Fundationis super notam diei

### Quid putabatur

Vitium Gradus 4 non deletum est. `oldDayTag(day)` adhuc duplicat distantiam absolutam a Fundatione et distinctionem lateris posterioris ignorat. Ideo ipsa functio legacy in Fundatione zerum et post Fundationem numeros pares reddit.

### Quid repertum est

Discrepantia exacte localis est. Ante Fundationem valor legacy iam cum norma congruit. In Fundatione et post eam series normativa eadem distantia duplicata est, sed uno aucta. Correctio igitur non requirit novum calculum distantiae neque mutationem functionis veteris.

Praeterea inspectio regressionis Gradus 4 monstravit eam numerum discrepantiarum ex vocatione directa `oldDayTag` deduxisse. Forma illa patch viridem fieri vetabat dum cicatrix legacy servaretur. Structura regressionis hoc gradu emendata est ut eadem inputs et eadem valores normativos contra viam productionis metiatur. Forma correcta contra codicem Gradus 4 pristinum adhuc tres discrepantias et exitum `1` produxit; ergo correctio probationis vitium non abscondit.

### Quid circumventum est

Addita est `dayTagWithFoundationScar(day)`. Ea `oldDayTag(day)` primum vocat. Si `day >= FOUNDATION_DAY_OLD`, unum addit. Deinde custos secundus manet: si `day == FOUNDATION_DAY_OLD` et valor nondum unus est, valor ad unum ponitur. Custos secundus post primam regulam ordinariam redundans est, sed ex historia obligata non removetur.

`Patch02DayTagWrapper` hanc functionem tegit. `Patch02DayTagHandler` primum per `LegacyDayTagAdapter` valorem veterem colligit, deinde patch applicat, statum `patch02Applied` ponit, et validatorem separatam copiam regulae computare iubet. `executeUnpatchedDayTagDiagnostic` viam veterem adhuc directe exercere potest.

### Cur hoc aequivalet normae

Si `day < FOUNDATION_DAY_OLD`, `oldDayTag` reddit `2 * (FOUNDATION_DAY_OLD - day)`, quod est definitio normativa illius partis; patch nihil mutat.

Si `day >= FOUNDATION_DAY_OLD`, `oldDayTag` reddit `2 * (day - FOUNDATION_DAY_OLD)`, et patch unum addit. Hic est exacte `2 * (day - FOUNDATION_DAY_OLD) + 1`, inclusa Fundatione ubi valor fit unus. Custos secundus eundem valorem confirmat nec aliam semanticam inducit.

Ita patch omnibus diebus integeris cum `dayCount` normativo congruit.

### Stratum monstri hoc gradu additum

Additi sunt `patchedDayTagOutput`, `patch02Applied`, `Patch02DayTagWrapper`, `Patch02DayTagHandler`, dispatchatio propria, via diagnostica legacy et `requirePatch02Ready` cum computatione validationis duplicata. Semanticum state adhuc contextui unius invocationis proprium est. Metrics et branch trace exitum normativum non determinant.

## Gradus 6 — Detectio 03: distantia inter notas dierum

### Quid putabatur

Postquam notae dierum per cicatricem Fundationis correctae sunt, systema vetus putabat distantiam operis obtineri posse ex differentia absoluta duarum notarum iam correctarum. Ideo introducta est functio `oldDistance(cDay, tDay)`, quae `abs(dayTagWithFoundationScar(cDay) - dayTagWithFoundationScar(tDay))` reddit.

### Quid repertum est

Regressio nova viam activam `BaseMonsterManager::executeDistance` exercet et exitum cum `workCounts(...).distance` oraculi localis comparat. Quinque ex octo casibus discrepant: eadem dies zerum pro uno reddit; separatio duorum dierum eodem latere quattuor pro tribus reddit; transitus ab uno die ante Fundationem ad unum diem post eam unum pro tribus reddit.

Tres casus fortuito concordant, inter quos dies adiacentes eodem latere. Hoc ostendit vitium non posse simpliciter ex una constantia defecta describi: ipsa scala notarum inter latera et intra latera aliud spatium quam axis chronologicus exhibet.

### Quid circumventum est

Nihil hoc gradu circumventum est. `oldDistance` in via activa manet et regressio nova consulto rubra est. Nullus `patchedCounts`, nullus `Patch03`, nullus calculus `chronological` et nullus status emendationis tertiae introductus est.

Auditum temporalem probationis Gradus 5 necesse fuit restringere: in illo gradu `oldDistance` iure prohibebatur quia adhuc futurum erat, sed in hoc gradu ipsum legacy introduci debet. Solum prohibitio temporalis huius nominis remota est; auditum contra PATCH 03 ipsum manet, atque omnia expected values PATCH 02 integra sunt.

### Cur hoc adhuc aequivalentia normativa non est

Norma distantiam definit ut `abs(targetDay - calculationDay) + 1`. Via legacy autem differentiam notarum dierum reddit. Cum hae quantitates in pluribus inputibus differant, aequivalentia nondum obtinetur. Status `EXPECTED_RED` hanc condicionem exacte significat.

### Stratum monstri hoc gradu additum

Additi sunt status distantiae legacy in `BaseMonsterContext`, `LegacyDistanceAdapter`, `Discovery03DistanceHandler`, dispatchatio separata et `LegacyDistanceReport`. Relatio exitum legacy separatim servat ut cicatrix post patch futurum probari possit. Haec omnia contextui invocationis propria sunt; nullum state semanticum globaliter communicatur et observationes non regunt exitum.

## Gradus 7 — Emendatio 03: distantia chronologica super differentiam notarum

### Quid putabatur

Vitium Gradus 6 non deletum est. `oldDistance(cDay, tDay)` adhuc differentiam absolutam notarum dierum correctarum computat. Formula illa in nonnullis casibus fortuito congruit, sed neque eandem scalam chronologicam neque inclusionem utriusque finis generaliter repraesentat.

### Quid repertum est

Regressio Gradus 6 iam ostenderat quinque classes discrepantes: eadem dies, separatio duorum dierum eodem latere et transitus per Fundationem. Ex hoc sequitur correctionem non posse fieri sola additione unius ad exitum legacy, quia exempli gratia `DUO_POST` legacy quattuor reddit ubi distantia inclusiva normativa tres est.

Praeterea auditum probationum priorum recognitum est. Gradus 5 et 6 recte vetabant PATCH 03 dum futurum erat, sed prohibitiones nominum patch non sunt invariantae perpetuae postquam gradus patch ipse venit. Illae tantum partes temporales remotae vel in assertionem perpetuam cicatricis conversae sunt; expected values et probationes semanticae non mutatae sunt. Forma correcta regressionis Gradus 6 contra productionem Gradus 6 pristinam adhuc quinque discrepantias et exitum rubrum produxit.

### Quid circumventum est

Addita est `distanceWithChronologicalPatch(calculationDay, targetDay, legacyDistance)`. Ea exitum `oldDistance` accipit, deinde `chronological = abs(targetDay - calculationDay)` computat. Si exitus legacy ab hoc valore differt, variabile locale legacy valore chronologico superatur. Deinde unum additur.

`Patch03DistanceHandler` primum per `LegacyDistanceAdapter` `oldDistance` re vera vocat, exitum veterem in contextu retinet, et tantum postea `Patch03DistanceWrapper` applicat. `executeUnpatchedDistanceDiagnostic` viam veterem adhuc exercet sine patch.

### Cur hoc aequivalet normae

Post conditionalem, valor localis `d` necessario aequalis est `abs(targetDay - calculationDay)`: si legacy iam concordabat, nihil mutatur; si discrepabat, expresse substituitur. Exitus est deinde `d + 1`, id est exacte definitio normativa distantiae operis.

Validatio separata eandem quantitatem iterum computat et solum invariantiam confirmat. Non eligit inter duas responsiones et non vocat oracle productionis.

### Stratum monstri hoc gradu additum

Additi sunt `patchedDistanceOutput`, `patch03Applied`, `Patch03DistanceWrapper`, `Patch03DistanceHandler`, dispatchatio patch separata, via diagnostica legacy et `requirePatch03Ready`. Relatio distantiae simul exitum auctoritative correctum et exitum legacy ante patch servat. Haec duplicatio audibilitatem cicatricis auget, sed semanticam unicam non bifurcat.

## Gradus 8 — Detectio 04: mutatio lapidum sequentialis

### Quid putabatur

Post arithmeticam fundamentalem emendatam systema vetus fabricam quinque lapidum ut mutationem ordinariam eiusdem recordi implementavit. `mutateStonesWrong(i, S)` partes quinque ordine scribit et putat unamquamque formulam adhuc statum eiusdem lapidis veterem legere.

In re autem assignmentes iam factae statum mutant. Hordeum triticum novum legit; sal hordeum novum; amarum sal novum; rubrum plures valores iam mutatos. Ita una translatio conceptu simultanea in seriem dependentiarum intra eandem iterationem conversa est.

### Quid repertum est

`buildStonesThroughWrongLegacyMutation` mechanismum legacy ad lapides 2–46 adhibet et via activa eum per `LegacyStoneMutationAdapter` atque `Discovery04StoneMutationHandler` exponit. Regressio tabulam hanc cum `buildStones()` oraculi C++ localis comparat.

Lapis primus concordat omnino. In lapide secundo pars tritici adhuc concordat, quia prima formula solum semen vetus legit; partes autem 2–5 iam discrepant. Exempli gratia hordeum normativum `1073` est, legacy `1434`; sal `2375` contra `3780`; amarum `6195` contra `9932`; rubrum `10493` contra `25047`.

A lapide tertio contaminatio prioris lapidis etiam ad triticum propagatur. Summa regressionis est 224 discrepantiae componentium, cum regressiones Graduum 1–7 omnes transeant.

### Quid circumventum est

Nihil hoc gradu circumventum est. `mutateStonesWrong` et builder eius sunt ipsa via activa. Nullus snapshot status veteris, nullus clone ad vocationem legacy, nullum overwrite quinque valorum et nullus `stonePatch` introductus est. Regressio igitur consulto rubra manet.

### Cur hoc adhuc aequivalentia normativa non est

Norma requirit ut quinque valores lapidis `i` omnes ex uno snapshot lapidis `i-1` computentur et tantum deinde simul substituantur. Legacy autem mutationes medias in computationes subsequentes eiusdem gradus reducit. Quia tabula activa in 224 componentibus a tabula normativa differt, aequivalentia hoc gradu nondum obtinetur.

### Stratum monstri hoc gradu additum

Additi sunt `Stone`, `StoneTable`, status `legacyStoneTable` et `legacyStoneTableReady`, `LegacyStoneMutationAdapter`, `Discovery04StoneMutationHandler`, dispatchatio propria, relatio `LegacyStoneTableReport` et validatio readiness. Validatio semen confirmat et completionem viae requirit, sed valores posteriores non normalizat. Omnis mutatio tabulae intra contextum unius invocationis manet et observationes non determinant semanticam.

## Gradus 9 — Emendatio 04: snapshot quinque lapidum super mutationem sequentialem

### Quid putabatur

Vitium Gradus 8 integrum relinquitur. `mutateStonesWrong` adhuc recordum quinque partium ordine mutat, ita partes posteriores valores iam novos eiusdem transitionis legunt. Functio non refacta nec ad formulam simultaneam conversa est.

### Quid repertum est

Regressio Gradus 8 monstraverat 224 discrepantias componentium. Ex forma ipsius mutationis patet causam esse contaminationem intra unam transitionem: prima pars lapidis secundi adhuc ex semine veteri procedit, sed hordeum iam triticum novum legit, sal hordeum novum, amarum sal novum, atque rubrum plures partes mutatas.

Probatio Gradus 8 etiam metadata exacta handler/status figebat. Haec metadata non sunt semantica normativa et necessario mutari debent cum wrapper PATCH 04 in viam auctoritative additur. Assertio metadata igitur ad duas formas historice legitimas dilatata est; indices, expected values et comparatio tabulae cum oraculo non mutata sunt. Eadem forma probationis contra codicem Gradus 8 pristinum iterum currens 224 discrepantias et exitum `1` adhuc produxit.

### Quid circumventum est

Addita est `stonePatch(i, state)`. Ea `old = state` capit, deinde `mutateStonesWrong(i, state)` re vera vocat et exitum in `garbage` accipit. Legacy igitur non est codex mortuus neque vocatio ficta. Postea omnes quinque partes `garbage` expresse superimponuntur formulis quarum omnes reads ex `old` veniunt.

`buildStonesThroughLegacyBuilder` transit per `stonePatch` pro lapidibus 2–46. `Patch04StoneMutationHandler` etiam tabulam totam legacy per adapter separatam computat et in contextu servat ut cicatrix observabilis maneat. Via `executeUnpatchedStoneTableDiagnostic` adhuc tabulam veterem sine patch reddit.

### Cur hoc aequivalet normae

Pro quolibet gradu `i`, `old` est exacta copia lapidis `i-1`. Quinque formulae overwrite legunt tantum `old`, ergo nulla pars nova potest aliam partem novam eiusdem gradus contaminare. Formulae quinque sunt eadem quae Appendix normativa pro tritico, hordeo, sale, amaro et rubro praescribit; substitutio fit tantum postquam omnes valores ex eodem snapshot computati sunt.

Vocatio `mutateStonesWrong` semanticam finalem non mutat, quia quinque eius exitus omnes ante return superimponuntur. Sic cicatrix legacy physice et operationaliter manet, dum tabula auctoritative exacte cum tabula normativa congruit.

### Stratum monstri hoc gradu additum

Additi sunt `patchedStoneTable`, `patch04Applied`, `Patch04StoneSnapshotWrapper`, `Patch04StoneMutationHandler`, dispatchatio patch separata, via diagnostica legacy et `requirePatch04Ready`. Validator computationem quinque partium ex snapshot iterat ut COPY_VALIDATION; discrepantia invariant error est, non electio inter responsiones. Report utramque tabulam servat, sed solum `patchedStoneTable` est exitus auctoritative.

## Gradus 10 — Detectio 05: repositio retrograda guttarum occultarum

### Quid putabatur

Postquam tabula lapidum per snapshot emendata est, subsystema guttarum occultarum septem valores recte computare coepit. Structura repositionis tamen ex versione antiqua orta erat, in qua elementa physice ordine `hidden7, hidden6, ..., hidden1` servabantur. Codex consumptor putabat autem locum primum esse `hidden1`, secundum `hidden2` et sic porro.

### Quid repertum est

`makeHiddenLegacyValue(k, ...)` eadem semantica ac Appendix normativa utitur: maneries actionis, target, distantiae, connectionis et directionis iam per cicatrices Graduum 1–3 correctae sunt; lapides ex fabricatore Gradus 9 proveniunt; septem grindes eodem ordine lapidum fiunt. Deinde `buildHiddenWithBackwardStorage` valorem k in locum `8-k` scribit.

Regressio `stage_10_discovery_05_tests.cpp` primum probat omnes septem valores in repositione retrograda exacte ibi inveniri ubi ex inverso ordine exspectantur. Haec probatio transit, ergo formulae guttarum ipsae rectae sunt. Deinde eandem seriem sine translatione quasi ordinem proximitatis comparat cum oraculo. Sex positiones discrepant; sola gutta quarta propter centrum inversionis concordat.

### Quid circumventum est

Nihil hoc gradu circumventum est. `Discovery05HiddenStorageHandler` repositionem retrogradam directe in `report.output` exponit. Nulla functio `hiddenByNearness`, nulla translatio `8-k`, nulla inversio seriei et nullus PATCH 05 introductus est. Regressio nova consulto rubra manet.

### Cur hoc adhuc aequivalentia normativa non est

Norma consumptoribus ordinem semanticum `hidden1..hidden7` praebet. Via activa autem ordinem physicum retrogradum reddit. Quamquam singuli valores recti sunt, identitas positionis est pars semantica quia guttae visibiles postea predecessores 1/3/7 per proximitatem petent. Sex positiones iam in test locali discrepant, ergo aequivalentia nondum obtinetur.

### Stratum monstri hoc gradu additum

Additi sunt `HiddenDrops`, duo campi repositionis retrogradae in `BaseMonsterContext`, `LegacyHiddenStorageAdapter`, `Discovery05HiddenStorageHandler`, `LegacyHiddenReport`, validator promptitudinis et dispatchatio propria. Formula guttarum occultarum etiam per cicatrices anteriores transit, ita dependentia indirecta crescit. Omne state semanticum contextui invocationis proprium manet; observationes non regunt exitum.

## Gradus 11 — Emendatio 05: accessus proximitatis super repositionem retrogradam

### Quid putabatur

Vitium Gradus 10 non in valoribus guttarum occultarum sed in interpretatione locorum erat. Repositio legacy physice `hidden7, hidden6, ..., hidden1` continet. Delere hanc ordinationem aut seriem in-place invertere historiam architecturalem destrueret et sequentem vitium historiae guttarum minus fidelem redderet.

### Quid repertum est

Regressio Gradus 10 iam demonstraverat relationem exactam `legacyOutput[8-k] == hidden[k]` omnibus septem guttis. Ergo nulla recomputatio guttarum, nulla mutatio formulorum et nulla repositio nova requiritur. Correctio potest esse pure accessus: pro proximitate semantica `k`, locus physicus est `8-k` in numeratione unum-basata.

Inspectio harness etiam ostendit regressionem Gradus 10 clausulam temporalem habuisse quae sex discrepantias expresse requirebat. Haec clausula DISCOVERY rubrum recte certificabat, sed PATCH viridem impossibilem faciebat. Eadem inputs, eadem expected values et eadem probatio ordinis retrogradi servata sunt; solum exitus mutatus est ut sex discrepantiae ante patch exitum `1`, nullae post patch transitum, alius numerus defectum inopinatum significet. Contra codicem Gradus 10 pristinum forma correcta adhuc exactas sex discrepantias et exitum `1` produxit.

### Quid circumventum est

Addita est `hiddenByNearness(backwardStorage, k)`. Ea range 1..7 validat, `oneBasedSlot = 8-k` computat, deinde `backwardStorage[oneBasedSlot-1]` legit. `buildHiddenWithBackwardStorage` ne uno quidem passu mutatum est et nulla `reverse` operatio addita est.

`Patch05HiddenStorageHandler` primum per `LegacyHiddenStorageAdapter` repositionem retrogradam re vera fabricat et in `legacyHiddenBackward` servat. Deinde `Patch05HiddenNearnessWrapper` septies vocatur, semel pro unoquoque k, ut `patchedHiddenNearness` construatur. Hic array secundus est visio semantica output, non mutatio neque inversio storage legacy.

`executeUnpatchedHiddenStorageDiagnostic` viam Gradus 10 adhuc exercet et sex discrepantias observabiles servat.

### Cur hoc aequivalet normae

Ex invariantia Gradus 10, valor normativus hidden `k` iacet in loco physico unum-basato `8-k`. `hiddenByNearness` exacte illum locum legit. Itaque pro omni `k` inter 1 et 7 exitus accessorii est valor normativus hidden `k`.

Quia patch storage non mutat, cicatrix `hidden7..hidden1` integra manet. Quia omnis lectio auctoritative huius gradus per wrapper ad accessor transit, ordo semanticus externus est tamen `hidden1..hidden7`. Test novus utramque proprietatem simul confirmat.

### Stratum monstri hoc gradu additum

Additi sunt `patchedHiddenNearness`, `patch05Applied`, `Patch05HiddenNearnessWrapper`, `Patch05HiddenStorageHandler`, dispatchatio patch separata, via diagnostica legacy et `requirePatch05Ready`. Validator mapping octo-minus-k iterat ut COPY_VALIDATION, sed oracle in productione non vocat. Nullum state PATCH 06, nulla historia visibilium et nullus `legacyPrior` introductus est.

## Gradus 12 — Detectio 06: helper prioris solum historiam visibilem novit

### Quid putabatur

Postquam repositio guttarum occultarum per mapping `8-k` correcta est, subsystema vetus ad guttas visibiles venire poterat. Helper ad valores antecedentes legendos simplicissimus erat: `legacyPrior(dropStore, i, back)` indicem `i-back` calculabat et ex historia visibili iam scripta legebat. Auctor huius helper putabat omnem predecessorem necessarium iam in eodem store visibili exsistere.

Haec opinio valet tantum postquam satis multae guttae visibiles scriptae sunt. In initio seriei autem norma predecessors negativos conceptuales per septem guttas occultas supplet.

### Quid repertum est

`legacyPrior` consulto tantum indices `1..i-1` accipit. Historia `[101,202,303]` cum `i=4` demonstrat helper ipsum in suo dominio rectum esse: `back=1,2,3` reddit `303,202,101`. Petitio `back=4` iam extra historiam visibilem cadit et reicitur.

Vitium apparet perfecte in `i=1`. Norma semantica habet septem predecessors validos: `back=1` significat `hidden1`, usque ad `back=7` quod `hidden7` significat. Sed `i-back` tunc est `0,-1,-2,-3,-4,-5,-6`. Helper legacy nullum horum indicum intellegit et septem errores emittit.

Regressio Gradus 12 valores occultos ex oraculo C++ locali computat, sed via productionis eos non legit. Omnes septem petitiones ergo `NON_RESOLUTUS` sunt; regressiones Graduum 1–11 manent virides.

### Quid circumventum est

Nihil hoc gradu circumventum est. `BaseMonsterManager::executePrior` transit directe per `Discovery06PriorHandler`, `LegacyPriorAdapter` et `legacyPrior`. Quamquam dies calculationis et target in contextu praesto sunt, handler eos ad guttas occultas fabricandas vel quaerendas non adhibet.

Nullus `priorPatch`, nullus catch cum supplemento occulto, nullus mapping ad `hiddenByNearness` et nullus state PATCH 06 introductus est. Error legacy igitur usque ad superficiem regressionis ascendit.

### Cur hoc adhuc aequivalentia normativa non est

Appendix normativa guttae visibili `i` tres predecessors ex intervallis 1, 3 et 7 tribuit; in primis positionibus hi predecessors ex septem guttis occultis venire possunt. Accessor qui solum store visibilem legit non potest seriem a `i=1` construere.

Septem petitiones fundamenti testis iam demonstrant domain gap exactum. Quia via activa valores semantice existentes ut inexsistentes tractat, aequivalentia normativa hoc gradu nondum obtinetur.

### Stratum monstri hoc gradu additum

Additi sunt `VisibleDropStore`, campi `legacyPriorDropStore`, `legacyPriorI`, `legacyPriorBack`, `legacyPriorOutput`, `legacyPriorReady`, relatio `LegacyPriorReport`, `LegacyPriorAdapter`, `Discovery06PriorHandler`, dispatchatio propria et validatio readiness. Haec structura errorem historicum per viam realem exponit et locum organicum futuro PATCH 06 parat, sed ipsum patch nondum continet.

## Gradus 13 — PATCH 06: historia occulta supra helper visibilem

### Quid repertum erat

Gradus 12 demonstravit `legacyPrior(dropStore,i,back)` in suo dominio visibili rectum esse, sed indices `0..-6` ignorare. Pro prima gutta visibili hoc septem predecessors semantice existentes tamquam absentia tractabat. Helper ipsum corrigere vetitum est, quia cicatrix historica manere debet.

### Quid circumventum est

Addita est functio `priorPatch(dropStore, backwardStorage, i, back)`. Ea primum `slot = i-back` calculat. Si `slot >= 1`, exactum helper `legacyPrior` vocat. Aliter `hiddenK = 1-slot` calculat et `hiddenByNearness(backwardStorage, hiddenK)` reddit. Ergo mapping normativum `slot=0 -> hidden1`, `slot=-1 -> hidden2`, usque ad `slot=-6 -> hidden7` servatur.

`Patch06PriorHandler` repositionem occultam productionis ex lapidibus iam per PATCH 04 correctis fabricat, deinde viam slot positivam vel occultam expresse notat. `Patch06PriorWrapper` solum ad `priorPatch` delegat. `executeUnpatchedPriorDiagnostic` handler Gradus 12 adhuc exercet, itaque petitio occulta sine patch adhuc errorem legacy producit.

### Cur hoc aequivalet normae

Pro `slot >= 1`, valor normativus est gutta visibilis iam scripta in indice `slot`; `legacyPrior` exactum eundem locum legit. Pro `slot <= 0`, definitio patch dat `k = 1-slot`; hic est exacte numerus propinquitatis guttae occultae. PATCH 05 iam probavit `hiddenByNearness` valorem hidden k per storage retrogradum recte reddere. Ergo utraque pars partitionis slot valorem normativum reddit.

Comprobator productionis logicam iterum ut COPY_VALIDATION computat, non oracle testium vocat. Responsum semanticum ab una via patch venit.

### Regressio Gradus 12 recognita

Forma Gradus 12 fixerat `status` et `handler` ad nomina DISCOVERY, quae mutationem organicam ad handler PATCH impediebant. Solum haec verificatio meta-path relaxata est ut vel via DISCOVERY vetus vel via PATCH nova legitima sit. Expected values et assertiones semanticae non mutatae sunt.

Contra codicem Gradus 12 pristinum forma correcta adhuc septem `NON_RESOLUTUS`, `REGRESSIO_DISCOVERY_06_DEFECIT` et exitum `1` produxit. Contra Gradum 13 eadem probatio transit.

### Stratum monstri hoc gradu additum

Additi sunt `priorPatch`, `patch06HiddenBackward`, `patchedPriorOutput`, duae notae viae, `patch06Applied`, `Patch06PriorWrapper`, `Patch06PriorHandler`, `dispatchPatchedPrior`, `requirePatch06Ready` et `executeUnpatchedPriorDiagnostic`. Relatio prioris nunc exitum legacy ante patch et viam electam retinet. `legacyPrior` ipse immutatus manet.

Nulla structura Gradus 14 vel PATCH 07 addita est.

## Gradus 14 — Detectio 07: numeratio molitionis ab uno contra tabulam a nullo

### Quid putabatur

Subsystema guttarum visibilium iam habebat tres predecessores recte resolvendos post PATCH 06. Tabula undecim molitionum etiam ordines reales rectos continebat. Caller vetus tamen ex conventionibus anterioribus numerum molitionis ut indicem directum tractabat, quasi numeratio semantica et numeratio physica eundem initium haberent.

### Quid repertum est

Tabula legacy undecim ordines reales continet in locis physicis `0..10`, sed `legacyGrindRow(grind)` numero semantico `1..11` directe utitur. Regresso localis ostendit omnes undecim petitiones a norma discrepare. Molitio 1 ordinem 2 legit, molitio 10 ordinem 11 legit, et molitio 11 extra tabulam cadit. Primus ordo realis numquam legitur.

Discrimen igitur non est in coefficientibus nec in ordine ipsorum undecim ordinum. Ipsi ordines in tabula recti sunt; vitium est sola conventio indicis inter vocatorem et repositionem.

### Quid circumventum est

Nihil hoc gradu circumventum est. `LegacyGrindTableAdapter` et `Discovery07GrindIndexHandler` exactam conventionem veterem exercent et eventum pravum exponunt. Ordo absens pro molitione 11 ut `found=false` servatur; nullus valor substitutus est et nulla correctio per recovery facta est.

### Cur hoc adhuc aequivalentia normativa non est

Norma undecim molitiones reales ordine 1..11 requirit. Via activa autem ordines 2..11, deinde absentiam, producit. Quia omnis petitio ab ordine normativo suo differt, aequivalentia hoc gradu nondum obtinetur.

### Stratum monstri hoc gradu additum

Additi sunt `GrindStoneKind`, `VisibleGrindRow`, `LegacyGrindLookup`, tabula legacy a nullo numerata, `legacyGrindRow`, campi contextus molitionis, `GrindLookupReport`, `LegacyGrindTableAdapter`, `Discovery07GrindIndexHandler`, dispatchatio propria et validatio readiness. Validatio confirmat vocator legacy ordinalem semanticum directe ut indicem physicum adhibuisse; vitium non corrigit. Omne state adhuc uni invocationi proprium est.

## Gradus 15 — PATCH 07: sentinella in indice nullo sine mutatione calleris

### Quid repertum erat

Gradus 14 demonstravit undecim ordines ipsos rectos esse, sed tabulam legacy a nullo numeratam et callerem ab uno numerantem inter se discrepare. Mutare callerem ad `grind-1` vitium historicum deleret et formam patch praescriptam violaret.

### Quid circumventum est

Tabula legacy `legacyVisibleGrindTableZeroBased()` cum undecim ordinibus in `0..10` integra manet, et `legacyGrindRow(grind)` adhuc indicem directum adhibet. Addita est altera tabula `grindTableWithSentinel()` cum duodecim locis. Locus 0 est sentinella exacta `{NONE,0,0,0,0}`; undecim ordines reales in locis 1..11 servantur.

`Patch07GrindIndexHandler` primum `LegacyGrindTableAdapter::read` re vera vocat et exitum pravum in contextu retinet. Deinde `Patch07SentinelGrindWrapper` eundem numerum `grind` sine translatione ad `grindRowWithSentinel` mittit. Ita indexing legacy non corrigitur; structura datae circa eum mutatur.

Sentinella non est temporalis. Ex hoc gradu pars cicatricis permanens est et in evolutione posteriore non removenda.

### Cur hoc aequivalet normae

Pro omni molitione semantica `g` inter 1 et 11, tabula patched ordinem normativum `g` exacte in loco physico `g` servat. Caller directe locum `g` petit. Ergo lectio patched exactum ordinem normativum reddit sine conversione indicis.

Comprobator productionis eandem relationem per COPY_VALIDATION confirmat. Testis PATCH 07 sentinellam exactam, omnes undecim ordines, cicatricem tabulae veteris et diagnosticum sine patch simul probat.

### Regressio Gradus 14 recognita

Additio valoris enum technici `NONE` warning in printer testis Gradus 14 creabat. Printeri solum ramus `default` additus est; nulla expected value, nulla comparatio molitionis et nulla ratio discrepantiarum mutata est. Contra codicem Gradus 14 pristinum probatio recognita adhuc undecim discrepantias et exitum `1` reddit. Contra PATCH 07 nunc transit.

### Stratum monstri hoc gradu additum

Additi sunt `GrindStoneKind::NONE`, `grindTableWithSentinel`, `grindRowWithSentinel`, `patchedGrindOutput`, `patchedGrindFound`, `patch07Applied`, `Patch07SentinelGrindWrapper`, `Patch07GrindIndexHandler`, `dispatchPatchedGrindIndex`, `requirePatch07Ready` et `executeUnpatchedGrindDiagnostic`. `GrindLookupReport` nunc exitum legacy ante patch et signum patch servat.

Nullus codex DISCOVERY 08 vel PATCH 08 additus est.

## Gradus 16 — Detectio 08: rank permutationis zero-based sub ordinali one-based

### Quid putabatur

Post sentinellam molitionis, subsystema ad ordinem sex craterum pervenit. Helper vetus permutationis ab indice mathematico nullo incipiebat: `oldPermutationUnrank0(rank0)` spatium exactum `0..719` in ordinem lexicographicum sex elementorum vertebat. Caller autem numerum ordinis iam semanticum et one-based tractabat. Quia utraque pars numeros parvos integros videbat, conventio diversae originis diu latere potuit.

### Quid repertum est

Helper legacy in proprio dominio rectus est. `oldPermutationUnrank0(0)` identitatem `[1,2,3,4,5,6]` reddit et `oldPermutationUnrank0(719)` ultimam permutationem `[6,5,4,3,2,1]` reddit; rank0 720 rite reicitur.

Vitium nascitur in via activa. `Discovery08PermutationRankHandler` ordinalem calleris `1..720` sine ulla translatione in `legacyPermutationRank0Input` ponit et ad adapter transmittit. Itaque ordinalis 1 permutationem rank0 1, ordinalis 2 rank0 2 et sic porro legit. Ordinalis 720 omnino extra dominium helperis cadit.

Regressio localis quinque puncta marginis et initii probat. Omnia quinque discrepant: 1, 2, 3 et 719 permutationem sequentem accipiunt; 720 absentem accipit. Omnes regressiones priorum graduum manent virides.

### Quid circumventum est

Nihil hoc gradu circumventum est. `oldPermutationUnrank0` non mutatur ad conventionem one-based neque caller subtractio unius facit. `LegacyPermutationAdapter` helper zero-based directe vocat; `Discovery08PermutationRankHandler` rank one-based directe ut rank0 servat et eventum vel reiectionem exponit.

### Cur hoc adhuc aequivalentia normativa non est

Norma permutationis ordinales `1..720` requirit, ubi 1 est prima permutatio et 720 ultima. Via activa autem functioni zero-based eosdem numeros transmittit. Pro `1..719` hoc est exacta translatio +1 in ordine lexicographico; pro 720 est extra fines. Ergo ne primus neque ultimus terminus normativus recte redditur.

### Stratum monstri hoc gradu additum

Additi sunt `PermutationOrder`, campi contextus rank calleris et rank0 legacy, `PermutationRankReport`, `oldPermutationUnrank0`, `LegacyPermutationAdapter`, `Discovery08PermutationRankHandler`, validator structurae permutationis et dispatchatio propria. Error rank0 720 in handler in statum `found=false` convertitur ut regressio divergence totam viam observare possit; nulla substitutio semantica fit.

Nullus bridge one-based, nullus wrapper PATCH 08 et nulla structura pours sequentis gradus addita est.

## Gradus 17 — PATCH 08: pons one-based ad rank zero-based permutationis

### Quid repertum erat

Gradus 16 demonstravit `oldPermutationUnrank0(rank0)` in proprio dominio `0..719` rectum esse. Defectus erat conventio calleris: ordinalis semanticus one-based directe in argumentum zero-based mittebatur. Inde ordines 1..719 ad permutationem sequentem movebantur et 720 reiciebatur.

Auxiliatorem legacy corrigere aut ad conventionem one-based mutare cicatricem deleretur. Praescriptum etiam expresse iubet catena per `drop` servari: ordinalis one-based primum per modulo normativum formandus est, deinde unum subtrahendum ante auxiliatorem zero-based.

### Quid circumventum est

`oldPermutationUnrank0` immutatus manet. `Patch08PermutationRankHandler` primum ordinem one-based normalizatum directe ut rank0 ad `LegacyPermutationAdapter` mittit et exitum pravum vel reiectionem in contextu retinet. Haec vocatio legacy non deletur.

Postea `Patch08PermutationRankWrapper::resolve` exactam catenam exsequitur:

```text
oneBased = regularMod(drop-1,720)+1
legacyRank0 = oneBased-1
order = oldPermutationUnrank0(legacyRank0)
```

Exitus emendatus, uterque rank et `drop` originalis in contextu servantur. `executePermutationOrder` compatibilitatem testium priorum servat delegando ad `executePermutationFromDrop`; `executeUnpatchedPermutationDiagnostic` viam erratam veterem separatam retinet.

### Cur hoc aequivalet normae

`regularMod(drop-1,720)+1` semper ordinalem in `1..720` reddit. Subtractio unius bijectionem exactam ad indices `0..719` facit. `oldPermutationUnrank0` iam Gradus 16 probavit se hunc dominium lexicographicum recte unrankare. Compositio igitur exactam permutationem ordinalis one-based normativi reddit.

Comprobator productionis hanc relationem iterum ut COPY_VALIDATION computat et exitum helperis zero-based cum exitu emendato comparat. Oracle testium productione non vocatur.

### Regressio Gradus 16 immutata

`tests/stage_16_discovery_08_tests.cpp` nullo modo mutatus est. Contra codicem Gradus 16 pristinum adhuc exactas quinque discrepantias et exitum `1` producit. Contra Gradum 17 eadem probatio transit, quia `executePermutationOrder` nunc per patch transit.

Regressio PATCH 08 addita etiam `drop=721`, `0`, `-1` et `1441` probat, ut reductionem modularem ipsam, non sola subtractio rank, verificetur. Via diagnostica confirmat cicatricem veterem adhuc observabilem esse.

### Stratum monstri hoc gradu additum

Additi sunt `Patch08PermutationResolution`, `Patch08PermutationRankWrapper`, `Patch08PermutationRankHandler`, `dispatchPatchedPermutationRank`, `executePermutationFromDrop`, `executeUnpatchedPermutationDiagnostic`, status permutationis emendatae, exitus legacy ante patch et `requirePatch08Ready`. `Patch08PermutationRankHandler` duas vocationes auxiliatoris continet: unam legacy pravum observabilem et alteram per pontem emendatum.

Nullus `bowlAlias`, nullus PATCH 09 et nulla logica fusionum introducta est.

## Gradus 18 — Detectio 09: fusiones ad crateres fixos pro positionibus ordinis

### Quid putabatur

Post PATCH 08, ordo sex craterum per permutationem one-based iam exactus erat. Vetus subsystema fusionum tamen ante hanc conventionem stabilitam nata erat et tres primas fusionum lecturas quasi tres primae positiones semper crateres cum ID 1, 2 et 3 significarent tractabat. Quia ordo identitas in aliquibus guttis occurrit, error diu latere potuit.

### Quid repertum est

`legacyPoursToFixedBowlIds` ordinem permutationis recte computat, sed ipsum ordinem ad lecturas craterum non applicat. Prima fusio tritici semper `oldBowls[0]`, secunda hordei semper `oldBowls[1]`, tertia salis semper `oldBowls[2]` legit. Sic loca semantica 1,2,3 falso cum IDs craterum fixis 1,2,3 confunduntur.

Regressio duos casus ostendit. `drop=1` ordinem identitatem reddit et defectus accidentaliter non apparet. `drop=241` ordinem `[3,1,2,4,5,6]` reddit; ibi omnes tres fusiones differunt a formula normativa quia norma crateres 3,1,2 per positionem legit, legacy autem 1,2,3.

### Quid circumventum est

Nihil hoc gradu circumventum est. `LegacyFixedPourAdapter` functionem legacy directe vocat, `Discovery09FixedPourHandler` tres exitus pravas in contextu servat et eas per viam activam exponit. Ordo rectus in contextu simul servatur ut causa discrepantiae observabilis maneat.

### Cur hoc adhuc aequivalentia normativa non est

Norma fusionis definit lecturam crateris per positionem ordinis permutationis. Via activa autem ipsos IDs fixos 1,2,3 legit. Ubi `order[1..3]` non sunt `1,2,3`, termini multiplicativi mutantur et exitus SAVE mutantur. Ergo via huius gradus consulto non est normativae aequivalens.

### Stratum monstri hoc gradu additum

Additi sunt `BowlState`, `PourTriplet`, `LegacyFixedPourComputation`, `legacyPoursToFixedBowlIds`, campi contextus fusionum, `LegacyFixedPourReport`, `LegacyFixedPourAdapter`, `Discovery09FixedPourHandler`, `requireLegacyFixedPourReady`, `dispatchLegacyFixedPours` et `executeFixedPours`. Contextus servat simul ordinem rectum et IDs fixos erratos, ut cicatrix semantica ante correctionem sequentem clare observetur.

Nullus `bowlAlias`, nullus PATCH 09, nullus `vaultOld` et nulla logica PATCH 10 addita est.

## Gradus 19 — PATCH 09: bowlAlias inter positiones et craterum IDs

### Quid repertum erat

Gradus 18 demonstravit ordinem permutationis iam recte computari, sed tres formulas fusionis ipsum ordinem ignorare et crateres fixos `1,2,3` legere. Defectus igitur non erat in permutatione neque in SAVE, sed in confusione inter positionem semanticae ordinis et ID crateris physicum.

### Quid circumventum est

`legacyPoursToFixedBowlIds` intactum manet et in via PATCH vere vocatur ante correctionem. `Patch09BowlAliasHandler` exitum illius vocationis in contextu servat ut cicatrix observabilis maneat.

Postea `Patch09BowlAliasWrapper` `poursThroughBowlAlias` vocat. Haec via `installBowlAlias(order)` constituit relationem permanentem:

```text
bowlAlias[position] = order[position]
```

Tres formulae fusionis nullum `oldBowls` directe per positionem legunt. Quaelibet lectio per `bowlAtAliasedPosition` transit, qui positionem ad ID crateris per alias resolvit et tum craterem legit.

### Cur hoc aequivalet normae

`order[position]` est ex definitione ID crateris qui in illa positione permutationis sedet. Ergo `bowlAlias[position]` eundem ID exactum servat. Legere `oldBowls[bowlAlias[position]]` est igitur eadem lectio ac formula normativa quae craterem per ordinem permutationis eligit. Formulae `SAVE`, coefficients lapidum et termini `3*i`, `5*i`, `7*i` immutati manent.

Comprobator productionis relationem `bowlAlias == order`, validitatem permutationis et tres formulas emendatas independenter recomputat; oracle testium productione non vocatur.

### Regressio Gradus 18 immutata

`tests/stage_18_discovery_09_tests.cpp` non mutatus est. Contra Gradum 18 pristinum `drop=241` adhuc tres discrepantias exactas et exitum `1` reddit. Contra Gradum 19 helper legacy directus adhuc easdem tres discrepantias habet, sed `executeFixedPours` output emendatum reddit et regressio transit.

Regressio PATCH 09 omnes 720 permutationis residua probat. `bowlAlias` semper ordini respondet; tres IDs aliased prima tria loca ordinis servant; via activa semper formulae normativae test-only concordat. Cicatrix legacy adhuc in 714 ex 720 casibus divergit. Via diagnostica unpatched separatim servatur.

### Stratum monstri hoc gradu additum

Additi sunt `BowlAlias`, `BowlAliasPourComputation`, `installBowlAlias`, `bowlAtAliasedPosition`, `poursThroughBowlAlias`, campi contextus alias et output emendati, `Patch09BowlAliasWrapper`, `Patch09BowlAliasHandler`, `dispatchPatchedFixedPours`, `requirePatch09Ready`, `executeUnpatchedFixedPoursDiagnostic` et campi report cicatricis ante patch.

Nullum `vaultOld`, nullum `pending`, nullus PATCH 10 et nulla logica contaminationis craterum sequentis gradus addita est.

## Gradus 20 — Detectio 10: contaminatio craterum per scripturam immediatam

### Quid putabatur

Post PATCH 09 tres fusiones iam crateres rectos per `bowlAlias` legebant. Vetus commotio autem tempore anteriori scripta erat, cum una structura craterum simul pro lectione et scriptione adhibebatur. Quia formula cuiusque positionis localis videbatur et omnis cratera semel per circuitum scribitur, credebatur hanc mutationem sequentialem exitum finalem non mutare.

### Quid repertum est

`legacyStirBowlsInPlace` sex positiones ordine percurrit et statim post singulam formulam in ipsum `bowls` scribit. Formula positionis sequentis igitur non necessario statum ante circuitum legit: si `prev` vel `next` iam in positione priore scriptus est, valor novus in calculum praesentem intrat.

Regressio duos casus probat. Pro `drop=1` et pro `drop=241` prima cratera scripta cum formula quae omnes lecturas ex statu antiquo facit concordat; quinque craterae reliquae in utroque casu discrepant. Summa exacta decem discrepantiarum demonstrat contaminationem intra unum circuitum, non errorem permutationis vel fusionum.

### Quid circumventum est

Nihil hoc gradu circumventum est. `LegacyInPlaceBowlAdapter` copiam inputis accipit tantum ut mutationem ab argumento calleris externo contineat, deinde `legacyStirBowlsInPlace` ipsam mutationem sequentialem exsequitur. `Discovery10InPlaceBowlHandler` output legacy in contextu servat et eum directe exponit.

### Cur hoc adhuc aequivalentia normativa non est

Norma unius commotionis postulat ut omnes sex formulae eosdem sex valores craterum ante circuitum legant. Via huius gradus autem lectiones posteriores ex obiecto iam partim mutato facit. Quamvis eadem algebra et idem `SAVE` adhibeantur, input termini `B[id]`, `B[prev]` vel `B[next]` iam alii esse possunt; inde exitus finalis non est normativae aequivalens.

### Stratum monstri hoc gradu additum

Additi sunt `legacyStirBowlsInPlace`, campi contextus commotionis craterum, `LegacyInPlaceBowlReport`, `LegacyInPlaceBowlAdapter`, `Discovery10InPlaceBowlHandler`, `requireLegacyInPlaceBowlReady`, `dispatchLegacyInPlaceBowlStir` et `executeInPlaceBowlStir`. Comprobator repetit computationem legacy solum ad determinismum confirmandum; nulla copia normativa productionis et nullus fallback introducitur.

Nullum snapshot semanticum separatum, nulla regio scripturae separata, nullus PATCH 10 et nulla logica Gradus 21 praemature addita est.

## Gradus 21 — PATCH 10: vaultOld, pending et commit tardivus craterum

### Quid repertum erat

Gradus 20 demonstravit `legacyStirBowlsInPlace` eundem `BowlState` ad lectiones et scriptiones intra unum circuitum adhibere. Prima positio omnia ex statu vetere legebat, sed quinque positiones posteriores vicinum iam scriptum videre poterant. In duobus witness casibus quinque craterae ex sex divergebant, summa decem discrepantiarum.

### Quid circumventum est

Helper legacy intactum manet et in via PATCH vere vocatur. `Patch10InPlaceBowlHandler` eius output contaminatum in `legacyInPlaceBowlOutput` servat ante quam correctionem ullam faciat.

Deinde `Patch10DeferredBowlWrapper` functionem `stirBowlsThroughVaultOld` vocat. Haec duas regiones semanticam separatas instituit:

```text
vaultOld = clone(B)
pending = clone(B)
```

Omnes termini `B[id]`, `B[prev]` et `B[next]` exclusive ex `vaultOld` leguntur. Sex exitus computati solum in `pending` scribuntur. Nulla lectio sequens ex `pending` fit. Post sextam computationem tantum `pending` ut status novus exponitur. `vaultOld`, `pending`, output emendatus et flag `patch10Applied` in contextu servantur.

Via diagnostica `executeUnpatchedInPlaceBowlStirDiagnostic` adhuc `Discovery10InPlaceBowlHandler` et helper legacy directe exsequitur.

### Cur hoc aequivalet normae

Norma commotionis unius circuitus sex formulas ex eodem statu ante circuitum definit. `vaultOld` est copia exacta illius status et numquam mutatur. Quia omnis formula solum ex ea copia legit, omnes sex formulae eosdem valores priores vident. `pending` solum destinationem scriptionis praebet et ante completionem circuitus in nullam formulam reingreditur. Commit post sex calculationes igitur idem est ac sex updates simultanei normativi.

`requirePatch10Ready` computationem independenter repetit ex input antiquo, non ex output wrapperis, et `vaultOld`, `pending` atque output finalem cum hac copia comprobationis comparat. Oracle testium productione non vocatur.

### Regressio Gradus 20

Regressio Gradus 20 data et formulas normativas non mutat. Solum assertiones quae output active necessario cum output legacy et nomine handleris DISCOVERY ligabant sublatae sunt. Cicatrix directa adhuc quinque discrepantias pro `drop=1` et quinque pro `drop=241` requirit.

Eadem regressio contra codicem Gradus 20 pristinum adhuc decem discrepantias et exitum `1` reddit. Contra Gradum 21 output activum nullas discrepantias habet et probatio transit.

### Regressio PATCH 10

Nova probatio omnes 720 ordines permutationis exercet. `stirBowlsThroughVaultOld` et via manageris semper output normativum reddunt; `vaultOld` input immutatum et `pending` output completum servant. Via diagnostica unpatched output legacy servat. Cicatrix legacy in omnibus 720 casibus probatis divergit.

Omnes regressiones Graduum 1–21 transeunt.

### Stratum monstri hoc gradu additum

Additi sunt `Patch10DeferredBowlComputation`, `stirBowlsThroughVaultOld`, campi contextus `bowlVaultOld`, `bowlPending`, `patchedInPlaceBowlOutput`, `patch10Applied`, campi report cicatricis, `Patch10DeferredBowlWrapper`, `Patch10InPlaceBowlHandler`, `dispatchPatchedInPlaceBowlStir`, `requirePatch10Ready` et via diagnostica unpatched.

`legacyStirBowlsInPlace` non mutatur. Nullus `orderAt46Latch`, nullus PATCH 11 et nulla logica post-stirs Gradus 22 praemature addita est.

## Gradus 22 — Detectio 11: ordo guttae 46 a memoria posteriori superscriptus

### Quid putabatur

Post PATCH 10 circuitus craterum iam snapshots rectos utebatur. Una memoria `order` quae ad permutationem praesentem pertinebat videbatur sufficere, quia quilibet circuitus ordinem suum statim consumebat. Credebatur igitur memoriam eandem per guttas et post-commotiones reutilizare sine damno posse.

### Quid repertum est

Query posterior non debet ordinem ultimae operationis videre; norma structuram query ad ordinem exactum guttae visibilis 46 ligat. Via legacy tamen unam memoriam superscribilem habet. Ea 46 vicibus in guttis visibilibus et deinde 12 vicibus in post-commotionibus scribitur.

Pro witness Fundationis ordo guttae 46 est `[4,5,2,3,6,1]`, sed memoria post post-commotionem 12 continet `[1,6,5,2,4,3]`. Query legacy hunc ultimum valorem legit. Omnes sex positiones discrepant. Numerus scripturarum est exacte 58 et fons ultimus `post-commotio 12`.

### Quid circumventum est

Nihil hoc gradu circumventum est. `legacySauceWithOverwritableOrderMemory` defectum consulto servat: `orderAtDrop46Diagnostic` ordinem rectum solum ad observationem retinet, dum `queryOrder` e memoria superscripta finali provenit.

Via tamen cicatrices anteriores vere exsequitur ante strata eorum reparativa: rank0 call diagnosticus, fusiones ad IDs fixos et commotio in-place in clone separato. Output semanticum intermediorum per sentinellam, rank bridge, `bowlAlias` et `vaultOld/pending` procedit, ne defectus huius gradus aliis erroribus confundatur.

### Cur hoc adhuc aequivalentia normativa non est

Ordo guttae 46 ipse recte calculatur. Sed semantica query requirit eundem ordinem postquam 12 post-commotiones finitae sunt. Quia memoria unica post guttam 46 iterum scribitur, valor query historicus non iam est valor guttae 46. Ergo via huius gradus consulto non est normae aequivalens.

### Stratum monstri hoc gradu additum

Additi sunt `LegacySauceCounts`, `LegacyOrderMemorySauceResult`, `sauceCountsThroughScars`, `buildVisibleDropsThroughPatchedHistory`, `initialBowlsThroughCounts`, `legacySauceWithOverwritableOrderMemory`, campi contextus memoriae ordinis, `LegacyOrderMemoryReport`, `LegacyOrderMemorySauceAdapter`, `Discovery11OverwrittenOrderHandler`, `requireLegacyOrderMemorySauceReady`, `dispatchLegacyOverwrittenOrder` et `executeOverwritableOrderMemorySauce`.

Memoria ordinis una est et consulto superscribitur. Nullum latch reparativum, nullus PATCH 11, nulla logica next-bowl aut codex posterior additus est.

## Gradus 23 — PATCH 11: latch unius scripturae pro ordine guttae 46

### Quid repertum erat

Gradus 22 ostendit `legacyOrderMemory` 58 vicibus scribi: 46 vicibus per guttas visibiles et 12 vicibus per post-commotiones. Ordo guttae 46 recte calculabatur, sed query finalis post ultimam superscriptionem ordinem post-commotionis 12 legebat. Pro witness Fundationis omnes sex positiones a gutta 46 discrepabant.

### Quid circumventum est

`legacySauceWithOverwritableOrderMemory` non mutatur et in via PATCH vere exsequitur. Exitum eius, inclusa memoria superscripta et fonte finali `post-commotio 12`, handler ante correctionem in contextu servat.

Deinde `Patch11OrderAt46LatchWrapper` functionem `sauceWithOrderAt46Latch` vocat. Haec eandem seriem computationis repassat, sed post completionem round guttae 46 et ante primam post-commotionem facit unicam scripturam:

```text
orderAt46Latch = clone(order)
```

Numerus scripturarum latch separatim numeratur et exactissime unus esse debet. Secunda scriptura invariantiam violaret. Post-commotiones memoriam legacy adhuc duodecies superscribunt, sed latch separatum non tangunt. `queryOrder` tandem exclusive `orderAt46Latch` legit.

### Cur hoc aequivalet normae

Norma query ordinis ad permutationem exactam guttae 46 refertur, non ad ultimam operationem sauce. Latch scribitur eo momento quo illa permutatio iam completa et valida est, ante ullam operationem quae memoriam legacy superscribere potest. Quia latch postea immutabile manet, valor query finalis idem est ac valor normativus guttae 46.

Craterae finales non mutantur: PATCH 11 solum proprietatem memoriae ordinis query reparat. `requirePatch11Ready` crateras finales viae PATCH cum crateris viae legacy comparat et discrepantiam vetat.

### Regressio Gradus 22

Regressio Gradus 22 eundem witness Foundationis et eundem ordinem normativum servat. Assertiones quae output active necessario cum memoria legacy ultima et nomine handleris DISCOVERY ligabant sublatae sunt, quia illae erant metadata historica, non semantica normativa.

Eadem regressio contra codicem Gradus 22 pristinum adhuc sex discrepantias exactas et exitum `1` reddit. Contra Gradum 23 query active e latch venit et regressio transit.

### Regressio PATCH 11

Nova probatio tres casus exercet: Fundationem, diem post Fundationem et transitum trans Fundationem. In omnibus latch semel scribitur et query ordini normativo guttae 46 concordat. Via diagnostica unpatched adhuc memoriam post-commotionis 12 legit; omnes tres casus cicatricem divergentem demonstrant. Craterae finales inter viam patched et unpatched identicae manent.

Omnes regressiones Graduum 1–23 transeunt.

### Stratum monstri hoc gradu additum

Additi sunt `Patch11LatchedOrderSauceResult`, `sauceWithOrderAt46Latch`, campi contextus latch et flag `patch11Applied`, campi report cicatricis, `Patch11OrderAt46LatchWrapper`, `Patch11OrderAt46LatchHandler`, `dispatchPatchedOrderAt46Latch`, `requirePatch11Ready` et `executeUnpatchedOverwritableOrderMemoryDiagnostic`.

Memoria legacy cum 58 scripturis intacta manet. Nullus `oldNextBowlFixedName`, nullus PATCH 12 et nulla logica Gradus 24 praemature addita est.

## Gradus 24 — DISCOVERY 12: next-bowl successor numericus fixus

### Quid putabatur

Post latch Gradus 23, query sauce iam ordinem exactum guttae 46 retinebat. Helper vetus next-bowl tamen ex tempore priore supponebat nomina craterum ipsam vicinitatem definire: post craterem 1 veniret 2, post 2 veniret 3, et post 6 rediret 1. Cum IDs ipsi omnes valide exstarent, helper simplex satis videbatur.

### Quid repertum est

Semantica next-bowl non sequitur ordinem numericum ID, sed successorem circulariter sequentem intra `orderAt46Latch`. `oldNextBowlFixedName(id)` nullum latch accipit et ideo ordinem permutationis ignorat.

Pro Fundatione latch verus est `[4,5,2,3,6,1]`. Successores normativi sunt 4→5, 5→2, 2→3, 3→6, 6→1, 1→4. Helper numericus dat 4→5, 5→6, 2→3, 3→4, 6→1, 1→2. Tres ex sex casibus discrepant: queried IDs 1, 3 et 5.

### Quid hoc gradu consulto non circumventum est

Nihil reparatur. `BaseMonsterManager::executeLegacyNextBowl` primum eundem Patch 11 realem per dispatcher exsequitur, ut `orderAt46Latch` validum et semel scriptum praesens sit. Deinde `Discovery12NextBowlHandler` latch in contextu servat, sed `LegacyNextBowlAdapter` ad `oldNextBowlFixedName` solum ID interrogatum tradit.

Validator confirmat latch non mutari et output legacy exactissime successorem numericum fixum esse. Nullus lookup positionis intra latch et nullus successor circularis productionis hoc gradu adest.

### Regressio

`tests/stage_24_discovery_12_tests.cpp` omnes sex IDs craterum in witness Fundationis exercet. Helper directus historicus separatim comprobatur. Output viae activae cum successore circulari latch comparatur. Tres concordantiae accidentales et tres discrepantiae exactae inveniuntur; regressio exitum `1` consulto reddit.

Omnes regressiones Graduum 1–23 denuo compilatae contra ABI Gradus 24 et exsecutae sunt; omnes transeunt.

### Stratum monstri hoc gradu additum

Additi sunt `oldNextBowlFixedName`, campi contextus next-bowl, `LegacyNextBowlReport`, `LegacyNextBowlAdapter`, `Discovery12NextBowlHandler`, `requireLegacyNextBowlReady`, `dispatchLegacyNextBowl` et `executeLegacyNextBowl`. Via eundem contextum per Patch 11 et deinde Discovery 12 ducit, quo dependentialis historia manifesta manet.

Nullus `Patch12`, nullus lookup positional, nullus successor circularis reparativus, nullus `biasedLegacyPick` et nullus codex posterior additus est.

## Gradus 25 — PATCH 12: successor circularis queried crateris intra latch

### Quid repertum erat

Gradus 24 demonstravit `oldNextBowlFixedName(id)` vicinitatem craterum ex nominibus numericis fingere. Helper 1→2→3→4→5→6→1 sequitur, quamvis `orderAt46Latch` permutationem exactam guttae 46 contineat. Pro Fundatione latch `[4,5,2,3,6,1]` est et tres ex sex queried IDs a helper legacy discrepant.

### Quid circumventum est

`oldNextBowlFixedName` non mutatur. `Patch12NextBowlHandler` prius `LegacyNextBowlAdapter::nextFixedName` vere vocat et output legacy in contextu servat. Deinde queried ID intra `orderAt46Latch` locat et positionem unius-based memorat.

`Patch12NextBowlWrapper` helper novum `nextBowlThroughOrderAt46Latch` vocat. Helper per sex positiones latch transit; ubi queried ID invenitur, elementum positionis sequentis reddit. Index sequentis per modulum longitudinis latch circumducitur, ideo ultima positio ad primam redit.

### Cur hoc aequivalet normae

Semantica next-bowl non est successor numeri crateris, sed successor illius crateris intra ordinem guttae 46. Patch 11 iam hunc ordinem in latch semel scripto protegit. PATCH 12 nihil de calculo sauce, crateris aut latch mutat; solum relationem queried crateris ad proximum craterem ex positione latch derivat.

Validator productionis oracle testium non vocat. Ipse verificat helper legacy adhuc eundem annulum numericum reddere, latch e Patch 11 non mutari, queried ID vere in positione servata reperiri, et output patch aequare `nextBowlThroughOrderAt46Latch`.

### Regressio Gradus 24

`tests/stage_24_discovery_12_tests.cpp` byte pro byte non mutatur. Contra Gradum 24 pristinum adhuc queried IDs 1, 3 et 5 discrepant et probatio exitum `1` reddit. Contra Gradum 25 eadem probatio pro omnibus sex IDs transit.

### Regressio PATCH 12

Nova probatio annulum legacy directum, viam diagnosticam unpatched et viam activam patched separat. Pro omnibus sex IDs output semanticum cum successore circulari calculato independenter ex latch comparatur. Positiones reportatae etiam comprobantur.

Casus wrap expresse exercetur: in latch Fundationis `[4,5,2,3,6,1]` queried ID 1 in positione sexta iacet et successor circularis 4, elementum primum, est. IDs 0 et 7 a helper patch reiciuntur. Tres cicatrices legacy divergentes manent.

Omnes regressiones Graduum 1–25 transeunt.

### Stratum monstri hoc gradu additum

Additi sunt `nextBowlThroughOrderAt46Latch`, campi contextus `patchedNextBowlOutput`, `patch12QueriedPosition`, `patch12Applied`, campi report cicatricis, `Patch12NextBowlWrapper`, `Patch12NextBowlHandler`, `requirePatch12Ready`, `dispatchPatchedNextBowl` et `executeUnpatchedNextBowlDiagnostic`.

`oldNextBowlFixedName` intactus et callable manet. Nullus `biasedLegacyPick`, nullus PATCH 13, nulla rejectio selectionis et nullus codex posterior praemature additus est.


## Gradus 26 — DISCOVERY 13: selector modulo directus ante rejectionem

### Quid putabatur

Post PATCH 12, annulus responsorum iam ex crateribus finalibus et successore next-bowl correcto constitui poterat. Selector vetus videbatur posse primum responsum statim ad familiam `1..N` per modulum redigere, quia omnis responsus annuli ipse in `1..M_OLD` iacet.

### Quid repertum est

Modulo directus aequalitatem distributionis frangit quando `N` non dividit `M_OLD`. Norma brevis prius caudam super `floor(M_OLD/N)*N` reicit et in eodem answer ring procedit. `biasedLegacyPick(x,N)` hanc rejectionem omnino ignorat.

Via realis Discovery 13 primum PATCH 11 et PATCH 12 exsequitur, deinde `LegacyAnswerRing` ex crateribus finalibus, queried crater, next crater et sigillo construit. `LegacyBiasedSelectionAdapter` solum `ringAnswer(stream,0)` accipit et statim `biasedLegacyPick` vocat.

Tres witnesses Fundationis electi sunt quibus `directionStep=-1`, `N=first-1` et `N>M_OLD/2`. In quolibet primus responsus est `N+1` et debet reici; proximus in eodem annulo est `N`. Selector legacy tamen 1 reddit. Ergo tres discrepantiae exactae sunt.

### Correctio test-only oracle reperta

Initio huius gradus comparatio answer ring ostendit productionem et oracle testium ante selectionem discrepare. Appendix A inspecta demonstravit productionem iam rectam esse: tam in circuitu guttae quam in post-commotione omnia additamenta primum in `s` colliguntur et deinde `square(s)` fit. `normative_reference.cpp` vetus additamenta extra quadratum posuerat.

Haec fuit culpa copiae test-only, non nova cicatrix productionis. Oracle C++ correctus est ad textum Appendix A et fixture bootstrap per generator C++ denuo producta est. Omnes regressiones anteriores post correctionem denuo compilatae et transierunt. Hoc corrigendum erat antequam divergence DISCOVERY 13 valida declarari posset.

### Quid hoc gradu consulto non circumventum est

Nulla rejectio productionis additur. Nullus acceptance limit computatur. Nullus offset crescit donec responsus acceptabilis invenitur. `biasedLegacyPick` vocatur ante omnem rejectionem et output eius est output semanticum viae Discovery 13.

### Cur hoc adhuc aequivalentia normativa non est

Pro tribus witness casibus `biasedLegacyPick(N+1,N)=1`, dum norma primum `N+1` reicit, deinde `N` accipit et rank `N` reddit. Divergentia est ipsa culpa Patch 13 destinata, non error upstream annuli.

### Stratum monstri hoc gradu additum

Additi sunt `LegacyAnswerRing`, `answerRingThroughPatchedNextBowl`, `ringAnswer`, `biasedLegacyPick`, campi contextus selectionis, `LegacyBiasedSelectionReport`, `LegacyBiasedSelectionAdapter`, `Discovery13BiasedSelectionHandler`, `requireLegacyBiasedSelectionReady`, `dispatchLegacyBiasedSelection` et `executeLegacyBiasedSelection`.

`oldNextBowlFixedName` et omnia strata priora manent. Nullus `patchedSmallPick`, nullus PATCH 13, nulla wide selection et nullus codex posterior praemature additus est.

## Gradus 27 — PATCH 13: rejectio brevis in eodem answer ring

### Quid repertum erat

Gradus 26 demonstravit `biasedLegacyPick(x,N)` directum modulum facere et distributionem inclinare quando `N` non dividit `M_OLD`. Tres witnesses Fundationis habebant `directionStep=-1`, `N=first-1` et `N>M_OLD/2`; primus responsus `N+1` reiciendus erat, sed helper legacy statim rank 1 reddebat.

### Quid circumventum est

`biasedLegacyPick` non mutatur. `Patch13BiasedSelectionHandler` annulum e Patch 11 et Patch 12 construit, deinde `LegacyBiasedSelectionAdapter::selectBeforeRejection` vere vocat et output historicum in contextu servat. Validator legacy hanc cicatricem directi modulo ante patch confirmat.

Postea `Patch13RejectionWrapper` magnitudinem familiae brevem ad `1..M_OLD` restringit et computat:

```text
acceptanceLimit = (M_OLD/N)*N
```

Offset ab zero incipit. Dum `ringAnswer(stream,offset)>acceptanceLimit`, solum offset eiusdem annuli crescit. Nullus annulus novus, nullum first novum et nulla directio nova gignitur. Cum primum responsum acceptabile invenitur, `LegacyBiasedSelectionAdapter::selectAcceptedAnswer` eundem `biasedLegacyPick` in illo responso vocat.

### Cur hoc aequivalet normae brevi

Massa `1..M_OLD` in `floor(M_OLD/N)` blocos integros magnitudinis `N` secatur; cauda residua supra `acceptanceLimit` reicitur. Ideo modulo post acceptance tantum classes aequales accipit. Progressus in eodem answer ring ordinem candidatorum normativum servat.

Validator productionis formula acceptance limit, accepted offset non negativum, accepted answer ex eodem annulo, conditionem `x<=limit`, absentiam candidati prioris acceptabilis et vocationem finalem `biasedLegacyPick(acceptedAnswer,N)` separat verificat.

### Regressio Gradus 26

`tests/stage_26_discovery_13_tests.cpp` non mutatur. Contra Gradum 26 pristinum tres discrepantias exactas et exitum `1` adhuc reddit. Contra Patch 13 novum eadem probatio transit.

### Regressio PATCH 13

Nova probatio tres witnesses Fundationis repetit. In omnibus output legacy ante patch est 1; acceptance limit est `N`; primus responsus reicitur; offset 1 responsum `N` dat; output patched cum norma congruit. Via diagnostica unpatched directum modulo servat.

Boundary `N=M_OLD` statim offset 0 accipit. `N=0` et `N>M_OLD` in selector brevi reiciuntur. Tres cicatrices legacy divergentes manent.

Omnes regressiones Graduum 1–27 transeunt.

### Stratum monstri hoc gradu additum

Additi sunt `Patch13RejectionSelection`, campi contextus acceptance limit, accepted answer, accepted offset et output patched, campi report cicatricis, `LegacyBiasedSelectionAdapter::selectAcceptedAnswer`, `Patch13RejectionWrapper`, `Patch13BiasedSelectionHandler`, `requirePatch13BiasedSelectionReady`, `dispatchPatchedBiasedSelection` et `executeUnpatchedBiasedSelectionDiagnostic`.

`biasedLegacyPick` intactus et callable manet. Nullus `wideDetour`, nullus dispatcher wide, nullae digits base-M et nullus PATCH 14 praemature additus est.
