# Pastafaríska tímatalan — Elm og íslenska

Þetta verkefni er sjálfstæð grunnsmíð Stage 1 fyrir Elm-línuna með íslensku sem eina mannlega frumtextamálið. Verkefnið var stofnað frá auðu tré og notar engin forrit, prófanir, niðurstöður, töflur, skyndiminni, rekjanir eða gátreikninga úr annarri útfærslu.

## Innihald Stage 1

`Pastafari.ExactInt` veitir nákvæman heiltölureikning með ótakmarkaðri stærð, skrifaðan í Elm. `NormativeOracle` er prófunar-eingöngu bein útfærsla á innbyggða staðlaða viðmiðinu. `Pastafari.SourceLanguageCatalog` frystir 17 kótilettunöfn og 47 mánaðanöfn með föstum `canonicalIndex`. `Pastafari.MonsterBase` er aðeins hlutlaus grunnur fyrir samhengi, stýringu, staðfestingu og mælingar. `Pastafari.Spaghetti` inniheldur enn enga eldri villuleið og enga leiðréttingarrökfræði úr síðari stigum.

Hrein prófunarrökfræði er í `tests/Stage01Checks.elm`. `tests/Stage01Harness.elm` er aðeins þunnt Elm-millilag með einni útleiðargátt fyrir textaskýrslu. `STAGE_01_OWNERSHIP_AUDIT.md` skráir sérstaka eignarhaldsúttekt og `STAGE_01_NORMATIVE_AUDIT.md` skráir kyrrstæða úttekt á staðlaða reikniritinu.

## Tungumál og röðun

Öll merkingarbær nöfn eru þýdd eftir merkingu. Staðanöfn og tilbúin nöfn eru meðhöndluð sem sérnöfn. Fyrir tilbúin hebresk hljóðnöfn er eftirfarandi regla fryst: samhljóð eru yfirfærð í næsta íslenskt eða íslenskt-læsilegt hljóðgildi, hebreska sj-hljóðið er ritað `sj`, greinileg sérhljóð úr punktun eru varðveitt með íslenskri lengdarmerkingu þegar það á við og engin ný merking er búin til. Því verða tilbúnu nöfnin hér `Palgúrasj` og `Karsjúmab`.

Staðanöfn með rótgróinni latneskri eða íslenskri ritmynd nota þá ritmynd: `Akkad`, `Erídú`, `Úrúk`, `Níníve` og `Babýlon`. Þessi texti hefur engin áhrif á staðlaða röðun.

Staðlaða röðin byggist eingöngu á `canonicalIndex`. Aldrei má raða eftir íslenskum strengjum, Unicode, stafrófsröð, staðfærsluröðun eða há-/lágstafabreytingu. Allar framtíðarstaðfærslur verða aðeins birtingarlag sem þýðir frá íslenska frumstrengnum og mega ekki hafa áhrif á `rank`, `unrank`, skyndiminnislykla eða val.

## Nákvæmni hliðavísitalna

Algerar hliðavísitölur eru `BigInt`, ekki Elm-`Int`. `GateState` notar kanónískan tugastreng vísitölunnar sem `Dict`-lykil, en staðlaðar samanburðar- og röðunaraðgerðir nota alltaf `BigInt` sjálft. Því getur mjög fjarlægur dagur ekki breytt niðurstöðu vegna `Int`-yfirflæðis. Aðeins staðbundnir stærðarfjöldar sem eru sannað bundnir af 5778 daga ársmarkinu eru færðir í `Int`.

## Keyrsla prófana

Fyrst skal láta Elm 0.19.1 þýða allt prófunartréð:

```text
elm make tests/Stage01Harness.elm --output=stage01.js
```

Hrein próf má síðan keyra beint í Elm-verkfærakeðjunni án sérsmíðaðs hjálparkóða í öðru forritunarmáli:

```text
elm repl
> import Stage01Checks
> Stage01Checks.allPassed
> Stage01Checks.summary
```

`Stage01Checks.allPassed` á að vera `True` og `Stage01Checks.summary` á aðeins að innihalda PASS-línur og lokayfirlit um að öll vitni hafi staðist. Útleiðargáttin í `Stage01Harness` er valfrjáls birtingarleið fyrir sömu fullgerðu skýrslu; engin reiknirit eða vænt gildi mega vera reiknuð utan Elm.

Í afhendingarumhverfinu sem bjó til þennan pakka var Elm-þýðandinn ekki tiltækur. Elm-pakkaskyndiminni var heldur ekki til staðar og nettenging úr keyrsluumhverfinu var óvirk, þannig að ekki var hægt að sækja verkfærakeðjuna. Því er ekki heimilt að halda því fram að prófin hafi verið keyrð eða að staða verkefnisins sé staðfest græn fyrr en raunveruleg Elm 0.19.1 keyrsla hefur farið fram.
