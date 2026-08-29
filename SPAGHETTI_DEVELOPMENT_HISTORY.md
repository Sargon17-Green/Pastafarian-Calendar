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



## Stage 9 — PATCH 04

### Quo esset circumit

`mutateStonesWrong` ne esset modificat. Li nov `stonePatch(index, state)` crea un snapshot `old` del statu ante li transition. It poy executa realmen `mutateStonesWrong(index, clone(state))`; ti call legacy ne es deletet ni convertet a diagnostic mort. Pos li call, li patch superscri `w`, `b`, `s`, `m` e `r` del object garbage con li quin formules original, ma chascun lecture veni exclusivmen del snapshot `old`.

### Pro quo li patch es normativmen equivalent

Li transition normativ defini omni quin componentes ex li sam row precedent. Li snapshot old congela exactmen ti row. Chascun overwrite usa `savePatch`, quel ja es equivalent a `SAVE`, e usa li coefficient e dependenties normativ por su componente. Ergo li valor mutat sequentialmen per li call legacy es completmen neutralisat ante return, durant que li call historic resta real. `getStoneTableThroughLegacyBuilder()` aplica ti transition desde li row inicial e rende 46 rows exactmen in li órdine normativ.

### Crescentie monster in ti stage

Un `Patch04StoneWrapper` ha esset insertet pos `Discovery04StoneMutationHandler`. Li context conserva li index, li snapshot old, un copie del garbage legacy ante overwrite, un flag quel registra li conservation del call legacy e li output reparat. In addition, un builder separat `getStoneTableThroughLegacyBuilder` usa `stonePatch` iterativmen, creante un via production quel preserva li scar a chascun transition.

### Pro quo li strat nov ne altera semantics ultra li patch

Li wrapper ne consulta li oracle e ne usa metrics o diagnostics por decisiones. Li source state es validat ma ne mutat; li call legacy opera sur clones. Solmen li quin overwrites mandad de Patch 04 decide li output. `mutateStonesWrong` resta directmen invocabil e demonstra ancora su divergentie. Null storage retrograd de hidden drops, `hiddenByNearness` o altri code de Patch 05 es present.

## Stage 10 — DISCOVERY 05

### Quo on pensat

Li quinesim design historic tractat li array de sett hidden drops quam un contenitor u li orientation fisic ne importat. Li coefficients legacy es mantenet in `LEGACY_HIDDEN_COEFF_REVERSED`, e li builder scri chascun hidden k in slot `8-k`, resultante in li sequence fisic hidden7, hidden6, ..., hidden1. On assumet que un consumidor posterior vell posser leer slot k directmen quam hidden k.

### Quo esset decovrit

Li hidden drops have un signification per proximity al prim visible drop: hidden1 es li plu proxim e hidden7 li plu lontan. Li storage inversat ne preserva ti convention. Li values calculat self es exact; li defect es exclusivmen orientation de storage. Por li casu Foundation/Foundation, slots 1..7 es exactmen li reversal del serie normativ, e un access direct a slot 1 rende hidden7 in vice de hidden1.

### Quo esset circumit

Null circumventione existe in ti stage. Li array ne es reversat e null translator de access es present. Li function reservat quel va mappar chascun access logic a hidden k vers slot `8-k` apartene exclusivmen a PATCH 05 in Stage 11.

### Crescentie monster in ti stage

Un `LegacyHiddenStorageAdapter` e un `Discovery05HiddenStorageHandler` ha esset addit. Li handler valida li comptes e li table de stones, executa li builder retrograd, conserva un copie del comptes, li storage legacy e probes de slots 1 e 7 in li context, e registra un metric non-semantic.

### Pro quo li strat nov ne adjunte un defect extra

`makeHiddenPatched` usa li coefficients, checksum de stone, sett grinds e `savePatch` secun li pseudocode historic, e li table de stones veni del builder ja reparat de Patch 04. Null oracle es consultat in production. Li handler ne reordina, ne traducte e ne corrige li storage. Ergo li unic divergentie nov es precis li orientation retrograd mandat de Discovery 05.

## Stage 11 — PATCH 05

### Quo esset pensat

Pos Discovery 05 on acceptat que li array legacy self ne deve esser restructurat: altri parts historic posse depender de su orientation retrograd. Li correction deve esser local al punctu de access semantic, ne un migration del storage.

### Quo esset circumit

`hiddenByNearness(legacyHidden, k)` traducte proximity `k` al slot fisic `8-k`. `Patch05HiddenNearnessWrapper` executa solmen pos `Discovery05HiddenStorageHandler`, conserva li array backward intact in li context e rende li valore semantic correct. Li test de Discovery 05 conserva li mem values expected e deven verd solmen per ti translator.

### Scar conservat

`buildHiddenWithBackwardStorage` continua scrir hidden7 in slot 1 e hidden1 in slot 7. Null `reverse()` es usat quam correction. Li divergence fisic resta observabil e testabil.


## Stage 12 — DISCOVERY 06

### Quo on pensat

Li sixesim design historic assumet que omni predecessor de un visible drop ja trova se in `dropStore`. Li function nov `legacyPrior(dropStore, i, back)` calcula `i-back` e retorna directmen ti slot, sin un duesim fonte de history.

