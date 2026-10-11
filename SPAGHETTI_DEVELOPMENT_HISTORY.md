# Istwa devlopman monstr espageti a

## Stage 1 — Bootstrap

### Ki sa nou te konstwi

Liy sa a te kòmanse nan yon pyebwa vid pou Lua ak Kreyòl ayisyen. Nou te mete yon BigInt an Lua pou tout kalkil ki ka depase limit antye natif la. Nou te rekonstrui oracle normatif la nan Lua apati referans ki te bay nan enstriksyon yo, epi nou te kreye fixture lokal yo ak oracle sa a sèlman.

Nou te mete yon `SourceLanguageCatalog` ki kenbe 17 non kotlèt ak 47 non mwa. `canonicalIndex` se sèl lòd ki gen valè normatif. Katalòg la pa ekspoze tablo entèn yo pou modifikasyon, epi modil la refize nouvo chan dirèk.

### Kouch monstr ki parèt nan etap sa a

Nou te mete sèlman enfrastrikti jeneral ki otorize nan Bootstrap la: yon `MonsterContext` pou yon sèl invocation, yon `MonsterManager`, yon dispatcher debaz, yon validatè debaz, yon anvlòp erè ak yon koki metrik. Eta semantik la sèvi ak yon ti pwotokòl `begin -> validate -> commit` ak rollback. Pa gen okenn chemen legacy, flag patch, cache istorik oswa ghost computation nan Stage 1.

### Poukisa kouch sa a pa chanje semantik

Koki production Stage 1 la pa kalkile dat kalandriye a ankò. Enfrastrikti a sèlman valide kalite jou yo, kenbe eta lokal pou yon sèl invocation epi pwouve ke eta annatant pa koule. Oracle tès la separe fizikman nan `test/` epi production pa enpòte li.

### Sa nou poko fè

Nou pa ekri davans okenn nan 26 defo legacy yo. Nou pa ekri okenn patch ki pou Stage 2 oswa apre. Premye defo istorik la dwe antre sèlman lè Stage 2 rive.

### Verifikasyon korektif pou baz Stage 1

Yon enspeksyon endepandan te jwenn ke tès fòm lang lan t ap chèche yon fichye HANDOFF ki pa fè pati pyebwa GitHub la; fichye livrezon sa yo rezève pou itilizatè a. Tès la kounye a egzamine sèlman dokiman ki nan depo a. Anplis, konvèsyon antye Lua ki pi piti a, gwo miltiplikatè yo, ak retou nan antye Lua jwenn tès limit egzak. Tout 17 non kotlèt yo ak 47 non mwa yo rete idantik nan endis yo ak nan chèn yo. Nou te verifye SHA-256 fichye orijinal la ak kadna a, apre sa nou te ajoute yon tablo pwoteksyon pou anpeche ranplasman metòd ki deja egziste, san manyen okenn non. Nou te renouvle SHA-256 pou fichye ki pwoteje a epi nou te ajoute tès kont chanjman API yo. Kopi eta semantik yo kounye a posede sou-tab yo tou, konsa yon referans kandida pa ka modifye tranzaksyon an apre kòmansman li. Koreksyon sa yo pa entwodui okenn defo istorik ni okenn patch Stage 2.

## Stage 2 — DISCOVERY 01: `oldRemainder`

### Sa nou te kwè

Premye chemen SAVE la sipoze ke yon rès modulo òdinè ak modil `M` toujou bay menm valè ak operasyon SAVE normatif la. Sipozisyon istorik sa a antre nan `oldRemainder(x) = BigInt.mod(x, M)` epi li konekte ak dispatcher pwodiksyon an atravè `saveSpaghetti`; `legacySaveProbe` toujou bay dyagnostik legacy a.

### Sa nou dekouvri

Pou `M`, `2M` ak `3M`, rès òdinè a se `0`, men SAVE normatif la se `M`. Pou `M+1`, de chemen yo bay `1`. Nou verifye tou limit `0` ak `-M`, kote diferans lan parèt ankò. Se pa yon pwoblèm prezantasyon oswa presizyon: de algoritm yo aplike de entèval rezilta diferan, `[0, M-1]` kont `[1, M]`.

### Kouch monstè a ki grandi

Yon handler `LEGACY_SAVE` antre nan dispatcher pwodiksyon an. Li kenbe input ak output kòm chèn desimal egzak pandan tranzaksyon an, valide eta annatant, komèt rezilta a, anrejistre metrik ak dyagnostik epi retounen yon BigInt. Chak apèl gen pwòp kontèks li. Tout estrikti sa yo prezève rezilta legacy ki mal la; yo pa kache diferans lan ak oracle la.

