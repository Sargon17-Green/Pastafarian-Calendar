# Magouy Monstr Espageti a — Lua + Kreyòl ayisyen

Pwojè sa a se liy aplikasyon endepandan pou `Lua` ak lang sous imen `Kreyòl ayisyen`. Stage 1 la te kòmanse nan yon pyebwa vid. Li pa soti nan okenn lòt aplikasyon, li pa sèvi ak fixture, rezilta, tab jenere, hash, trace oswa oracle ki soti nan yon lòt liy.

## Sa Stage 1 genyen

- `src/bigint.lua`: aritmetik antye egzak ak presizyon abitrè, ekri an Lua sèlman.
- `src/source_language_catalog.lua`: katalòg sous ki jele pou 17 non kotlèt ak 47 non mwa; lòd semantik la se `canonicalIndex` sèlman.
- `src/monster_base.lua`: kontèks debaz, dispatcher debaz, validasyon debaz, anvlòp erè ak koki metrik. Pa gen okenn chemen legacy ni patch nan Stage 1.
- `src/spaghetti.lua`: koki production Stage 1. Fonksyon final la poko entegre, paske sa ta antre nan etap ki poko rive.
- `test/normative_oracle.lua`: oracle tès la, rekonstrui dirèkteman apati referans normatif ki te nan enstriksyon Stage 1 yo.
- `test/generate_stage01_fixtures.lua`: jeneratè fixture ki sèvi ak oracle Lua lokal la sèlman.
- `test/stage01_tests.lua`: runner tès Stage 1 la.

## Lang ak lòd non yo

Tout semantik non rete sou endis yo. Tèks Kreyòl la rezoud sèlman nan kouch prezantasyon an. Yon sort Unicode, yon collation lokal, majiskil/miniskil oswa yon tradiksyon lokal pa gen dwa antre nan rank, unrank, cache key semantik oswa chwa konbinatwa.

## Kouri tès yo

Nan anviwònman travay sa a, `texlua` bay yon runtime Lua 5.3. Tès yo rete kòd Lua nòmal epi yo pa rele okenn lòt runtime langaj.

```text
texlua test/generate_stage01_fixtures.lua <rasin-pwojè>
texlua test/stage01_tests.lua <rasin-pwojè>
```

Rezilta ki nesesè pou Stage 1 se `PASS Stage 1`.

## Limit istorik la

Stage 1 pa gen okenn nan 26 defo legacy yo ak okenn patch ki vin apre. Sa fèt espre: istwa a dwe grandi etap pa etap, epi Stage 2 sèlman ap gen dwa entwodui premye defo legacy a.

## Stage 2 — Discovery 01: rès òdinè a

Nou te ajoute `src/legacy_save.lua` kòm premye chemen pwodiksyon legacy a. Li itilize `BigInt.mod(x, M)` san koreksyon, epi `src/spaghetti.lua` ekspoze `saveSpaghetti(value)` kòm chemen otoritè pwovizwa a, ansanm ak `legacySaveProbe(value)` kòm chemen dyagnostik la, toude atravè dispatcher la. Fonksyon `calendarDateSpaghetti` la toujou poko pare; nou p ap fabrike yon rezilta kalandriye anvan etap entegrasyon an.

Nan etap sa a, `oldRemainder(M)`, `oldRemainder(2M)` ak `oldRemainder(3M)` bay zewo, pandan `SAVE` normatif la bay `M`. Pou `M+1`, toude bay 1. Nou kenbe erè a fè espre jouk Stage 3 — PATCH 01.

Pou egzamine tras yo ak kontra fonksyon yo san echèk:

```text
texlua test/stage02_trace_tests.lua .
texlua test/stage02_contract_tests.lua .
texlua test/stage02_boundary_tests.lua .
texlua test/stage02_expected_red_audit.lua .
```

Dènye tès ki nan gwoup sa a pran echèk tès ekivalans lan kòm done pou verifye **egzakteman** twa ka `M`, `2M`, `3M`; li pa ta dwe aksepte yon lòt erè kòm prèv Discovery. Tès limit yo kouvri 125 ka bò kote miltip `M` yo ak sis antye ki depase 256 bit. `saveSpaghetti` retounen yon sèl rezilta; `legacySaveProbe` retounen rezilta a ak kontèks dyagnostik la.

Pou tcheke tès tout Stage 1 yo, apre sa tras la epi echèk ekivalans ki obligatwa a:

```text
texlua test/stage02_tests.lua .
```

Nan checkpoint Stage 2 a, dezyèm kòmand lan te fini ak `EXPECTED_RED Stage 2 DISCOVERY 01`. Depi PATCH 01 nan Stage 3, li dwe pase: tès ekivalans `saveSpaghetti` la kounye a vèt, men odit `stage02_expected_red_audit.lua` toujou verifye menm twa diferans istorik yo sou `legacySaveProbe`. Konsa nou konsève prèv dekouvèt la san nou pa kite tès prensipal yo wouj.

## Yon lòt revizyon pwopriyete pou Stage 2

`test/stage02_property_tests.lua` fè 575 esè repwodiktib: 455 ka sou baryè `-32M` rive `32M` avèk deplasman `-3..3`, epi 120 ka ak antye long ak translasyon pa miltip `M`. Li teste idantite divizyon Eklidyen, izolasyon eta chak apèl, ak lefèt ke divèjans lan fèt sèlman pou rès zewo. `test/stage02_scope_tests.lua` verifye pa gen kòd patch Stage 3 ni import oracle nan kòd pwodiksyon an. Toude tès sa yo dwe pase anvan echèk ekivalans la.

```text
texlua test/stage02_property_tests.lua .
texlua test/stage02_scope_tests.lua .
```

## Stage 3 — PATCH 01: reparasyon SAVE a

`src/save_patch.lua` mete yon kouch ki rele `savePatch(x)` sou ansyen `oldRemainder(x)`: si rès la se zewo, kouch la retounen `M`; sinon li retounen rès la san chanjman. **`src/legacy_save.lua` rete idantik** ak vèsyon Discovery 01 la, epi `legacySaveProbe` kontinye montre ansyen defo a.

`saveSpaghetti` pase nan kouch patch la, pandan `savePatchProbe` retounen valè korije a ak kontèks de etap yo. Dispatcher la kenbe `LEGACY_SAVE` anvan `SAVE_PATCH`, de commit eta semantik, metrik apa, ak dyagnostik ki prezève ansyen rezilta a. Oracle normatif la rete sèlman nan `test/`.

Pou kouri tout etap ki deja ekri yo ansanm, sou Lua 5.3:

```text
texlua test/stage03_tests.lua .
```

Tès sa a kouri tout regresyon Stage 1 ak Stage 2, odit diferans legacy istorik la, ak tès PATCH 01 yo. Tout dwe pase; eta depo a se `GREEN`. Tès Stage 3 la kouvri 903 ka bò kote miltip `M`, 8 ka espesyal, 131 ranplasman zewo, eta ak tras, epi valè ki depase presizyon Lua natif la.

Pa entwodui okenn lòt defo istorik, ni koreksyon ki pou Stage 4 oswa apre.

## Stage 4 — DISCOVERY 02: nimewo jou legacy a

Nou ajoute `src/legacy_day_tag.lua` ak fonksyon istorik `oldDayTag(day) = 2 * abs(day - FOUNDATION)`. Nou itilize `BigInt` pou distans egzak, pou yon debòdman nan Lua pa fè nou dekouvri yon defo ki pa fè pati etap sa a. Nou konekte kalkil ki mal la ak yon handler `LEGACY_DAY_TAG` nan dispatcher pwodiksyon an. `dayTagSpaghetti(day)` se wout pwovizwa otoritè a; `legacyDayTagProbe(day)` ekspoze rezilta ak kontèks dyagnostik la.

Anvan jou Fondasyon an, legacy a bay menm valè ak oracle normatif la. Jou Fondasyon an li bay `0` olye de `1`; pou premye jou apre a li bay `2` olye de `3`. Erè a kontinye pou tout jou apre Fondasyon an. Sa pwouve ansyen sipozisyon ki te kwè yon nimewo jou ta toujou dwe pè.

Nou pa mete koreksyon Stage 5 la nan kòd pwodiksyon an: pa gen `dayTagWithFoundationScar`, pa gen koreksyon `+1`, pa gen guard espesyal pou jou Fondasyon an. Pwodiksyon `SAVE` ki te korije nan Stage 3 la rete vèt. Premye chemen `oldRemainder` rete san chanjman.

Pou kouri tès pozitif yo:

```text
texlua test/stage03_tests.lua .
texlua test/stage04_trace_tests.lua .
texlua test/stage04_property_tests.lua .
texlua test/stage04_scope_tests.lua .
texlua test/stage04_expected_red_audit.lua .
```

Tès pwopriyete yo kouvri 631 jou egzak, ladan yo 501 jou ozalantou Fondasyon an, 128 jou detèminis, ak de valè ekstremal antye Lua; yo verifye tou 65 pè simetrik. Yo pèmèt detekte erè presizyon, eta ki koule ak koreksyon prematire.

Nan eta Discovery 02 sa a, `texlua test/stage04_tests.lua .` oubyen `texlua test/stage04_regression_tests.lua .` dwe fini ak `EXPECTED_RED Stage 4 DISCOVERY 02` ki nonmen egzakteman kat ka: `FOUNDATION`, `AFTER_1`, `AFTER_2`, `AFTER_20`. Echèk la obligatwa jiskaske PATCH 02 rive nan Stage 5. Nan checkpoint Stage 4 la, CI te rapòte wouj entansyonèl nan travay `lua_stage04_discovery`; depi PATCH 02, tout travay CI yo dwe vèt epi odit istorik legacy a rete disponib.

## Stage 5 — PATCH 02: parite nimewo jou yo

Nou kite `src/legacy_day_tag.lua` san okenn chanjman. Nou ajoute `src/day_tag_patch.lua` pou aplike *egzakteman* koreksyon preskri a: pran `oldDayTag(day)`, ajoute yon inite si `day >= FOUNDATION`, epi tcheke yon **dezyèm guard istorik** sou jou Fondasyon an; si rezilta a pa `1`, fòse li tounen `1`. Guard sa a rete nan kòd la menm si premye kondisyon an deja fè li retounen `1`.

`dayTagSpaghetti(day)` kounye a retounen tag normatif la. `dayTagPatchProbe(day)` kenbe rezilta koreksyon an ak kontèks, epi `legacyDayTagProbe(day)` kontinye bay ansyen rezilta pè a. Dispatcher la anrejistre `LEGACY_DAY_TAG` anvan `DAY_TAG_PATCH`, epi li itilize de komèt eta semantik ki posede separeman, metrik ak dyagnostik diferan. Nou pa itilize oracle tès la nan production. PATCH 01 pou `SAVE` rete entak.

Nou adapte tès Stage 4 yo pou fè regresyon pwodiksyon an vèt, pandan odit `EXPECTED_RED` la toujou verifye kat diferan rezilta istorik yo lè li rele **chemen legacy a**. Sa konsève prèv Discovery 02 la san li pa bloke Stage 5. Tès Stage 5 la egzamine 2,001 jou youn apre lòt sou baryè Fondasyon an, 320 lòt jou repwodiktib ak kat valè toupre limit antye Lua; li verifye de tras dispatcher, guard la, izolasyon, parite ak egalite ak oracle test-only la.

