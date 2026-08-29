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