### Sa ki rete pou Stage 3

Pa gen `savePatch`, pa gen chanjman pou ranplase zewo ak `M`, pa gen koreksyon silencieux. Tès ekivalans lan dwe rete wouj jouk PATCH 01. Nou kenbe ansyen chemen an pou istwa a.

### Verifikasyon apwofondi ki rete nan Discovery 01

Yon odit API te jwenn yon dezyèm valè ki t ap soti nan `saveSpaghetti` pa aksidan, paske yon `return` Lua te remèt tout valè `LegacySave.execute` yo. Nou mete rezilta a nan yon varyab lokal anvan `return`: sa kenbe yon sèl rezilta piblik san li pa chanje `oldRemainder`, chemen dispatcher la, oswa tras dyagnostik `legacySaveProbe` a.

Nou teste 125 antre ant -12M ak 12M ak deplasman -2, -1, 0, 1, 2; sis lòt antre depase 256 bit. Nou teste izolasyon state, refi antre ki pa antye, ak kantite valè ki soti nan API a. Yon tès odit apa kouri regresyon wouj la anba `pcall` epi li aksepte **sèlman** twa diferans nonmen yo. Apre li pase, regresyon endepandan an kontinye echwe fè espre. Sa bay yon prèv ke wouj la se defo ki nan istwa a, pa yon aksidan enfrastrikti.

Pa gen okenn koreksyon SAVE, okenn import oracle nan production, ni okenn chanjman non kanonik. Premye koreksyon normatif la rete rezève pou Stage 3.

### Odit pwopriyete repwodiktib la

Nan menm etap Discovery 01 la, nou ogmante sijè tès yo pou kouvri 575 antre egzak. Nou teste idantite `x=qM+r` ak `0<=r<M`, nonmodifikasyon rès la lè nou ajoute oswa retire yon miltip `M`, ak izolasyon chak tranzaksyon. Nan mayaj sou miltip `M` yo, se 65 ka rès zewo ki bay diferans atann ant rès òdinè ak SAVE. Nou mete yon tès limit istorik ki refize kode patch 01 nan production. Sa pa chanje algoritim nan, tras la, ni defo a; tès ekivalans lan rete wouj entansyonèlman.

## Stage 3 — PATCH 01: kouch ki repare `SAVE`

### Sa nou te bezwen korije

Discovery 01 te pwouve ke modulo òdinè a bay zewo lè antre a se yon miltip egzak de `M`, pandan `SAVE` normatif la dwe bay `M`. Li pa nesesè pou ranplase algoritm BigInt la ni pou chanje nenpòt lòt rès.

### Kijan nou korije li san nou pa efase erè a

Nou kite `src/legacy_save.lua` ak `oldRemainder` idantik ak vèsyon Stage 2 a. Nou ajoute `savePatch(x)`: li rele `oldRemainder(x)`; si rezilta a se zewo, li retounen `M`, sinon li retounen ansyen rès la. `saveSpaghetti` kounye a rele kouch patch la; `legacySaveProbe` pa chanje.

Nou fè menm `MonsterContext` pase nan de handler dispatcher: `LEGACY_SAVE`, apre sa `SAVE_PATCH`. Premye commit la toujou kenbe rès ki mal la, dezyèm lan konsève antre a, ansyen rès la, rezilta korije a ak rezon koreksyon an. Metrik, tras ak dyagnostik yo pèmèt yon odit san melanje eta de invocation diferan. Pa gen okenn import oracle normatif nan production.

### Regrèsyon ak prèv istorik

Tès ekivalans ki te wouj la vin vèt san modifye konparezon normatif li. Pou prèv Discovery 01 la pa disparèt, `stage02_expected_red_audit.lua` kounye a kouri yon regresyon **espesifik pou chemen legacy a**, ki kontinye pwodwi egzakteman twa diferans `M`, `2M`, `3M`; odit la dwe pase. Tès tras, limit ak pwopriyete Stage 2 yo toujou verifye ansyen rès la, men egzije kounye a yon rezilta piblik korije. Nou ajoute tès pozitif sou 903 ka limit, 8 ka espesyal, antre gwo, izolasyon eta, sekans dispatcher, metrik ak pwopriyetè eta.

Se sèl premye patch la nou fè. Lòt defo istorik yo rete pou etap ki vin apre yo.

