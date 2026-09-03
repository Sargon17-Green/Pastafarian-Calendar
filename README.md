# Calendare Pastafarian — JavaScript + Interlingue / Occidental

Ti directoria es un linea de implementation completmen independent. It ha esset creat de zero por li pare `JavaScript` + `Interlingue / Occidental`, solmen ex li specification normativ includet in li task. Null code, test, fixture, output, table generat, cache, log, hash o checksum de un altri implementation ha esset usat.

## Statu actual

Li linea es in **Stage 54 de 55: INTEGRATION** e li repository local es `GREEN`. Omni 26 patches resta activ e li route final `calendarDateSpaghetti(calculationDay,targetDay)` es nu integrat. `sauceWithScars` conserva li cresciment historic del sauce; li main state-machine conecta gates, years, cache, structure, cutlets, mensus e li exact five-field return sin production oracle.

Stage 55 resta separat quam audit independent. Null conclusion de completitá final es fat in Stage 54.

## Lingue-fonte canonic

`src/source-language-catalog.js` contene un unic `SourceLanguageCatalog` congelat. Li 17 nomes de cutlettes e li 47 nomes de mensus have indices canonic 1..17 e 1..47. Li órdine semantic usa exclusivmen `canonicalIndex`; textu, collation, Unicode e locales ne participa in selection, rank, unrank o cache semantic.

Nomes con signification lexical es traductet secun lor signification. Nomes de locs con form international stabil usa lor form international in Interlingue. Nomes inventet sin signification ne recive un signification artificial.

### Regul deterministic de transliteration

Por formes hebreic vocalisat, signes de vocalisation es resoluet in vocales `a e i o u`; consonantes es transliterat in lettres latines secun un table fonetic stabil, e marcas cantillatori ne es conservat. Por un form non-vocalisat u li scritura ne determina unicmen li pronunciation, li resultate es un entry explicit e congelat in li catalog; un tal entry ne posse esser recalculat per locale o collation. Por li du formes inventet del specification, li outputs congelat de Bootstrap es `Palgursh` e `Karshumb`. Ti decision es solmen presentation; lor `canonicalIndex` resta li unic identitá semantic.

## Exactitá numeric

Omni calcul normativ e historic numeric usa `BigInt`. Null floating-point es usat por SAVE, tags, distance o mutation de stones. `M = 2^127 - 1` es representat exactmen.

## Tests

Omni regressions til Patch 26 deve restar verd:

```text
npm run test:previous
```

Li verifier actual deve esser verd:

```text
node tests/verify-stage-01.js
```

Li test focal del integration final deve esser verd:

```text
npm run test:integration-54
```

Li suite complet deve esser verd:

```text
npm test
```

## Stage 11 — Patch 05

Li storage legacy del sett hidden drops resta fisicmen retrograd. `hiddenByNearness` adjunte exclusivmen li translator `8-k` por access semantic per proximity; it ne reverse, ne copie in ordine nov e ne elimina li scar de Discovery 05. `Patch05HiddenNearnessWrapper` registra li proximity demandat e li slot fisic usat durant li route historic. Li regression de Discovery 05 es nu verd.


## Stage 12 — Discovery 06

Li history legacy ne conosse li hidden drops. `legacyPrior(dropStore, i, back)` lee directmen `dropStore[i-back]`; por un slot positiv it posse trovar un visible drop precedent, ma por `0..-6` it ne traducte a hidden1..hidden7. `Discovery06PriorHandler` conserva ti failure intact in li route historic. Li correction `priorPatch` es reservat exclusivmen por Stage 13.

## Stage 13 — Patch 06

`legacyPrior` resta intact. `priorPatch` usa li call legacy real quand `i-back >= 1`; altrimen it mappa li slot non-positiv a `k = 1-(i-back)` e delega a `hiddenByNearness`. Li array hidden backward ne es reversat ni migrat. `Patch06PriorWrapper` conserva li scar e li decision de branch in li context. Li regression de Discovery 06 es verd.


## Stage 14 — Discovery 07

Li table historic de visible grinds es almacenat quam un array zero-based de undec rows, durante que li caller historic continua numerar grinds 1..11 e usa ti ordinal directmen quam index. Li data self es correct; li defect es exclusivmen li mismatch de convention de indices. `Discovery07GrindIndexHandler` conserva ti scar in li route production. Li sentinel reparativ de Patch 07 ne es present in ti stage.

## Stage 15 — Patch 07

`LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED` e `legacyGrindRow` resta intact quam scar historic. `GRIND_TABLE_WITH_SENTINEL` adjunte un slot permanent a index 0 e conserva li undec rows real in indices 1..11. `grindRowWithSentinel` usa ancora li ordinal one-based directmen quam index, e `Patch07GrindSentinelWrapper` conserva li output legacy e li reparat in li sam context. Li regression de Discovery 07 es nu verd sin deleter li sentinel.


## Stage 16 — Discovery 08

`oldPermutationUnrank0(rank0)` es congelat quam li helper historic de unranking por rank0 0..719. Li caller de Discovery 08 deriva `oneBased = regularMod(drop-1,720)+1` e passa ti ordinal directmen al helper, ergo rank 1 deven li duesim permutation in vice del prim, e talmen por omni valore acceptat. Li conversion `legacyRank0 = oneBased-1` apartene exclusivmen a Patch 08 in Stage 17.


## Stage 17 — Patch 08

`oldPermutationUnrank0` e `legacyBowlOrderFromDrop` resta intact quam scars historic. `orderPatchFromValue` conserva exactmen li bridge mandat `oneBased = regularMod(value-1,720)+1`, `legacyRank0 = oneBased-1`, poy voca li helper legacy con ti rank0. `Patch08PermutationWrapper` conserva li ordinal e li rank traductet in li context. Li regression de Discovery 08 es nu verd; li chain -1 ... +1 ... -1 ne es simplificat.


## Stage 18 — Discovery 09

Li order de bowls ja es reparat per Patch 08, ma li routine historic de pours ne usa ti IDs selectet. It tracta positions semantic 1,2,3 quam bowl IDs fisic 1,2,3 e lee directmen `oldBowls[1]`, `oldBowls[2]`, `oldBowls[3]`. `LegacyFixedPourAdapter` e `Discovery09FixedPourHandler` conserva ti mismatch. Li translator de Patch 09 resta reservat por Stage 19.


## Stage 19 — Patch 09

`legacyPoursToFixedBowlIds` resta intact quam scar historic. `installBowlAlias` fixa li relation `bowlAlias[position]=order[position]` por positions 1..6, e `bowlAtLegacyPosition` es li unic read semantic usat por li bowls del tri pours. `poursThroughBowlAlias` executa realmen li helper legacy ante li overwrite aliased; `Patch09BowlAliasWrapper` conserva li output legacy e li reparat. Li regression de Discovery 09 es nu verd sin introducter li snapshot/commit de Patch 10.

## Stage 20 — Discovery 10

Li route historic nu expone un defect separat in li stir del six bowls. `legacyStirOneDropInPlace` prende li pours ja reparat per `bowlAlias`, ma actualisa li vector de bowls directmen position pos position. Ti significa que un position posterior posse leer un prev o next bowl ja actualisat in li sam round, in vice de leer exclusivmen li statu ante li drop.

Li regression de Discovery 10 usa intentionalmen un order identic por isolar li contamination del problema de alias: li prim output concorda, ma li quin bowls posterior diverge del transition simultan normativ. `npm run test:previous` resta verd; `npm run test:discovery-10` e `npm test` es intentionalmen rubi. Null snapshot reparativ, null `vaultOld` e null `pending` es includet in ti stage.


## Stage 21 — Patch 10

`legacyStirOneDropInPlace` resta intact quam scar historic e continua contaminar bowls posterior quand it es vocat directmen. `stirOneDropViaShadow` voca realmen ti helper sur un clone separat, conserva su garbage, poy crea li snapshot fisic `vaultOld`. Li six calculs semantic lee solmen ex ti snapshot e scri exclusivmen in `pending`; solmen pos li six positions li buffer complet deven li commit final. `Patch10ShadowBowlWrapper` conserva li snapshot, pending, garbage legacy e output reparat in li sam context. Li regression de Discovery 10 es nu verd. Null latch de order al drop 46 o code de Patch 11 es present.


