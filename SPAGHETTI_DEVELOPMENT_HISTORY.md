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


## Stage 10 — DISCOVERY 05: depo sèt gout kache yo ranvèse

### Sa nou te sipoze

Ansyen konstriksyon gout kache yo te mete sèt valè yo nan yon tablo kote
gout nimewo 7 te vini an premye epi gout nimewo 1 te vini an dènye. Pita,
chemen aksè a te aji tankou premye plas la te gout nimewo 1.

### Sa nou verifye

Sèt fòmil yo, ansanm ak sèt seri tounaj yo, sèvi ak bon koefisyan ak bon
wòch yo; pa gen erè matematik nan valè yo. Men kote done yo ye pa konpatib
ak endis ki nan lekti a. `storage[k]` reprezante `hidden(8-k)`. Se sèlman
mityèm gout la, `hidden4`, ki pa bouje. Tout lòt sis pozisyon ka pa kòrèk.
Nou fè tès endepandan kont oracle test-only la, epi nou egzije egzakteman
sis pozisyon sa yo kòm `EXPECTED_RED`.

### Yon lòt kouch monstr

Nou ajoute `LEGACY_HIDDEN` avèk yon dispatcher, yon eta semantik ki posede,
tras, metrik ak dyagnostik sou plas fizik yo. Kalkil gout yo konsome
vrè rezilta `DAY_TAG_PATCH`, `DISTANCE_PATCH`, `STONE_PATCH`, ak `SAVE_PATCH`.
Nou pwoteje done retounen yo kont alias ak kontèks lòt invocation.

### Sa nou pa korije

Nan Stage 10, nou kite chemen lekti a san tradiksyon endis. **Stage 11 —
PATCH 05** pral ajoute aksè `8-k` men li p ap ranvèse tablo fizik la ni
retire chemen istorik la. Nou pa fè travay Stage 12 oswa pita.


## Stage 11 — PATCH 05: lekti lojik sèt gout yo

### Ki jan nou kenbe vye erè a

Nou kite `legacy_hidden.lua` ak depo fizik ranvèse a nèt tankou nan Stage 10.
Fonksyon `oldHiddenAt(storage,k)` la pa konnen tradiksyon endis la; li
kontinye li move plas `k` la. Nou pa chanje ni kalkil gout yo, ni kote
sèt valè yo ekri nan tablo fizik la.

### Nouvo kouch PATCH 05 la

Nou ajoute `hiddenByNearness(storage,k)` ki tounen
`LegacyHidden.oldHiddenAt(storage,8-k)`, san modifye `storage`.
Nan dispatcher la, `HIDDEN_PATCH` vini apre apèl reyèl `LEGACY_HIDDEN`;
nou kenbe de commit semantik ak de tras, ansanm ak sèt plas fizik,
sèt gout lojik ak dyagnostik de fason lekti a te repare. Nou pa retire
fonksyon istorik la. Ni oracle ni okenn eleman Stage 12 pa nan production.

### Prèv koreksyon an

Regresyon normatif Stage 10 la vin vèt pou tout sèt gout, pandan
regresyon legacy apa a toujou bay egzakteman sis pozisyon ki mal:
1, 2, 3, 5, 6, 7. Nou fè tès mapping, izolasyon ak kontèks sou 36 koup jou
ak 252 pozisyon; menm gout mitan an rete an plas. Runner prensipal Stage 11
pral kouri tout etap 1–11 nan CI. Nan handoff sa a, tès kouch mapping nan
te pase lokalman avèk doublon depandans; apre sa, CI konplè GitHub Actions te pase pou etap 1–11.


Yon lòt verifikasyon Stage 11 enumere tout 5,040 permutasyon sèt idantite diferan, ak 35,280 lekti lojik. Sa kenbe prèv tradiksyon endis la se yon envèsyon jeneral epi li pa depann de yon sèl pè jou oswa yon sèl konbinezon gout.


### Rezilyans kont echèk lokal yo

Anvan handoff Stage 11, nou ajoute yon tès fault-injection apa pou
chak nan sèt aksè fizik yo. Nou egzije yon echèk ki parèt klèman,
apre sa yon lòt invocation pwòp, ak tras, commit ak metrik orijinal.
Nou teste tou yon depo fizik ki manke valè, yon echèk legacy anvan
li tounen done yo, ak alias BigInt (enkli kopi limb si li ekspoze).
Yon QA lokal ki sèvi ak doublon depandans yo pase; apre sa, suite Lua natif la sou GitHub Actions te bay `FULL_NATIVE_SUITE=PASS` ak tout sis travay vèt.


## Stage 12 — DISCOVERY 06: yon fonksyon history ki sèlman wè gout vizib

### Sipozisyon istorik

Apre sèt gout kache yo te korije nan Stage 11, ansyen wout history la
toujou te sèvi sèlman ak `dropStore[i-back]`. Li te sipoze tout
endèks li mande yo pozitif epi yo nan tablo gout vizib la. Lè gout
vizib nimewo 1 bezwen p1, p3 oswa p7, rezilta sa a vin nil, malgre
sèt gout kache yo deja kalkile kòrèkteman.

