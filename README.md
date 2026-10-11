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
