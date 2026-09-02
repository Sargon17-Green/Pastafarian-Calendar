# Afhending — Stage 1 Bootstrap

## Skrár sem voru búnar til

- `elm.json`
- `src/Pastafari/ExactInt.elm`
- `src/Pastafari/SourceLanguageCatalog.elm`
- `src/Pastafari/MonsterBase.elm`
- `src/Pastafari/Spaghetti.elm`
- `tests/NormativeOracle.elm`
- `tests/Stage01Harness.elm`
- `README.md`
- `SOURCE_LANGUAGE_CATALOG.md`
- `SPAGHETTI_DEVELOPMENT_HISTORY.md`
- `DEVELOPMENT_STAGE.md`
- `STAGE_01_EXECUTION_STATUS.txt`
- `HANDOFF_STAGE_01.md`

Engin skrá var eytt og engin fyrri skrá var notuð, því verkefnið byrjaði frá auðu tré.

## Vænt prófniðurstaða

`Stage01Harness` á að skila öllum grunnprófum sem PASS. Prófin ná yfir `M`, `SAVE`, `dayCount`, `workCounts`, röðun umraðana, fallandi margfeldi, talningu og opnun takmarkaðra samsetninga, talningu og opnun vefja, heilleika `canonicalIndex` og einangrun grunnsamhengis.

## Raunstaða

Elm-verkfærasafnið var ekki tiltækt í afhendingarumhverfinu og ekki var hægt að sækja það. Því voru prófin ekki keyrð og Stage 1 má ekki teljast lokið enn.

## Hvað notandinn þarf að gera

Settu allt tréð inn í nýja grein fyrir þessa Elm+íslensku línu. Keyrðu síðan Elm 0.19.1 prófunarharnessinn. Ef þýðing eða próf bregst skaltu skila nákvæmu Elm-úttakinu; aðeins Stage 1 verður þá lagað. Ekki hefja Stage 2 fyrr en Stage 1 er staðfest grænt og `DEVELOPMENT_STAGE.md` hefur verið uppfært í samræmi við raunverulega keyrslu.

## Tillaga að commit-heiti

`Byggja sjálfstæðan Stage 1 grunn í Elm`

## Tillaga að commit-lýsingu

`Stofnar nýja Elm+íslensku útfærslulínu frá auðu tré. Bætir við hreinni staðlaðri viðmiðunarvél í Elm, nákvæmum ótakmörkuðum heiltölukjarna, Elm-prófunarharnessi, frystum íslenskum SourceLanguageCatalog og hlutlausum grunnlögum fyrir samhengi, stýringu, staðfestingu og mælingar. Engin eldri villa eða leiðrétting úr síðari stigum er komin inn. Prófin eru tilbúin en voru ekki keyrð í afhendingarumhverfinu vegna þess að Elm 0.19.1 verkfærasafnið vantaði.`

## GitHub-athugasemd

`Stage 1 var byggt sjálfstætt frá auðu tré án kóða, prófunargagna, væntra niðurstaðna, gátreikninga eða mismunasamanburðar við aðra útfærslu. SourceLanguageCatalog er frystur og staðlaða röðin byggist eingöngu á canonicalIndex. Afhendingarumhverfið hafði ekki Elm-þýðanda, þannig að commit ætti ekki að merkja Stage 1 sem lokið fyrr en Elm-prófunarharnessinn hefur raunverulega verið keyrður og staðfestur grænn.`