### Kouch ki parèt nan etap sa a

Nou ajoute dispatcher `LEGACY_PRIOR` ak yon kontèks posede,
metriks, dyagnostik, eta semantik ak prèv apèl reyèl nan HIDDEN_PATCH.
Nou pa itilize valè hidden yo nan kalkil legacy a. Sa se erè istorik
nou vle konsève, pa yon erè jwèt ki fèt sèlman nan tès yo.

### Pwotokòl prèv la

Sèt plas hidden 0, -1, -2, -3, -4, -5, -6 dwe bay egzakteman
erè `EXPECTED_RED Stage 12 DISCOVERY 06` nan regresyon nouvo a.
Menas ki ta chanje fonksyon legacy a oswa ki ta ranje hidden yo twò bonè
fè tès scope ak trace yo echwe. Tout etap 1–11 dwe rete vèt.
Stage 13 sèlman ap mete mapping `hiddenK=1-slot` pou history.

## Stage 13 — PATCH 06: sèt plas history kache yo te jwenn

### Pwoblèm nou jwenn nan Stage 12

Ansyen `legacyPrior` la te kontinye gade nan yon sèl depo gout vizib,
`dropStore[i-back]`. Pou `i=1`, sèt valè back yo mande slot 0,-1,...,-6;
rezilta legacy yo se `nil`, menm si Stage 11 te deja kalkile tout hidden yo.
Nou **pa efase oswa repare** fonksyon legacy sa a.

### Koreksyon an kòm yon lòt kouch moun ka swiv

Nou ajoute `priorPatch` apre apèl orijinal la ak yon nouvo handler
`PRIOR_PATCH` sou menm kontèks tranzyonèl la. Pou slot pozitif,
fonksyon legacy a sèvi kòm sous la; pou slot ki pa pozitif,
`hiddenK=1-slot`, epi `hiddenByNearness` tradui nan plas fizik `8-hiddenK`.
Premye kalkil hidden la deja nan `nestedHiddenContext` orijinal la:
nou pran sèt fisèl `physical1..physical7` li te anrejistre epi nou
konvèti yo an BigInt posede, san rekalkile ni ranvèse tablo a.

De tras, de commit, de dyagnostik ak metrik history ki ansyen/koreksyon
rete vizib. Lè history a mande yon plas vizib ki pa egziste,
rezilta a toujou `nil`, pa yon BigInt fo. Lè yon lòt invocation kòmanse,
li pa resevwa eta kontèks anvan an.

### Verifikasyon ak delè istorik la

Nou kenbe regresyon wouj Stage 12 la kòm yon prèv legacy separe ki
egzije egzakteman sèt plas ki manke yo. Regresyon pwodiksyon an ak
tès 24 koup jou yo vin vèt; yon suite nouvo ajoute 22 erè piki.
`GRIND_TABLE_WITH_SENTINEL` ak tout etap Stage 14 yo poko antre.

### Vèdik natif Stage 13

GitHub Actions `38229918405` konfime sèt travay `success`.
Yon tès endepandan sou Lua 5.3 rapòte 1,344 lekti (672 hidden,
672 vizib), 22 piki echèk izole, 15 rekiperasyon ak PASS Stage 13.
Se sèlman apre prèv sa yo nou fèmen PATCH 06.


## Stage 14 — DISCOVERY 07: tounaj ki chita sou move endis

### Sa nou te fè nan ansyen kalkil la

Yon tab onz ranje te konte pozisyon fizik yo depi 0. Men bouk
tounaj yo te konte `g=1` rive `11`, epi `oldGrindRow(g)`
te itilize `ORIGINAL_ROWS[g]` san korije orijin endis la.
Nou konsève defo sa a kòm yon istwa aktif, pa yon mock tès sèlman.

### Prèv ki fè defo a klè

Tounaj 1 li paramèt tounaj 2; menm deplasman an repete jiska
tounaj 10 ki li paramèt tounaj 11. Tounaj 11 pa gen ranje ditou.
Nou ajoute tès tab endepandan ki egzije egzakteman 11 divergences,
epi yon odit EXPECTED_RED ki verifye mesaj la, san aksepte
echèk sentaks oswa regression yon lòt etap kòm prèv.

### Kouch monstr ki grandi

Nou ajoute `LEGACY_GRIND_INDEX`, yon dispatcher, eta semantik ki
posede, metrik, dyagnostik ak depo fizik ki rete envèse.
Nou konekte li ak premye wout gout vizib la, ki konsome fonksyon
PATCH 06, wòch 46 yo, SAVE ak konte jou yo. Chemen an montre
tou de dis tounaj yo ak mank onzyèm lan. Li pa gen okenn sentinel.

### Sa ki rezève pou pwochen etap la

