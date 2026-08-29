# Historie del developation spaghetti

## Stage 1 — Bootstrap

### Quo esset constructet

Li linea de implementation ha esset creat de zero por JavaScript con Interlingue / Occidental quam unic lingue-fonte human. Un `SourceLanguageCatalog` versionat e congelat contene 17 nomes de cutlettes e 47 nomes de mensus con indices canonic stabil. Un reference normativ local, un generator local de fixtures e un test harness local ha esset creat in JavaScript.

Li production ha solmen un infrastructura monster neutral: `BaseMonsterContext`, `BaseDispatcher`, `BaseValidationManager`, `BaseErrorWrapper`, `BaseMetricsManager` e `BaseMonsterManager`. Chascun invocation crea su propri context. Metrics e logs de ti stage es non-semantic e ne es consultat por decisiones normativ.

### Quo ne esset constructet

Null defect legacy e null patch historic es ancor present. Null path de stages futur ha esset anticipat. `calendarDateSpaghetti` jetta un errore explicit de Bootstrap in vice de simular un implementation prematur.

### Independentie

Null altri implementation ha esset leet quam fonte semantic o calculatori. Null test, fixture, output expectat, table generat, serialized state, hash, checksum o differential cross-implementation ha esset usat. Li reference e li fixtures de ti linea deriva exclusivmen ex li specification includet in li task.

### Crescentie monster in ti stage

Solmen li strat general permisset in Bootstrap ha esset addit: context, dispatcher, validation, wrapping de errores e metrics. Ti strat ne contene semantics del patches e ne altera null resultat normativ.

### Verification supplementari ante Stage 2

Ante crear li prim defect legacy, li Bootstrap ha esset subjectet a un porta de verification plu strict. Un nov test-only verifier in JavaScript compara pluri partes del reference con copies de validation separat e con enumerations exhaustiv de spaces micri. It verifica anc permutationes, portes, annus, isolation de state, congelation del catalog, absentie de imports del oracle in production e absentie de code futur.

Li porta passa con 25 gruppes e 60226 assertions. Null semantic patch e null nove strat monster ha esset addit; ergo li crescentie historic resta exactmen in Stage 1.

Un probe diagnostic plen de `calendarDate` ne finit ante 120 secundes in ti ambiente, pro li grand DP de intertexe de un annu real. Ti observation ne ha esset mascat per approximation o fallback. It es conservat quam nota de performance; li equivalence del DP es verificat exhaustivmen sur spaces micri.

## Stage 2 — DISCOVERY 01

### Quo on pensat

Li prim design historic tractat «save» quam un simplic regular modulo de `M`. Li operation legacy es `oldRemainder(value) = regularMod(value, M_OLD)`, e it es nu conectet a un path real de production.

### Quo esset decovrit

Ti assumption perde li representation reservat del residu zero. Por `M`, `2M` e `3M`, `oldRemainder` rende `0`; li reference normativ `SAVE` rende `M`. Li casu `M+1` rende `1` in ambi paths e demonstra que li defect ne es un shift general.

### Quo esset circumit

Null circumventione existe in ti stage. Li correction es expressmen reservat por PATCH 01 in Stage 3. `savePatch` ne es present.

### Crescentie monster in ti stage

Un `LegacyRemainderAdapter` e un `Discovery01RemainderHandler` ha esset addit. `BaseMonsterManager` crea li context, passa it tra li dispatcher de Bootstrap, e poy route li valore a ti nov handler. Li context conserva handler current/precedent, input e output legacy, trace e metric non-semantic.

### Pro quo li strat nov ne adjunte un altri defect semantic

Li adapter e li handler copia exactmen li operation legacy definat por ti discovery; ili ne normalisa, ne corrige e ne consulta li oracle. Li unic divergentie es li defect historic intentional de `oldRemainder`. Li state del context resta proprietá de un unic invocation.


## Stage 3 — PATCH 01

### Quo esset circumit

Li function `oldRemainder` ne esset modificat. Un nove `savePatch(value)` apella it e examina su resultate. Si li legacy rende `0`, li wrapper rende `M_OLD`; altrimen it rende exactmen li residu legacy. Li defect original resta dunc fisicmen present e directmen testabil.

### Pro quo li patch es normativmen equivalent

`oldRemainder` rende li residu Euclidean in `0..M-1`. Por omni residu non-zero, `SAVE` rende li sam valore. Por un multiplica de `M`, incluid 0 e multiplicas negativ, li unic diferentie es que `SAVE` representa li classe zero quam `M`. Remappar exclusivmen `0` a `M` es dunc exactmen li definition normativ, sin altri transformation.

### Crescentie monster in ti stage

Un `Patch01SaveWrapper` ha esset insertet pos `Discovery01RemainderHandler`. Li context conserva simultanmen li input, li output legacy, un flag indicant si li legacy esset zero, li output reparat, li handlers precedent/current e un trace de ambi stages. Ti strat adjunte un dependentie e un passu historic real sin compartir state inter invocations.

