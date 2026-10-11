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

Dezyèm kòmand lan dwe fini ak `EXPECTED_RED Stage 2 DISCOVERY 01`, apre tout tès vèt yo fin pase. Pa konsidere rezilta sa a kòm yon patch ki manke: nan Discovery 01, echèk sa a se prèv defo istorik nou gen pou korije nan Stage 3. Pa aplike patch la davans.

## Yon lòt revizyon pwopriyete pou Stage 2

`test/stage02_property_tests.lua` fè 575 esè repwodiktib: 455 ka sou baryè `-32M` rive `32M` avèk deplasman `-3..3`, epi 120 ka ak antye long ak translasyon pa miltip `M`. Li teste idantite divizyon Eklidyen, izolasyon eta chak apèl, ak lefèt ke divèjans lan fèt sèlman pou rès zewo. `test/stage02_scope_tests.lua` verifye pa gen kòd patch Stage 3 ni import oracle nan kòd pwodiksyon an. Toude tès sa yo dwe pase anvan echèk ekivalans la.

```text
texlua test/stage02_property_tests.lua .
texlua test/stage02_scope_tests.lua .
```