### Quo esset decovrit

Por li prim visible drops, `i-back` posse esser `0` o negativ. Ti slots ne es visible drops: `0` significa hidden1, `-1` hidden2 e talmen usque `-6` hidden7. Li storage hidden existe ja, e Patch 05 posse leer it per proximity, ma `legacyPrior` ne conosse ni ti storage ni li translation. In un probe isolat con slots `0, -2, -6, -1`, li legacy rende quatre valores absent contra hidden1, hidden3, hidden7 e hidden2.

### Quo esset circumit

Null circumventione existe in ti stage. `priorPatch` ne es present. Null branch por slot negativ, null mapping `k = 1-slot` e null call a `hiddenByNearness` ha esset addit. Ti correction apartene exclusivmen a PATCH 06 in Stage 13.

### Crescentie monster in ti stage

Un `LegacyPriorAdapter` e un `Discovery06PriorHandler` ha esset addit. Li handler valida li storage indexabil e li du indices, calcula e conserva li slot historic, registra si ti slot es visibil, executa li legacy e conserva su output. `BaseMonsterManager` expone un route separat con un context fresc e un metric non-semantic.

### Pro quo li strat nov ne adjunte un defect extra

Li adapter apella exactmen `legacyPrior`. Li handler ne consulta li hidden storage, ne fabrica un fallback e ne usa metrics por decisiones. Li scars e patches 01..05 resta separatmen testabil. Ergo li unic divergentie nov es precis li ignorance de slots hidden mandat de Discovery 06.

## Stage 13 — PATCH 06

### Quo esset circumit

`legacyPrior` ne esset modificat. Li nov `priorPatch(dropStore, legacyHidden, i, back)` calcula `slot = i-back`. Quand `slot >= 1`, it voca realmen `legacyPrior(dropStore, i, back)` e usa su resultate. Quand `slot <= 0`, it calcula `k = 1-slot` e rende `hiddenByNearness(legacyHidden, k)`. Ti branche cobre exactmen slots `0..-6` quam hidden1..hidden7.

### Pro quo li patch es normativmen equivalent

Por un visible predecessor, li value semantic es ja li visible drop in `dropStore[slot]`, dunc conservar li call legacy rende exactmen li predecessor normativ. Por un predecessor ante li prim visible drop, li convention historic es `slot 0 = hidden1`, `slot -1 = hidden2`, ... `slot -6 = hidden7`; algebraicmen ti es `k = 1-slot`. Patch 05 ja defini `hiddenByNearness` quam translator semantic exact super li storage retrograd, ergo li combination rende li history normativ sin restructurar li arrays.

### Crescentie monster in ti stage

Un `Patch06PriorWrapper` ha esset insertet pos `Discovery06PriorHandler`. Li context conserva li storage hidden legacy, li slot historic, li proximity hidden solmen quand necessi, un flag `patch06LegacyVisibleCallUsed` e li output final. `BaseMonsterManager` expone un route historic quel executa discovery e patch in li sam invocation.

### Scar conservat

`legacyPrior` continua retornar `undefined` por slots `0..-6` quand it es vocat directmen. Li storage hidden continua fisicmen retrograd e `hiddenByNearness` resta li unic translator semantic. Null slots negativ es fabricat in `dropStore`; null `reverse()` es usat. `GRIND_TABLE_WITH_SENTINEL` e omni code de Patch 07 o posterior resta absent.


## Stage 14 — DISCOVERY 07

### Quo on pensat

Li settesim design historic conservat li undec grinds visibil in un table ordinari de JavaScript. Li caller, heredat de un convention one-based, continua numerar chascun grind de 1 til 11 e usa ti ordinal directmen quam index del table. On assumet que li numeration semantic e li index fisic esset li sam.

### Quo esset decovrit

Li array fisic es zero-based. Su index 0 contene exactmen li prim row normativ, ma `legacyGrindRow(1)` prende index 1 e rende li duesim row. Li displacement continua til grind 10, quel prende li undecim row; grind 11 cade ultra li table e rende un valore absent. Li undec rows almacenat self concorda con li specification; li unic defect es li convention de lookup.

### Quo esset circumit

Null circumventione existe in ti stage. Null sentinel row es addit e `GRIND_TABLE_WITH_SENTINEL` ne existe. Li correction quel deve preservar li indexing legacy per un sentinel a index 0 apartene exclusivmen a PATCH 07 in Stage 15.

### Crescentie monster in ti stage

`LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED` conserva li data historic. Un `LegacyGrindTableAdapter` e un `Discovery07GrindIndexHandler` ha esset addit; li handler registra li ordinal demandat, li sam index fisic direct, si li row es absent e li output legacy. `BaseMonsterManager` expone un route separat con context fresc e metric non-semantic.

### Pro quo li strat nov ne adjunte un defect extra

Li adapter delega exclusivmen a `legacyGrindRow`; li handler ne shift, ne fallback, ne consulta li oracle e ne fabrica un row. Li table self usa li undec rows real in ordine correct. Ergo li unic divergentie nov es precis li mismatch one-based/zero-based mandat de Discovery 07. Omni scars e patches precedent resta separatmen testabil.


