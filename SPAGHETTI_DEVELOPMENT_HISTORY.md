# Þróunarsaga spaghettískrímslisins

## Stage 1 — Bootstrap

### Hvað var byggt

Verkefnið var stofnað frá auðu tré fyrir Elm og íslensku. Sjálfstæður nákvæmur heiltölukjarni var skrifaður í Elm, staðlaða viðmiðunarvélin var endurgerð beint úr innbyggða viðmiðinu og sérstakur Elm-prófunarharness var búinn til. `SourceLanguageCatalog` var frystur með 17 kótilettum og 47 mánuðum.

### Hlutlaus skrímslagrunnur

Aðeins almenn og merkingarlega hlutlaus grunnlög voru sett inn: kallsamhengi, einfaldur stýringaraðili, staðfestingarmörk og mælingaskel. Engin eldri villa, leiðrétting, samhæfingarleið eða stilling úr framtíðarstigi var sett inn.

### Eign á ástandi

Allt `BaseContext` tilheyrir einu kalli. Mælingar og framkvæmdarslóð eru athugunargögn og mega ekki verða staðlað inntak. Ekkert alþjóðlegt breytanlegt merkingarástand var sett inn á þessu stigi.

### Prófunarstaða

Kóðinn var útbúinn fyrir Elm 0.19.1, en afhendingarumhverfið hafði engan Elm-þýðanda og gat ekki sótt hann. Þess vegna er Stage 1 ekki staðfest lokið fyrr en Elm-prófin hafa verið keyrð með raunverulegu Elm-verkfærasafni og niðurstaðan hefur verið skráð.