Nan Stage 15 sèlman nou pral mete yon ranje sentinel nan plas fizik
0 epi onz vrè ranje yo nan plas 1..11, pandan n ap konsève fonksyon
indexing legacy a ak dyagnostik li. Pa entwodui fonksyon
permutation Stage 16 oswa lòt travay ki vini pita.


## Stage 15 — PATCH 07: kouch sentinel ki kenbe move endis istorik la

Nan Stage 14, tab 0..10 la te sèvi mal pou 11 grind yo. Nou pa efase
konpòtman sa a. Nou konstwi yon nouvo depo ak sentinel fizik nan plas 0,
ak ranje reyèl 1..11, chak ranje sòti nan kopi ranje fizik legacy a.

GRIND_PATCH rele LEGACY_GRIND_INDEX anvan li konsome tablo korije a.
De komit semantik, de tras, metrik ak dyagnostik konsève aksè erone
ansyen an ak rezilta konpetan nouvo a. Wout gout vizib la sèvi ak
fòmil p1/p3/p7 atravè PATCH 06, wòch atravè PATCH 04, SAVE atravè
PATCH 01 epi onz grind sa yo nan bon lòd.

Prèv obligatwa yo enkli onz ranje korije, onz divèjans legacy,
konpetisyon test-only kont nèf gout vizib ak 99 tounaj, ak regression
tout etap 1..15. Tout travay Stage 16 rete entèdi nan patch sa a.


### Prèv final natif PATCH 07

Run 38237011389: uit travay yo tout success. Tès endepandan
test-only la konfime nèf gout vizib ak 99 grind; onz ranje
nouvèl yo mache, pandan odit EXPECTED_RED Stage 14 la toujou
detekte tout onz move ranje legacy yo. Nou pa mete okenn etap 16.

## Stage 16 — DISCOVERY 08: rank six-bowl la te glise

### Sa ansyen kòd la te kwè

Apre premye kalkil gout vizib yo, ansyen ouvèti lòd sis bòl yo te sèvi
ak `oldPermutationUnrank0`. Fonksyon an te byen kalkile factoradic pou
0..719; menm non li montre li atann zewo. Men moun ki te rele li a te
pase rang 1..720 san adaptasyon.

### Ki prèv ki montre move sipozisyon an

Enumerasyon endepandan tout 720 permutasyon yo montre unrank0 a kòrèk.
Pwoblèm nan se sèlman premye apèl la: `1` chwazi dezyèm permutasyon,
`719` chwazi dènye a, epi `720` pa gen dwa antre. Odit EXPECTED_RED la
fè distenksyon ant 719 permutasyon deplase ak yon rang ki rejte.

### Ki kouch monstr nou te ajoute

Nou konsève unrank0, epi nou ajoute de handler `LEGACY_ONE_BASED_RANK`
ak `LEGACY_PERM_UNRANK0`, de commit ak branch-trace, metrics, ak dyagnostik.
Nan rang 720, pwodiksyon an kenbe yon rezilta `nil` ak yon rapò presi
olye li fabrike yon lòd bòl.

### Sa nou poko fè

Nou pa korije rang anvan unrank0 a, nou pa fè okenn pours, pa gen
`bowlAlias`, ni okenn kòd PATCH 08. Stage 17 sèlman pral ajoute chèn
`oneBased=regularMod(drop-1,720)+1`, `legacyRank0=oneBased-1`, epi
`oldPermutationUnrank0(legacyRank0)`, pandan l ap konsève tras istorik la.

### Lè yon erè diferan rive

Yon ansyen tès te trete tout erè ki soti nan unrank0 tankou rang 720 manke.
Nou limite anvlòp sa a: se sèlman mesaj validasyon istwa a, sou rang
720 toutbon, ki vin MISSING. Yon pann sou rang 1..719, oswa yon lòt pann
sou 720, pase klèman pou odit la pa bay fo prèv EXPECTED_RED.

### Chèn gout vizib rive jiska rank

Tès entegre a egzèse kalkil gout vizib ki sot nan PATCH 07, ak tout
11 tounaj, anvan li pase valè sa yo nan legacy permutation. Pa gen
valè oracle ki antre kòm antre pwodiksyon. Se sèlman tès yo ki itilize
oracle pou mezire erè rank ki te deja la.


### Distenksyon echèk yo nan menm etap Discovery 08 la

Yon mekanis tretman erè te konfonn yon mesaj ki sanble ak erè
istorik rang 720 ak validasyon reyèl unrank0 la. Nou kenbe menm
konpòtman istorik pou rang yo, men nou bay validatè 0..719 la
yon token erè prive. Se idantite token sa a, pa mo ki nan mesaj la,
ki fè konteks Discovery 08 la mete `MISSING`. Yon faux panik rete
yon faux panik; tès kalite yo pa ka bay fo PASS sou sa.


### Provenans erè a, pa idantite erè a sèlman (QA v004)

