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