## Stage 15 — PATCH 07

### Quo esset circumit

`legacyGrindRow` e `LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED` ne esset modificat. Li nov `GRIND_TABLE_WITH_SENTINEL` reserva fisicmen index 0 quam sentinel e copia li undec rows real in indices 1..11. `grindRowWithSentinel(grind)` conserva exactmen li convention del caller historic: grind 1 usa index 1, e talmen til grind 11 usa index 11.

### Pro quo li patch es normativmen equivalent

Li table de Discovery 07 ja contene li undec rows correct in ordine. Prefixar un sentinel ne cambia null row; it solmen deplazza lor indices fisic per un unit, quel alinea li storage con li ordinals semantic 1..11 del caller. Ergo chascun grind rende exactmen li sam row normativ sin recalcular, reordinar o duplicar li data semantic.

### Crescentie monster in ti stage

Un `Patch07GrindSentinelWrapper` ha esset insertet pos `Discovery07GrindIndexHandler`. Li context conserva li ordinal demandat, li index fisic direct, un flag quel confirma que li sentinel resta in index 0, li output legacy e li output reparat. `BaseMonsterManager` expone un route historic separat quel executa discovery e patch in li sam invocation.

### Scar conservat

`legacyGrindRow(1)` continua rendre li duesim row e `legacyGrindRow(11)` continua rendre `undefined`. Li sentinel ne es removet pos lookup e ne es tratat quam un grind real. Null `oldPermutationUnrank0` o code de Patch 08 o posterior es present.


## Stage 16 — DISCOVERY 08

### Quo on pensat

Li ottesim design historic ja possede un helper de permutation quel parla in ranks zero-based. Li caller de bowls, tamen, parla in un ordinal one-based derivat ex li drop per `regularMod(drop-1,720)+1`. On assumet que li du numerationes esset intercambiabil e passat li ordinal directmen al helper.

### Quo esset decovrit

`oldPermutationUnrank0(0)` rende li prim permutation e `oldPermutationUnrank0(719)` li ultim. Passar `oneBased=1` quam rank0 rende dunc li duesim permutation, ne li prim; li displacement continua til `oneBased=719`, e `oneBased=720` es extra li contract 0..719. Li defect es in li caller, ne in li unranking zero-based self.

### Quo esset circumit

Null circumventione existe in ti stage. Li caller continua passar `oneBased` directmen a `oldPermutationUnrank0`. Li bridge mandat `legacyRank0 = oneBased-1` ne existe e apartene exclusivmen a PATCH 08 in Stage 17.

### Crescentie monster in ti stage

Un `LegacyPermutationOrderAdapter` e un `Discovery08PermutationRankHandler` ha esset addit. Li context conserva li drop, li ordinal one-based, li valore exact passat quam rank0 e li order legacy. `BaseMonsterManager` expone un route separat con context fresc e metric non-semantic.

### Pro quo li strat nov ne adjunte un defect extra

`oldPermutationUnrank0` implementa exactmen su contract 0..719; li adapter ne reordina ni muta li resultate. Li unic assumption fals nov es li confusion mandat inter ordinal 1..720 e rank0 0..719. Li sentinel permanent de Patch 07 resta intact. Null pours, aliases de bowls o code de Patch 09 es present.


## Stage 17 — PATCH 08

### Quo esset circumit

`oldPermutationUnrank0` e `legacyBowlOrderFromDrop` ne esset modificat. Li nov `orderPatchFromValue(value)` recalcula intentionalmen `oneBased = regularMod(value-1,720)+1`, deriva `legacyRank0 = oneBased-1`, e voca poy `oldPermutationUnrank0(legacyRank0)`. Li chain -1 ... +1 ... -1 resta fisicmen visibil quam scar mandat e ne es algebricmen simplificat.

### Pro quo li patch es normativmen equivalent

Li helper legacy enumera exactmen li 720 permutations lexicographic per ranks 0..719. Li ordinal semantic derivat del drop es 1..720; subtracter un unit produce bijectivmen li rank 0..719 correspondent. Ergo li call final rende exactmen li permutation normativ por chascun residue del drop modulo 720, includente li boundary oneBased=720 quel deven rank0=719.

### Crescentie monster in ti stage

Un `Patch08PermutationWrapper` ha esset insertet pos `Discovery08PermutationRankHandler`. Li context conserva li drop, li ordinal one-based, li `legacyRank0` e li output reparat. `BaseMonsterManager` expone un route historic separat quel executa discovery e patch in li sam context e metrics resta non-semantic.

### Scar conservat

`legacyBowlOrderFromDrop(1)` continua rendre li duesim permutation, e li caller legacy continua passar su ordinal directmen quam rank0. Li patch ne muta ni reordina li helper legacy. Null `bowlAlias`, pours de Patch 09 o code posterior es present.


## Stage 18 — DISCOVERY 09

### Quo on pensat

Pos li correction del rank de permutation, li routine historic de pours ja possede un `order` exact. Tamen su design anterior considera numeration de position e identitá de bowl quam li sam cose, ergo li tri pours continua leer bowls fix 1,2,3.

### Quo esset decovrit