### Pro quo li strat nov ne altera semantics ultra li patch

Li wrapper usa solmen li input exact e li output del operation legacy del sam invocation. Metrics e trace resta non-semantic. Null oracle es consultat in production, null fallback existe, e li correction aplica solmen li remappage `0 -> M` mandat per Patch 01.

## Stage 4 — DISCOVERY 02

### Quo on pensat

Li duesim design historic assumet que un tag de die posse esser duplic li distance absolut al Foundation. Li nov operation legacy es `oldDayTag(day) = 2 * abs(day - FOUNDATION_DAY_OLD)`. It es conectet a production tra un adapter e un handler real, sin correction.

### Quo esset decovrit

Li formule perde li paritá mandat del latere posterior e anc li valore special del Foundation. Al Foundation, li legacy rende `0` in vice de `1`. Un die pos li Foundation it rende `2` in vice de `3`, e du dies pos it rende `4` in vice de `5`. Li latere anterior coincide por ti cases, dunc li defect es localisat e ne es un simplic offset global.

### Quo esset circumit

Null circumventione existe in ti stage. Li correction quel adjunte un unit por dies al o pos li Foundation, con li guard historic separat por li Foundation, es reservat exclusivmen por PATCH 02 in Stage 5.

### Crescentie monster in ti stage

Un `LegacyDayTagAdapter` e un `Discovery02DayTagHandler` ha esset addit. `BaseMonsterManager` crea un context fresc, passa it tra li dispatcher existent e route poy li die al handler nov. Li context conserva li input e output legacy, li handler current e precedent, un trace de branch e un metric non-semantic separat.

### Pro quo li strat nov ne adjunte un defect extra

Li adapter apella exactmen `oldDayTag` e li handler ne normalisa su resultate, ne consulta li oracle e ne usa metrics por decisiones. Ergo li unic divergentie nov es precis li defect historic mandat por Discovery 02, durant que Patch 01 e omni state anterior resta isolat e testabil.

## Stage 5 — PATCH 02

### Quo esset circumit

Li function `oldDayTag` ne esset modificat. Un nove `dayTagWithFoundationScar(day)` apella it e conserva su resultate quam base. Si `day >= FOUNDATION_DAY_OLD`, li wrapper adjunte un unit. Pos to, un duesim guard separat resta explicit: si li die es exactmen li Foundation e li valore ne es `1`, it es fortiat a `1`. Ti duesim guard es redundant pos li prim correction, ma it resta quam scar historic mandat.

### Pro quo li patch es normativmen equivalent

Ante li Foundation, `oldDayTag` ja rende `2 * (FOUNDATION - day)`, exactmen quam `dayCount`. Al Foundation, li legacy rende `0`; adjunter un unit rende `1`. Pos li Foundation, li legacy rende `2 * (day - FOUNDATION)`; adjunter un unit rende li serie impar `2d + 1` mandat del reference. Li guard final ne cambia li resultate normal, ma preserva li scar ex li correction historic.

### Crescentie monster in ti stage

Un `Patch02DayTagWrapper` ha esset insertet pos `Discovery02DayTagHandler`. Li context conserva simultanmen li input del patch, li output legacy, un flag indicant si li unit de paritá esset addit, un flag indicant que li guard del Foundation esset attinget, li output final, li handlers current/precedent e un trace de ambi passes. `BaseMonsterManager` expone un route separat quel executa li discovery e poy li patch in li sam invocation.

### Pro quo li strat nov ne altera semantics ultra li patch

Li wrapper consulta solmen li die exact e li resultate legacy del sam invocation. Metrics, flags observatori e trace ne participa in li calculation. Null oracle es consultat in production, null fallback existe, e li unic correction semantic es li unit posterior con li guard redundant mandat de Patch 02.

## Stage 6 — DISCOVERY 03

### Quo on pensat

Li triesim design historic assumet que, pos reparar li tags de die, li distance inter du dies posse esser derivat directmen quam li diferentie absolut inter tis tags. Li operation legacy nov es `oldDistance(calculationDay, targetDay) = abs(dayTagWithFoundationScar(calculationDay) - dayTagWithFoundationScar(targetDay))`. It es conectet a production sin correction.

### Quo esset decovrit

Li tags codifica li du lateres del Foundation con paritá e direction, ne un axe metric linear. Lor diferentie ne es li distance cronologic inter li dies, e mem quand it coincide accidentalmen it manca li regul inclusiv `+1`. Por un die contra se self, li legacy rende `0` in vice de `1`; por `Foundation-2` a `Foundation+2` it rende `1` in vice de `5`; e por separation de du dies sur un unic latere it rende `4` in vice de `3`. Li pare `Foundation` a `Foundation+1` coincide accidentalmen a `2`, quel monstra pro quo un exemple unic ne suffi.