## Stage 22 — Discovery 11

Li nov path `legacySauceWithOverwritableOrderMemory` materialisa 46 visible drops tra li patches ja existent, aplica chascun bowl-round per `stirOneDropViaShadow`, e poy executa 12 post-stirs con `savedStirSum = SAVE(sum(oldBowls)+149*stir)`. Omni bowl reads del post-stir veni del sam snapshot e omni six writes deven un batch separat, talmen li bowls resta exact.

Li defect current es exclusivmen li memorie de order: un unic `legacyOrderMemory` es superscrit un vez per drop e un vez per post-stir. Li order de drop 46 es dunque calculat exactmen ma poy perdit quam fonte semantic de query. `Discovery11OverwrittenOrderHandler` conserva li 58 writes, li fonte final post-stir 12, li diagnostic del drop 46 e li query legacy superscrit. Li regression nov compara positions 1, 2 e 6 contra li order normativ de drop 46 e resta rubi intentionalmen. Null latch reparativ es addit in ti stage.


## Stage 23 — Patch 11

`legacySauceWithOverwritableOrderMemory` resta intact e continua esser un witness direct del defect: 58 writes al sam memorie e un `queryOrder` final egal al order del post-stir 12. `sauceWithOrderAt46Latch` apella realmen ti legacy quam garbage historic, poy executa li route semantic con un separat state single-write.

Exactmen pos drop 46, `writeOrderAt46LatchOnce` clona li order in `orderAt46Latch`; ti write-site precede li loop del 12 post-stirs. Li latch rejecte un duesim write, e li post-stirs ne toca it. Durante que li `legacyOrderMemory` continua til 58 writes, `queryOrder` es derivat exclusivmen per `readOrderAt46Latch`. `Patch11OrderAt46LatchWrapper` conserva simultanmen li garbage legacy, li latch, li ultim memorie superscrit e li resultate semantic. Null next-bowl logic de Patch 12 es anticipat.


## Stage 24 — Discovery 12

Li latch de drop 46 ja es exact e stabil, ma li layer historic de next-bowl conserva un vocabularium anterior: `oldNextBowlFixedName(id)` avansa per li IDs numeric `1→2→3→4→5→6→1`. Ti helper ne cerca li queried ID in `orderAt46Latch` e ne conosse null position circular.

`LegacyNextBowlAdapter` es insertet pos Patch 11 e `Discovery12NextBowlHandler` registra li latch, li queried ID e li successor legacy in li context invocation-local. Li regression nov usa un latch nontrivial por monstrar que li successor numeric fix diverge del successor circular definit per li order latchet. Null correction de Patch 12 es anticipat.


## Stage 25 — Patch 12

`oldNextBowlFixedName` resta intact e continua representar li successor numeric fix historic. `nextBowlFromOrderAt46Latch` valida un permutation latchet de six IDs, trova li queried ID per position e retorna `orderAt46Latch[(position+1) mod 6]`; li ultim position wrap al prim. `NextBowlPatchWrapper` voca li legacy diagnosticmen e conserva su output in li context, ma li successor semantic veni solmen del latch. Li regression de Discovery 12 deven verd por li fixture `[1,2,3,4,6,5]` e li test de Patch 12 verifica omni six IDs super omni 720 permutations. Null `biasedLegacyPick` o code de Patch 13 es present.


## Stage 26 — Discovery 13

Li state precedent ja posse derivar un next-bowl exact ex `orderAt46Latch`. Ti stage adjunte `answerRingFromCurrentState` e `ringAnswerAt` por representar li answer ring exact, ma conserva un selector historic separat: `biasedLegacyPick(x,N)` fa directmen `regularMod(x-1,N)+1`. `LegacyBiasedSelectionAdapter` prende solmen `ringAnswerAt(stream,0)` e passa ti prim answer al selector, sin examinar si it cade in li parte rejectend del ring.

`Discovery13BiasedSelectionHandler` es conectet pos `NextBowlPatchWrapper`, talmen li witness real usa li six bowls final e li successor circular ja reparat. Por li Foundation, bowl 1 e seal 1, li prim answer es `90411690289794975082828500805689671121` con direction `-1`. Si `N` es un minus quam ti first, li prim answer es rejectend e li sequent answer es exactmen `N`; li legacy tamen mappa li prim answer directmen e rende 1. Li correction de rejection apartene exclusivmen a Stage 27 / Patch 13. Null `wideDetour` o logic de Patch 14 es present.

## Stage 27 — PATCH 13

### Quo esset conservat

`biasedLegacyPick(x,N)` resta fisicmen intact e continua retornar `regularMod(x-1,N)+1` sin rejection quand on lo voca directmen. `LegacyBiasedSelectionAdapter` e `Discovery13BiasedSelectionHandler` resta egalmen disponibles por demonstrar li scar historic de Stage 26.

### Quo li patch adjunte

`patchedSmallPick(stream,N)` calcula `limit=(M_OLD/N)*N`, prende `ringAnswerAt(stream,0)` e avansa un offset sur exactmen li sam answer ring durante que `x>limit`. Solmen pos trovar un `x` acceptabil it voca `biasedLegacyPick(x,N)`. Li helper legacy ne es duplicat ni correctet in su fonte.

`SelectionRejectionPatchWrapper` deriva e conserva li limite, li offset acceptat e li answer acceptat in li context. Li route reparat ne passa per `Discovery13BiasedSelectionHandler`, pro que ti handler per definition historic voca li modulo selector ante rejection. Ti omission es intentional e necessari por respectar li ordine normativ del calls.

### Verification

Li witness real del Foundation continua monstrar `legacy=1` por li prim answer rejectend, durante que li route reparat rejecte un passu e retorna `N`. Un gril additiv de streams e families curt concorda con li reference normativ local. Null `wideDetour` o logic de Patch 14 es present.


## Stage 28 — Discovery 14

Li selector de Patch 13 es exact solmen por families curt `1<=N<=M_OLD`. Li scar nov `legacySelectionAssumingNLeM(stream,N)` ne have null dispatcher de largore: it presume que omni familie es curt e delega directmen a `patchedSmallPick`. Ti helper resta exact in su domini precedent, ma por `N>M_OLD` it rejecte li familie con un `RangeError`.

`LegacyShortFamilyAssumptionAdapter` e `Discovery14WideSelectionHandler` conserva ti failure quam state invocation-local pos li route real de Patch 12. Li handler ne inventa null representation wide, ne combina digits e ne calcula null space `M^places`; it registra solmen que li path curt esset assumet e que ti assumption fallit. Li witness real del Foundation con `N=M_OLD+1` falla in legacy durant que li reference test-only retorna rank `2`. `wideDetour` resta reservat exclusivmen por Stage 29 / Patch 14.

## Stage 29 — Patch 14

`legacySelectionAssumingNLeM` resta intact quam scar historic e su route de Discovery 14 continua fallir diagnosticmen por families plu grand quam `M_OLD`. `selectionDispatcherWithWideDetour` branchia explicitmen: `N<=M_OLD` usa li path curt ja reparat de Patch 13, e `N>M_OLD` entra in `wideDetour`.

Li detour wide deriva `space=M_OLD^places` con li minimal places suficient, lee chascun digit exactmen un vez ex li sam answer ring, e combina li numero wide con pesos little-endian. Pos li construction del digits, li loop de rejection ne voca plu `ringAnswerAt`; it move solmen li numero combinat per li direction del stream sur li ring `1..space`. `WideSelectionPatchWrapper` conserva li diagnostic legacy e li places, space, digits, limite, numero inicial, numero acceptat e passus de rejection in li context. Li regression de Discovery 14 es verd e null logic de Patch 15 es present.

## Stage 30 — Discovery 15

Li selection curt e wide de Stage 29 resta intact. Ti stage comensa li subsystem de gates con un scar historic mult plu simplic: `oldGateQuestionDay(n)` conosse solmen un magnitude non-negativ e calcula sempre `FOUNDATION_DAY_OLD+n`.