Li specification liga pour 1 al bowl in position 1 del `order`, pour 2 al bowl in position 2, e pour 3 al bowl in position 3. `legacyPoursToFixedBowlIds` calcula li sam order ma usa directmen `oldBowls[1]`, `oldBowls[2]`, `oldBowls[3]`. Quand li prim tri IDs del order ne es 1,2,3, li factors de WHEAT, BARLEY e SALT multiplica li bowl fals. Por drop 127 li order es `[2,1,4,3,5,6]`; li tri outputs legacy deven `16163,16188,16242` contra `16167,16182,16252`.

### Quo esset circumit

Null circumventione existe in ti stage. Null alias de position a bowl ID es addit. Li correction mandat quel deve traducter chascun position per li order apartene exclusivmen a PATCH 09 in Stage 19.

### Crescentie monster in ti stage

Un `LegacyFixedPourAdapter` e un `Discovery09FixedPourHandler` ha esset addit. Li context conserva li drop, su index, li order calculat, li lista explicit de bowl IDs fix `[1,2,3]`, li bowls anterior, li row de stones e li output legacy. `BaseMonsterManager` expone un route separat con context fresc e metric non-semantic.

### Pro quo li strat nov ne adjunte un defect extra

Li order veni exclusivmen de `orderPatchFromValue`, ergo Patch 08 resta activ e exact. Li routine de Discovery 09 ne muta bowls, ne implementa li update de six bowls e ne introduce contamination in-place de Patch 10. Li unic divergence nov es precis li confusion mandat inter position e bowl ID durant li tri pours. Null `bowlAlias`, null `vaultOld` e null code posterior es present.


## Stage 19 — PATCH 09

### Quo esset circumit

`legacyPoursToFixedBowlIds` ne esset modificat. Li nov `installBowlAlias(order)` crea un array one-based u `bowlAlias[position]` es li bowl ID in ti position del order. `bowlAtLegacyPosition(oldBowls, bowlAlias, position)` es insertet quam translator explicit, e `poursThroughBowlAlias` voca realmen li routine legacy ante superscrir li tri pours con reads exclusivmen tra ti alias.

### Pro quo li patch es normativmen equivalent

Patch 08 ja rende li order exact. Li specification liga chascun pour al bowl in un position del order; ergo li map `position -> order[position]` rende exactmen li ID semantic sin mutar ni reordinar li bowls. Li formules numeric, li SAVE, li stone factors e li index del visible drop resta identic; solmen li fonte del bowl multiplicat es traductet al ID correct.

### Crescentie monster in ti stage

Un `Patch09BowlAliasWrapper` ha esset insertet pos `Discovery09FixedPourHandler`. Li context conserva li output fixed-bowl legacy, li `bowlAlias`, li tri IDs aliased, un flag quel confirma li call legacy e li output final. Li helper de patch apella anc directmen li routine legacy, talmen li scar ne posse esser optimisat for del route historic.

### Scar conservat

`legacyPoursToFixedBowlIds(127,...)` continua rendre `16163,16188,16242` e resta directmen testabil. `bowlAlias` ne es eliminat ni remplaciat per indexing simplificat. Null bowl update in-place existe ancor; `vaultOld`, `pending` e li commit simultan de Patch 10 resta absent.

### Pro quo li strat nov ne adjunte un defect extra

Li alias es un permutation direct del order exact e ne participa in selection, SAVE o mutation de state. Li wrapper ne muta `oldBowls` ni `stoneRow`, e metrics/diagnostics ne decide null valore semantic. Ergo li unic change semantic es li correction local mandat de positions a bowl IDs.

## Stage 20 — Discovery 10: contamination in-place del bowl-round

### Quo on pensat

Pos li correction de bowlAlias, on tractat li six updates del bowls quam un serie natural de assignationes al sam vector: calcular un position, scrir su bowl, continuar al position sequent. On supposit que li order circular sufficet por conservar li relation inter neighbors.

### Quo esset decovrit

Li semantics normativ exige que omni six outputs de un drop nasce ex li sam statu anterior. Li routine legacy scri directmen in `bowls[bowlId]`; consequentmen un position posterior posse usar un `prevId` o `nextId` ja mutat. Con drop 1 e order identic, li prim bowl concorda ma omni bowls 2..6 diverge, quo isola li contamination sin depender de un permutation nontrivial.

### Quo esset circumit

Null circumition existe ancor in ti stage. Li regression resta rubi intentionalmen e li routine in-place resta li unic behavior nov expost.

### Crescente del monster

`LegacyInPlaceBowlAdapter` e `Discovery10InPlaceBowlHandler` adjunte un nov route. Li handler clona li input extern solmen por ownership del invocation, registra li statu ante li mutation, li order, li pours, li vector de labor e li output legacy, e demonstra que li helper retorna exactmen li sam object mutat.

### Pro quo li nov layer ne change altri semantics

Li route de Discovery 10 es isolat e ne participa ancor in un resultate final. Omni scars e patches 01..09 resta fisicmen intact, omni regressions precedent resta verd, e null code reparativ de Patch 10 es present.


## Stage 21 — PATCH 10

### Quo esset circumit

