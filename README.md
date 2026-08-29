# Calendare Pastafarian — JavaScript + Interlingue / Occidental

Ti directoria es un linea de implementation completmen independent. It ha esset creat de zero por li pare `JavaScript` + `Interlingue / Occidental`, solmen ex li specification normativ includet in li task. Null code, test, fixture, output, table generat, cache, log, hash o checksum de un altri implementation ha esset usat.

## Statu actual

Li linea es in **Stage 46 de 55: DISCOVERY 23** e li repository local es intentionalmen `EXPECTED_RED`. Omni regressions til Patch 22 resta verd; li unic divergence nov es que li API historic de month-lengths ancor expone un liste concret de "omni vias".

`legacyMaterializeMonthLengthWays` e `LegacyMonthLengthAllWaysAPI` conserva ti contract concret. `Discovery23MonthLengthMaterializationHandler` veni pos li route complet de Patch 22, selecte li month count per bowl 3 / seal 30 e executa li enumerator old sur li request semantic quam un sondage capat. Por li witness de year length 1000 e 16 mensus, li sondage atinge 2048 rows e ancor have plu; li reference test-only demonstra un familie exact de `5239332298078798668173613753510` membres. Null `VirtualLegacyList` o code de Patch 23 es present. Li function final `calendarDateSpaghetti` resta intentionalmen ne implementat.

## Lingue-fonte canonic

`src/source-language-catalog.js` contene un unic `SourceLanguageCatalog` congelat. Li 17 nomes de cutlettes e li 47 nomes de mensus have indices canonic 1..17 e 1..47. Li órdine semantic usa exclusivmen `canonicalIndex`; textu, collation, Unicode e locales ne participa in selection, rank, unrank o cache semantic.

Nomes con signification lexical es traductet secun lor signification. Nomes de locs con form international stabil usa lor form international in Interlingue. Nomes inventet sin signification ne recive un signification artificial.

### Regul deterministic de transliteration

Por formes hebreic vocalisat, signes de vocalisation es resoluet in vocales `a e i o u`; consonantes es transliterat in lettres latines secun un table fonetic stabil, e marcas cantillatori ne es conservat. Por un form non-vocalisat u li scritura ne determina unicmen li pronunciation, li resultate es un entry explicit e congelat in li catalog; un tal entry ne posse esser recalculat per locale o collation. Por li du formes inventet del specification, li outputs congelat de Bootstrap es `Palgursh` e `Karshumb`. Ti decision es solmen presentation; lor `canonicalIndex` resta li unic identitá semantic.

## Exactitá numeric

Omni calcul normativ e historic numeric usa `BigInt`. Null floating-point es usat por SAVE, tags, distance o mutation de stones. `M = 2^127 - 1` es representat exactmen.

## Tests

Omni regressions til Patch 22 deve restar verd:

```text
npm run test:previous
```

Li verifier deve esser verd:

```text
node tests/verify-stage-01.js
```

Li regression focal de Discovery 23 deve esser intentionalmen red:

```text
npm run test:discovery-23
```

Li suite complet deve esser `EXPECTED_RED` exclusivmen in Discovery 23:

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
