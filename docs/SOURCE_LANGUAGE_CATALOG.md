# Eesti lähtekeele kataloogi reeglid

## Staatus

Selle teostusliini ainus inimkeelne lähtekeel on eesti keel. Kataloogiversioon on `et-EE-stage01-v1`. Pärast esimese etapi kinnitamist käsitletakse 17 kotleti ja 47 kuu `canonicalIndex`-i ning nende eesti lähtevorme külmutatuna.

## Semantiline järjekord

Normatiivne järjekord tuleneb ainult `canonicalIndex`-ist. Eesti stringi ei kasutata sortimiseks, rank/unrank-arvutuseks, juhuvalikuks, semantiliseks vahemäluklahviks ega muu kalendritulemuse määramiseks.

Tee on alati:

```text
kanooniline semantika -> canonicalIndex -> eesti lähtevorm -> võimalik tulevane tõlge
```

Mitte kunagi:

```text
tõlgitud string -> sortimine või aste -> semantika
```

## Tõlkimine

Tavalise leksikaalse tähendusega nimed on tõlgitud eesti keelde tähenduse järgi. Näiteks nisu on `nisu`, jõgi on `jõgi`, sool on `sool` ja suletud ukse nimetus on `suletud uks`. Murdnimed on käsitatud ühe tervikliku nimena: `neli üheksandikku` ja `kolm viiendikku`.

## Kohanimed ja väljamõeldud nimed

Ajalooliste kohanimede puhul kasutatakse eesti kirjakeeles loomulikku või kinnistunud kuju, kui see on olemas: `Lagaš`, `Akad`, `Eridu`, `Uruk`, `Niineve`, `Babülon`.

Väljamõeldud või tähenduseta häälikujadade puhul kasutatakse deterministlikku latiniseerimist, mis säilitab lähtekuju hääldusliku eristuse. Š-häälik kirjutatakse `š`; selgelt märgitud täishäälikud säilitatakse lähima eesti ladinatähega; sõnaalguse ja sõnalõpu konsonandid säilitatakse samas järjestuses. Selle reegli järgi on kaks sellist nime `Palguraš` ja `Karšumav`. Neile ei omistata uut leksikaalset tähendust.

## Esituspiir

Kõik sisemised nimevalikud töötavad indeksitega. Eesti nimi lahendatakse `SourceLanguageCatalog`-ist alles esitus- või lõpptulemuse kihis. Tulevane locale võib muuta ainult kuvatavat tõlget, mitte indeksit ega kalendri struktuuri.