`legacyStirOneDropInPlace` ne esset modificat. Li nov `stirOneDropViaShadow` voca realmen ti helper sur un clone separat e conserva li resultate contaminat quam `legacyGarbage`. Solmen poy it crea un snapshot fisic `vaultOld` del bowls original e un buffer separat `pending`. Durante li loop de six positions, omni read de current, prev e next bowl veni exclusivmen ex `vaultOld`; chascun output es scrit solmen a `pending[bowlId]`. Li commit semantic es creat per `pending.slice()` solmen pos li loop complet.

### Pro quo li patch es normativmen equivalent

Li specification defini li six outputs de un visible drop quam un transition simultan ex li statu ante ti drop. Un snapshot immutabil del six bowls representa exactmen ti statu anterior. Calcular chascun formule con current/prev/next ex `vaultOld`, durant que li outputs nov ne deven legibil til li fin del round, elimina exclusivmen li contamination sequential e conserva li order, pours, SAVE, stones, index e formule numeric ja reparat per patches precedent. Ergo `pending` coincide position per position con li transition normativ.

### Crescentie monster in ti stage

Un `Patch10ShadowBowlWrapper` ha esset insertet pos `Discovery10InPlaceBowlHandler`. Li context conserva simultanmen li output legacy contaminat de Discovery 10, un duesim legacy garbage executet intra li helper de patch, `patch10VaultOld`, `patch10Pending`, un flag explicit que li commit eveni pos omni six writes, e li output final. Ti duplicat execution es intentional e ne es simplificat.

### Scar conservat

Li helper legacy continua mutar e retornar li sam vector. Li route reparat ne renoma ni elimina `vaultOld` o `pending`; ambi deve restar quam detour historic. Null `orderAt46Latch`, post-stir o code de Patch 11 es addit in ti stage.

### Pro quo li strat nov ne adjunte un defect extra

Li snapshot e buffer es invocation-local e ne participa in selection o cache. Li input extern ne es mutat per li route semantic, li legacy garbage ne decide li output, e li commit usa solmen li six values ja complet in `pending`. Omni patches 01..09 resta fisicmen intact e testabil.


## Stage 22 — DISCOVERY 11

### Quo on pensat

On conservat un unic camp de memorie por li order current del bowls. Durante li 46 drops ti camp semblat suficient: chascun nov drop superscri li order anterior, e al fin de drop 46 li camp contene exactmen li order necessi. Li sam camp esset poy reutilisat durant li post-stirs quam diagnostic del order current.

### Quo esset decovrit

Li query posterior ne questiona li ultim order del post-stir; it besona li order exact del visible drop 46. Li memorie general es tamen superscrit 46 vezes durant li drops e anc 12 vezes durant li post-stirs. Consequentmen li valore correct de drop 46 existe solmen por un moment e, pos post-stir 12, li query legacy lee un permutation diferent. In li witness del Foundation, omni six bowls final resta exact, ma li positions 1, 2 e 6 del query order diverge del order de drop 46.

### Quo esset circumit

Null circumition existe in Discovery 11. Li memorie superscribil resta li unic fonte semantic de `queryOrder`. Un copie del order de drop 46 es conservat solmen quam diagnostic de test e context; it ne es leet por decidir li query. Li latch separat apartene exclusivmen a PATCH 11.

### Crescentie monster in ti stage

Li monster obtene un path complet de sauce partial: `initialBowlsForOrderMemoryDiscovery`, `visibleDropThroughCurrentLayers`, `postStirOneForOrderMemoryDiscovery` e `legacySauceWithOverwritableOrderMemory`. Supra ti path, `LegacyOverwritableOrderMemoryAdapter` e `Discovery11OverwrittenOrderHandler` conserva li 58 writes, li ultim fonte, li order diagnostic de drop 46, li ultim post-stir, li drops e li bowls final in un context invocation-local.

### Pro quo li nov layer ne change altri semantics

Li visible drops usa exclusivmen li access history de Patch 06 e li grind table con sentinel de Patch 07; li order usa Patch 08, li pours usa bowlAlias de Patch 09, e li six updates de chascun drop usa `vaultOld`/`pending` de Patch 10. Li 12 post-stirs usa un snapshot old e un pending complet por chascun round. Ergo li six bowls final concorda con li reference normativ local; li unic defect nov e intentional es li ownership historic del memorie de order.


## Stage 23 — PATCH 11

### Quo esset circumit

`legacySauceWithOverwritableOrderMemory` ne esset modificat. Li nov `sauceWithOrderAt46Latch` voca realmen ti route legacy quam garbage historic, poy repassa li 46 drops e 12 post-stirs con li sam patches numeric. Pos que li bowl-round de drop 46 es complet, ma ante que post-stir 1 comensa, `writeOrderAt46LatchOnce` clona li order exact in un state separat. Li loop de post-stirs continua superscrir solmen `legacyOrderMemory`; it ne ha null write-site al latch.

### Pro quo li patch es normativmen equivalent

Li specification demanda que queries posterior usa li order del visible drop 46, ne li order current de un post-stir. Al moment exact inter drop 46 e post-stir 1, li order calculat es ja normativmen exact per Patch 08 e ne depende de null state posterior. Un clone single-write conserva precis ti valore. Diriger `queryOrder` al latch cambia solmen ownership temporal del order; drops, bowls, post-stirs, SAVE e omni formules resta identic.

