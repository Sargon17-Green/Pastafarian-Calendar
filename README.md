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