Yon wrapper ka atrap vrè token erè validatè a, epi voye menm objè
lan ankò. Tès ak idantite token sèlman te aksepte sa. Nou
konplete baryè a avèk yon referans ki rete sou fonksyon legacy
original la. Nou teste `replay-direct` ak `wrapper-calling-original`,
ansanm ak rekiperasyon apre yo. Mòd Discovery 08 la rete
an menm erè one-based li te genyen an.


### Fenèt chanjman ant apèl ak verifikasyon (QA v005)

Nan premye tantativ ranfòsman an, nou konpare fonksyon aktyèl la
apre `pcall`; yon wrapper te ka retabli referans ansyen fonksyon an
an tablo a pandan apèl la, epi re-voye token otantik la. Nou fèmen
fenèt sa a lè nou konsève referans fonksyon REYÈLMAN rele a anvan
`pcall` epi nou konpare li ak orijinal la. Twa atak ak twa
rekiperasyon pase, san korije erè istorik rank 1..720 lan.


### Peryodisite ki pa depann de gwosè BigInt (QA Stage 16 v006)

Nou egzije menm rang legacy a lè yon valè chanje pa `+720` oswa
`-720`, menm sou antre negatif ak antye 512 chif. 2,199 invocation
verifye pa yon kalkil rezidi desimal ki endepandan; okenn koreksyon
unrank0 pa antre. Mutation tès sèlman ki deregle modulo negatif la
se detekte.

### Verifikasyon siplemantè pou Stage 16

Nou ajoute yon tès entèlasman pou 360 gwo BigInt ak 720 invocation,
ki teste ke repons yo ak branchTrace/diagnostics/metrics pa pataje
referans ki ka koule soti nan yon apèl pou ale nan yon lòt. Mutasyon
pataj konteks la detekte. QA izole kouri vrè legacy_grinds, grind_patch
ak legacy_permutation ansanm; seulement bigint ak MonsterBase se doublon.
Pa gen okenn chanjman kòd production ni okenn patch ki pou Stage 17.

### Izolasyon pandan apèl nested (Stage 16)

Nan DISCOVERY 08, plizyè dispatcher kapab aktif ansanm. Nou ajoute
prèv ke apèl `LEGACY_ONE_BASED_RANK` oubyen `LEGACY_PERM_UNRANK0` ki
lanse yon lòt invocation pa sal eta, tras oswa commit yo. Yon tès
mutation sou kontèks pataje ap echwe jan li dwe. Pa gen okenn chanjman
semantik ni okenn kòd PATCH 08 nan tès sa a.

## Stage 17 — PATCH 08

Nou prezève fonksyon istorik oldPermutationUnrank0 ak erè one-based la.
Nan nouvo kouch la, Legacy.execute kouri anvan koreksyon: nou konsève
2 commit ak de tras li yo, answit dispatcher PERMUTATION_PATCH rele
oldPermutationUnrank0(oneBased-1) toutbon, ak validasyon rank factoradic.
Nou teste 720 lòd, BigInt negatif ak anpil chif, erè enjekte, kopi posede,
ak nèf gout vizib reyèl. Nou pa ajoute okenn mouvman bòl.
Tès natif CI Stage 17 dwe pase anvan nou fèmen etap la.

### Fèmti Stage 17

CI natif `38266889952` fini ak 10/10 travay PASS. Tout 720 rang
korije, 237 ka BigInt, 15 fault injections, 9 gout vivan, 180
entèlasman ak 8 apèl nested verifye. LAST_COMPLETED_STAGE=17.

## Stage 18 — DISCOVERY 09: vide istorik yo sou id fiks

Lòd permutation sis bòl la sòti kòrèkteman nan PATCH 08. Men premye
twa vide yo toujou pran bòl fizik 1, 2, 3, olye id bòl ki parèt nan
twa premye pozisyon lòd permutation sa a. Nou konsève fonksyon
`legacyPoursToFixedBowlIds`, metrik, dyagnostik, tras tranzaksyon,
premye eta bòl yo ak wout reyèl gout vizib premye a. Nou pa
chanje mwayen vide yo; Stage 19 sèlman ap korije erè id bòl sa a.

### Fèmti Stage 18: EXPECTED_RED konfime

Run `38274743802`: 10/10 travay anvan yo PASS. Travay discovery la
pase syntax, scope, tout suite pozitif, injection, reentrance ak odit,
men li bay sèl echèk normatif istorik la nan dènye step la. Sa
pwouve 3 gout yo toujou vide sou bòl 1,2,3 olye order permutation.
Nou make LAST_COMPLETED_STAGE=18. Pa gen okenn PATCH 09.

## Stage 19 — PATCH 09: koreksyon id bòl yo

Kòd `legacy_fixed_pours.lua` rete san chanjman. Nan nouvo kouch la,
nou rele chemen legacy a an premye, verifye tras ak lòd PATCH 08 la,
apre sa vide nan bòl `order[1]`, `order[2]`, `order[3]`.
Yon nouvo handler `BOWL_ORDER_POUR_PATCH` komèt eta koreksyon an
san detwi prèv id fizik 1, 2, 3. Chemen piblik premye gout la
fè koreksyon sa a, tandiske probe istorik la rete disponib.
Pa gen melanj bòl oswa operasyon etap pita.