### Crescentie monster in ti stage

Li monster adjunte `createOrderAt46LatchState`, `writeOrderAt46LatchOnce`, `readOrderAt46Latch`, `sauceWithOrderAt46Latch` e `Patch11OrderAt46LatchWrapper`. Li context conserva in parallel li garbage legacy, li latch, su write-count e fonte, li memorie legacy final pos 58 writes, li ultim order de post-stir, li bowls final e li query reparat. Un tentative de duesim write al latch es explicitmen rejectet.

### Scar conservat

Li memorie legacy continua esser superscrit 46 + 12 vezes e termina con fonte `post-stir 12`. Su `queryOrder` direct continua esser fals in li witness del Foundation. Li helper legacy resta byte-per-byte identic e ne conosse null `orderAt46Latch`. Null `oldNextBowlFixedName` o logic de Patch 12 existe in ti stage.

### Pro quo li strat nov ne adjunte un defect extra

Li latch es invocation-local, contene un clone fisic de six IDs e posse esser scrit exactmen un vez. Reads retorna anc clones, ergo un consumer ne posse mutar li fonte semantic. Post-stirs conserva lor memorie legacy separat, e li garbage legacy ne decide li output reparat. Li six bowls final e omni regressions precedent resta invariat.


## Stage 24 — DISCOVERY 12

### Quo on pensat

Pos que Patch 11 ha conservat li order exact del drop 46, li layer historic de query continuat usar li notion anterior que bowls have nomes numeric fix e que "li sequent bowl" es simplicmen li ID numeric sequent, con wrap de 6 a 1. Ti assumption sembla innocu si li order latchet coincide con li ring numeric.

### Quo esset decovrit

Li semantics de query depende del position del queried bowl in `orderAt46Latch`, ne de su ID numeric. In un latch `[1,2,3,4,6,5]`, por exemple, li successor de 4 es 6, li successor de 5 es 1 e li successor de 6 es 5. `oldNextBowlFixedName` rende respectivmen 5, 6 e 1, ergo li defect resta visibil mem si li latch self es correct.

### Quo esset circumit

Null circumition existe in Discovery 12. `oldNextBowlFixedName(id)` es li unic helper nov de next-bowl e continua usar exclusivmen li ring numeric fix. Null code de production cerca li queried ID in li latch o calcula su successor circular. Ti detour apartene exclusivmen a PATCH 12.

### Crescentie monster in ti stage

Li monster adjunte `LegacyNextBowlAdapter` e `Discovery12NextBowlHandler`. Li manager prepara realmen Discovery 11 e Patch 11 ante intrar in Discovery 12, talmen li handler recive un `orderAt46Latch` valid e single-write. Li context conserva separatmen li latch, li queried ID e li output fixed-ID legacy, durant que metrics registra li nov call.

### Pro quo li nov layer ne change altri semantics

Li helper ne muta li latch, bowls, drops o stones. Li route usa li output de Patch 11 solmen quam state precedent valid e li regression nov es isolat al next-bowl. Omni regressions precedent resta verd e null logic de Patch 12 o Patch 13 es present.


## Stage 25 — PATCH 12

### Quo esset circumit

`oldNextBowlFixedName` ne esset modificat. Li nov `NextBowlPatchWrapper` recive li `orderAt46Latch` ja valid de Patch 11 pos que `Discovery12NextBowlHandler` ha executet li scar fixed-ID. Li wrapper voca li helper legacy denov quam diagnostic explicit e conserva ti raw valore, ma deriva li output semantic per `nextBowlFromOrderAt46Latch`.

### Pro quo li patch es normativmen equivalent

Li specification defini next-bowl quam li successor del queried bowl in li order latchet de drop 46. Trovar li position del ID in un permutation de six IDs e leer li position sequent con wrap modulo six implementa exactmen ti relation circular. Null valore de bowl, drop, sauce o post-stir es recalculat per ti patch.

### Crescentie monster in ti stage

Li context obtene `patch12OrderAt46Latch`, `patch12QueriedId`, `patch12QueriedPosition`, `patch12LegacyDiagnostic`, un flag que li diagnostic legacy esset realmen executet, e `patch12Output`. Li route complet passa per Discovery 11, Patch 11, Discovery 12 e finalmen `NextBowlPatchWrapper`, con metrics separat por li scar e li detour.

### Scar conservat

Li helper `oldNextBowlFixedName(id)` continua retornar li ring numeric fix `1→2→3→4→5→6→1` e ne conosse null latch. It resta directmen testabil e su source ne contene null lookup positional. Ti duplicat diagnostic ne es simplificat.

### Pro quo li strat nov ne adjunte un defect extra

`nextBowlFromOrderAt46Latch` valida que li latch es un permutation complet de 1..6 e que li queried ID es valid. It ne muta li latch e ne usa state global. Un sweep de omni 720 permutations e omni six queried IDs concorda con li reference normativ local. Null `biasedLegacyPick` o code de Patch 13 es addit.


## Stage 26 — DISCOVERY 13

### Quo on pensat