```text
texlua test/stage05_tests.lua .
```

Tout tès yo dwe pase (`GREEN`). Nou pa ajoute `oldDistance` ni okenn lòt eleman Stage 6 oswa Stage 7.

## Stage 6 — DISCOVERY 03: move distans ant tag jou yo

Nou ajoute `src/legacy_distance.lua` ak erè istorik `oldDistance(c,t) = abs(dayTag(c)-dayTag(t))`. Pou jwenn **tag** yo, kòd la rele `DayTagPatch.execute` ki soti nan Stage 5 pou chak jou. Konsa sa se yon chemen pwodiksyon reyèl, pa yon tès ki fè kòm si dispatcher la mache. `distanceSpaghetti(c,t)` retounen valè legacy ki mal la; `legacyDistanceProbe(c,t)` retounen valè a ak kontèks dyagnostik la. Yon nouvo handler `LEGACY_DISTANCE` kenbe antre, toude tag yo, repons lan ak de kontèks entèmedyè yo, avèk yon commit eta semantik apa.

Distans normatif la se `abs(t-c)+1`, epi li pa egal diferans tag yo an jeneral. Pou menm jou Fondasyon an kòm kalkil ak sib, legacy a bay `0` men distans normatif la se `1`. Pou `FOUNDATION-1` rive `FOUNDATION+1`, legacy a bay `1` men règ normatif la bay `3`. Gen ka vwazen kote ansyen kalkil la rive bay repons ki kòrèk la pa aza; se pou sa tès yo kouvri toude rezilta.

Tès pwopriyete yo kouvri yon kadriyaj `37 x 37`, 256 pè detèminis ak uit pè sou limit antye Lua; yo verifye ekivalans ak diferans tag yo, simetri, epi izolasyon eta. Odit `EXPECTED_RED` la egzije *sèlman* senk divergences `SELF`, `ACROSS`, `LONG_BEFORE`, `LONG_AFTER`, `REVERSE_CROSS`. Tout tès yo nan Stage 1–5 rete vèt.

```text
texlua test/stage06_trace_tests.lua .
texlua test/stage06_property_tests.lua .
texlua test/stage06_scope_tests.lua .
texlua test/stage06_expected_red_audit.lua .
texlua test/stage06_tests.lua .
```

Nan checkpoint Stage 6 la, dènye kòmand lan te fini ak **`EXPECTED_RED Stage 6 DISCOVERY 03`**. Apre PATCH 03, regresyon pwodiksyon an pase; odit la toujou egzije menm senk diferans istorik yo atravè `legacyDistanceProbe`. Nan checkpoint Stage 6 la, te gen ni kalkil `chronological = abs(t-c)`, ni konparezon ki ranplase legacy a, ni adisyon `+1` nan chemen pwodiksyon an; se Stage 7 sèlman ki ajoute etap sa yo. `oldRemainder`, `oldDayTag`, `savePatch` ak `dayTagWithFoundationScar` rete san okenn chanjman.

## Stage 7 — PATCH 03: distans kwonolojik enklizif

Nou kite `src/legacy_distance.lua` **san okenn chanjman**. Nou ajoute `src/distance_patch.lua`: li rele `LegacyDistance.execute(c,t)` ak tout chemen `DAY_TAG_PATCH` la, li kalkile `chronological = abs(t-c)` an BigInt, li konpare rezilta istorik la ak valè kwonolojik la, epi li ranplase ansyen valè a **sèlman si de valè yo diferan**. Finalman, li ajoute `1` pou jwenn distans enklizif `abs(t-c)+1`. Nou kenbe branch kote de valè yo deja egal, menm si li ka sanble redondan; li fè pati kontra istorik PATCH 03 la.

Fonksyon `distanceSpaghetti(c,t)` pase nan nouvo `DISTANCE_PATCH` handler la. `distancePatchProbe(c,t)` bay rezilta korije a ak kontèks ki konsève `LEGACY_DISTANCE` ak `DISTANCE_PATCH`, de tranzaksyon ki fini, de kontèks tag ki deja korije, metrik ak dyagnostik. `legacyDistanceProbe(c,t)` kontinye bay ansyen distans ki mal la pou analiz. Pa gen okenn oracle normatif nan kòd pwodiksyon, pa gen okenn pyès Stage 8 oswa Stage 9.

Depi Stage 7, regresyon `test/stage06_regression_tests.lua` vin **GREEN**, men `test/stage06_expected_red_audit.lua` kontinye verifye egzakteman senk ansyen diferans yo sou `test/stage06_legacy_regression_tests.lua`. `test/stage06_trace_tests.lua` ak `test/stage06_property_tests.lua` kontinye egzamine ansyen konpòtman an via `legacyDistanceProbe`, epi yo egzije pwodiksyon korije a. Sa konsève eksperyans Discovery 03 la.

Tès patch yo kouvri **2,665 pè jou**: mayaj 49 × 49 bò Fondasyon an, 256 pè detèminis, ak 8 limit Lua, ki gen ladan `math.mininteger` ak `math.maxinteger`. Yo verifye tou simetri, apèl repete, branch rekonsilyasyon kont branch san ranplasman, de handler, metrik, dyagnostik ak izolasyon kontèks.

Pou kouri tout etap 1 rive 7 yo ak Lua 5.3:

```text
texlua test/stage07_tests.lua .
```

Tout tès yo dwe pase epi GitHub Actions dwe rapòte `GREEN`. Pou konpare ak ansyen defo a, sèlman `test/stage06_legacy_regression_tests.lua` dwe toujou echwe entansyonèlman; runner prensipal la pa kouri li kòm tès vèt.

## Stage 8 — DISCOVERY 04: wòch yo chanje youn apre lòt

Nou ajoute `src/legacy_stones.lua` avèk premye fonksyon istorik `mutateStonesWrong(i, S)`. Li ekri senk nouvo valè yo nan **menm tablo `S` a**, youn apre lòt, nan lòd `w → b → s → m → r`. Li toujou rele `SavePatch.savePatch`, ki te deja korije nan Stage 3, men li li nouvo `w`, `b`, `s`, ak `m` yo twò bonè. Nou pa ajoute okenn snapshot reparatè ni okenn koreksyon Stage 9.

Nan checkpoint Stage 8 la, `stoneSpaghetti(i, stones)` ak `legacyStoneProbe(i, stones)` te pase atravè handler `LEGACY_STONES` la. Depi Stage 9, `stoneSpaghetti` pase nan nouvo `STONE_PATCH`, pandan `legacyStoneProbe` kontinye sou chemen istorik la. Chak invocation posede kopi done li yo, yon eta semantik tranzaksyonèl, tras, metrik, ak dyagnostik. Wout `stoneTableSpaghetti()` bati tout 46 ranje depi `{w=17,b=29,s=43,m=71,r=101}` atravè menm dispatcher legacy a. Referans odit yo rete sèlman nan `test/`; kòd pwodiksyon an pa enpòte yo.

Nan ranje 2, wòch `w` se `378` sou toude chemen yo. Men rès rezilta legacy yo se `b=1434`, `s=3780`, `m=9932`, `r=25047`, kont valè snapshot normatif `b=1073`, `s=2375`, `m=6195`, `r=10493`. Kat diferans sa yo fòme prèv egzak `EXPECTED_RED Stage 8 DISCOVERY 04`; odit separe a refize nenpòt lòt mesaj erè.

Tès pwopriyete yo valide 410 tranzisyon: 45 ranje tab aktyèl la, 125 konbinezon baryè, epi 240 gwo antye detèminis ki rive pi lwen pase 256 bit. Yo verifye valè legacy yo kont yon referans test-only endepandan, kantite ranje yo ak izolasyon done yo. Depi Stage 9, yo verifye se pwodiksyon korije a ki matche ak snapshot normatif la. Yo verifye tou ke tout senk rezilta yo rete nan entèval `[1,M]`.

```text
texlua test/stage08_trace_tests.lua .
texlua test/stage08_property_tests.lua .
texlua test/stage08_scope_tests.lua .
texlua test/stage08_expected_red_audit.lua .
texlua test/stage08_tests.lua .
```

Nan checkpoint Stage 8 la, dènye kòmand lan te fini ak `EXPECTED_RED Stage 8 DISCOVERY 04`. Depi PATCH 04, tout kòmand yo dwe pase. Odit istorik la rele `stage08_legacy_regression_tests.lua` atravè `legacyStoneProbe` pou konsève egzakteman kat diferans orijinal yo.


## Stage 9 — PATCH 04: senk wòch soti nan yon sèl snapshot

Nou kite `src/legacy_stones.lua` ak `mutateStonesWrong` **san chanjman**.
Nou ajoute `src/stone_patch.lua` ki fè twa operasyon obligatwa, nan lòd:
pran yon snapshot posede `old`, fè yon apèl **reyèl** bay fonksyon legacy a sou yon clone pou jwenn `garbage`, epi **ranplase tout senk rezilta** nan `garbage` ak fòmil ki li sèlman `old`.
`SavePatch.savePatch` rete operasyon modulo korije a; oracle normatif la rete sèlman nan `test/`.

`stoneSpaghetti(i,S)` itilize `STONE_PATCH` atravè dispatcher la. `stonePatchProbe(i,S)` retounen valè ak kontèks de handler yo, `LEGACY_STONES` apre `STONE_PATCH`. Nou toujou ekspoze `legacyStoneProbe` pou mezire erè istorik la. De komèt eta semantik, de tras, metrik, dyagnostik, ak rezilta legacy anvan ranplasman rete vizib nan chak kontèks. `stoneTableSpaghetti()` konstwi tout 46 ranje yo avèk patch la: li pa sote premye fonksyon legacy a ni li pa sèvi ak yon tab prepare davans.

Regresyon `test/stage08_regression_tests.lua` kounye a dwe vèt. `test/stage08_legacy_regression_tests.lua` rete wouj entansyonèlman, epi `test/stage08_expected_red_audit.lua` kontinye egzije mesaj kat diferans yo san okenn tolerans pou lòt echèk. Yon seri test Stage 9 ajoute 455 tranzisyon sou tab la, baryè modil, gwo antye, ak tout index legal yo; tès Stage 8 yo rete aktif.

```text
texlua test/stage09_tests.lua .
```

Rezilta obligatwa a se `GREEN` pou tout tès ak travay GitHub Actions. Pa gen okenn defo oswa patch Stage 10 oswa pita ki antre nan branch sa a.


## Stage 10 — DISCOVERY 05: sèt gout kache yo estoke nan move sans

Nan etap sa a nou mete yon chemen pwodiksyon reyèl pou sèt gout kache yo.
`src/legacy_hidden.lua` pran konte jou nan kouch `DAY_TAG_PATCH` ak `DISTANCE_PATCH`,
li bati sèt premye ranje wòch yo nan `STONE_PATCH`, epi li kalkile chak gout ak
koefisyan kanonik yo, sèt tounaj yo ak `SavePatch.savePatch`.

**Erè istorik la konsène depo a, pa kalkil gout la.** Chak gout lojik `k`
ale nan plas fizik `8-k`, konsa tablo a gen `hidden7, hidden6, ..., hidden1`.
Chemen piblik `hiddenDropsSpaghetti(c,t)` retounen depo sa a, epi
`hiddenDropSpaghetti(c,t,k)` li plas `k` san tradiksyon. Se yon vrè divèjans
ak referans normatif la. Yon kontèks `LEGACY_HIDDEN` kenbe sèt plas fizik yo,
tranzaksyon, metrik, tras, dyagnostik ak prèv izolasyon ant invocation.