### Fèmti Stage 19

Run `38278529281`: 12 travay PASS, `lua_stage18_discovery`
vin vèt paske regresyon istorik EXPECTED_RED kouri anndan odit
pozitif. Suit Stage 19 pase 720 permutation, 140 gwo BigInt,
27 vide reyèl, 16 erè enjekte, 16 rekiperasyon ak 4 apèl nested.
`LAST_COMPLETED_STAGE=19`; pwodiksyon korije, legacy toujou mal
jan li dwe rete pou tras. Pa gen okenn travay Stage 20.

## Stage 20 — DISCOVERY 10: move alias old/next pandan brase

Apre PATCH 09, tout twa vide yo matche ak oracle. Premye chèn
brase sis bòl la mete `old=working` epi `nextBowls=working`,
ki vle di chak update chanje done lòt pozisyon yo pral li.
Nan `LEGACY_ALIASED_STIR`, nou konsève tout rezilta istorik,
metrik, branchTrace ak de premye patch pou vide yo. Nou pa fè
PATCH 10, ni melanj douz etap ki vin apre a. Fòk tès normatif
la kontinye echwe sèlman pou alias sa a nan Stage 20.

### Fèmti Stage 20: alias confime natif

Run `38281453888`: 12/12 travay ansyen ak tout tès pozitif PASS,
sèl echèk la se regresyon istorik ki fèt espre sou id alias old/next.
9 gout reyèl, 100 BigInt, 12 piki/12 rekiperasyon, 8 nested PASS.
Nou kenbe modil legacy a san koreksyon e n make
`LAST_COMPLETED_STAGE=20`, `EXPECTED_REPOSITORY_STATE=EXPECTED_RED_VERIFIED`.
Pa gen PATCH 10 ni brase 12 etap yo.

## Stage 21 — PATCH 10: separe snapshot avan brase

Nou konsève `legacy_aliased_stir.lua` byte-pou-byte.
Nou kouri `LEGACY_ALIASED_STIR` natif anvan koreksyon.
`STIR_SNAPSHOT_PATCH` se katriyèm commit nan kontèks la:
nou refè sis pozisyon brase ak `old` separe de `nextBowls`,
kòm kontrè egzak erè Stage 20. Tès Stage 20 la kontinye
teste move alias la sou probe legacy li sèlman.
Sa pa enkli lòt 45 gout ni `postStir12`.

### Fèmti Stage 21: native CI vèt

`38285581054` se run konplè sou commit `ba0201ac`.
15/15 jobs PASS. Tout 720 lòd sis bòl, 111 BigInt, 54 bòl
nan 9 gout reyèl, 15/15 rekiperasyon ak 8 apèl nested PASS.
Legacy Stage 20 konsève; chemen piblik ale nan
`STIR_SNAPSHOT_PATCH`. `LAST_COMPLETED_STAGE=21`.
Etap 22 pa lanse.

## Stage 22 — DISCOVERY 11: bòl inisyal yo reaplike sou chak gout

Apre PATCH 10, yon sèl brase ak snapshot bay bon rezilta.
Nou ajoute `LEGACY_BOWL_STATE_RESET`: chak gout nouvo rele
`StirPatch.execute(drop,i,initialBowls,stones[i])`, olye
konte sou six bowls ki soti nan gout anvan an. Sous
`INITIAL_BOWLS_REUSED_AT_EVERY_VISIBLE_DROP` rete yon
nouvo branch/commit, epi context kenbe childContexts natif,
perDrop tras, metrik ak diagnostik. Stage 23 ap korije
transmisyon eta a. Pa gen `postStir12` oubyen seleksyon.

### Fèmti Stage 22: native CI ak scar istorik

Run `38287878912` te bay 16/16 lòt travay vèt. Yon sèl
echèk te nan regresyon normatif DISCOVERY 11 a, jan nou te
mande a. QA natif verifye 46 gout ak oracle endepandan,
9 gout vizib reyèl, 13 defayans ak 13 rekiperasyon, epi
5 nested chains endepandan. Nou make
`LAST_COMPLETED_STAGE=22`, `EXPECTED_REPOSITORY_STATE=EXPECTED_RED_VERIFIED`.
PATCH 11 rete pou Stage 23.


## Stage 23 — PATCH 11: pote eta bòl yo atravè tout gout

Nou kite `legacy_reset_chain.lua` byte-pou-byte ak defo reset
la. `bowl_chain_patch.lua` fè chèn legacy a pase an premye
epi ajoute handler `BOWL_CHAIN_STATE_PATCH`, avèk dezyèm
commit li, kopi sis bòl yo ak `patchedChildContexts` apa.
Depi gout 2, antre `StirPatch.execute` soti nan rezilta
gout anvan an. Kontèks prensipal la konsève ansyen
`legacySemanticState` ak `legacyLastBowls`. Mank kontinwite
historik Stage 22 la rete vizib nan `legacyResetBowlsProbe`.