`LegacyGateQuestionAdapter` prende un `signedStep`, perde intentionalmen su signe per convertir it al magnitude e invia ti magnitude al helper legacy. `Discovery15NegativeGateQuestionHandler` registra li signed step original, li magnitude, li die questionat e li fact que un passu negativ finit al latere positiv. Li regression usa `-1`, `-2` e `-10`: li legacy demanda dies pos li Foundation, durante que li semantics normativ exige li dies ante li Foundation. Null correction de Patch 15 es present; li detour negativ resta reservat exclusivmen por Stage 31.


## Stage 31 — Patch 15

`oldGateQuestionDay(n)` resta intact quam scar historic e continua adjunter li magnitude al Foundation. `gateQuestionWithSignedStep(signedStep)` voca ti helper ante alcun correction, poy devia exclusivmen passus negativ a `FOUNDATION_DAY_OLD-abs(step)`. Por zero e passus positiv, li valore legacy es retornat sin alteration.

`NegativeGateQuestionPatchWrapper` succede al handler de Discovery 15, conserva li question legacy quam diagnostic, registra li magnitude e li decision de detour, e retorna li question-day semantic reparat. Li test confirma passus `-1`, `-2`, `-10`, `-101`, zero e positives, con contexts invocation-local separat. Null `LEGACY_YEAR_MAX=5781` o filtre de 5778 es addit in ti stage.


## Stage 32 — Discovery 16

Ti stage introduce li constant legacy obligatori `LEGACY_YEAR_MAX=5781` e usa it quam ceiling real de `legacyYearCandidateAllowed`. Li helper conserva li criteries historic: adminim six gate gaps e longore 252..5781. Li nov familie raw es materialisat per `legacyYearCandidatesBeforeSort`; solmen poy `legacyStableLengthOnlyYearCandidates` aplica un stable sort per longore solmen. Null tie-key secundari es present.

`LegacyYearCandidateAdapter` expone explicitmen li passage al selection existent, e `Discovery16LegacyYearCandidateHandler` es ligat pos `NegativeGateQuestionPatchWrapper`. In li boundary family 5778, 5779, 5780, 5781, omni quar passa li ceiling legacy e arriva al selection; li tri ultim viola li ceiling normativ 5778. Ti divergence es li unic failure intentional del stage. Li late filter `REAL_YEAR_MAX_PATCH=5778` resta reservat exclusivmen por Stage 33 / Patch 16.


## Stage 33 — Patch 16

`LEGACY_YEAR_MAX=5781` e `legacyYearCandidateAllowed` resta intact quam scar historic. `REAL_YEAR_MAX_PATCH=5778` es un ceiling separat. `yearCandidateAfterFootnotePatch` voca li helper legacy real e rejecte solmen pos ti call si `candidateLength>5778`. Li materialisation semantic usa `yearCandidatesAfterFootnotePatchBeforeSort`, e solmen pos ti filter `stableLengthOnlyPatchedYearCandidates` executa li stable sort per longore. `YearCandidateCeilingPatchWrapper` conserva li raw family legacy quam diagnostic, ma porta solmen li familie filtrat al selection. Li regression de Discovery 16 es nu verd. Equal-length ties resta in ordine stabil legacy; Patch 17 ne es anticipat.


## Stage 34 — Discovery 17

Li familie de Year 5000 usa li candidate set ja filtrat per Patch 16 e li stable sort historic per longore solmen. `Discovery17Year5000TieHandler` es insertet pos li wrapper 5778 e observa un witness de candidates con longore egal quel omnes contene li calculation-day. Li handler ne muta lor ordre e conserva li candidate ja selectet per li dispatcher existent.

Li witness usa tri candidates de longore 490 con opening gates in ordre tardiv, tempran, medial. Pro que li sort es stabil e ne have null secondary key, li ordre resta talmen e rank 1 selecte li opening tardiv. Li ordre normativ del tie deve esser tempran, medial, tardiv; ti comparison es li unic EXPECTED_RED nov. Null correction de Patch 17 es includet.


## Stage 35 — PATCH 17

### Scar historic conservat

`stableLengthOnlyPatchedYearCandidates` resta byte-per-byte intact quam li sort historic posterior al filter 5778. `Discovery17Year5000TieHandler` resta anc intact e continua exposir li ordre legacy tardiv-tempran-medial e li selection legacy quand li route de Discovery 17 es vocat directmen. Li patch ne retroedita null de ti strates.

### Circumition exact per runs

`sortEqualLengthRunsByOpeningGate(list)` prende un liste ja ordinar per longore. It trova un `start` e `end` por chascun run contigui de `candidateLength` egal. Solmen si li run contene plu quam un candidate, it copia ti slice, ordina li slice per `openGate` ascendent e scri li slice retro in li sam positions. Li helper ne executa `list.sort` sur li familie complet e ne combina `candidateLength` con `openGate` in un comparator global.

### Route monster e diagnostics

`Year5000TiePatchWrapper` es conectet pos `Discovery17Year5000TieHandler`. It conserva li familie stable-length legacy e li candidate legacy selectet quam diagnostics invocation-local, calcula li quantitá de equal-length runs, aplica li reorder local e usa li sam `LegacyYearCandidateAdapter.select` con li sam answer stream por selection semantic final. Li witness 490/490/490 deven tempran-medial-tardiv e rank 1 selecte li opening gate plu tempran.

### Pro quo li patch ne anticipa Stage 36

Null `oldJumpGuess`, null division per 365 e null transition de year successiv/precedent es addit. Ti scar apartene exclusivmen a Discovery 18. SourceLanguageCatalog, li ceiling 5778, li route de gate-sign e omni scars anterior resta intact.

## Stage 36 — Discovery 18

Li route de Year 5000 ja passa per li ceiling 5778 e li duesim tie passu de Patch 17. Ti stage adjunte li scar historic `oldJumpGuess(anchor,targetDay)`: it usa li difference `targetDay-anchor.firstDay`, fa floor division exact per `365` e adjunte li quotient al numer del anchor. Li helper resta intentionalmen un estimation de longore medie e ne conosse li intervalles real del annus.

`LegacyYearJumpAdapter` voca ti helper realmen. `Discovery18YearJumpHandler` prende li candidate selectet per Patch 17, forma un anchor de Year 5000 e conserva number, open day, first day, close day, target, delta e guess quam state invocation-local. In ti Discovery li defect es activ: li guess es usat directmen quam numer semantic del year, ne solmen quam telemetry.

Li witness usa tri candidates egal de longore 1000. Pos li tie repair, li anchor selectet have li opening plu tempran. Por `firstDay+365`, `closeDay` e `closeDay+1`, li guess legacy retorna respectivmen 5001, 5002 e 5002; li semantics per intervalles/year-walk exige 5000, 5000 e 5001. Ti comparison es li unic EXPECTED_RED del stage. Null `findYearByWalkPatch`, null `patchedNextYear`, null `patchedPreviousYear` e null code de Patch 19 es includet.


## Stage 37 — Patch 18

`oldJumpGuess(anchor,targetDay)` resta intact quam scar historic. Li route separat de Discovery 18 continua demonstrar que li quotient per 365 posse etiquettar un target intern de Year 5000 quam 5001 o 5002. Patch 18 ne netta, ne inlinea e ne substitue ti helper.

`patchedNextYear` e `patchedPreviousYear` es strates de un unic transition. Chascun valida li record de year, exige un cambio de numero exactmen +1 o -1 e confirma que li gate de limite es compartit exactmen inter li du annus. `findYearByWalkPatch` comensa sempre al anchor Year 5000, repeti next-year durant que `targetDay>closeDay`, repeti previous-year durant que `targetDay<=openDay`, e fini solmen quand `openDay<targetDay<=closeDay`.

`SequentialYearWalkPatchWrapper` es conectet pos `Discovery18YearJumpHandler`. Ergo `oldJumpGuess` es vocat realmen ante li walk, su output es conservat quam `patch18LegacyGuessDiagnostic`, e li wrapper marca explicitmen que ti guess es ignorat por semantics. Li resultate final veni solmen del year atinget per li caminada annual.