Tès yo verifye endepandamman, atravè `test/normative_oracle.lua`, ke tout sèt
**valè** yo kòrèk men sis **pozisyon** yo mal; pozisyon 4 la pa deplase lè
yon lis sèt eleman ranvèse. Tès espesyal sou Fondasyon an kouvri sèt rezilta
egzak; tès pwopriyete yo kouvri senk koup jou diferan. Tout etap 1–9 rete
vèt.

```text
texlua test/stage10_trace_tests.lua .
texlua test/stage10_property_tests.lua .
texlua test/stage10_scope_tests.lua .
texlua test/stage10_expected_red_audit.lua .
texlua test/stage10_tests.lua .
```

Nan checkpoint Discovery 05 la, kat premye tès yo te pase, epi dènye a te fini ak
`EXPECTED_RED Stage 10 DISCOVERY 05: 6 hidden drops nan move plas: 1,2,3,5,6,7`.
Depi Stage 11, runner piblik la dwe pase tou, pandan odit la kenbe erè legacy a.

**Nan Stage 10, pa t gen PATCH 05.** Chemen legacy a toujou pa fè tradiksyon `8-k`;
sèlman nouvo kouch Stage 11 lan ranje lekti a. Nou pa ranvèse depo fizik la.


## Stage 11 — PATCH 05: lekti pa endis `8-k` san chanje depo a

Nou kite `src/legacy_hidden.lua` san okenn chanjman: li toujou estoke
`hidden7, hidden6, ..., hidden1`, epi `oldHiddenAt(storage,k)` toujou li
`storage[k]` dirèkteman. Nou ajoute `src/hidden_patch.lua`, avèk fonksyon
`hiddenByNearness(storage,k)` ki sèvi ak apèl legacy a sou **endis `8-k`**.
Pa gen envèsyon tablo fizik la, pa gen kopi oracle tès nan production, epi
pa gen entwodiksyon `legacyPrior` ki rezève pou Stage 12.

`hiddenDropsSpaghetti(c,t)` ak `hiddenDropSpaghetti(c,t,k)` kounye a bay
sèt gout yo nan bon lòd normatif. `hiddenPatchProbe(c,t)` retounen rezilta
ak kontèks dispatcher li; `legacyHiddenProbe(c,t)` kontinye ekspoze
vye depo a. Menm kontèks `LEGACY_HIDDEN` la ajoute `HIDDEN_PATCH`: de
tranzaksyon, de tras, metrik pou sèt tradiksyon endis yo, ak dyagnostik
ki montre plas fizik 1 a pa chanje. Tout BigInt ak lis rezilta yo posede
apa ant invocation yo.

`test/stage10_regression_tests.lua` retounen vèt. Nou konsève
`test/stage10_legacy_regression_tests.lua` ki toujou echwe ak sis pozisyon
istorik egzak yo, epi `test/stage10_expected_red_audit.lua` verifye li.
Nou ajoute 252 konparezon pozisyon sou 36 pè jou diferan, ansanm ak
verifikasyon `BigInt`, transfòmasyon konteks, izolasyon ak antre ki pa valab.

Pou kouri tout suite a sou branch konplè a, avèk Lua 5.3:

```text
lua5.3 test/stage11_tests.lua .
```

Rezilta konfime sou GitHub Actions: **GREEN**, sis travay PASS, tout etap 1–11. Pa demare Stage 12 anvan etap sa a fini; etap 11 la kounye a verifye.


### Verifikasyon konbinatwa PATCH 05

`test/stage11_index_properties.lua` teste tout 5,040 permutasyon posib sèt plas fizik yo (35,280 lekti). Li kouvri zewo, siy negatif, baryè SAVE, de gwo antye ki depase 256 bit, aksè fizik legacy san chanjman, epi rejè endis ilegal. Tès sa a pa chanje lòd depo a; li egzamine sèlman tradiksyon lekti `8-k`. Li kouri ansanm ak tout tès Stage 1–11 nan `test/stage11_tests.lua`.


### Tès enjeksyon echèk PATCH 05

`test/stage11_fault_injection_tests.lua` verifye tout sèt pozisyon kote
`oldHiddenAt` ka voye yon erè, yon erè anvan legacy retounen depo a,
ak sèt ka kote yon plas fizik manke. Apre chak echèk, yon nouvo apèl
dwe retounen sèt valè kòrèk ak de commit; yon echèk pa dwe kite eta
yon lòt invocation domaje. Li verifye tou lòd aksè fizik `7,6,...,1`
ak absans pataj BigInt, menm nan limb entèn yo lè yo aksesib.
Tès sa a kouri nan `stage11_tests.lua`; li pa modifye kòd pwodiksyon.


## Stage 12 — DISCOVERY 06: history pa jwenn sèt gout kache yo

Nou mete ansyen `legacyPrior(dropStore,i,back)` la nan `src/legacy_prior.lua`.
Li li `dropStore[i-back]` sèlman. Pou jou vizib nimewo 1, ak
`back=1..7`, li mande plas 0, -1, ..., -6. Plas sa yo pa egziste
nan depo vizib òdinè a, menm si sèt gout kache korije yo disponib nan
`HiddenPatch.execute`. Nou fè yon apèl reyèl nan kouch hidden sa a
pou konsève prèv depandans, men legacy a inyore rezilta li.

Nou ajoute `priorSpaghetti` ak `legacyPriorProbe` nan fasad piblik la.
Handler `LEGACY_PRIOR` anrejistre plas kalkile a, si li jwenn done,
yon sèl komit, yon tras, metrik, dyagnostik epi yon kontèks hidden
entèmedyè konplè. Valè vizib ki egziste yo toujou li kòrèkteman; plas
hidden yo rete manke. Li pa panse rive nan HiddenPatch pou korije sa.

Nan `test/stage12_regression_tests.lua`, nou egzije yon prèv
`EXPECTED_RED` sou egzakteman sèt plas 0 rive -6. Odit separe a
verifye mesaj erè a. Tès tras ak pwopriyete yo pwoteje lekti vizib,
entegrite BigInt, kopye depo, eta tranzaksyonèl, ak lefèt ke legacy pa
konnen yo ka li gout kache yo.

`lua5.3 test/stage12_tests.lua .` dwe echwe sèlman nan dènye
regresyon an, apre tout tès Stage 1–11 ak odit Stage 12 yo fin pase.

**Pa mete PATCH 06 nan Stage 12.** Li rezève pou Stage 13: si slot >= 1,
rele legacy; sinon k=1-slot epi li gout hidden k nan kouch PATCH 05 la.

## Stage 13 — PATCH 06: history jwenn gout kache yo san efase legacy a

Nou kenbe `src/legacy_prior.lua` orijinal la byte-pou-byte: fonksyon
`LegacyPrior.legacyPrior(dropStore,i,back)` la toujou li sèlman
`dropStore[i-back]`. Nan nouvo `src/prior_patch.lua`, wout prodiksyon an
premye fè yon **apèl reyèl** nan `LegacyPrior.execute`, ki li history
ansyen an epi ki deja rele `HIDDEN_PATCH` pou sèt gout yo. Lè sa a, nou
ajoute handler `PRIOR_PATCH` sou **menm kontèks** la ak yon dezyèm commit.

Pou `slot=i-back >= 1`, patch la rele fonksyon legacy a toutbon epi li
kenbe valè vizib la. Pou `slot <= 0`, patch la kalkile `hiddenK=1-slot`,
li rekonstwi sèt plas **fizik** yo nan eta `nestedHiddenContext` ki te
sòti nan premye apèl la, epi li rele
`HiddenPatch.hiddenByNearness(physical, hiddenK)`. Sa sèvi ak koreksyon
`8-k` ki te deja egziste nan Stage 11; pa gen envèsyon tab fizik la,
pa gen doub oracle oswa rekalkil pa yon lòt lang, epi pa gen chanjman
nan kòd istorik la.

`priorSpaghetti` kounye a sèvi ak `PRIOR_PATCH`; `priorPatchProbe`
retounen repons lan ansanm ak kontèks pou de handler yo. Ansyen
`legacyPriorProbe` la rete pou teste sèt mank history orijinal yo.
`stage12_legacy_regression_tests.lua` toujou bay sèt pozisyon manke,
men `stage12_regression_tests.lua` vin **GREEN**: li konpare tout sèt
pozisyon yo ak oracle test-only la. Odit EXPECTED_RED la toujou egzije
menm mesaj istorik la sou **chemen legacy apa** a.

Tès Stage 13 yo egzamine 1,344 lekti nan 24 koup jou (672 hidden ak
672 vizib), gwo antye >256 bit, modifikasyon done nan yon kontèks,
plas ki manke, validasyon, de commit ak 22 echèk izole ki gen
15 rekiperasyon. Tès sa yo pase lokalman avèk doublon depandans;
`lua5.3 test/stage13_tests.lua .` nan GitHub Actions dwe pase tout
etap 1 rive 13 sou runtime Lua natif la.

**Pa kòmanse Stage 14 la.** Okenn tab grind sentinel pa antre nan branch sa a.

### Konfimasyon GitHub Actions Stage 13

Run `38229918405` te pase tout **sèt** travay yo sou Lua natif.
Lòd history vizib ak sèt hidden yo matche ak oracle la; odit legacy
Stage 12 la toujou montre egzakteman sèt mank istorik yo.
Rezilta: `STAGE13_NATIVE_SUITE=PASS`, `STAGE13_REMOTE_CI=PASS`.


## Stage 14 — DISCOVERY 07: tablo onz tounaj yo gen endis ki pa bon

Nou ajoute `src/legacy_grinds.lua` ak tablo istorik 11 ranje tounaj yo,
men tablo sa a sèvi ak endis fizik `0..10`. Ansyen `oldGrindRow(g)`
mande `ORIGINAL_ROWS[g]` pou tounaj lojik `g=1..11`. Se konsa premye
dis tounaj yo pran ranje ki vin apre a, epi tounaj nimewo 11 la pa gen
okenn ranje. **Sa se erè indexing ansyen an, pa yon koreksyon.**

Tablo koefisyan yo gen onz ranje kòrèk yo, men nan plas fizik ki mal yo:
`{3,5,7,11,w}` nan plas 0, `{5,7,11,13,b}` nan plas 1,
jiska `{37,41,43,47,w}` nan plas 10. Nou kenbe
`originalPhysicalRow` ak `oldGrindRow` ansanm pou odit, epi nou ajoute
handler `LEGACY_GRIND_INDEX` ak yon commit, yon tras, metrik ak
dyagnostik `GRIND_ROW_SHIFTED_BY_ONE` oubyen `GRIND_11_ROW_MISSING`.

Nan fasad `spaghetti.lua`, `grindRowSpaghetti` sèvi ak menm
handler istorik la. `visibleDropSpaghetti` itilize kalkil jou, wòch,
`PRIOR_PATCH` pou p1/p3/p7, ak `SAVE_PATCH`, epi li eseye fè
11 tounaj reyèl atravè legacy. Apre 10 tounaj, li jwenn ranje
nimewo 11 ki manke. Li retounen yon rapò dyagnostik, pa yon gout
normatif envante.