### Fèmti Stage 23

Run natif `38290676201`: **18/18 travay PASS**. Suite Stage 1–23
pase sèt sekans kout / 28 gout, chèn konplè 46 gout ak 276
rezilta bòl, oracle endepandan, 16 defayans + 16 rekiperasyon,
5 nested chains, 3 pè jou / 9 gout natif ak odit
`EXPECTED_RED` Stage 22 otantik. Oracle 46-gout orijinal la
rete entak; nou itilize yon helper tès pou sekans ki pi kout.
`LAST_COMPLETED_STAGE=23`, `EXPECTED_REPOSITORY_STATE=GREEN`.
Pa gen Stage 24 ni douz brase final.


## Stage 24 — DISCOVERY 12: id fiks yo pa respekte sik lòd gout 46

Premye chemen nouvo a rele PATCH 11 sou tout 46 gout yo,
epi PATCH 08 sou dènye gout la. Men chwa vwazen an toujou
`(queriedId % 6)+1`, ki suiv non fizik 1..6 yo olye
sik permutation 46 la. Nou anrejistre rank, lòd otantik,
bòl ki soti nan chèn anvan an, tras konplè de premye commits
ak twazyèm commit `LEGACY_FIXED_NAME_NEIGHBOR`.
Oracle pa antre nan pwodiksyon; ni PATCH 12 ni douz
brase final yo pa kòmanse. Regresyon wouj la ap konpare
id 2 (legacy) ak id 6 (oracle) pou rank 720, queried id 1.
Rezilta CI natif te verifye sou run 38292918409.

### Fèmti DISCOVERY 12 — Stage 24

Run `38292918409`: 20/20 travay endepandan PASS. Job
`lua_stage24_discovery` pase suite konplè Stage 1–24,
apre sa li echwe egzakteman sou regresyon normatif ki
rezève pou DISCOVERY 12. Prèv: 720 lòd, 4,320 vwazen,
3,456 diferans, 864 matche, 46 gout vre, BigInt >256 bit,
9 defayans/9 rekiperasyon, ak 3 nested chains.
Fichye Stage 23 yo rete ak lojik orijinal yo; sa pa fè
PATCH 12 oswa brase final yo antre.
`LAST_COMPLETED_STAGE=24`, `EXPECTED_RED_VERIFIED`.


## Stage 25 — PATCH 12: rekonsilyasyon vwazen apre gout 46

`neighbor_patch.lua` rele tout chèn istorik 46 gout la
ki rive jis nan `LEGACY_FIXED_NAME_NEIGHBOR`.
San efase ansyen kalkil la, li verifye rank ak lòd
permutation PATCH 08, sis bòl PATCH 11, tras legacy ak
diagnostics, epi li ajoute katriyèm commit
`DROP46_NEIGHBOR_ORDER_PATCH`. Eta istorik la rete
nan `legacyNeighborSemanticState`; kontèks pitit ak
eta BigInt posede yo pa pataje ant envokasyon.

Tout 720 permutation × 6 id bay 4,320 repons ki matche
oracle; 3,456 repare vwazen mal, 864 yo matche deja.
BigInt negatif >256 bit, 46 gout/276 bòl, 8 piki erè
ak 8 rekiperasyon, tès nested 46 gout ak gout reyèl
pase sou Lua 5.3. Egzanp rank 720, id 1: legacy=2,
PATCH 12=6. PATCH 13 ak douz brase final yo pa antre.

### Fèmti Stage 25

GitHub Actions `38372225320`: **25/25 jobs PASS**.
Suite Stage 1–25 vèt, odit `EXPECTED_RED` Stage 24
toujou egzije mesaj erè istorik egzak la sou wout legacy a.
`LAST_COMPLETED_STAGE=25`, `EXPECTED_REPOSITORY_STATE=GREEN`.

## Stage 26 — DISCOVERY 13: chwa modulo san rejè

Apre PATCH 12, nou separe mekanis repons SAVE ak mekanis
seleksyon. Sous la itilize `A_k = SAVE(A_0+direction*k)`;
seleksyon istorik la kenbe `1+((A_0-1) mod N)` san tcheke
`floor(M/N)*N`. Nou pa modifye 46 gout, bowls, permutation,
oswa `neighbor_patch.lua`. `legacy_biased_choice.lua`
gen de commits, metrik ak diagnostics pou temwaye de faz yo.
Tès oracle short path yo ak kat witness wouj yo distenge
mechanism valid la de bias la. Stage 27 dwe ajoute rejè
san efase chemen istorik la. CI/verification poko fini.

### Fèmti DISCOVERY 13 — Stage 26