Li witness del stage conserva li divergence legacy 5001/5002/5002, ma li path reparat retorna 5000/5000/5001. Tests separat confirma zero-step intra li anchor, multi-step avante e retro, limites de gate, rejection de transitiones malformed e isolation de contexts. Null cache keyed per year number, null guards de Patch 19 e null `oldStructureSauce` es addit.


## Stage 38 — Discovery 19

Patch 18 resta li proprietario semantic del year resoluet. Discovery 19 adjunte un cache persistent al `BaseMonsterManager`: `LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER` es un `Map` quel usa exclusivmen `year.number` quam clave. `legacyYearNumberOnlyLookup` e `legacyYearNumberOnlyPut` forma li scar historic explicit; li lookup ne riceve calculation-day ni limites del interval.

`buildLegacyYearStructureValue` forma li value current ex li year resoluet e li calculation-day. `LegacyYearNumberCacheAdapter` consulta li map e `Discovery19YearNumberCacheHandler` usa li value current solmen sur un MISS. Sur un HIT, li value ja guardat es retornat directmen, mem si li request current have un altri calculation-day, opening day o closing day. Li context conserva li key, request current, value fresh, HIT/MISS e output stale quam state invocation-local; li Map sol es manager-owned e persiste inter invocations del sam manager.

Li regression crea tri managers separat por isolar tri defectes: changement solmen del calculation-day, changement solmen del opening gate e changement solmen del closing gate. Chascun duesim request conserva `year.number=5000` e recive un HIT, ma su output egala li value del prim request e diverge del value current. Ti tri divergenties es resumit in un unic assertion EXPECTED_RED final.

Null entry guardat con `calculationDayFingerprint/openGate/closeGate/value` es creat. Null helper de action-guard es present, e null `oldStructureSauce` o code de Patch 20 es anticipat. Li bad cache key resta intentionalmen activ til Stage 39 / Patch 19.


## Stage 39 — PATCH 19

Li cache manager-owned continua esser keyed exclusivmen per `year.number`; Patch 19 ne netta ti scar. `legacyYearNumberOnlyLookup` e `legacyYearNumberOnlyPut` resta fisicmen intact e li path reparat real-voca li lookup legacy ante omni decision de guard.

`calculationDayFingerprint(calculationDay)` retorna directmen li calculation-day exact. `cachePutWithGuard` conserva sub li sam year-number key un entry con exactmen `calculationDayFingerprint`, `openGate`, `closeGate` e `value`. `cacheGetWithActionGuard` accepta HIT solmen si omni tri guards concorda con li request current. Un entry absent, un value legacy sin forma guardat o qualcunc mismatch deven MISS.

`YearCacheActionGuardPatchWrapper` es conectet directmen pos `SequentialYearWalkPatchWrapper`. It ne consume li stale output del handler defectiv de Discovery 19; in vice, su call a `cacheGetWithActionGuard` conserva li bad lookup quam diagnostic e usa solmen un entry guardat valid. Sur MISS, li structura current es recalculat e `cachePutWithGuard` reemplazza li entry sub li sam key. Sur HIT valid, li cached semantic value es reutilisat.

Li regression conserva li route direct de Discovery 19 quam prova que li scar resta wrong, ma li route Patch 19 deven verd por tri changements independent: calculation-day, opening gate e closing gate. Un duesim request con guard mutat es MISS/recompute, e un triesim request identic deven HIT. Null `oldStructureSauce` o recomputation del structure sauce de Patch 20 es present.

## Stage 40 — Discovery 20

Patch 19 resta intact e resolve li year current con cache guards valid. Discovery 20 adjunte li scar historic `oldStructureSauce(cDay,originalTargetDay)`. `structureSauceCountsFromDays` deriva action, target, distance, connection e direction ex li du dies con li scars reparat anterior; `sauceWithCurrentScars` usa li table de stones del implementation e `sauceWithOrderAt46Latch`, ergo li sauce old es exact por li inputs quel it realmente riceve.

`LegacyStructureSauceAdapter` voca li helper historic. `Discovery20StructureSauceHandler` deriva separatim `yearFirstDay` ex li year ja resoluet, ma conserva intentionalmen li assumption wrong e passa `originalTargetDay` al helper. `LegacyStructureSelectorAdapter` consuma directmen ti resultate e rende observabil un token con bowl 2 e li latch de drop 46. Li route dunque demonstra li defect semantic sin inventar un sauce aproximativ o un shortcut.

Li regression usa tri targets originals distint intra Year 5000. Por omni witness, `oldStructureSauce(cDay,originalTargetDay)` concorda con li oracle por ti target original, ma li token resultant diverge del sauce quel deve esser calculat con `(cDay,year.firstDay)`. Li comparison final es li unic EXPECTED_RED nov. Null `structureSaucePatch`, null ghost de oldStructureSauce e null partition de Patch 21 es includet.

## Stage 41 — PATCH 20

`oldStructureSauce(cDay,originalTargetDay)` resta intact quam scar historic e continua esser executet realmen. `structureSaucePatch` voca ti helper prim e conserva su bowls e `orderAt46Latch` quam ghost diagnostic. Li helper old ne es reparat ni redirectionat: su duesim input resta exactmen li target original.

Pos li call ghost, `structureSaucePatch` materialisa un sauce semantic separat per `sauceWithCurrentScars(cDay,year.firstDay)`. `StructureSaucePatchWrapper` prende li `year.firstDay` del year resoluet per Patch 18, conserva li ghost in state invocation-local e passa al selector exclusivmen li object `semanticSauce`. Li route de Patch 20 ne executa `Discovery20StructureSauceHandler`, pro que ti handler resta li route defectiv separat quel envia li sauce old al selector legacy.

Li tri witnesses de Discovery 20 conserva lor bowls/latch legacy distint por li targets originals, ma li route reparat retorna por omni tri li sam token derivat de `(cDay,year.firstDay)`: bowl 2 `130140581193907225400293230678310495177` e order `6,2,4,3,5,1`. Un witness adicional con `originalTargetDay==year.firstDay` confirma que li valores del ghost e del sauce semantic coincide, ma li object semantic resta materialisat separatmen e li ghost ne es usat quam input del selector.

Omni regressions til Discovery 20 es nu verd. Null `legacyPositiveCompositions`, null `CutletPartitionPatchWrapper` e null code de Patch 21 es includet.

## Stage 42 — DISCOVERY 21

### Familie legacy all-positive

`legacyPositiveCompositions(gapCount,cutletCount)` es li scar historic nov. It conta exactmen omni composition positiv del gate-gap count e expone un `unrank1` lexicografic. Su contract ne conosse null calculation-day, gate intern, boundary obligatori o prefix condition. Li helper resta separat del reference test-only e usa solmen arithmetic JavaScript exact.

### Selection real pos Patch 20

`LegacyCutletPartitionAdapter` prende li sauce semantic de Patch 20, ne li ghost. Por li cutlet count it questiona bowl 2 con seal 20 e usa li dispatcher de selection curt/wide ja reparat. Poy it questiona li sam bowl con seal 21, calcula li count del familie all-positive e unranke li partition selectet. Talmen li scar de Discovery 21 vive in un route semantic real e ne in un fixture isolat.

`Discovery21CutletPartitionHandler` es conectet pos `StructureSaucePatchWrapper`. It prende li `openIndex` e `closeIndex` del year selectet, calcula `gapCount` e examina deterministicmen li indices strictmen intern por trovar si li calculation-day es exactmen un gate. Si un tal gate existe, su index e offset es guardat invocation-local; ma li adapter legacy ne riceve ti offset e ne filtra su familie.

### Witness EXPECTED_RED

Li witness selecte un year con indices 10..20, ergo 10 gate gaps, e li calculation-day coincide con gate 14: offset intern 4. Bowl 2 / seal 20 selecte 8 cutlets. Li familie legacy have 36 positive compositions; bowl 2 / seal 21 selecte rank 15 e produce `[1,1,1,3,1,1,1,1]`. Su prefix sums es 1,2,3,6,7,8,9,10 e manca 4.

Li expectation normativ test-only filtra exactmen li sam familie legacy per li boundary intern. It have 28 membres; con li sam answer ring, rank 3 produce `[1,1,1,1,1,1,3,1]`, quel have un prefix sum 4. Li unic failure intentional del stage compara ti du partitions.