`test/stage14_property_tests.lua` verifye onz ranje fizik yo, dis
deplasman ak yon mank. Odit `EXPECTED_RED` la mande egzakteman
11 divergences (`1..11`), avèk dènye ranje a ki manke.
`test/stage14_visible_smoke_tests.lua` egzèse wout gout vizib la
avèk vrè sous Lua anvan li rive nan erè history la.

```text
lua5.3 test/stage14_property_tests.lua .
lua5.3 test/stage14_scope_tests.lua .
lua5.3 test/stage14_visible_smoke_tests.lua .
lua5.3 test/stage14_expected_red_audit.lua .
lua5.3 test/stage14_tests.lua .
```

Kat premye tès yo dwe pase; dènye a dwe bay `EXPECTED_RED Stage 14
DISCOVERY 07` pou onz ranje yo sèlman. Tout regresyon Stage 1–13
dwe rete vèt.

**Pa gen PATCH 07 nan Stage 14.** Stage 15 sèlman pral kreye yon
tab ak sentinel fizik nan endis 0 epi onz tounaj reyèl 1..11,
san efase fonksyon legacy a ni sa li te fè.


## Stage 15 — PATCH 07: sentinel nan plas 0, onz grind nan plas 1..11

Nou pa modifye src/legacy_grinds.lua: oldGrindRow(g) kontinye mande move ranje
nan depo istorik 0..10 epi li pa jwenn ranje 11. Kouch src/grind_patch.lua
rele fonksyon legacy a reyèlman anvan koreksyon. Li bati buildWithSentinel()
ak yon ranje {0,0,0,0,NONE} nan endis 0 ak onz ranje reyèl endis 1..11.
Chak nouvo ranje g soti nan LegacyGrinds.originalPhysicalRow(g-1), san
efase ni reekri tablo istorik la.

grindRowSpaghetti ak grindPatchProbe itilize GRIND_PATCH. Kontèks la
kenbe de komit, de tras, done istorik, done korije, metrik ak dyagnostik.
legacyGrindProbe rete sou chemen orijinal la.

visibleDropSpaghetti itilize PRIOR_PATCH, STONE_PATCH ak SAVE_PATCH ansanm
ak onz grind korije yo. legacyVisibleDropProbe rete disponib pou
montre mank onzyèm grind istorik la.

Regresyon Stage 14 la vin vèt pou tout onz ranje yo. Nou kenbe
stage14_legacy_regression_tests.lua ki toujou bay onz diferans istorik
ak odit EXPECTED_RED egzak. Tès Stage 15 verifye 11 ranje, de tranzaksyon,
izolasyon, endis ilegal ak nèf gout vizib sou twa pè jou kont oracle
test-only la (99 grind nan total).

Kòmand suite konplè: lua5.3 test/stage15_tests.lua .
Rezilta espere: GREEN. Pa gen kòd Stage 16 ni permutation ranking.


### Konfimasyon natif Stage 15

GitHub Actions run 38237011389 te pase tout uit travay yo.
Suite Lua Stage 1–15 la konfime onz ranje yo, sentinel fizik la,
99 grind nan nèf gout vizib normatif, ak EXPECTED_RED legacy a
kòm yon odit ki rete toujou aktif. Rezilta: GREEN.

## Stage 16 — DISCOVERY 08: rang one-based voye bay unrank0

Nan premye chemen pou lòd sis bòl yo, nou ajoute `src/legacy_permutation.lua`.
Fonksyon istorik `oldPermutationUnrank0(rank0)` kòrèk pou **tout** rang
`0..719`: yon dekonpozisyon factoradic bay permutasyon leksikografik sis
idantite `1..6`. Men chemen k ap rele li a kalkile nimewo **one-based**
`1..720` apati valè gout la epi li voye nimewo sa a dirèkteman bay
fonksyon ki mande rang **zero-based**. Sa se erè ki pou Stage 16, pa yon
koreksyon ki pou Stage 17.

Handler `LEGACY_ONE_BASED_RANK` kalkile rang gout la avèk BigInt egzak;
handler `LEGACY_PERM_UNRANK0` anrejistre apèl ki mal la. Kontèks yo posede
apa epi yo kenbe de commit, de tras, metrik, dyagnostik ak ranje ki manke
lè rang one-based la egal `720`. 

Nou ekspoze `permutationSpaghetti(drop)` ak `legacyPermutationProbe(drop)`
nan fasad `src/spaghetti.lua`. Kòd pwodiksyon an pa enpòte oracle tès la.

**Prèv DISCOVERY 08:** pou 719 premye rang yo, rezilta legacy a deplase
nan pwochen permutasyon. Pou rang `720`, fonksyon 0-based la rejte rang
nan. Tès odit la egzije egzakteman mesaj sa a:

`EXPECTED_RED Stage 16 DISCOVERY 08: 719 rang deplase, rang 720 rejte`

`test/stage16_factoradic_tests.lua` pase nan 720 permutasyon endepandan ak
yon jeneratè leksikografik Lua. `stage16_property_tests.lua` verifye
719 deplasman ak rejè rank 720 ak oracle branch sa a; `stage16_boundary_tests.lua`
verifye 147 valè, enkli gwo antye >256 bit; `stage16_fault_injection_tests.lua`
kouvri 13 echèk ki pa kontamine nouvo invocation. Yon erè factoradic
oswa yon eksepsyon dependency, menm sou rank 720, pwopaje kòm erè reyèl;
sèlman refi range istorik 720 la vin rezilta MISSING pou odit.

Apre upload, kouri tout suite Stage 1–15 ak tès pozitif Stage 16 yo, epi
kite sèlman tès regresyon normatif Stage 16 la wouj. **Pa mete PATCH 08,
pa fè konvèsyon `legacyRank0=oneBased-1`, pa demare Stage 17.**

### Entegrasyon gout vizib reyèl yo

`test/stage16_visible_integration_tests.lua` pran nèf gout nan
`visibleDropSpaghetti` sou twa koup jou, atravè vrè kouch PATCH 07.
Li konpare ansyen lòd rank la ak oracle branch la, egzije ke pwodiksyon
kenbe erè one-based la (oswa rejè 720), epi pwouve ke Stage 17 poko antre.
Tès sa a mande tout kòd branch natif la; QA ak doublon pa ka sètifye li.


### Fail-closed sou erè unrank0 (ranfòsman QA Stage 16)

Nou pa konpare fragman mesaj erè pou rekonèt rejè rang 720 ankò.
Validatè `requireRank0` la voye yon token prive ki gen yon mesaj
li ka afiche nòmalman; se idantite token sa a sèlman ki ka tounen
`LEGACY_PERM_RANK_OUT_OF_RANGE`, epi sa fèt sèlman pou rang 720.
Yon lòt panik, menm si li pote menm tèks la, rete yon echèk reyèl.
`test/stage16_error_identity_tests.lua` enjekte sis kalite fo erè ak
sis apèl rekiperasyon, san okenn koreksyon sou ansyen erè 1..720 lan.


### Prèv ke refi rank 720 soti nan validatè orijinal la (QA v004)

Menm token prive yon validatè te deja voye kapab rete nan men yon
wrapper oubyen yon fonksyon ranplase. Se poutèt sa, nan chemen
`LEGACY_PERM_UNRANK0`, nou egzije **tou de** idantite token sa a
**ak** idantite fonksyon `oldPermutationUnrank0` orijinal la anvan
nou aksepte yon refi rank 720 kòm `MISSING`. Si yon wrapper rele
fonksyon orijinal la men rejwe erè a, sa rete yon erè ki dwe pwopaje.
`test/stage16_authentic_validation_tests.lua` kouvri de atak sa yo
ak de invocation pwòp apre sa. Nou pa modifye dezakò 719/720 a.


### Pa teste idantite yon fonksyon apre li fin kouri (ranfòsman v005)

Anvan nou rele `oldPermutationUnrank0`, nou kenbe referans
`invokedUnrank` ki pral egzekite reyèlman. Nou sèvi ak referans sa a
pou verifye provenans erè a: yon wrapper pa ka retabli chan tab la
ak fonksyon orijinal la **apre apel la komanse men anvan li voye
token an**. Twazyèm ka adversarial la pwouve pwoteksyon sa a.


### Peryodisite ran yo atravè gwo antye (QA v006)

`test/stage16_periodicity_tests.lua` verifye **2,199** invocation sou tout
720 klas ran yo, ansanm ak `+720`, `-720` ak antye desimal ki depase
plizyè santèn chif. Kalkil rezidi tès la sèvi ak chif desimal yo dirèkteman,
pa fonksyon modulo BigInt ki nan production. Kontra sa a kenbe erè
legacy a: 2,189 rang yo deplase, 10 eksepsyon rang 720 jwenn refi
historik. Tès mutation separe a pwouve ke yon erè modulo sou kantite
negatif yo pa ta kache anba `EXPECTED_RED`. Sa PA fè PATCH 08 antre.

### QA adisyonèl Stage 16: entèlasman ak tounaj istorik yo

Nou verifye 360 BigInt ki gen ant 70 ak 246 chif, avèk 720 apèl
endepandan pou konteks, tras, metrik ak kopi rezilta yo. Yon mutasyon
ki fòse pataj konteks la fè tès la echwe.

Nan QA_ONLY sèlman, nou rasanble vrè modil Lua Stage 14, 15 ak 16:
onz ranje sentinel korije, onz aksè legacy ki toujou mal, ak
55 lekti rank sou menm fasad. Se sèlman bigint ak MonsterBase nou
ranplase ak doublon nan QA sa a. Tout tès sa yo pase lokalman, men
sa pa egal yon PASS sou suite natif Stage 1..16.

### QA sou apèl rekiran nan Stage 16

`test/stage16_reentrancy_tests.lua` fè uit apèl nested pandan dispatcher
rank one-based oubyen unrank0 a poko fini. Li egzije uit kontèks outer ak
uit kontèks inner endepandan, de commit pa apèl, menm lòd legacy ki mal
pou rank 1..719, epi de panik ki pa gen dwa kache anba erè rank 720.
Tès mutation `QA_ONLY/verify_reentrancy_mutant.lua` fòse tout apèl pataje
menm kontèks la; tès sa a detekte erè a. Kòd pwodiksyon an pa chanje.
Rezilta lokal yo sèvi ak doublon BigInt ak MonsterManager sèlman;
`FULL_NATIVE_SUITE` rete PENDING.

## Stage 17 — PATCH 08: korije rang lòd sis bòl yo

Nan Stage 16, chemen istorik la toujou transmèt rank one-based bay
`oldPermutationUnrank0` san -1. Sa kenbe 719 lòd ki deplase ansanm ak
sèl rejè rank 720 la. Nan Stage 17, `src/permutation_patch.lua` fè
chemen istorik sa a kouri an premye, apre sa li pase `oneBased-1` bay
vrè fonksyon zero-based la. Nou ekspoze koreksyon an atravè
`Spaghetti.permutationSpaghetti` ak `Spaghetti.permutationPatchProbe`;
`Spaghetti.legacyPermutationProbe` kontinye montre defo orijinal la.

PATCH 08 konsève dyagnostik ak twa handler nan kontèks la, verifye rank
factoradic la ansanm ak sis id bòl diferan, retounen kopi posede,
epi kite tout erè depandans pwopaje. Li pa ajoute okenn operasyon
pou vide, melanje oubyen tounen bòl yo.

