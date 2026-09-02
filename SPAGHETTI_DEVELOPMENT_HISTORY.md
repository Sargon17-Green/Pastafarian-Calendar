# Þróunarsaga spaghettískrímslisins

## Stage 1 — Bootstrap

### Hvað var byggt

Verkefnið var stofnað frá auðu tré fyrir Elm og íslensku. Sjálfstæður nákvæmur heiltölukjarni var skrifaður í Elm, staðlaða viðmiðunarvélin var endurgerð beint úr innbyggða viðmiðinu og sérstök hrein Elm-prófunarumgjörð var búin til. `SourceLanguageCatalog` var frystur með 17 kótilettum og 47 mánuðum.

### Hlutlaus skrímslagrunnur

Aðeins almenn og merkingarlega hlutlaus grunnlög voru sett inn: kallsamhengi, einfaldur stýringaraðili, staðfestingarmörk og mælingaskel. Engin eldri villa, leiðrétting, samhæfingarleið eða stilling úr framtíðarstigi var sett inn.

### Eign á ástandi

Allt `BaseContext` tilheyrir einu kalli. Mælingar og framkvæmdarslóð eru athugunargögn og mega ekki verða staðlað inntak. Sérstök úttekt staðfesti að `Model`-ræsing, útleiðargátt, prófunarumgjörð, endurnýting óbreytanlegra myndaðra gagna og röð óháðra kalla mynda enga merkingarlega tengingu. `SEMANTIC_STATE_OWNER_VALIDATED` er því `YES` áður en lokakeyrsla fer fram.

### Leiðréttingar innan Bootstrap

Við framhaldsúttekt Stage 1 fundust tvö atriði sem þurfti að laga áður en hægt væri að kalla smíðina tilbúna til þýðingar. Fyrri drög við `NormativeOracle` notuðu fjögurra og fimm staka tuple, sem Elm leyfir ekki; þau voru skipt út fyrir nafngreind record-gildi án merkingarbreytingar. Einnig voru algerar hliðavísitölur færðar úr `Int` í `BigInt` svo að fjarlægir löglegir dagar gætu ekki valdið yfirflæði. Höfnunarteljari stutta valsins var af sömu ástæðu færður í `BigInt`.

Þessar breytingar eru hluti af Bootstrap-innviðum og bæta hvorki við eldri villu né leiðréttingu úr Stage 2–53.

### Prófunarstaða

Kyrrstæð úttekt á Stage 1 finnur nú engan þekktan galla um merkingu, eignarhald eða Elm-sértæka byggingu. Kóðinn er útbúinn fyrir Elm 0.19.1, en afhendingarumhverfið hefur engan Elm-þýðanda, ekkert Elm-pakkaskyndiminni og enga virka nettengingu til að sækja þau. Þess vegna er `LAST_COMPLETED_STAGE` áfram 0 og Stage 1 verður ekki merkt lokið fyrr en Elm-þýðing og öll Stage 1 vitni hafa raunverulega staðist.