### Limite del stage

Null `CutletPartitionPatchWrapper`, null familie filtrat production e null DP con state de boundary es includet. Patch 21 resta reservat por Stage 43 e deve conservar `legacyPositiveCompositions` quam scar fisic. Null generator de nomes repetit de Patch 22 es present.


## Stage 43 — PATCH 21

### Scar legacy conservat e executet

`legacyPositiveCompositions(gapCount,cutletCount)` resta sin modification e continua representar omni positive compositions in ordine lexicografic. `LegacyCutletPartitionAdapter.selectAllPositive` continua selecter un raw rank ex ti familie e `Discovery21CutletPartitionHandler.handle` continua calcular li internal gate diagnostic sin passar it al helper legacy. Li route de Patch 21 executa ti chain complet ante li wrapper reparativ.

### Familie semantic filtrat

`filteredCutletCompositions(gapCount,cutletCount,internalGateOffset)` usa un DP exact con `BigInt` por contar branches legal e por unrankar un rank one-based. Li iteration de parts resta ascendent exactmen quam in li legacy helper; branches es eliminat solmen si ili ne posse atinger exactmen li boundary intern. Ergo su serie es exactmen li subsequence filtrat del serie legacy, sin reordination.

### Wrapper e ownership

`CutletPartitionPatchWrapper` copia li family count, raw selected rank, raw partition, raw prefix sums e raw boundary result in diagnostics invocation-local. Ti values ne retorna al decision semantic. Si `internalGateOffset` es null, li wrapper passa exactmen li raw partition e su raw rank/family count. Si un gate intern existe, it questiona denov li sam bowl 2 / seal 21 stream contra li count del familie filtrat e unranka solmen in ti familie legal.

### Witness e regressions

Li witness 10 gaps / 8 cutlets / offset 4 continua producer raw diagnostic `36 / rank 15 / [1,1,1,3,1,1,1,1]`, con prefixes quel manca 4. Li familie semantic have 28 membres; li sam answer stream selecte rank 3 e produce `[1,1,1,1,1,1,3,1]`, con prefix 4. Un witness separat sin gate intern confirma li pass-through exact del raw legacy partition.

Omni regressions es verd. Null `legacyNameRowWithRepeats`, null partial-permutation correction e null `VirtualLegacyList` es addit; Patch 22 resta completmen absent.


## Stage 44 — DISCOVERY 22

### Generator legacy con repetition

`legacyNameRowWithRepeats(masterCount,itemCount)` interpreta li old familie de nomes quam omni rows de longore `itemCount` sur li master indices 1..`masterCount`. Li count exact es `masterCount^itemCount`. Li unrank es one-based e lexicografic, ma null statu memora indices ja usat; repetition es talmen possibil e intentional por ti discovery.

### Route real pos Patch 21

`LegacyRepeatedNameGenerator` prende li 17 `canonicalIndex` directmen ex li `SourceLanguageCatalog` congelat. It reconstrui un answer ring ex li structure sauce semantic ja reparat de Patch 20, questiona bowl 5 con seal 22, usa li dispatcher curt/wide existent, e unranka li row legacy. Textu de nomes ne participa in selection.

`Discovery22RepeatedNameHandler` exige un `PATCH_21_RESULT` complet e usa exactmen li cutlet count semantic. Li candidate legacy deven li resultate current del route Discovery 22 e es conservat invocation-local con family count, stream, rank e flag de repetition.

### Witness EXPECTED_RED

Con li witness selectet, li cutlet count es 6. Li familie legacy have `17^6 = 24137569` membres e bowl 5 / seal 22 selecte rank `7563989`. Li row old es `[6,6,10,10,17,9]`, quel repeti `canonicalIndex` 6 e 10. Li expectation normativ test-only usa six indices distinct e retorna `[3,11,4,9,12,5]`. Li final comparison es intentionalmen red.

### Limite del stage

Null `RepeatedNamePatchWrapper`, null `partialPermutationUnrank`, null falling-factorial helper production e null `VirtualLegacyList` es includet. Patch 22 deve esser implementat solmen in Stage 45, conservante ti generator legacy quam scar activ.


## Stage 45 — PATCH 22

### Scar repeated conservat

`legacyNameRowWithRepeats`, `LegacyRepeatedNameGenerator.select` e `Discovery22RepeatedNameHandler.handle` resta fisicmen e semanticmen li route historic de Discovery 22. Li route reparat executa ti generator ante li detour e conserva su candidate, count `17^K`, rank e repetition flag quam state invocation-local. Li defect old dunque ne es netta ni transformat in un helper mort.

### Familie distinct e unrank lexicografic

`fallingFactorialDistinct(n,k)` calcula exactmen `n*(n-1)*...*(n-k+1)` con `BigInt`. `partialPermutationUnrank(n,k,rank1)` tene un liste ascendent de indices restants; por chascun position it calcula li block-size del suffix per falling factorial e consume blocks in ordre. Talmen su ordre es exactmen li ordre lexicografic del partial permutations de `1..n` sin repetition.

### Detour semantic de Patch 22

`RepeatedNamePatchWrapper` exige un resultate complet de Discovery 22. It ne reexecuta li generator old: `bad` es li array ja materialisat per ti scar. Li wrapper reconstrui li sam answer ring del structure sauce semantic de Patch 20, bowl 5 / seal 22, selecte un rank contra li familie distinct e calcula `correct` per `partialPermutationUnrank`.

Li decision final conserva exactmen li regul mandat: si `bad` e `correct` es identic, li sam object `bad` passa; si ili difere, solmen `correct` deven semantic. Li raw candidate resta sempre diagnostic.

### Witness e limite historic

Li witness de Stage 44 resta observabil: familie old `24137569`, rank `7563989`, `bad=[6,6,10,10,17,9]`. Li detour distinct usa familie `8910720`, rank `1348551` e rende `[3,11,4,9,12,5]`, identic al reference test-only. Un audit exhaustiv de 28 pares `(n,k)` micri e 16064 membres confirma li ordre lexicografic exact del unrank distinct.

Omni regressions, li verifier, li test focal e li suite complet es verd. Null `VirtualLegacyList` de Patch 23, null `legacyChooseEachDaySeparately` de Patch 24 e null `oldContiguousMonthDayGuess` de Patch 25 es present.


## Stage 46 — DISCOVERY 23

### API legacy de "omni vias" concret

Li proxim scar tracta li familie de longores de mensus quam un liste complet materialisat. `legacyMaterializeMonthLengthWays(totalDays,monthCount)` enumera compositions in ordine lexicografic per longore ascendent; chascun part es 4..123 e li summa deve esser `totalDays`. Li return es un `Array` concret de arrays. `LegacyMonthLengthAllWaysAPI.allWays` expone ti comportament directmen e ne have null count/unrank virtual.

### Route real e sondage anti-OOM

`Discovery23MonthLengthMaterializationHandler` exige un `PATCH_22_RESULT`, ergo li generator repeated legacy e li detour distinct ja ha esset executet. Ex li year semantic it deriva li longore, calcula li interval legal de month counts, questiona bowl 3 / seal 30 e selecte li month count con li dispatcher curt/wide existent. Li answer ring por li selection posterior de longores es derivat ex bowl 3 / seal 31 e conservat diagnosticmen.

Executar `allWays` complet por li witness real vell esser destructiv. Por demonstrar li scar sin provocar OOM, li sam recursive enumerator es executet per `probeAllWays` con un cap diagnostic de 2048 rows. Ti sondage materialisa realmen arrays in li sam ordre e signala que li limite es superat; it ne conta li familie complet e ne decide null resultate semantic.

### Witness EXPECTED_RED

Li witness selecte un year de 1000 dies. Li limits de month count es 9..47 e bowl 3 / seal 30 selecte li octesim option, ergo 16 mensus. Li sondage old materialisa 2048 rows e signala que li enumeration continua. Li reference test-only usa su bounded-composition counter normativ e trova exactmen `5239332298078798668173613753510` membres legal.