## Stage 4 — DISCOVERY 02: `oldDayTag`

### Sa nou te kwè

Premye lide pou nimewo jou a te pran de fwa distans ant jou kesyon an ak Jou Fondasyon an: `2 * abs(day - FOUNDATION)`. Nou te sipoze yon nimewo pè konstan t ap sifi sou toude bò Fondasyon an.

### Sa nou dekouvri

Pou yon jou anvan Fondasyon an, fòmil la koresponn ak règ normatif la. Men pou jou Fondasyon an menm, legacy a bay `0` olye de `1`; pou jou ki vin apre yo, li manke inite `1` la epi li toujou pè. Se yon chanjman parite egzak, pa yon erè `SAVE`, pa yon erè tradiksyon, epi pa yon debòdman antye.

### Kouch monstr ki grandi

Nou ajoute yon dispatcher handler `LEGACY_DAY_TAG`, ak nouvo kontèks tranzaksyon lokal pou chak invocation, antre ak sòti desimal, metrik `legacy.daytag.calls`, tras ak dyagnostik. Li pase nan `dayTagSpaghetti`, yon pwen antre reyèl ki retounen rezilta legacy ki mal la. `legacyDayTagProbe` fè tras yo disponib. Nou pa enpòte oracle tès la nan pwodiksyon. Nou itilize `BigInt` sou distans jou a pou konsève kalkil orijinal la pou `math.mininteger` ak `math.maxinteger`.

### Prèv ak etap ki manke

Tès yo egzamine 631 antre, simetri ansyen fòmil la, izolasyon ant invocation, API ak tras dispatcher, epi yo egzije egzakteman kat divergences nan regresyon wouj la. Tout tès Stage 1–3 dwe toujou pase. Nou pa ajoute koreksyon +1 pou jou Fondasyon an ak apre li, ni guard espesyal sa a: de kouch sa yo fè pati **Stage 5 — PATCH 02** sèlman.

## Stage 5 — PATCH 02: nimewo jou yo reprann parite normatif la

### Sa nou korije

Ansyen `oldDayTag` la te retounen de fwa valè absoli distans ak jou Fondasyon an, ki kreye nimewo pè sou toude bò Fondasyon an. Li te bay `0` sou Fondasyon an, alòske nimewo normatif la se `1`; pou tout jou apre Fondasyon an, li te manke yon inite. Nou pa efase ni chanje ansyen fonksyon sa a.

### Kouch reparasyon an

Nou ajoute `dayTagWithFoundationScar(day)` ki rele `LegacyDayTag.oldDayTag(day)`, ajoute `1` lè jou a nan Fondasyon an oswa apre li, epi *kenbe yon guard adisyonèl* lè `day == FOUNDATION` epi valè a pa `1`. Guard la redondan apre adisyon an, men li se yon chikatris istorik obligatwa. Nou sèvi ak BigInt egzak pou pa melanje debòdman Lua ak erè sa a.

Yon handler `DAY_TAG_PATCH` vin apre `LEGACY_DAY_TAG` nan menm kontèks, ak de commit tranzaksyon, etap tras diferan, estatistik pou koreksyon parite, estatistik pou verifikasyon guard la, ak dyagnostik ki montre ansyen ak nouvo valè. Nou kenbe `legacyDayTagProbe` ak `dayTagPatchProbe` apa. Fonksyon `dayTagSpaghetti` la kounye a bay valè ki korije a.

### Prèv ak sa nou pa fè

Regresyon normatif Stage 4 la vin vèt; yon nouvo regresyon endepandan sou chemen legacy a kontinye echwe egzakteman sou kat jou Discovery 02 a, epi odit la verifye tèks erè sa a. Tout tès Stage 1–4 yo rete aktif. Yon seri 2,325 jou ak limit Lua yo egzamine parite, presizyon, dispatcher, metrik ak pwopriyetè eta. Nou pa entwodui okenn eleman `oldDistance` oswa patch pou etap ki vin apre yo.

## Stage 6 — DISCOVERY 03: `oldDistance`

### Sa nou te kwè

Paske nou te deja korije tag jou yo nan Stage 5, ansyen chemen distans lan te sipoze diferans absoli de tag sa yo t ap egal distans ant de jou yo. Nou te ekri `oldDistance(c,t) = abs(dayTag(c)-dayTag(t))` epi nou te pase nan chemen tag aktyèl la, pa nan yon kopi nan tès yo.

### Sa nou dekouvri

