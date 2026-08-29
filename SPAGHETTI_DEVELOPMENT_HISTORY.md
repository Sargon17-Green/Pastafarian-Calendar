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

Validator productionis logicam iterum ut COPY_VALIDATION computat, non oracle testium vocat. Responsum semanticum ab una via patch venit.

### Regressio Gradus 12 recognita

Forma Gradus 12 fixerat `status` et `handler` ad nomina DISCOVERY, quae mutationem organicam ad handler PATCH impediebant. Solum haec verificatio meta-path relaxata est ut vel via DISCOVERY vetus vel via PATCH nova legitima sit. Expected values et assertiones semanticae non mutatae sunt.

Contra codicem Gradus 12 pristinum forma correcta adhuc septem `NON_RESOLUTUS`, `REGRESSIO_DISCOVERY_06_DEFECIT` et exitum `1` produxit. Contra Gradum 13 eadem probatio transit.

### Stratum monstri hoc gradu additum

Additi sunt `priorPatch`, `patch06HiddenBackward`, `patchedPriorOutput`, duae notae viae, `patch06Applied`, `Patch06PriorWrapper`, `Patch06PriorHandler`, `dispatchPatchedPrior`, `requirePatch06Ready` et `executeUnpatchedPriorDiagnostic`. Relatio prioris nunc exitum legacy ante patch et viam electam retinet. `legacyPrior` ipse immutatus manet.

Nulla structura Gradus 14 vel PATCH 07 addita est.