Li regression nov exige un representation virtual scalabil e dunque falla contra li actual contract `ALL_WAYS_CONCRETE_ARRAY`. Omni tests precedent resta verd. Null `VirtualLegacyList`, null DP count production e null `itemAt1` lexicografic es includet; ili apartene solmen a Stage 47 — PATCH 23. Null code de Patch 24 es anticipat.


## Stage 47 — PATCH 23

### Scar concrete conservat

Stage 47 ne toca li corp de `legacyMaterializeMonthLengthWays`, ne li methods `allWays`/`probeAllWays` de `LegacyMonthLengthAllWaysAPI`, e ne li handler de Discovery 23. Li route patch traversa ti handler prim, materialisa li sample concrete capat e conserva contract, limite, sample-count e flag `exceededLimit` quam diagnostics invocation-local. Talmen li errore historic ne es retroeditat ni simulat post factum.

### VirtualLegacyList

`VirtualLegacyList(totalDays,monthCount)` representa exactmen li sam bounded compositions: chascun component es 4..123, li summa es `totalDays`, e li órdine es lexicografic ascendent. Li constructor construi un table de counts per quantitá de slots e subtotal. Un fenestre glissant adjunte li contribution entrant a distanza 4 e subtrae li contribution quittant pos 123, sempre con `BigInt` exact.

`count()` lee li cell final del DP. `itemAt1(rank1)` es 1-based: por chascun position it prova 4,5,...,123; li count DP del suffix define li grandore del bloc current. Si li rank passa li bloc, it es decrementat; altrimen li candidat current es fixat. Ti mechanism ne genera li membres precedent e ne materialisa li familie.

### Detour semantic

`MonthLengthVirtualPatchWrapper` veni solmen pos `Discovery23MonthLengthMaterializationHandler`. It prende li year length, month count e bowl 3 / seal 31 answer ring ja conservat, crea un `VirtualLegacyList`, questiona li dispatcher selection contra `count()` e usa `itemAt1` por li row selectet. Li façade semantic expone `VIRTUAL_EXACT_COUNT_LEXICOGRAPHIC_UNRANK`; li façade old `ALL_WAYS_CONCRETE_ARRAY` resta in li diagnostic legacy.

Li witness 1000/16 have `5239332298078798668173613753510` membres. Rank `1892970349028658514214546085756` rende `[46,62,31,19,31,123,10,47,108,96,7,97,113,29,74,107]`, egal al reference normativ JavaScript del sam linea. Un audit separat compara 43 families micri e 1999 rows exactmen contra li materializer old e confirma identitá del órdine.

### Limite historic

Patch 24 ne es anticipat. `legacyChooseEachDaySeparately`, `DPUnrankLegalWeaving` e un wrapper de month weaving ne existe. `oldContiguousMonthDayGuess` de Patch 25 resta anc absent. `SourceLanguageCatalog` resta congelat e production ne importa li reference test-only.


## Stage 48 — DISCOVERY 24

### Chooser historic die-per-die

`legacyChooseEachDaySeparately(lengths,answerStream)` conserva li algorithm old exact: chascun die prende un answer del ring, reduce it modulo li quantitá de mensus e prova ti monthId. Si li monthId ja ne have occurrence restant, `wrapMonth` avansa circularmen til un monthId ancor disponibil. Li helper ne conosse null count de intertexes, rank global, first-occurrence constraint o last-occurrence constraint.

### Sauce e route real

`monthWeavingAnswerRingFromSauce` construi li ring ex bowl 4 / seal 32 del structure sauce semantic reparat de Patch 20. `LegacyMonthWeavingAdapter` executa li helper old, e `Discovery24MonthWeavingHandler` veni pos li chain complet til `MonthLengthVirtualPatchWrapper`. Li longores de Patch 23 es usat quam multiplicities exact, e li ghost old deven li resultate current del Discovery. Ti es intentional: un Discovery deve revelar li defect ante que li patch posterior existe.

### Witness EXPECTED_RED

Por `[4,4,4]`, li familie legal test-only have 1301 membres. Un witness del structure sauce selecte rank 216; li intertexe legal esperat es `[1,1,2,1,3,3,1,2,2,2,3,3]`. Li old chooser produce `[3,1,2,3,1,2,3,1,2,3,1,2]`. Chascun monthId appare exactmen quatre vezes, ma month 3 appare ante month 1, ergo li ordre del unesim occurrences es illegal. Du witnesses sauce adicional confirma li sam classe de divergence.

### Limite historic

Null `wantedRank`, null `DPUnrankLegalWeaving` e null `MonthWeavingPatchWrapper` es present. `oldContiguousMonthDayGuess` de Patch 25 es anc absent. Stage 48 resta EXPECTED_RED exclusivmen pro ti scar; li proxim stage mandat es Stage 49 — PATCH 24.

## Stage 49 — PATCH 24

### Li chooser old resta activ

Patch 24 ne altera `legacyChooseEachDaySeparately`, `LegacyMonthWeavingAdapter.selectEachDay` ni `Discovery24MonthWeavingHandler.handle`. Li route reparat traversa prim Discovery 24, ergo li word die-per-die old es calculat realmen con bowl 4 / seal 32 e resta in state quam ghost. Li patch ne usa ti ghost por determinar un rank ni por modificar li familie legal.

### Familie legal complet sin vector-state explosion

`LegalMonthWeavingDP` representa exactmen li familie normativ de words con multiplicities fix e du constraints: unesim occurrences de monthIds in órdine ascendent, e ultim occurrences anc in órdine ascendent. Por evitar un memo gigant de omni vectores de remaining counts, li backend decomposi li count exact in du partes: intertexes del labels ja apert con ultim-occurrence order, e un table DP del labels futur quel depende del quantitá de simbols pos li unesim occurrence del maxim label apert. Omni combinatorica es exact in `BigInt`.

Durant `unrank1`, li moves legal es provat in monthId ascendent. Por chascun move, li backend calcula exactmen li count del suffix e subtrae solmen blocs complet. Talmen li rank 1-based conserva exactmen li ordre lexicografic del familie normativ.

### wantedRank e detour semantic

`compatibleMonthWeavingRank` manda li sam answer ring de bowl 4 / seal 32 al dispatcher curt/wide ja reparat. Li resultate es `patch24WantedRank`. `DPUnrankLegalWeaving` usa ti rank por calcular `correct`. `MonthWeavingPatchWrapper` conserva separatim ghost, count, wanted rank e correct; si ghost e correct es identic element-per-element, it retorna li sam object ghost, altrimen it retorna li correct.

Li witness `[4,4,4]` conserva li old ghost `[3,1,2,3,1,2,3,1,2,3,1,2]`, ma li familie legal have 1301 membres, rank 216 e correct `[1,1,2,1,3,3,1,2,2,2,3,3]`. Li suite torna verd. Un audit test-only del sam linea JavaScript compara 10 families micri e 1332 membres contra li reference normativ local. Li route real con li 16 longores de Patch 23 have un count legal de 1064 cifras e usa li wide path sin materialisar li familie.

### Limite historic

Patch 25 ne es anticipat. `oldContiguousMonthDayGuess` e `ContiguousMonthDayPatchWrapper` resta absent, e null logic de month-in-day contigui es introductet.


## Stage 50 — DISCOVERY 25

### Li mensu esset tractat quam un bloc contigui

Pos Patch 24 li implementation ja have un intertexe legal complet. Li proxim assumption historic calcula tamen li die intra mensu quam si omni occurrences del monthId formasse un segment contigui. `oldContiguousMonthDayGuess(weaving,targetPosition)` prende li monthId al target, trova su unesim occurrence e retorna `targetPosition-firstPosition+1`. Null occurrence-count es usat.

### Route real pos Patch 24

`LegacyContiguousMonthDayAdapter` conserva un call direct al helper old. `Discovery25ContiguousMonthDayHandler` exige li state `PATCH_24_RESULT`, prende exactmen `patch24SemanticMonthWeaving` e deriva li position del target per `targetDay-year.openDay`. Li helper old es executet realmen e su guess es guardat quam diagnostic e quam current semantic day-in-month de ti Discovery.