Suite `test/stage17_tests.lua` teste prèv legacy a, 720 rank, 237 antre
BigInt laj oubyen negatif, 15 piki erè, 9 gout vizib reyèl, 180 ka entèlasman ak 8 apèl nested.
Nan CI, odit EXPECTED_RED Stage 16 la tounen yon verifikasyon pozitif
ki egzije menm mesaj echèk istorik la. Stage 17 pa dwe vin COMPLETE
anvan tout travay natif CI yo pase.

### Prèv final natif Stage 17

GitHub Actions `38266889952` fin pase tout 10 travay yo. Suite Lua
Stage 1–17 la bay 720/720 rank kòrèk, 237 ka BigInt, 15 piki
ak 15 rekiperasyon, 9 gout vizib reyèl, 180 entèlasman (360 apèl),
ak 8 apèl nested. Odit Stage 16 lan toujou detekte 719 rank
deplase ak sèl rejè rank 720 la. PATCH 08 fèmen; pa gen okenn
kòd pou brase bòl ki antre.

## Stage 18 — DISCOVERY 09: twa vide sou id bòl fiks

Fonksyon `src/legacy_fixed_pours.lua` kalkile sis bòl inisyal yo ak
PATCH 01/02/03, epi li resevwa lòd sis bòl ki deja korije nan PATCH 08.
Sepandan twa vide istorik yo sèvi ak `oldBowls[position]` pou position
1, 2, 3, **pa** ak bòl la ki nan pozisyon sa a nan permutation a. Se
egzakteman defo n ap ekspoze nan DISCOVERY 09.

Chemen pwodiksyon `openingPoursSpaghetti(c,t)` kalkile premye gout vizib
reyèl la atravè PATCH 01–07, rank bòl yo atravè PATCH 08, epi li fè yon
sèl apèl pou twa vide istorik sa yo. `openingPoursProbe` bay menm
rezilta ak kontèks pou dyagnostik. Depo bòl la pa chanje.

Sa se etap DISCOVERY sèlman: tès istorik la dwe rete EXPECTED_RED;
`test/stage18_expected_red_audit.lua` asire mesaj erè egzak la.
Koreksyon pozisyon-vè-id bòl la se PATCH 09 nan Stage 19. Pa gen
kòd pou alias id bòl, pou brase bòl, oubyen pou PATCH 10.

### QA adisyonèl DISCOVERY 09

Yon validasyon ki pa modifye fòmil legacy a rejte permutation falsifye
oswa tras PATCH 08 ki pa konplè. Tès sa a enjekte 16 defayans
(4 sou PATCH 08, 4 sou SAVE, 4 sou BigInt, 4 sou permutation)
epi mande 16 rekiperasyon pwòp. Yon lòt tès fè uit apèl nested
pandan handler rank oswa pandan kalkil matematik vide yo.
Toujou pa gen PATCH 09 ni okenn koreksyon id bòl.

### Konfimasyon natif DISCOVERY 09

GitHub Actions run `38274743802` te gen **10 travay PASS** ak yon
sèl travay `lua_stage18_discovery` ki te echwe entansyonèlman nan
dènye etap `Regression normatif DISCOVERY 09 — EXPECTED_RED sèl`.
Sentaks, gad scope, suite Stage 1–17 ak tout tès pozitif Stage 18
te pase: 48 bòl inisyal, 3 gout vizib premye yo, 16 piki erè ak
16 rekiperasyon, 8 apèl nested. Mesaj erè egzak la rete:
`EXPECTED_RED Stage 18 DISCOVERY 09: 3 gout, vide id fiks kont lòd korije`.
Etap 18 fini kòm EXPECTED_RED; Stage 19 pa kòmanse.

## Stage 19 — PATCH 09: vide dapre lòd sis bòl yo

`src/pour_patch.lua` rele `LegacyFixedPours.execute` **an premye**,
san modifye `src/legacy_fixed_pours.lua`. Li itilize id bòl nan
twa premye pozisyon lòd PATCH 08 la epi li rekalkile twa vide yo ak
`Save.savePatch`, men li kite resi istorik yo ak de handler, de commit,
métrik ak dyagnostik apa nan menm kontèks la. Nou pa brase okenn bòl.

`fixedBowlPoursSpaghetti` ak `openingPoursSpaghetti` pase sou
koreksyon an; `legacyFixedBowlPoursProbe` ak `openingPoursProbe`
toujou montre erè istorik Stage 18. Tès Stage 18 la kontinye pwouve
`EXPECTED_RED` sou chemen sa a; nan CI li pase atravè odit ki
egzije mesaj istorik egzak la. Stage 19 mande tès natif konplè
anvan LAST_COMPLETED_STAGE vin 19.

### Konfimasyon final PATCH 09

GitHub Actions `38278529281` pase **12/12 travay vèt**. Tout 720
permutation yo bay vide koreksyon ki matche ak oracle tès endepandan;
1800 vide legacy diferan epi 6 permutation kenbe menm twa id fizik
1, 2, 3. Yon seri 140 BigInt laj ak negatif, 9 gout reyèl/27 vide,
16 piki erè ak 16 rekiperasyon, epi 4 apèl nested konfime koreksyon
an. Tès Stage 18 la toujou verifye defo istorik la sèlman sou
chemen `legacyFixedBowlPoursProbe`. Pa gen brase bòl nan PATCH 09.

## Stage 20 — DISCOVERY 10: alias pandan brase sis bòl yo

Nan nouvo `src/legacy_aliased_stir.lua`, twa vide yo pase nan
PATCH 09 ki kòrèk, epi premye brase sis bòl la sèvi ak lòd sis
id PATCH 08 la. Men `old` ak `nextBowls` lonje dwèt sou **menm
tab lokal** la. Premye kalkil nan brase a ka matche oracle a;
pwochen yo li valè deja chanje nan pozisyon anvan yo. Sa se defo
istorik ki dwe parèt nan `DISCOVERY 10`, pa yon koreksyon.

Tab bòl moun k ap rele a rete pwoteje pa yon kopi apa. Erè a se
**nan anndan brase a**: old/next sèvi ak menm tablo. Chemen PATCH 09
la kouri reyèlman anvan brase istorik la; nou kenbe twa commit,
twa handler, diagnostik ak mezi kontèks. Yon apèl piblik
`openingStirSpaghetti(c,t)` travèse tout chemen premye gout
vizib la.

Regresyon normatif Stage 20 dwe bay `EXPECTED_RED` nan etap CI
dedye a; odit pozitif la verifye egzakteman erè sa a. Stage 21
PATCH 10 pral separe snapshot ak nextBowls pou korije alias la.
Nou pa lanse lòt 45 gout yo, `postStir12`, ni seleksyon ki vini apre.

### Gad reentrance pou Stage 20

Uit reentrance reyèl sou `Pour.execute` ak `Save.savePatch` dwe kenbe
chak kontèks ki gen twa commit ak sis bòl pwòp, san aliase repons
apèl nested yo ak repons apèl deyò a. Tès sa yo pa fè PATCH 10.

### Fèmti Stage 20 — EXPECTED_RED konfime

GitHub Actions `38281453888` pase **12 travay vèt**,
ak yon sèl travay `lua_stage20_discovery` wouj, sèlman nan
dènye step `Regression normatif DISCOVERY 10 — EXPECTED_RED sèl`.
Tout sentaks, tès legacy, 7 lòd sentetik, 100 BigInt, 9 gout reyèl,
12 injections ak 12 rekiperasyon, 8 nested apèl ak odit erè istorik
la pase. Mesaj erè natif la egzakteman:
`EXPECTED_RED Stage 20 DISCOVERY 10: ansyen bòl yo vin alias ak nouvo bòl`.

Yon travay smoke endepandan verifye premye gout ak sis bòl yo san
rale tout suite ki pi ansyen an. Etap 20 fini kòm DISCOVERY,
san PATCH 10. Etap 21 poko kòmanse.

## Stage 21 — PATCH 10: brase sis bòl ak snapshot separe

Nou rele `Legacy.execute` nan `src/legacy_aliased_stir.lua`
**an premye**; li toujou fè move alias lokal `old=nextBowls`.
Nou ajoute `src/stir_patch.lua` ak nouvo handler
`STIR_SNAPSHOT_PATCH`. Yon kopi `old` rete imuiab,
`nextBowls` se yon tab vid apa, epi chak lekti sis pozisyon
yo jwenn **sèlman** done ki te egziste anvan brase a.
Tou le kat tranzaksyon, kat branchTrace, tras legacy,
metrik, dyagnostik ak dosye BigInt yo rete posede pa
chak invocation.

Chemen piblik `aliasedStirSpaghetti` ak
`openingStirSpaghetti` kounye a retounen sis bòl korije.
`legacyAliasedStirProbe` ak `openingStirProbe` toujou bay
rezilta alias istorik la, ki rete anba odit EXPECTED_RED
nan Stage 20. `postStir12` ak gout #2..#46 pa antre nan
premye wout piblik la ankò: yo mande etap ki vini apre.

### Fèmti natif Stage 21

Run GitHub Actions `38285581054` bay **15/15 travay PASS**,
san okenn echèk. Nou verifye 720 permutation, 111 BigInt
jiska >256-bit ak siy negatif, 9 gout vizib reyèl/54 bòl,
15 piki erè ak 15 rekiperasyon pwòp, ansanm ak 8 apèl nested.
Kontra eritaj Stage 20 rete `EXPECTED_RED` nan audit pozitif li.
Nou pa touche `src/legacy_aliased_stir.lua`; li toujou fè
move alias la. PATCH 10 sèlman korije etap yon sèl brase sis bòl.
`LAST_COMPLETED_STAGE=21`, repo GREEN.

## Stage 22 — DISCOVERY 11: kontinwite bòl yo kase ant gout yo

`src/legacy_reset_chain.lua` kouri PATCH 10 otantik pou chak
gout vizib ak pwòp tablo wòch li. Men vèsyon istorik la
**rdemare chak gout ak sis bòl inisyal yo**, menm lè gout i-1
te deja bay sis nouvo bòl. Sa pa chanje kalkil chak gout
endividyèl: se transmisyon eta ant gout yo ki kraze.

`resetBowlsSpaghetti` ekspoze rezilta istorik sa a.
`visibleResetChainProbe(c,t,count)` kouri gout vizib reyèl yo
ak istwa gout (PATCH 01–10), epi bay context, eta inisyal,
sous/rezilta chak gout, tras kat commit chak PATCH 10, mezi ak
dyagnostik. `visibleResetChainSpaghetti` bay sis bòl istorik.
Tout bagay rete ak copies BigInt posede; okenn tablo antre pa
modifye pa alias entèn.

Tès normatif endepandan dwe rete `EXPECTED_RED` pou gout 2+;
gout 1 dwe matche. Koreksyon `PATCH 11` ap pase bòl ki soti
nan gout i-1 pou brase gout i, nan Stage 23. Nou pa fè
`postStir12`, ni latching lòd nan gout 46, ni seleksyon bòl.

### Fèmti natif Stage 22 — EXPECTED_RED otantifye

GitHub Actions `38287878912` konfime **16 travay PASS**, epi
yon sèl travay `lua_stage22_discovery` echwe ekspre nan
dènye step `Regression normatif DISCOVERY 11 — EXPECTED_RED sèl`.
Tout etap pozitif te pase: sèt sekans, 46 gout ak 276 rezilta
brase sis bòl, oracle endepandan pou 46 gout, nèf gout reyèl,
13 injections/13 rekiperasyon, ak senk apèl nested. Mesaj echèk
egzak la se:
`EXPECTED_RED Stage 22 DISCOVERY 11: chak gout rekòmanse ak bòl inisyal`.