### Quo esset circumit

Null circumventione existe in ti stage. Li correction quel calcula `abs(targetDay-calculationDay)`, substitue ti valore si li legacy diverge e adjunte li unit inclusiv es reservat exclusivmen por PATCH 03 in Stage 7. `patchedCounts` ne es present.

### Crescentie monster in ti stage

Un `LegacyDistanceAdapter` e un `Discovery03DistanceHandler` ha esset addit. Li handler crea null state global: it usa li context fresc del `BaseMonsterManager`, conserva ambi dies, li du tags reparat, li output legacy, li handler current/precedent, un trace e un metric non-semantic.

### Pro quo li strat nov ne adjunte un defect extra

Li adapter apella exactmen `oldDistance`; li handler ne normalisa li resultate, ne consulta li oracle e ne usa metrics por decisiones. Li scars de Patch 01 e Patch 02 resta separatmen testabil. Ergo li unic divergentie nov es li assumption historic mandat de Discovery 03.


## Stage 7 — PATCH 03

### Quo esset circumit

Li function `oldDistance` ne esset modificat. Un nov `distanceWithChronologyDetour(calculationDay, targetDay)` comensa per apellar li legacy. It calcula separatmen li distance cronologic absolut `abs(targetDay-calculationDay)`. Si li valore legacy diverge, li variable legacy local es substituet per ti distance cronologic; si ili coincide, li valore legacy resta. Solmen pos ti comparation li detour adjunte `1` por render li distance inclusiv.

### Pro quo li patch es normativmen equivalent

Li reference defini `distance = abs(targetDay-calculationDay) + 1`. Li patch calcula exactmen ti magnitude cronologic con integers `BigInt`. Li branch de substitution ne posse cambiar li resultate correct: si legacy diverge, it es remplacat per li magnitude normativ; si it ja coincide, conservar it rende li sam magnitude. Li addition final de un unit transforma li distance de separation in li distance inclusiv mandat.

### Crescentie monster in ti stage

Un `Patch03DistanceWrapper` ha esset insertet pos `Discovery03DistanceHandler`. Li context conserva li du dies del patch, li output legacy, li distance cronologic calculat separatmen, un flag `patch03LegacyReplaced`, li valore selectet ante li unit inclusiv e li output final. `BaseMonsterManager` expone un route historic separat quel executa li discovery e poy li patch in li sam invocation. Un invariant local confirma ante return que li output es exactmen li valore selectet plus un.

### Pro quo li strat nov ne altera semantics ultra li patch

Li wrapper usa solmen li du dies exact e li output legacy del sam invocation. Li trace, flags e metrics resta observatori e ne alimenta null decision semantic. Null oracle es consultat in production, null fallback existe, e `oldDistance` resta fisicmen e comportamentalmen intact. `patchedCounts` ne es creat in ti stage; ergo null parte de Patch 04 o posterior es anticipat.

## Stage 8 — DISCOVERY 04

### Quo on pensat

Li quaresim design historic tractat li transition del quin stones quam un serie de assignationes direct al sam object. `mutateStonesWrong(index, state)` actualisa `w`, poy `b`, `s`, `m` e `r`, e li assignationes posterior lege li state ja modificat. Ti operation legacy es nu conectet a production per un adapter e un handler real.

### Quo esset decovrit

Li transition normativ es simultan: omni quin nov valores deve esser calculat ex li sam statu anterior. Li mutation sequential contamina li calculs posterior intra li sam passu. Con li statu inicial `{w:17,b:29,s:43,m:71,r:101}` e index `2`, `w` coincide a `378` pro que it es calculat prim, ma li legacy rende poy `b=1434, s=3780, m=9932, r=25047` contra li valores simultan `1073, 2375, 6195, 10493`.

### Quo esset circumit

Null circumventione existe in ti stage. Li legacy call resta sin neutralisation, e li regression nov deve restar rubi. Null `stonePatch` e null calcul ex un copie anterior es present.

### Crescentie monster in ti stage

Un `LegacyStoneMutationAdapter` e un `Discovery04StoneMutationHandler` ha esset addit. Li manager crea li context fresc, li handler conserva li intrada por diagnostics, crea un statu de labor del invocation e passa ti object al legacy. Li context conserva index, intrada, object mutat, un flag de identitá, trace e metric non-semantic.

### Pro quo li strat nov ne adjunte un defect extra

Li adapter apella exactmen `mutateStonesWrong`; li handler ne recomputa null valore, ne consulta li oracle e ne corrige li mutation. Li copie de intrada al statu de labor servi solmen por ownership del invocation e ne es usat quam snapshot semantic por recalcular li transition. Ergo li divergentie nov es precis li defect sequential mandat de Discovery 04.