In li witness del route real, target position 92 have monthId 9. Li unesim occurrence de month 9 es position 15, ergo li formule old retorna 78. Ma solmen 14 occurrences de month 9 existe in li prefix del year til position 92 inclusiv. Li regression nov compara ti du valores e resta intentionalmen red.

### Limite historic

Null helper de occurrence count e null wrapper reparativ es present. In particular, `countMonthOccurrencesThroughTarget` e `MonthDayOccurrencePatchWrapper` ne existe. Patch 26 concernent li opening gate ne es anticipat. Li proxim stage mandat es Stage 51 — PATCH 25.


## Stage 51 — PATCH 25

### Li guess contigui resta un scar real

`oldContiguousMonthDayGuess`, `LegacyContiguousMonthDayAdapter.guess` e `Discovery25ContiguousMonthDayHandler.handle` ne es modificat. Li route de Patch 25 traversa Discovery 25 prim, ergo li distance historic desde li unesim occurrence es calculat realmen e conserva su valore diagnostic ante li overwrite semantic.

### Occurrence count inclusiv

`countMonthOccurrencesThroughTarget(weaving,targetPosition)` prende li monthId al target e examina exclusivmen li prefix positions 1..targetPosition. It incrementa li count solmen quand li item current have li sam monthId. Li target self es ergo includet exactmen un vez. Null assumption de contiguitá resta in ti calcul.

`MonthDayOccurrencePatchWrapper` exige un `DISCOVERY_25_LEGACY_RESULT`, conserva li guess old e su diagnostics, calcula li occurrence count e superscri sempre `legacyMonthDaySemantic` e `patch25SemanticMonthDay` per li count. In un case contigui old e correct posse esser egal; in un case intertexet li resultate correct prende sempre precedence.

### Witness e limite historic

Li route real conserva target position 92, monthId 9, first position 15 e guess old 78. Li prefix inclusiv contene 14 occurrences de monthId 9, ergo li semantic day-in-month deven 14. Omni regressions e li suite complet torna verd. Null code de Patch 26 — ni un correction del ownership del opening gate — es anticipat.


## Stage 52 — DISCOVERY 26

### Li opening gate esset atribuit al year quel comensa ta

Li ultim assumption historic usa un interval annual cludet a ambi lateres. `legacyFindYearClosedOpeningInterval` camina avante si li target es pos `closeDay`, ma camina retro solmen si li target es strictmen ante `openDay`. Quande li target es exactmen `openDay`, null transition retro ocurre e li current year es acceptet. Ti es exactmen li scar `[open,close]`.

### Route real pos Patch 25

`LegacyOpeningGateIntervalAdapter` voca li finder old directmen. `Discovery26OpeningGateIntervalHandler` exige `PATCH_25_RESULT` e conserva li year authoritative ja resoluet per Patch 18. Si li target es li closing gate de ti year, li sam die es anc li opening gate del adjacent year; li layer historic trata ti adjacent year quam ownership anchor e executa li interval legacy sur it. Talmen li defect es executet pos omni 25 patches precedent e resta separat del caminada sequential ja reparat in Patch 18.

In li witness real, Year 5000 fini al die `-15054661`. Li adjacent Year 5001 comensa exactmen al sam gate. Li finder old usa `targetDay < openDay`, fa 0 passus retro e retorna Year 5001, durante que li interval normativ `(open,close]` atribui ti gate a Year 5000. Li regression nov resta intentionalmen red.

### Limite historic

Null `OpeningGateIntervalPatchWrapper`, null `correctOpeningGateInterval` e null detour reparativ de Patch 26 es present. Li `<=` semantic existe ja in li caminada authoritative de Patch 18 ma ne es copiat in ti nov layer legacy. Li proxim stage mandat es Stage 53 — PATCH 26.


## Stage 53 — PATCH 26

### Li interval cludet old resta un scar real

Patch 26 ne modifica `legacyFindYearClosedOpeningInterval`, ne `LegacyOpeningGateIntervalAdapter.call`, ne `Discovery26OpeningGateIntervalHandler.handle`. Li route reparat executa Discovery 26 prim. Ergo li opening-year adjacent es ancor usat quam ownership anchor al shared gate, li condition strict `targetDay<openDay` lassa li year errat in loco, e ti resultate resta observabil quam diagnostic.

### Detour authoritative `(open,close]`

`correctOpeningGateInterval` usa li sam contract de year-walk e conserva li branch avante `targetDay>closeDay`. Li unic mutation semantic mandat es in li branch retro: tant que `targetDay<=current.openDay`, it passa al year precedent. Li validation final es exactmen `current.openDay<targetDay && targetDay<=current.closeDay`.

`OpeningGateIntervalPatchWrapper` exige li state de Discovery 26, conserva li year legacy e su numero semantic raw, poy executa li detour ex li sam ownership anchor. Li context registra separatmen li trace reparat, li count de passus, li flag de equality moved backward e li year semantic final.

### Witness e verification

Al shared gate `-15054661`, Discovery 26 conserva Year 5001 e zero backward steps. Patch 26 fa exactmen un passu retro e rende Year 5000. Witnesses local adicional con annus positiv e negativ confirma que equality al opening gate sempre move retro, durante que dies strictmen intra li interval e li closing gate resta in li year current.

`test:previous`, li verifier, `test:patch-26` e li suite complet es verd. Li verifier passa 74 gruppes / 66832 assertions. Null integration de Stage 54 es anticipat; `calendarDateSpaghetti` resta explicitmen ne integrat.


## Stage 54 — INTEGRATION

### Un unic route authoritative

Pos Patch 26, `calendarDateSpaghetti(calculationDay,targetDay)` ne es plu un stub. `Stage54MonsterIntegrationManager` extende li manager historic e orchestra li invocation per un state-machine explicit `programCounter/switch/loop`. Li context conserva mode, subfase, retry budget, recovery depth, flags compatibility, answer streams, gates tocat, Year 5000, current year, structure, snapshots transactional, cache events, diagnostics e li resultate de quin fields.

### Sauce con omni scars

`sauceWithScars` usa un duesim state-machine explicit. It deriva li counts con li patches de remainder/day-tag/distance, passa li stones travers li builder legacy e su overwrite reparat, conserva hidden storage retrograd e prior translation, e invoca li sauce historic quel executa 46 drops. In chascun drop li permutation 0/1-based, aliases de pours e shadow bowl commits resta activ; li memorie order legacy continua esser superscrit, ma `orderAt46Latch` es scrit un sol vez al drop 46 e resta authority durant 12 post-stirs. Li queries usa li successor positional del latch, durante que `oldNextBowlFixedName` resta diagnostic.

### Gates, years e cache

`Stage54GateRegistry` conserva gates in un registry deterministic indexat per BigInt. Chascun gap usa li question signat de Patch 15, bowl 1 / seal 1 e li dispatcher curt/wide. Year 5000 construi li familie legacy con 5781, filtra 5779..5781 ante li selection, reordena ties egal per opening gate e selecte per bowl 1 / seal 10. Years adjacent usa seals 11/12. `oldJumpGuess` es calculat ma ignorat; `findYearByWalkPatch` camina secuentialmen. Li ultim scar `[open,close]` es anc executet, poy `correctOpeningGateInterval` valida `(open,close]`.

Li structure-cache conserva li bad key `year.number`: `cacheGetWithActionGuard` voca li lookup legacy real, ma un HIT deven semantic solmen si calculation-day fingerprint, opening gate e closing gate concorda.

### Structure e final five

Li build de structure executa `structureSaucePatch` por conservar `oldStructureSauce(cDay,targetOriginal)` quam ghost e compara su sauce semantic con `sauceWithScars(cDay,year.firstDay)`. Li cutlet partition executa li familie positive legacy e usa exactmen li subsequence filtrat si calculationDay es un gate intern. Nomes de cutlettes conserva li candidate repeated legacy e passa al partial permutation distinct.