GitHub Actions run `38375388629`: 26/26 travay pozitif
vèt, `lua_stage26_discovery` pase Stage 1–26, epi echwe sèlman
sou `EXPECTED_RED Stage 26 DISCOVERY 13 witness 1: modulo san rejè`.
Kat witness yo te verifye pa audit, 409 repons kont oracle
te pase, 8 fault / 8 recovery ak 2 nested streams te pase.
Pa gen PATCH 13 nan Stage 26.
`LAST_COMPLETED_STAGE=26`, `EXPECTED_RED_VERIFIED`.

## Stage 27 — PATCH 13: premye repons ki nan limit akseptasyon

`short_choice_patch.lua` rele `legacy_biased_choice.lua`
anvan tout koreksyon. Li ajoute twazyèm commit ak prèv
`floor(M/N)*N`, premye index akseptab la, kantite rejè,
rank korije, rank legacy ak state apa. Nou prezève
kat witness EXPECTED_RED Stage 26 nan audit pozitif.
N=M//2+1, premye=M, direksyon -1 mande plis pase
`2^64` rejè lojik; kòd la itilize prèv rejyon kontig
pou rive egzakteman nan premye akseptasyon an.
Tout kalkil toujou fèt ak BigInt Lua; pa gen wide detour.
Rezilta CI native final la verifye nan run 38430726689.

### Fèmti natif Stage 27

GitHub Actions `38430726689`: **31/31 PASS**.
Tout Stage 1–27 pase ansanm, 1,239 rank oracle,
165 bias legacy korije, >2^64 rejè lojik, 12 fault/recovery,
de kontex reentrant, de sauce kanonik, ak kat odit
`EXPECTED_RED` istorik Stage 26. Legacy rete byte-pou-byte
e modil oracle pa antre nan production.
`LAST_COMPLETED_STAGE=27` / `EXPECTED_REPOSITORY_STATE=GREEN`.

## Stage 28 — DISCOVERY 14: short-only dispatcher bloke N>M

Nou pa modifye PATCH 13. Modil `legacy_short_only_choice.lua`
rele chemen short korije a menm lè N depase M.
Pou N>M, verifikasyon short la rejte gwosè opsyon an
e chemen legacy retounen rank nil ak MonsterContext
ki gen yon commit ak diagnostics. Pou N<=M, PATCH 13
rete san chanjman. Oracle wide sèlman nan `test/`
montre repons valab ki pa disponib sou chemen sa a,
ak 4 scripts EXPECTED_RED ak plizyè gwosè >256 bit.
Pa gen wideDetour PATCH 14, ni chif wide nan production.
Natif CI verifye sou run `38435176181`.

### Fèmti DISCOVERY 14 — Stage 28

GitHub Actions `38435176181`: **34/34 travay pozitif PASS**;
`lua_stage28_discovery` pase tout Stage 1–28 anvan li echwe
sèlman sou `EXPECTED_RED Stage 28 DISCOVERY 14 witness 1: N>M blocked by short-only legacy`.
Kat witness istorik yo pase audit egzak. 59 chwa short
PATCH 13 pa bouje; sèt rank wide valab bloke nan
legacy, BigInt rive `M^5+1`, 8 erè/8 rekiperasyon,
de nested contexts ak sauce reyèl pase. Pa gen
PATCH 14 ni brase final davans.
`LAST_COMPLETED_STAGE=28`, `EXPECTED_RED_VERIFIED`.

## Stage 29 — PATCH 14: detou baz M pou N>M

`wide_choice_patch.lua` konsève premye commit blokaj Stage 28,
verifye diagnostics, eta ak provenance li, epi ajoute yon dezyèm
commit `WIDE_CHOICE_REJECTION_PATCH`. Li itilize repons SAVE natif,
konbine chif yo an lòd pwa piti an premye, epi sote rejè kontig
avèk prèv limit olye iterasyon ki ka twò long. Pa gen okenn chwa
wide nan ansyen modil legacy, ni melanj final 12 brase yo.
Tès ak CI Stage 29 verifye sou run `38439596829`.

### Tès Stage 29 ki soumèt pou CI

Nou konpare chwa laj ak oracle endepandan, verifye
lòd chif baz M, limit akseptasyon, skippage matematik,
10 defayans/10 rekiperasyon, de apèl nested ak sauce.
Regresyon Stage 28 rete yon odit istorik; job Stage 28
pa echwe entansyonèlman apre PATCH 14. CI konfime.

### Fèmti natif Stage 29

GitHub Actions run `38439596829`: **39/39 travay PASS**.
Job `lua_stage29_patch` pase tout Stage 1–29, avèk
25 chwa laj kont oracle endepandan, rejè matematik
plis pase `2^64`, BigInt rive `M^5+1`,
10 defayans/10 rekiperasyon, de kontèks nested, de sous
sauce kanonik ak kat odit `EXPECTED_RED` Stage 28.
Chemen legacy short-only ak PATCH 13 pa chanje (hash lock PASS).
Pa gen okenn modil oracle nan production, ni melanj
`postStir12`, ni kòd Stage 30. Premye commit blokaj la
rete nan tras anvan dezyèm commit koreksyon wide la.
`LAST_COMPLETED_STAGE=29` / `EXPECTED_REPOSITORY_STATE=GREEN`.