Pou menm jou a, diferans tag yo se zewo men distans normatif la se youn. Pou de jou ki travèse Fondasyon an, lòd ak parite tag yo ka fè diferans la twò piti; pou de jou ki lwen sou menm bò a, faktè de nan tag yo ka fè li twò gwo. Gen kèk pè youn apre lòt ki rive egal pa aza. Se poutèt sa erè a pa sèlman yon erè `+1` sou tout rezilta yo: ansyen baz kalkil la menm pa kwonolojik.

### Kouch monstè ki grandi

Nou ajoute `LEGACY_DISTANCE` nan dispatcher la, ak yon nouvo kontèks, metrik, yon tranzaksyon semantik, dyagnostik epi de kontèks pitit ki sòti nan `LEGACY_DAY_TAG -> DAY_TAG_PATCH`. Rezilta tag ki korije yo tounen antre kalkil erè `oldDistance` la, pandan fonksyon piblik `distanceSpaghetti` reyèlman ekspoze rezilta sa a. Antre ak sòti semantik yo se chèn desimal egzak; nou pa fè soustraksyon natif Lua ki ta debòde sou `math.mininteger` ak `math.maxinteger`.

### Prèv ak limit etapa a

Nou teste sèt tras nonmen, yon kadriyaj 1369 pè jou, 256 lòt pè ak uit pè ekstremal: 1633 pè an tout. Gen 1539 divergences nan seri sa a, epi yon regresyon endepandan bay egzakteman senk ka ki obligatwa pou prèv Discovery 03. Odit separe a refize tout lòt echèk kòm yon fo wouj. Tès ak kontra Stage 1–5 yo rete aktif ak vèt.

Pa gen `PATCH 03` nan etap sa a. Pou Stage 7 sèlman, nou pral konpare ansyen distans la ak `abs(t-c)`, korije si yo pa egal, epi ajoute inite final la. Nou pa pre-enkode metòd sa a nan pwodiksyon.

## Stage 7 — PATCH 03: ranplase diferans tag la sèlman lè li pa kwonolojik

### Sipozisyon ak rezilta ki soti nan Discovery 03

Ansyen `oldDistance(c,t)` la te pran diferans absoli ant de tag jou ki te deja korije nan Stage 5. Nou te jwenn egzanp kote rezilta a te `0` pou menm jou a, `1` olye de `3` atravè Fondasyon an, epi `6` olye de `4` sou menm bò a. Gen lòt pè kote diferans tag la egal aksidantèlman ak diferans jou kwonolojik la. Se poutèt sa senpleman ajoute `1` sou `oldDistance` pa ta sifi.

### Kouch PATCH 03 a

Nou pa chanje `src/legacy_distance.lua`. Nou ajoute yon kouch `distancePatch` ki rele `LegacyDistance.execute(c,t)` nan chemen pwodiksyon an. Apre li resevwa valè istorik la, li kalkile `chronological = abs(t-c)` ak BigInt, li konpare valè yo, li ranplase valè istorik la sèlman lè yo diferan, epi li fè `distance = reconciled + 1`. Toude branch yo rete vizib nan eta semantik ak nan dyagnostik. Nou pa retounen oracle tès la; se yon koreksyon lokal ki defini nan kontra a.

Handler `DISTANCE_PATCH` la ajoute yon dezyèm tranzaksyon nan menm kontèks `LEGACY_DISTANCE` lan: li kenbe tag orijinal yo, diferans legacy a, distans kwonolojik la, valè apre rekonsilyasyon an, ak distans enklizif final la. Li ajoute metrik `distance.patch.calls`, `distance.patch.reconciliations` ak `distance.patch.inclusiveUnits`. De kontèks tag pitit yo rete disponib; chak deja gen de etap `LEGACY_DAY_TAG` ak `DAY_TAG_PATCH`. Sa ogmante achitekti monstr lan san li pa kache ansyen erè a.

### Regrèsyon ak sa ki rete pou pita

Regresyon normatif Stage 6 la vin vèt. Nou kreye `stage06_legacy_regression_tests.lua` pou kenbe mesaj `EXPECTED_RED` orijinal la egzak, pandan odit Stage 6 la kouri sou chemen legacy a. Nou ajiste tès tras ak pwopriyete yo pou yo konpare legacy ak legacy, epi wout piblik la ak règ enklizif la. Nou egzamine 2,665 pè, limite debòdman Lua ak BigInt, epi teste reentrancy ak diferan branch rekonsilyasyon. Stage 8 ak defo ki vin apre yo pa enkli.