Por mensus, li API concrete legacy es executet quam probe limitat, durante que `VirtualLegacyList` furni count/itemAt1 exact. `legacyChooseEachDaySeparately` produce anc li ghost weaving real ante `LegalMonthWeavingDP` e `DPUnrankLegalWeaving`. Nomes de mensus usa bowl 5 / seal 33 con li sam pattern repeated-candidate versus partial permutation distinct. Al resolver final `oldContiguousMonthDayGuess` es calculat diagnosticmen e li day-in-month semantic es li occurrence count del monthId in li prefix inclusiv til target.

Li return es exactmen `[year, cutletName, dayInCutlet, monthName, dayInMonth]`. Li Foundation witness del integration rende `[5000, scorpion, 503, pute, 56]`; un duesim call warm rende li sam resultate per li guarded cache. Null oracle test-only es importat o vocat per production.

### Porta ante Stage 55

`npm run test:previous`, `node tests/verify-stage-01.js`, `npm run test:integration-54` e `npm test` es GREEN. Li verifier reporta 75 gruppes / 66842 assertions. Stage 55 resta reservat por un audit independent; production ne es declarat final-auditat in ti stage.

## Stage 55 — AUDIT final independent

Stage 55 ne adjunte null correction e ne muta `src/`. It audita independentmen li route integrat de Stage 54 contra li reference normative JavaScript test-only del sam linea. Por li differential pesant, un backend fast de bounded compositions e legal month weaving es usat solmen in tests e es validat prim contra li reference recursive sur families micri.

Li audit core confirma exact arithmetic, SAVE/modulo, day tags e distance, permutation, short/rejection/wide selection, sauce e `orderAt46Latch`, answer streams, gate symmetry non-forcet, year ceiling 5778, sequential year walk, membership `(open,close]`, cutlet filtering, partial permutations distinct, `VirtualLegacyList`, `LegalMonthWeavingDP`, occurrence-count day-in-month, catalog freezing, 26 scars + 26 patches, oracle isolation, cache guards, deterministic retry/exhaustion, du instances, registry insertion order e semantic ownership.

Li audit differential end-to-end concorda por Foundation, ante Foundation, pos Foundation e trans Foundation. Li Foundation rende `[5000, scorpion, 503, pute, 56]`; li crossing audit rende `[5000, Akkad, 1, pute, 15]`. Null mismatch es trovat.

Production resta byte-for-byte identic a Stage 54. In li runner de construction li audit differential es executet in du processes separat: base Foundation/lateres e crossing trans Foundation. Li completation es declarat solmen pos que omni regressions precedent, li verifier, li audit core e ambi processes differential es GREEN. `SPAGHETTI_MONSTER_IMPLEMENTATION_COMPLETE=YES`.

## Stage 56 — corrective post-completion: raw bowl sum in post-stirs

Stage 56 ne rescri li completion historic de Stage 55. It circumva un divergence provat in li 12 post-stirs pos drop 46. Li scar `postStirOneForOrderMemoryDiscovery` resta intact: it calcula `savedStirSum=SAVE(rawSum+149*stir)`, usa ti valore por li permutation e anc, incorrectmen, adjunte it in `u`.

Li detour nov `stage56RawBowlSumPostStirDetour` es vocat solmen pos que li scar old ha esset executet realmen sur li sam snapshot. It recalcula `rawBowlSum=sum(oldBowls)`, conserva `savedOrderNumber=SAVE(rawBowlSum+149*stir)` quam unic fonte del permutation, verifica que order number e permutation es identic al scar, e usa `rawBowlSum` — ne li saved order number — quam operand in `u`. Omni six bowls es calculat ex li sam `old` e commitet junt.

`sauceWithStage56RawBowlSumDetour` conserva li sauce Stage 55 complet quam ghost e recomputa li 12 post-stirs. `sauceWithScarsStage56` es li provider authoritative por `Stage56MonsterIntegrationManager`. Li aliases `calendarDateSpaghettiStage55Historical*` conserva li route historic; `calendarDateSpaghetti*` usa li corrective Stage 56.

Li state invocation-local del corrective registra old result, corrected result, raw bowl sum, saved order number, stir index, applied count, applied flag, legacy-scar call count e un history de 12 rows. Null oracle test-only es importat in production.

Li evidence local confirma omni 12 stirs contra `tests/stage-56-reference.js`, six bowls final e drop-46 order por Foundation e `c=t=-15048173`, e li quatre tuples canonical extern del corrective specification. Li reference SHA `d5cfe77ef7950a9a67ff0e6814833a3eedacae8a` ne esset disponibil directmen in li repository public durant ti session; ergo li formulas e bowls esset reconstructet independentmen e null code esset copiat ex ti commit.


## Stage 57 — corrective post-completion: Patch 26 round-trip ghost

Un testbench differential multi-million trovat un failure nov al global index 6859: `c=-15048553, t=-15044872`. Stage 56 jetta li guard `Patch 26 final diverge del year resoluet per li sequential walk.`, durante que li reference retorna `(5000,14,547,7,72)` per indices canonic.

Li membership ne es errat in Patch 18: `findYearByWalkPatch` ja usa `targetDay<=openDay` por caminar retro e fini in `(open,close]`. Li failure veni del diagnostic de Patch 26 al closing gate. Ti diagnostic reancra al year sequent por far visibil li old `[open,close]` scar, poy prova caminar retro. In production, adjacent-year selection ne es invertibil: li round-trip retorna year-number 5000 con open gate 9, durante que Patch 18 ja have li authoritative Year 5000 con open gate 10.

Stage 57 ne modifica null helper historic. `legacyStage54Patch26RoundTripGuard` conserva e executa li old guard; `legacyFindYearClosedOpeningInterval` e `correctOpeningGateInterval` resta intact. `stage57PreserveSequentialYearAfterPatch26Ghost` conserva li round-trip quam ghost e, solmen in `Stage57MonsterIntegrationManager`, reten li year Patch 18 quam semantic. Li old Stage 56 route resta accessibil per `calendarDateSpaghettiStage56Historical*` e continua faller sur li witness exact.

Li public Stage 57 rende `[5000, rise, 547, tri partes de quin, 72]`, egal a canonical `(5000,14,547,7,72)`. Li Stage 55 certificate e li Stage 56 corrective ne es rescrit.


## Stage 58 — remembered acceleration scars

Stage 58 ne netta li monster. Li public package-version ne es incrementat: it resta `0.0.57-stage-57-corrective`, quam un compatibility scar intentional. It adjunte un nov strata de memoria supra li archaeology existent: bounded gate/gap checkpoints, direction-tagged year anchors, weak sauce memories separat por Stage 54/56, exact selection/rejection memo, weak reuse de `VirtualLegacyList` e `LegalMonthWeavingDP` backends, un fast weaving traversal sibling, e un semantic structure cache keyed per full fingerprint supra li intentionally bad `year.number` cache.

Li old routes resta fisicmen activ. `sauceWithOrderAt46Latch`, `selectionDispatcherWithWideDetour`, `LegalMonthWeavingDP.unrank1`, li sequential gate registry, `findYearByWalkPatch`, Patch 19, Stage 56 historic e li Patch 26 round-trip ghost de Stage 57 ne es eliminat. Quand Stage 58 evita heavyweight work, diagnostics marca li route quam remembered/cache-backed invez de pretender que li calcul esset refat.

Li memories pesant es weak e bounded per key slots; gate/year/selection/structure memories have caps explicit. Sur Node v22.16.0 li cold Stage 57 witness cade de 20371.367 ms a 15732.753 ms, neighbor-year retro de 7994.777 ms a 5664.486 ms, far-retro fresh de 28517.259 ms a 22675.463 ms, e identical repeat de 4.205 ms a 0.705 ms. Stage 54/56 historic cold anc deven plu rapid sin cambiar lor canonical outputs. Omni 10 benchmark comparisons es canonical-identic.

Li detailed evidence, cache counters, memory tradeoffs e intentional bottlenecks resta in `STAGE_58_ACCELERATION_REPORT.md` e `artifacts/STAGE_58_*`. `tests/stage-58-acceleration.js` verifica historical/replay sauce equivalence, generation separation, rejection reuse, DP backend reuse, 1301 exhaustive weaving ranks, shared gate checkpoints e direction-safe year anchors. Li branch GitHub Actions workflow execut ti test in su propri `acceleration-58` shard, e li final GREEN gate depende de it.