`LAST_COMPLETED_STAGE=22` ak `EXPECTED_REPOSITORY_STATE=EXPECTED_RED_VERIFIED`.
Kòd istorik reset chak gout la rete entak; Stage 23 PATCH 11
pa kòmanse.


## Stage 23 — PATCH 11: sis bòl yo kontinye viv ant gout yo

Nan Stage 22, kalkil sis bòl pou chak gout te kòrèk pou yon sèl
gout, men chèn istorik `src/legacy_reset_chain.lua` te toujou
retounen nan sis bòl inisyal yo lè li kòmanse gout ki vin apre a.

Nou **pa modifye kòd legacy sa a**. Nou ajoute
`src/bowl_chain_patch.lua`: li egzekite `LegacyResetChain.execute`
an premye pou anrejistre erè orijinal la. Apre li fin valide
tras, komit ak rezilta sa a, li egzekite menm `StirPatch.execute`
otantik pou chak gout, men li bay rezilta gout i kòm antre gout i+1.
Handler `BOWL_CHAIN_STATE_PATCH` ajoute yon dezyèm commit nan
kontèks prensipal la. Kontèks yo kenbe tras reset legacy a, tras
koreksyon an, kontèks pitit pou chak gout nan toude chemen yo,
metrik, dyagnostik ak kopi eta BigInt ki posede apa.

`resetBowlsSpaghetti` ak `visibleResetChainSpaghetti` kounye a
bay **sis bòl ki korije** yo. Pou enspekte de commit yo, sèvi ak
`bowlChainPatchProbe(drops,stones,initial)` oubyen
`visibleBowlChainPatchProbe(c,t,count)`. Pou teste defo ansyen
an, `legacyResetBowlsProbe` ak `visibleResetChainProbe` rete
disponib. Odit `EXPECTED_RED` Stage 22 la kontinye pase epi
egzije mesaj erè istorik egzak la sou chemen legacy apa a.

Tès natif `lua5.3 test/stage23_tests.lua .` kouvri tout etap 1–23,
sèt sekans kout ak 28 gout, 46 gout avèk BigInt >256 bit, 16 piki
erè oswa falsifikasyon ak 16 rekiperasyon, senk chèn nested, nèf
gout vizib natif sou twa pè jou, ak yon oracle tès endepandan.
Fonksyon `test/stage23_oracle_helper.lua` egzamine sekans kout;
`test/normative_oracle.lua` ki gen kontra fiks pou 46 gout
**pa chanje**.

### Fèmti Stage 23 — CI natif vèt

GitHub Actions `38290676201` te konplete avèk **18/18 travay PASS**.
Travay `lua_stage23_patch` la pase verifikasyon sentaks Lua,
kadna idantite legacy Stage 22, epi suite natif Stage 1–23.
Tout travay anvan yo rete vèt; regresyon wouj istorik la rete
nan odit ki ap tann menm mesaj la. `LAST_COMPLETED_STAGE=23`,
`EXPECTED_REPOSITORY_STATE=GREEN`. Nou pa kòmanse Stage 24,
ni `postStir12`, ni seleksyon bòl.


## Stage 24 — DISCOVERY 12: vwazen an soti nan non bòl la olye lòd gout 46

Nou ajoute `src/legacy_fixed_neighbor.lua`: li rele chèn PATCH 11
pou **46 gout egzakteman**, epi li rele vrè PATCH 08 sou gout 46
pou jwenn lòd sis id bòl la. Men ansyen fonksyon
`oldNextBowlFixedName(id)` kontinye retounen `id%6+1`
**san konsilte lòd sa a**. Erè a make nan dispatcher
`LEGACY_FIXED_NAME_NEIGHBOR` kòm twazyèm commit.
Tout kontèks Stage 22/23, lòd PATCH 08, kopi eta sis bòl,
dyagnostik ak mezi rete disponib. Oracle normatif rete
nan `test/`, pa nan modil pwodiksyon.

`nextBowlSpaghetti(drops,stones,bowls,id)` retounen id
legacy ki mal la; `legacyFixedNeighborProbe` kenbe tras yo.
`visibleFixedNeighborProbe(c,t,id)` bati 46 gout vizib natif
avèk istwa yo, PATCH 01–11, epi li ekspoze lòd gout 46.
Nou pa aplike `postStir12` oubyen koreksyon PATCH 12.

Sou 720 lòd leksikografik ak sis id kesyone, atant odit la
se 3,456 move vwazen, 864 matche aksidantèlman, epi 6
permutation kote tout sis vwazen matche. Pou rank 720,
`id=1`, legacy chwazi bòl 2 pandan lòd gout 46 mande bòl 6.
Regression `test/stage24_regression_tests.lua` dwe rete
`EXPECTED_RED`; `test/stage24_expected_red_audit.lua`
dwe pase ak mesaj egzak sa a:
`EXPECTED_RED Stage 24 DISCOVERY 12: vwazen pa non fiks inyore lòd gout 46`.

Pou suite pozitif ak odit legacy:
`lua5.3 test/stage24_tests.lua .`
Pou regresyon wouj entansyonèl:
`lua5.3 test/stage24_regression_tests.lua .`
CI Stage 24 dwe pase tout etap pozitif, epi se sèlman dènye
step discovery sa a ki dwe echwe. **Pa ajoute PATCH 12 nan Stage 24.**

### Fèmti Stage 24 — EXPECTED_RED natif otantifye

GitHub Actions run `38292918409`: **20 travay PASS**, epi
`lua_stage24_discovery` echwe fè espre **sèlman** nan dènye
etap regresyon normatif la. Suite pozitif Stage 1–24 pase
anvan echèk sa a. Odit separe a verifye egzakteman:
`EXPECTED_RED Stage 24 DISCOVERY 12: vwazen pa non fiks inyore lòd gout 46`.

Egzamen endepandan kouvri 720 lòd × 6 id = 4,320 kesyon:
3,456 vwazen mal, 864 matche aksidantèlman, sèlman sis
permutation ki matche pou tout bòl. Tès 46 gout ak BigInt
gwo/negatif, 9 echèk + 9 rekiperasyon, 3 nested chains
ki genyen 46 gout, ak entegrasyon 46 gout vizib natif,
tout pase. PATCH 11 rete intact, lòd gout 46 konsève,
legacy chwazi 2 pandan oracle la chwazi 6 pou rank 720/id 1.
`LAST_COMPLETED_STAGE=24` epi
`EXPECTED_REPOSITORY_STATE=EXPECTED_RED_VERIFIED`.
**Pa kòmanse Stage 25; pa gen PATCH 12 ni douz brase final yo.**


## Stage 25 — PATCH 12: vwazen an swiv lòd sis bòl gout 46 la

Ansyen `src/legacy_fixed_neighbor.lua` **pa chanje**. Nou ajoute
`src/neighbor_patch.lua` ki **egzekite chemen DISCOVERY 12 la an
premye**, valide twa commit li yo, 46 gout PATCH 11 la, ansanm ak
prèv vrè PATCH 08 la pou permutation gout 46. Li konpare lòd sa a
ak unrank factoradic istorik la sou rank korije a, epi li ajoute
yon katriyèm commit `DROP46_NEIGHBOR_ORDER_PATCH`.
Nou chwazi bòl ki vini aprè id kesyone a nan sik
`orderAtDrop46`, pa `(queriedId%6)+1`.

Pou rank 720 ak id kesyone 1, nouvo rezilta a se **6** pandan
ansyen wout la toujou retounen **2**. Nan 720 permutation × sis
kesyon, fonksyon PATCH 12 la matche oracle endepandan an nan
**4,320/4,320** ka; 3,456 nan yo repare rezilta istorik,
epi 864 lòt yo te deja matche pa aza.

`nextBowlSpaghetti(drops,stones,bowls,id)` se chemen korije a;
`neighborPatchProbe` montre kontèks kat commit yo;
`nextInDrop46OrderProbe` verifye nwayo permutation an san
rekalkile gout; `visibleNeighborPatchProbe(c,t,id)` bati
46 gout natif ak tout kontèks yo; `visibleNeighborSpaghetti`
se antre piblik korije sou jou reyèl.
`legacyFixedNeighborProbe`, `visibleFixedNeighborProbe`,
ak `oldNextBowlFixedNameProbe` rete istorik; okenn oracle
pa enpòte nan production.

`lua5.3 test/stage25_tests.lua .` kouvri tout Stage 1–25,
720 permutation, chèn BigInt >256 bit negatif 46 gout/276 bòl,
8 injections oswa falsifikasyon ak 8 rekiperasyon pwòp,
reentrancy vre sou de envokasyon 46 gout, ak 46 gout natif.
Odit `test/stage24_expected_red_audit.lua` konsève egzak
mesaj wouj Stage 24 la, men li pase kòm yon tès pozitif.
Pa gen `postStir12`, ni PATCH 13, ni seleksyon bòl.

### Fèmti natif Stage 25 — GitHub Actions vèt

Run `38372225320` fini avèk **25/25 jobs PASS**. Suite
`lua_stage25_patch` pase Stage 1–25 an antye; jobs
`lua_stage25_smoke`, `lua_stage25_resilience`,
`lua_stage25_real` pase separeman, ansanm ak tout suites
istorik yo. Ansyen chèn ak ansyen erè Stage 24 konsève.
`LAST_COMPLETED_STAGE=25`; `EXPECTED_REPOSITORY_STATE=GREEN`.

## Stage 26 — DISCOVERY 13: modulo dirèk bay yon chwa ki gen bias

`src/legacy_biased_choice.lua` ajoute yon vrè sous repons
`A_k = SAVE(A_0 + direction*k)`, ak (1 ≤ A_0 ≤ M),
`direction = +1/-1`, epi `M = 2^127-1`. Nou valide premye
repons lan, direksyon an, index nonnegatif ak kantite opsyon
`1 <= N <= M`; BigInt travay san limit 64/256 bit.

Erè istorik `oldBiasedModuloPick` pran premye repons lan sèlman:
`rank = 1 + ((A_0 - 1) mod N)`. Li pa verifye si
`A_0 > floor(M/N)*N`; se poutèt sa kèk rank resevwa
plis repons pase lòt yo. San `PATCH 13`, okenn repons
apre `A_0` pa konsome. De handler otantik
`LEGACY_REPLY_STREAM` ak `LEGACY_BIASED_MODULO_PICK`
kenbe de commit, métriques ak diagnostics.

`answerAtSpaghetti(first,direction,k)` bay sous la san bias;
`choiceSpaghetti(first,direction,N)` rete legacy ak bias;
`legacyBiasedChoiceProbe` bay rezilta ak context;
`oldBiasedModuloPickProbe` ekspoze chwa istorik la.
Modil Stage 25 yo rete entak. Nan etap sa a, kantite opsyon
pi gwo pase M ak final `postStir12` pa antre nan pipeline:
se modil seleksyon izole epi verifikab, pa yon kalkil dat nèt.

Kat sak diferans normatif ki dwe rete `EXPECTED_RED`:
- N=5, A0=M, direction=+1: legacy 2, oracle 1
- N=5, A0=M, direction=-1: legacy 2, oracle 5
- N=5, A0=M-1, direction=-1: legacy 1, oracle 5
- N=11, A0=M, direction=+1: legacy 6, oracle 1

