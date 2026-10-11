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

Nan eta Discovery 02 sa a, `texlua test/stage04_tests.lua .` oubyen `texlua test/stage04_regression_tests.lua .` dwe fini ak `EXPECTED_RED Stage 4 DISCOVERY 02` ki nonmen egzakteman kat ka: `FOUNDATION`, `AFTER_1`, `AFTER_2`, `AFTER_20`. Echèk la obligatwa jiskaske PATCH 02 rive nan Stage 5. CI a rapòte wouj entansyonèl sèlman nan travay `lua_stage04_discovery`; tès tout etap anvan yo rete vèt.