Li selector historic tractat li answer de un bowl quam si un simplic modulo esset suficient por projecter it in un familie ordonat de grandore `N`. Pos que li answer self es uniformmen situat sur li ring `1..M`, on passat li prim valore directmen a `biasedLegacyPick(x,N)` e retornat `regularMod(x-1,N)+1`.

### Quo esset decovrit

Si `N` ne divide `M`, li ultim `M mod N` valores del answer ring forma un caude quel ne posse esser projectet directmen sin bias. Li specification exige que ti valores es rejectet e que on avansa sur li sam answer ring til trovar un `x` acceptabil. In li witness real del Foundation, bowl 1 con seal 1 produce un prim answer `90411690289794975082828500805689671121` e direction `-1`. Con `N=first-1`, li prim answer deve esser rejectet e li sequent answer es exactmen `N`; li legacy direct rende tamen 1.

### Quo esset circumit

Null circumition existe in Discovery 13. `biasedLegacyPick` es li unic selector nov e resta direct modulo. `LegacyBiasedSelectionAdapter` usa exactmen `ringAnswerAt(stream,0)` e voca li helper immediatmen; it ne calcula null limite, ne avansa null offset e ne executa null rejection. Li correction apartene exclusivmen a PATCH 13.

### Crescentie monster in ti stage

Li monster adjunte `answerRingFromCurrentState`, quel deriva `first` e `directionStep` ex li bowls final e li next-bowl ja reparat, poy `ringAnswerAt` quam ring exact. `LegacyBiasedSelectionAdapter` e `Discovery13BiasedSelectionHandler` conserva in li context li seal, first, direction, `N`, li prim answer e li output modulo legacy. Li manager conecta ti layer pos Discovery 11, Patch 11, Discovery 12 e Patch 12, ergo li defect es visibil sur un route real e ne sur un helper isolat solmen.

### Pro quo li nov layer ne change altri semantics

Li answer ring usa solmen state invocation-local ja derivat per patches precedent e ne muta bowls, latch, stones o catalog. `biasedLegacyPick` ne es usat retroactivmen in alcun selector anterior, e null acceptance-limit o wide selection existe in production. Omni regressions til Patch 12 resta verd; li unic failure intentional es li comparison normativ de Discovery 13.



## Stage 26 — DISCOVERY 13

### Quo on pensat

Li selector historic tractat li answer de un bowl quam si un simplic modulo esset suficient por projecter it in un familie ordonat de grandore `N`. Pos que li answer self es situat sur li ring `1..M`, on passat li prim valore directmen a `biasedLegacyPick(x,N)` e retornat `regularMod(x-1,N)+1`.

### Quo esset decovrit

Si `N` ne divide `M`, li ultim `M mod N` valores del answer ring forma un caude quel ne posse esser projectet directmen sin bias. Li specification exige que ti valores es rejectet e que on avansa sur li sam answer ring til trovar un `x` acceptabil. In li witness real del Foundation, bowl 1 con seal 1 produce un prim answer `90411690289794975082828500805689671121` e direction `-1`. Con `N=first-1`, li prim answer deve esser rejectet e li sequent answer es exactmen `N`; li legacy direct rende tamen 1.

### Quo esset circumit

Null circumition existe in Discovery 13. `biasedLegacyPick` es li unic selector nov e resta direct modulo. `LegacyBiasedSelectionAdapter` usa exactmen `ringAnswerAt(stream,0)` e voca li helper immediatmen; it ne calcula null limite, ne avansa null offset e ne executa null rejection. Li correction apartene exclusivmen a PATCH 13.

### Crescentie monster in ti stage

Li monster adjunte `answerRingFromCurrentState`, quel deriva `first` e `directionStep` ex li bowls final e li next-bowl ja reparat, poy `ringAnswerAt` quam ring exact. `LegacyBiasedSelectionAdapter` e `Discovery13BiasedSelectionHandler` conserva in li context li seal, first, direction, `N`, li prim answer e li output modulo legacy. Li manager conecta ti layer pos Discovery 11, Patch 11, Discovery 12 e Patch 12, ergo li defect es visibil sur un route real e ne sur un helper isolat solmen.

### Pro quo li nov layer ne change altri semantics

Li answer ring usa solmen state invocation-local ja derivat per patches precedent e ne muta bowls, latch, stones o catalog. `biasedLegacyPick` ne es usat retroactivmen in alcun selector anterior, e null acceptance-limit o wide selection existe in production. Omni regressions til Patch 12 resta verd; li unic failure intentional es li comparison normativ de Discovery 13.

## Stage 27 — PATCH 13

### Scar historic conservat

`biasedLegacyPick(x,N)` resta sin modification. It continua mappar directmen `x` per `regularMod(x-1,N)+1`, e li route separat de Discovery 13 continua esser disponibil por provar que ti call es biased si `x` cade in li caude rejectend.

### Circumition exact

`patchedSmallPick(stream,N)` implementa li ordine mandat: `limit=(M_OLD/N)*N`, `offset=0`, poy `x=ringAnswerAt(stream,offset)`; durante que `x>limit`, it incrementa offset e lee denov ex li sam ring. Solmen pos que `x<=limit`, li function voca `biasedLegacyPick(x,N)`. Li helper legacy ne es correctet in-place.