## Stage 8 — DISCOVERY 04: `mutateStonesWrong`

### Sa nou te kwè

Nan premye konstriksyon tab 46 wòch yo, nou te sipoze nou te ka kalkile senk nouvo valè yo youn apre lòt nan menm tablo a. Fòmil yo te sanble respekte `SAVE`, paske chak apèl te sèvi ak `SavePatch.savePatch`, men yo pa t respekte kondisyon ki mande pou **tout senk wòch yo soti nan menm eta anvan an**.

### Sa nou dekouvri

Sou ranje 2 a, valè ble `w=378` la bon, paske li sèlman itilize `w` ak `b` ansyen yo. Lè n ap kalkile `b`, nou itilize `w=378` ki deja chanje, olye de `w=17`: rezilta a vin `1434` olye de `1073`. Apre sa, `s` itilize `b` ki deja chanje, `m` itilize `s` ki deja chanje, epi `r` itilize `w` ak `m` ki deja chanje. Rezilta yo se `3780/9932/25047` olye de `2375/6195/10493`. Se yon erè depandans tanporèl, pa yon erè BigInt oswa modil SAVE.

### Kouch monstr ki grandi

Nou kreye `LEGACY_STONES` nan dispatcher ak metrik, kontèks semantik ki posede apa, dyagnostik `SEQUENTIAL_REUSE_OF_NEW_STONES` ak tras pou chak apèl. Fonksyon `mutateStonesWrong` la li menm toujou ekri **in-place** sou tablo ki resevwa li, jan kontra istorik la mande. Yon adapter `execute` pwoteje antre apèl piblik la epi pwouve tranzaksyon commit li. Bati 46 ranje yo mande 45 apèl reyèl nan chemen legacy a; pa gen tablo prekwit ki soti nan yon lòt branch.

### Prèv, limit ak sa ki rete

Nou konpare 410 tranzisyon, ladan yo 240 gwo antye detèminis, ak yon referans lokal ki sèvi ak oracle test-only `SAVE` la. Odit `EXPECTED_RED` la egzije kat non ak valè presi, san tolere echèk ki pa gen rapò ak mutation an. Tès ansyen etap yo rete vèt. Nou pa mete snapshot korektif nan production: **Stage 9 — PATCH 04** sèlman ap klone valè `old` yo, rele legacy sou yon clone pou konsève erè a, epi ranplase tout senk rezilta yo ak fòmil ki sèvi ak `old` sèlman.


## Stage 9 — PATCH 04: snapshot anvan tout senk wòch yo

### Ki erè n ap konsève

Nan Stage 8, `mutateStonesWrong` te mete ajou `w`, `b`, `s`, `m`, ak `r` youn apre lòt, konsa chak nouvo valè te antre nan pwochen fòmil la. Nou pa netwaye fonksyon sa a ni retire apèl li yo. Li toujou ekri in-place epi li rete disponib nan `legacyStoneProbe`.

### Kouch koreksyon an

Nou ajoute `stonePatch(i,S)`: li klone tout senk ansyen wòch yo, li rele **vrè** `mutateStonesWrong` sou yon lòt clone pou pwodui garbage istorik la, epi li ranplase `garbage.w`, `garbage.b`, `garbage.s`, `garbage.m`, ak `garbage.r` ak senk fòmil `SAVE` ki pran done **sèlman** nan snapshot `old`. Nou pa ranplase algoritm legacy a ak yon apèl oracle, ni nou pa bati yon tablo normatif ki sote sa ki te ekri anvan.

Nan chemen dispatcher pwodiksyon an, `LegacyStones.execute` fè apèl istorik la, apre sa `STONE_PATCH` fè ranplasman an. Kontèks la konsève ansyen rezilta garbage yo, senk rezilta korije yo, de commit, metrik, dyagnostik, ak tras handler ki montre kisa ki te fèt.

### Regrèsyon ak mezi

Nou kenbe yon regresyon legacy endepandan ki kontinye echwe sou kat valè `b`, `s`, `m`, `r` nan ranje 2, epi yon odit ki refize nenpòt lòt erè kòm fo prèv. Regresyon piblik la vin vèt; menm bagay la pou tablo 46 ranje yo. Tès Stage 9 yo egzamine 455 tranzisyon, gwo antye, imutabilite antre, branch istorik ak devlopman eta tranzaksyonèl, pandan ansyen tès yo kouri ankò.

Stage 10 ak tout etap ki vini apre yo poko antre.