`lua5.3 test/stage26_tests.lua .` teste toude chemen yo,
endepandans eta, negatif/BigInt, rekiperasyon erè ak 4
`EXPECTED_RED` odit. Chak script wouj `stage26_expected_red_1..4.lua`
dwe echwe dirèkteman apre li valide premye diferans normatif la.
Nan CI: travay `lua_stage26_stream` dwe pase; travay
`lua_stage26_discovery` dwe pase tout suite pozitif,
apre sa li dwe echwe *sèlman* nan dènye step wouj la.
Koreksyon rejection sampling rete pou Stage 27.

### Fèmti Stage 26 — EXPECTED_RED natif verifye

Run GitHub Actions `38375388629` fini egzakteman
jan kontrak DISCOVERY 13 mande: **26/26 lòt jobs PASS**.
Travay `lua_stage26_discovery` pase tout suite pozitif
Stage 1–26, epi li echwe **sèlman** nan etap regresyon wouj final,
ak mesaj egzak `EXPECTED_RED Stage 26 DISCOVERY 13 witness 1: modulo san rejè`.
Nou verifye 409 repons SAVE kont oracle, 10 tras modulo,
kat diferans normatif, uit erè/uit rekiperasyon, ak de kouran
nested san eta pataje. Tout prèv erè a prezève pou PATCH 13.
`LAST_COMPLETED_STAGE=26`;
`EXPECTED_REPOSITORY_STATE=EXPECTED_RED_VERIFIED`.

## Stage 27 — PATCH 13: eliminasyon bias modulo pou N<=M

Nou konsève modil `legacy_biased_choice.lua` byte-pou-byte.
`src/short_choice_patch.lua` rele vrè `Legacy.execute` **an premye**,
valide tout de commit yo, tras ak métriques, epi ajoute
`SHORT_CHOICE_REJECTION_PATCH` kòm twazyèm commit.

Limit pou `1<=N<=M` se `floor(M/N)*N`. Nou pran premye
`A_k=SAVE(A_0+direction*k)` kote `A_k<=limit`, epi nou
retounen `1+((A_k-1)%N)`. Erè modulo Stage 26 la rete
vizib kòm `legacyChoiceSemanticState` ak `legacyChoiceRank`.
API `choiceSpaghetti` sèvi ak chemen PATCH 13; sondaj
`shortChoicePatchProbe` ak `shortChoiceCoreProbe` bay
kontèks ak prèv, pandan `legacyBiasedChoiceProbe` pa chanje.

Sik repons lan deplase egzakteman +1 oswa -1. Si A0 tonbe
nan rejyon rejte kontig `[limit+1,M]`, nou kapab sote
tousuit rive nan premye repons ki valab: pou +1 li se
1; pou -1 li se limit. Nou verifye premye repons
aksepte a, echantiyon anvan li, ak jiska 64 premye rejè,
epi nou anrejistre kantite rejè *lojik* konplè kòm BigInt.
Sa evite fè plis pase `2^64` iterasyon lè `N=M//2+1`,
san chanje premye repons akseptab la.

Tès endepandan yo konpare kont oracle normatif pou plizyè
N, direksyon, A0 ak ka limit. Kat witness Stage 26 yo dwe
kounye a bay rank korije, pandan tès historical EXPECTED_RED
la toujou pase kòm audit. Suite `lua5.3 test/stage27_tests.lua .`
gen QA Stage 1–27, gwo BigInt, 12 faults+12 recoveries,
nested context ak repons ki sòti nan sauce kanonik.
Path wide `N>M`, douz brase final yo nan production,
ak kouch gate yo pa antre nan Stage 27.

### Fèmti Stage 27 — PATCH 13 verifye nativman

GitHub Actions run `38430726689` fini ak **31/31 jobs PASS**.
Suite natif `lua_stage27_patch` pase tout Stage 1–27, ak
`lua_stage26_expected_red_audit` verifye kat ansyen
diferans modulo yo toujou egziste sou wout legacy a.
`lua_stage27_smoke` pase 1,239 konparezon kont oracle,
pami yo 165 kote PATCH 13 korije legacy; `lua_stage27_resilience`
pase >2^64 rejè lojik ak prèv premye akseptasyon, 12
defayans/12 rekiperasyon ak de nested contexts.
`lua_stage27_real` pase de sous repons soti nan sauce
kanonik la. Etap 26 a rete kòm prèv istorik, pa kòm
echèk CI ki pa atann.

`LAST_COMPLETED_STAGE=27` epi
`EXPECTED_REPOSITORY_STATE=GREEN`.
Pa gen chwa wide `N>M` ni final douz brase nan PATCH 13.

## Stage 28 — DISCOVERY 14: dispatcher legacy san chemen N>M

Apre PATCH 13, `choiceSpaghetti` toujou korije pou
`1<=N<=M`, men lòd done istorik yo pa konn chwa laj
lè `N>M`. Nou ajoute `src/legacy_short_only_choice.lua`,
ki eseye rele **PATCH 13 reyèl la** menm sou N>M.
Erè gwosè short la bloke rank (rezilta nil); nou konsève
li nan yon MonsterContext posede, avèk handler
`LEGACY_WIDE_SENT_TO_SHORT_PATH`, yon commit,
metrik, diagnostic ak `shortError`. Pa gen ran
artificiel oswa repons 0 ki ta sanble valab.

`legacyShortOnlyChoiceProbe(first,direction,N)` kenbe
tras istorik la pou short ak wide. Sou short, li verifye
twa commits PATCH 13 epi li retounen rank egzak la; sou
wide, li retounen nil ak `STAGE_28_DISCOVERY_14`.
`choiceSpaghetti` konsève PATCH 13 pou N<=M epi li
ekspoze blokaj short-only pou N>M. Modil
`short_choice_patch.lua` rete byte-pou-byte entak.

Oracle tès endepandan an gen yon `chooseRankWide` ki
chèche minimòm `k` ak `M^k>=N`, li pran k repons
yon sèl fwa epi li fòme chif baz M, ak chif pi ba a an
premye. Nou sèvi avè l sèlman nan `test/` pou pwouve
ke kat witness `N=M+1`, `N=M^2`, ak gwosè
jiska `M^3+1` kapab jwenn rank otantik pandan legacy
a bloke. Yon blòk vrè sauce kanonik teste menm defo a.

Kat fichye `test/stage28_expected_red_1..4.lua`
gen mesaj wouj egzak. `stage28_expected_red_audit.lua`
dwe pase si kat erè yo byen jwenn. `lua5.3
test/stage28_tests.lua .` kouvri tout Stage 1–28,
chwa short koreksyon PATCH 13, sizes jiska M^5+1,
oracle wide, fail-closed, reentrancy, ak sous sauce.
Stage 29 PATCH 14 ap bezwen yon wide detour apa;
Stage 28 pa kapab ajoute koreksyon an, ni final
douz brase yo.

### Fèmti Stage 28 — EXPECTED_RED natif verifye

GitHub Actions run `38435176181`: **34/34 travay pozitif PASS**.
`lua_stage28_discovery` pase tout suite Stage 1–28, kat odit
istorik `EXPECTED_RED`, epi li echwe sèlman nan dènye etap
wouj la ak mesaj egzak `EXPECTED_RED Stage 28 DISCOVERY 14 witness 1: N>M blocked by short-only legacy`.
Nou verifye 59 chwa short PATCH 13, sèt rank wide oracle
ki valab pandan dispatcher istorik la bloke, kat witness
wouj, limit BigInt jiska `M^5+1`, 8 echèk/8 rekiperasyon,
de kontèks nested ak yon sous sauce otantik.
`short_choice_patch.lua` pa chanje; pa gen PATCH 14 ni
`postStir12` nan production. Sa se echèk normatif ki fèt
espre, pa echèk suite pozitif la.

`LAST_COMPLETED_STAGE=28`;
`EXPECTED_REPOSITORY_STATE=EXPECTED_RED_VERIFIED`.

## Stage 29 — PATCH 14: detou laj apre blokaj istorik la

Nou ajoute `src/wide_choice_patch.lua` san chanje `legacy_short_only_choice.lua`
ni `short_choice_patch.lua`. Pou `N>M`, nou premye egzekite chemen
legacy ki bloke epi valide commit li. Apre sa, nou bati pi piti
`k` kote `M^k>=N`; `A_0` gen pwa 1, `A_1` pwa M, elatriye.
Nou sèvi ak limit akseptasyon `floor(M^k/N)*N`, ak yon sote
kontig pou rejè ki ka depase 64 bit. Commit koreksyon an suiv
commit blokaj la, avèk eta semantik apa ak prèv chif yo.
Pou `N<=M`, `choiceSpaghetti` toujou sèvi ak PATCH 13.
Tès ak CI natif Stage 29 verifye; pa gen `postStir12`.

### Verifikasyon Stage 29 — Suite natif

Nou ajoute `stage29_tests.lua` ak job CI apa pou oracle wide,
sekans ki depase `2^64` rejè lojik, 10 echèk/rekiperasyon,
de reentrances, sauce otantik ak kadna SHA modil legacy.
Odit kat regresyon wouj Stage 28 la toujou egziste,
men suite pozitif la pa rele script wouj la kòm echèk job ankò.
Rezilta CI natif yo verifye nan run `38439596829`.

### Fèmti Stage 29 — PATCH 14 verifye nativman

GitHub Actions run `38439596829`: **39/39 travay PASS**, san okenn
travay echwe. Job `lua_stage29_patch` pase tout suite natif
Stage 1–29. Nou verifye 25 chwa laj ak oracle endepandan,
rejè laj plis pase `2^64`, gwosè rive `M^5+1`, 10 erè
ak 10 rekiperasyon, de apèl nested, ak de kouran sauce
kanonik. Kat `EXPECTED_RED` Stage 28 yo toujou verifye
atravè audit sou legacy short-only; yo pa yon echèk CI.

Kadna Git hash sou `legacy_short_only_choice.lua` ak
`short_choice_patch.lua` pase. `wide_choice_patch.lua`
kenbe commit blokaj istorik la anvan commit koreksyon laj la.
Oracle rete sèlman anba `test/`; nou pa ajoute `postStir12`
ni okenn travay Stage 30 davans.
`LAST_COMPLETED_STAGE=29`;
`EXPECTED_REPOSITORY_STATE=GREEN`.

## Stage 30 — DISCOVERY 15: kestyon pòtay negatif sou move bò Fondasyon

Nou mete `src/legacy_gate_question_adapter.lua`. Li gen
`oldGateQuestionDay(n)=FOUNDATION_DAY_OLD+n`, men adaptè
istorik la toujou pase `abs(signedStep)`. Pou `-n`, li mande
`FOUNDATION_DAY_OLD+n` olye jou normatif
`FOUNDATION_DAY_OLD-n`. De commits kenbe demann orijinal
ak jou erone a apa; public `gateQuestionDaySpaghetti`
montre erè istorik sa a. `legacyGateQuestionProbe` retounen
kontèks konplè, san korije rezilta a.

Nan Stage 30, nou pa aplike PATCH 15, nou pa konstwi chèn
pòtay, e nou pa entegre `postStir12`. Regrèsyon normatif
negatif yo dwe rete `EXPECTED_RED` jouk Stage 31.
CI natif Stage 30 verifye sou run `38444537164`.

### Tès Stage 30 — DISCOVERY 15