### Route monster

`SelectionRejectionPatchWrapper` es conectet directmen pos `NextBowlPatchWrapper`. Li route reparat ne passa per `Discovery13BiasedSelectionHandler`, nam ti handler es li scar quel voca li selector legacy ante rejection. Li wrapper conserva li acceptance-limit, accepted offset, accepted answer e li output semantic in `BaseMonsterContext`, e un metric separat registra li call de Patch 13.

### Pro quo li patch es equivalent

Por `1<=N<=M_OLD`, li accepted region ha grandore multipli exact de `N`; ergo li direct modulo historic es unbiased solmen pos rejection. Avansar per `ringAnswerAt` conserva li unic answer ring e su direction; null stream alternativ es creat. Li witness del Foundation rejecte exactmen un answer e retorna `N`, e tests additiv concorda con li reference normativ local. Null `wideDetour` o logic de Patch 14 es addit.


## Stage 28 — DISCOVERY 14

### Quo on pensat

Pos Patch 13, li selector curt ja rejecte li caude biased correctmen, ma li architectura historic continua presumir que chascun familie ordonat posse esser tractat per ti sam path. Null dispatcher examina si `N` es plu grand quam `M_OLD`; li call site envia li grandore directmen al selector curt.

### Quo esset decovrit

Un answer ring individual contene solmen `M_OLD` valores. Ergo un familie con `N>M_OLD` ne posse esser representat per un unic answer e ne posse intrar in li contract de `patchedSmallPick`. In li witness real del Foundation, `N=M_OLD+1`: li route historic curta falla con `RangeError`, ma li selection wide normativ deriva un rank exact `2` ex plu quam un position del sam ring.

### Quo esset circumit

Null circumition existe in Discovery 14. `legacySelectionAssumingNLeM(stream,N)` conserva intentionalmen li assumption defectiv e delega directmen a `patchedSmallPick`, sin branch de largore e sin representation wide. `Discovery14WideSelectionHandler` captura solmen li failure quam diagnostic invocation-local por que li divergence posse esser testat deterministicmen. Li correction `wideDetour` apartene exclusivmen a PATCH 14.

### Crescentie monster in ti stage

Li monster adjunte `LegacyShortFamilyAssumptionAdapter` e `Discovery14WideSelectionHandler`. Li route prepara li sauce, latch e next-bowl per patches precedent, deriva un answer ring real, poy registra seal, first, direction, `N`, li flag de assumption curt, li nom del errore e su message. Un metric separat conta li tentative wide fallit.

### Pro quo li nov layer ne change altri semantics

Li selector `biasedLegacyPick` e `patchedSmallPick` resta textualmen e semanticmen intact. Families `N<=M_OLD` continua usar li route GREEN de Patch 13. Li nov handler es apellet solmen per li route de Discovery 14 e ne adjunte null `wideDetour`, null digits, null `M^places` e null rejection wide. Omni regressions precedent resta verd; li unic failure intentional es li comparison final del nov discovery.

## Stage 29 — PATCH 14

### Scar historic conservat

`legacySelectionAssumingNLeM(stream,N)` resta textualmen intact. It continua delegar omni familie a `patchedSmallPick` e dunque falla con `RangeError` por `N>M_OLD`. `Discovery14WideSelectionHandler` resta un route real e conserva ti failure quam diagnostic; li patch ne re-scrive ni masca li assumption historic.

### Dispatcher e detour wide

`selectionDispatcherWithWideDetour` introduce li branch exact mandat. Por `N<=M_OLD`, it usa `patchedSmallPick` e conserva li rejection curt de Patch 13. Por `N>M_OLD`, it usa `wideDetour`. Ti detour trova li minimal `places` tal que `space=M_OLD^places>=N`, poy lee `ringAnswerAt(stream,j)-1` por `j=0..places-1` un unic vez e construi `wide=1+Σ digits[j]*M_OLD^j` con pesos little-endian.

### Rejection sin nov digits

Li acceptance-limit wide es `floor(space/N)*N`. Pos li construction unic del vector `digits`, li rejection move solmen li numero `wide` self per `directionStep` sur li ring `1..space`. Null call a `ringAnswerAt` existe in ti fase. Quande li numero entra in li region acceptabil, li rank final es `regularMod(wide-1,N)+1`.

### Crescentie monster e ownership

`WideSelectionPatchWrapper` es insertet pos `Discovery14WideSelectionHandler`. It conserva separatmen li failure legacy, li mode del dispatcher, places, space, digits, quantité de reads, numero wide inicial, acceptance-limit, numero acceptat, passus de rejection e output final. Ti state es invocation-local e diagnostics legacy ne es re-leet por decision semantic.

### Verification

Li witness real del Foundation con `N=M_OLD+1` conserva `legacy output=null` e `RangeError`, durante que li route reparat retorna rank `2`. Un witness synthetic força exactmen un passu de rejection wide e verifica que li quantité de digit reads resta egal a `places`. Cases de du e tri places concorda con li reference normativ local, e li dispatcher curt concorda con Patch 13. Null `oldGateQuestionDay` o logic de Patch 15 es addit.