## Stage 30 — DISCOVERY 15: siy etap pòtay negatif efase

Adaptè a resevwa etap pòtay siyen, epi premye commit la
kenbe valè li. Ansyen `oldGateQuestionDay` pa konn siy:
li ajoute yon distans pozitif sou jou Fondasyon an. Dezyèm
commit la sèvi ak `abs(signedStep)`, konsa etap negatif
`-n` mande bò pozitif `F+n` olye `F-n`.
Sa se defo istorik nou dwe konsève. Yon PATCH 15 pou
korije jou negatif yo ap vini sèlman nan Stage 31.
Pa gen rekalkil pòtay antye oswa `postStir12`.
CI native verifye: run `38444537164`.

### Prèv Stage 30 ki soumèt nan CI

Sètifika planifye: 300 kestyon siy ak twa distans BigInt,
8 erè/8 rekiperasyon, twa nested calls, twa sauce reyèl,
kat jobs pozitif, ak twa regleman `EXPECTED_RED` egzak.
Regresyon wouj final la dwe sèl echèk volontè CI a.
Pa gen PATCH 15 nan production. CI konfime: 43 travay pozitif pase; sèl echèk la se witness wouj final.

### Fèmti DISCOVERY 15 — prèv natif

Run `38444537164`: **43 travay pozitif pase**; yon job
`lua_stage30_discovery` echwe sèlman sou dènye etap
`EXPECTED_RED Stage 30 DISCOVERY 15 witness 1: negative gate sign lost`.
Tout tès Stage 1–30, 300 rekèt siy, twa BigInt gwo,
8 defayans/8 rekiperasyon, twa reentrances ak twa
koup sauce kanonik pase. Twa witness wouj yo odit egzak.
Diferans jou kestyon an se `F+n` olye `F-n` pou n>0.
Etap 31 ap repare l san efase prèv istorik la.
`LAST_COMPLETED_STAGE=30` / `EXPECTED_RED_VERIFIED`.

## Stage 31 — PATCH 15: kestyon pòtay avèk siy egzak

Nou kite `legacy_gate_question_adapter.lua` byte-pou-byte
entak. `gate_question_patch.lua` verifye de commits,
jou erone `F+abs(step)`, siy orijinal, provenance ak metrik.
Lè step negatif, li soustrè de fwa distans absoli a,
apre sa li verifye egzakteman `F+step`. Lè step pozitif
oswa zewo, li pa chanje kestyon istorik la. Yon twazyèm
commit posede anrejistre jou korije a, ansanm ak snapshot
eta semantik ansyen an. Public `gateQuestionDaySpaghetti`
retounen rezilta PATCH 15; sond legacy rete ansyen an.
Pa gen chèn pòtay antye oswa `postStir12`.
Rezilta CI konfime sou run `38456163489`: 48/48 travay pase.
### Fèmti PATCH 15 — Stage 31

Run GitHub Actions `38456163489`: **48/48 PASS**.
Suite konplè Stage 1–31 ak 301 chwa kestyon jou
oracle, 150 diferans negatif korije, twa distans BigInt,
10 erè/10 rekiperasyon, twa reentrances ak de koup
sauce kanonik pase. Twa prèv `EXPECTED_RED` Stage 30
rete oditab, modil legacy a toujou gen SHA
`d7c86d6c41c61de06816c681417caa035c0e5337`.
Patch la ajoute twazyèm commit apre de commits eritaj yo,
san gate sequence oswa postStir12.
`LAST_COMPLETED_STAGE=31` / `GREEN`.


## Stage 32 — DISCOVERY 16: +1 anplis nan longè pòtay

Nou itilize kestyon jou siyen ki deja korije nan PATCH 15,
ak rank 1..922 nan kòd natif PATCH 13. Ansyen fonksyon
`oldGateGapFromRank(rank)` toujou ajoute 42 olye 41.
Se poutèt sa longè pòtay la depase oracle pa youn nan
tout ka ki valab, menm si kestyon jou a ak rank la kòrèk.
Premye twa commits kestyon an rete; nou ajoute katriyèm
commit ki anrejistre rank, kestyon jou, ansyen offset
ak longè move a. Defòmasyon istorik la rete akeyir.
Tès ak CI Stage 32 poko verifye; PATCH 16 pa antre.

### QA DISCOVERY 16 ki soumèt nan CI

70 konparezon rank oracle ak tras 4 commits; 8 gwo
kestyon siyen BigInt; 10 defayans ak rekiperasyon;
twa reentrances ak de sauce natif. Twa witness
`EXPECTED_RED` endepandan verifye +1 anplis.
Kat jobs CI ajoute, youn gen dènye etap wouj ki
dwe echwe entansyonèlman sèlman. PATCH 13, PATCH 15
ak legacy sign-day anba kadna SHA.
Tès natif poko konfime.