`lua5.3 test/stage30_tests.lua .` kouri tout Stage 1–30.
Tès yo kouvri 300 demann pozitif/negatif, twa BigInt ki gwo,
8 piki erè ak 8 rekiperasyon, twa kontèks nested, ak
twa kestyon pòtay sou sauce kanonik. Scripts wouj yo
teste `-1`, `-2`, `-10`; `stage30_expected_red_audit.lua`
verifye twa mesaj egzak san fè suite pozitif la echwe.
Nan CI, kat jobs pozitif dwe pase; job
`lua_stage30_discovery` dwe pase suite pozitif,
apre sa li dwe echwe sèlman nan etap `EXPECTED_RED` final la.
Verifikasyon natif fini: 43 travay pozitif PASS ak yon echèk wouj istorik entansyonèl.

### Fèmti DISCOVERY 15 — Stage 30

GitHub Actions run `38444537164`: **43/43 travay pozitif PASS**,
epi yon sèl travay `lua_stage30_discovery` echwe entansyonèlman
sou dènye etap li, avèk mesaj egzak
`EXPECTED_RED Stage 30 DISCOVERY 15 witness 1: negative gate sign lost`.
Suite natif Stage 1–30 anvan etap wouj la pase nèt.
Prèv yo kouvri 300 kestyon siy, 11 tras avèk senk
divèjans negatif, twa BigInt masif, 8 erè/8 rekiperasyon,
twa nested calls, twa konparezon sauce kanonik,
ak twa scripts wouj istorik verifye pa audit.
Pa gen PATCH 15 oswa `postStir12`.
`LAST_COMPLETED_STAGE=30`;
`EXPECTED_REPOSITORY_STATE=EXPECTED_RED_VERIFIED`.

## Stage 31 — PATCH 15: retabli siy kestyon pòtay negatif

Nou ajoute `src/gate_question_patch.lua` pou rele adaptè
istorik Stage 30 an premye. De commits legacy yo rete,
ak snapshot semantik ki dokimante demann ki gen siy
epi move jou `F+abs(n)`. Nou egzije provenance,
metrik, diagnostics, epi jou kestyon istorik ki egzak.
Twazyèm commit `SIGNED_GATE_QUESTION_PATCH` repare jou a:
sou etap negatif, `F+abs(n)-2*abs(n)=F+n`; sou etap
pozitif oswa zewo, jou a pa chanje. Tout kalkil se
BigInt natif; pa gen oracle pwodiksyon.
`legacyGateQuestionProbe` kontinye revele defo Stage 30 a.
Nou pa konstwi chèn pòtay, ni `postStir12`.
QA natif Stage 31 konfime nan run `38456163489`.
### Fèmti natif Stage 31 — PATCH 15

GitHub Actions run `38456163489`: **48/48 travay PASS**,
san okenn echèk. Tout Stage 1–31 pase ansanm. Nou teste
301 jou kestyon kont oracle endepandan, 150 koreksyon
sou bò negatif Fondasyon, twa distans BigInt gwo,
10 erè/10 rekiperasyon, twa nested calls ak de koup
sauce kanonik. Audit twa `EXPECTED_RED` Stage 30
toujou konfime move chemen istorik la.
Kadna SHA sou `legacy_gate_question_adapter.lua` pase:
`d7c86d6c41c61de06816c681417caa035c0e5337`.
Twa commits posede yo rete nan lòd: demann avèk siy,
move kestyon legacy, kestyon siyen repare. Pa gen
chèn pòtay antye, oracle nan production oswa `postStir12`.
`LAST_COMPLETED_STAGE=31` / `EXPECTED_REPOSITORY_STATE=GREEN`.


## Stage 32 — DISCOVERY 16: espas pòtay istorik la twò long pa youn

Apre `gateQuestionDaySpaghetti` PATCH 15 ak seleksyon
`choiceSpaghetti` PATCH 13 pou 922 opsyon, ansyen fòmil
`oldGateGapFromRank(rank)` ajoute **42+rank**.
Fòmil normatif la se **41+rank**, konsa rank 1..922
ta dwe pwodui yon espas 42..963; legacy bay 43..964.
Se yon defo reyèl fòmil offset la, pa yon fèy-repons fo.
`legacy_gate_gap.lua` konsève 3 commits kestyon siyen,
sove eta semantik seleksyon an, epi ajoute 4yèm commit
`LEGACY_GATE_GAP_PLUS_ONE` ki prezève rezilta erone a.

Nan Stage 32, pa gen PATCH 16, pa gen chèn pòtay konplè,
pa gen `postStir12`. Sous rank la soti nan kòd natif
PATCH 13, pa nan oracle tès la. Validasyon natif konfime sou run `38463642837`.

### Tès Stage 32 — DISCOVERY 16

`lua5.3 test/stage32_tests.lua .` kouvri tout Stage 1–32,
70 tras chwa rank ak oracle endepandan, 8 kestyon BigInt
gwo, 12 enjèksyon erè ak 12 rekiperasyon, twa nested
contexts, ak de rank ki sòti nan sauce kanonik reyèl.
Twa scripts `stage32_expected_red_1..3.lua` montre
diferans egzak `42+rank` kont `41+rank`; audit
pozitif la verifye tout mesaj yo. Kat jobs CI natif
teste sa; `lua_stage32_discovery` dwe echwe sèlman
nan dènye etap `EXPECTED_RED`, apre tout pozitif PASS.
Kadna SHA verifye PATCH 13, PATCH 15 ak legacy sign-day.
Stage 33 pral repare offset la san efase erè a.
Rezilta CI Stage 32 verifye: 51 travay pozitif PASS; yon sèl echèk `EXPECTED_RED` entansyonèl.
### Fèmti DISCOVERY 16 — Stage 32

GitHub Actions run `38463642837`: **51/51 travay pozitif PASS**,
avèk yon sèl job `lua_stage32_discovery` ki echwe
entansyonèlman nan dènye etap li:
`EXPECTED_RED Stage 32 DISCOVERY 16 witness 1: gate gap legacy offset plus one`.
Tout Stage 1–32 pase avan etap wouj la. Twa witness
istorik yo pase audit egzak, 70 chwa oracle verifye,
8 gwo kestyon BigInt, 12 echèk/12 rekiperasyon, twa
nested calls ak de rank soti nan sauce kanonik.
Kadna SHA sou PATCH 13, PATCH 15 ak ansyen kestyon siyen
pase; defo `42+rank` istorik la rete disponib pou audit.
`LAST_COMPLETED_STAGE=32`;
`EXPECTED_REPOSITORY_STATE=EXPECTED_RED_VERIFIED`.
Pa gen PATCH 16, chèn pòtay oswa `postStir12`.


## Stage 33 — PATCH 16: retabli espas pòtay normatif 42..963

Nou ajoute `src/gate_gap_patch.lua`: li fè apèl reyèl
`legacy_gate_gap.execute` an premye, verifye kestyon
siyen PATCH 15, rank PATCH 13 ak kat commits istorik yo,
epi sove state `42+rank` ansanm ak question day la.
Apre sa, senkyèm commit `GATE_GAP_OFFSET_PATCH`
retire 1: `(42+rank)-1=41+rank`, rank 1..922,
gap 42..963. Fonksyon piblik `gateGapSpaghetti`
pran PATCH 16, pandan `legacyGateGapProbe` rete pou audit.
Pa gen oracle nan production, pa gen chèn pòtay antye,
ni `postStir12`. QA natif konfime nan run `38565993353`.

### QA Stage 33 — PATCH 16

Suite `lua5.3 test/stage33_tests.lua .` ajoute
234 konparezon oracle egzak sou longè pòtay, 234
koreksyon `+1`, bornes 42..963, uit kestyon
BigInt siyen gwo, 14 enjeksyon erè ak 14 rekiperasyon,
twa nested PATCH 16 ak de kouran sauce kanonik reyèl.
Kadna SHA verifye modil legacy DISCOVERY 16 la,
PATCH 15 ak PATCH 13 pa chanje. Twa witness
`EXPECTED_RED` Stage 32 toujou disponib nan
`stage32_expected_red_audit.lua` kòm prèv istorik;
job Stage 32 a pa gen etap echèk volontè apre PATCH 16.
Kat jobs CI Stage 33 yo pase, ansanm ak tout lòt travay natif yo.
### Fèmti natif Stage 33 — PATCH 16

GitHub Actions run `38565993353`: **56/56 travay PASS**.
Suite natif Stage 1–33 pase nèt. Nou teste 234
espas pòtay kont oracle endepandan, 234 erè `+1`
repare, 8 kestyon BigInt gwo, 14 defayans/14
rekiperasyon, twa kontèks nested ak de sauce kanonik.
Kadna SHA sou sous legacy DISCOVERY 16, PATCH 13
ak PATCH 15 pase. Twa `EXPECTED_RED` Stage 32
rete odit istorik nan suite vèt la, pa yon echèk CI.
Katriyèm commit eritaj la rete; senkyèm commit
repare `41+rank` pou espas 42..963. Pa gen
gate sequence ni `postStir12`.
`LAST_COMPLETED_STAGE=33` / `EXPECTED_REPOSITORY_STATE=GREEN`.


## Stage 34 — DISCOVERY 17: pòtay pozitif bliye entèval avan yo

Apre PATCH 16, `gateGapSpaghetti` gen gap egzak
42..963 pou nenpòt kestyon Fondasyon siyen. Men lè
nou konstwi pozisyon pòtay pozitif `G(n)`, ansyen
`oldPositivePosition` kalkile `F+gap(n)` olye
`F+gap(1)+...+gap(n)`. Premye pòtay la kòrèk;
pòtay 2..n yo twò pre Fondasyon, menm lè chak
gap ak kestyon gen valè normatif.

`src/legacy_positive_gate_position.lua` mande yon lis
n sous SAVE otantik (premye repons ak direksyon);
li pa fabrike sauce nan production. Pou chak i, li
rele PATCH 16 reyèl epi kenbe snapshots prive gap yo, san kalkile
jou kimen normatif nan production. Li konsève senk commits
PATCH 16 pou dènye gap la epi ajoute yon sizyèm
commit `LEGACY_POSITIVE_GATE_RESETS_FOUNDATION`.
`positiveGateDaySpaghetti` ekspoze sa a kòm defo
istorik; `legacyPositiveGateProbe` retounen tras la.

Limit Stage 34 se 1..32 etap pozitif ak sous ki bay
deja. Li pa fè rechèch pòtay negatif, pa gen PATCH 17,
ni `postStir12`. Tès ak CI natif poko verifye.

### Tès Stage 34 — DISCOVERY 17

Suite `lua5.3 test/stage34_tests.lua .` kouvri
24 chèn konpare kont oracle (21 ka istorikman
diferan), 32 sous BigInt sou valè `M`, 18
enjeksyon erè/18 rekiperasyon, de nested contexts,
ak twa sous sauce kanonik reyèl ki verifye
`O.ensureGateIndex(3)` se sòm pozitif la.
Twa scripts `stage34_expected_red_1..3.lua`
pwouve ke `F+gap(n)` pa egale `G(n)` pou n>=2.
Gen kat jobs CI, twa pozitif ak youn ki dwe echwe
sèlman nan dènye etap `EXPECTED_RED`. Kadna SHA
sou PATCH 16 ak DISCOVERY 16 rete. Rezilta CI
natif poko verifye.
