# Calendr Pastaffaraidd — Kotlin + Cymraeg

Mae'r goeden hon yn cynnwys Cam 1 wedi'i gwblhau a delta Cam 2 (`DISCOVERY 01`) o linell weithredu annibynnol `Kotlin + Cymraeg`.

Dechreuwyd y llinell hon o sero. Ni chafodd cod, profion, gosodiadau, allbynnau disgwyliedig, tablau a gynhyrchwyd, logiau, cipluniau na hashnodau eu benthyca o unrhyw weithrediad arall. Mae'r cyfeirnod normadol prawf-yn-unig wedi'i ysgrifennu o'r newydd yn Kotlin ar sail Atodiad A y fanyleb a roddwyd ar gyfer y llinell hon.

## Cynnwys Cam 1

- gweithrediad rhif cyfan manwl-gywir wedi'i ysgrifennu yn Kotlin;
- cyfeirnod normadol prawf-yn-unig ar gyfer y saws, y dewiswyr, y gatiau, y blynyddoedd, y cytledi, y misoedd a'r gwead;
- `SourceLanguageCatalog` wedi'i rewi ar gyfer 17 enw cytled a 47 enw mis;
- sgerbwd cynhyrchu niwtral: cyd-destun sylfaenol, dosbarthwr, dilysydd, lapiwr gwallau a chragen metrigau;
- cynhyrchydd gosodiadau yn Kotlin;
- cyfres brofion leol yn Kotlin.

## Cam 2 — Darganfod 01

Mae `LegacyRemainderAdapter.oldRemainder` yn defnyddio gweddill Ewclidaidd arferol modulo `M`, nid `SAVE`. Mae'r llwybr cynhyrchu `MonsterBootstrapManager.observeLegacyRemainder` yn mynd drwy `BOOT`, yna `DISCOVERY_01`, ac yn cadw'r canlyniad etifeddol yng nghyd-destun y galwad.

Mae'r pedwar tyst `M`, `2M`, `3M` a `M+1` yn dangos tri gwahaniaeth normadol a chyfatebiaeth olaf. Mae hyn yn **EXPECTED_RED** bwriadol: nid oes `savePatch`, trosi sero i `M` na chod Patch 01 yn y cam hwn. Nid yw'r haen gynhyrchu yn galw'r cyfeirnod prawf.

## Adeiladu a phrofi

O wraidd y prosiect:

```text
sh run-stage01-tests.sh
sh run-stage02-tests.sh
```

I ailgynhyrchu'r gosodiadau Cam 1:

```text
sh generate-stage01-fixtures.sh
```

Cafwyd `STAGE01_PASS_66`, `STAGE02_EXPECTED_RED_3` a `STAGE02_STRICT_RED_CONFIRMED` wrth redeg y profion yn frodorol ar ffynonellau gwreiddiol y gangen, heb stubs.

## Archwiliad ychwanegol o'r delta

Mae prawf ynysig gyda `ExactInt.kt` gwreiddiol y gangen (Git SHA wedi'i
wirio) wedi pasio, gan gynnwys ffiniau negatif a pherchnogaeth cyd-destun.
Nid oedd y prawf cynnar hwn yn ddigon ar ei ben ei hun; cofnodir ardystiad Cam 2 yn adran v005 isod.

## Archwiliad cryfach v003

Mae Cam 2 bellach yn rhedeg 195 tyst cyfnodol, archwiliad rhif negyddol
pell, a gwiriad gwrthod handler heb BOOT. Rhaid i'r prawf Cam 1 argraffu
`STAGE01_PASS_66` yn union. Darganfuwyd nam annibynnol yn
`ExactInt.toLongExact()` gyda `Long.MIN_VALUE`; nid yw wedi'i guddio
na'i atgyweirio yng nghod hanesyddol Cam 2.

## Gwirio tarddiad Cam 2

Mae `sh run-stage02-tests.sh` yn mynnu'r gangen `Kotlin+Cymraeg`
a'r pum ffeil ffynhonnell Cam 1 union yn ôl Git blob SHA cyn rhedeg
y profion. Mae'r gweithdrefn hon yn atal disodli'r cyfeirnod normadol
gan amnewidyn sy'n argraffu marc llwyddiant. Nid yw'r prawf yn
newid SAVE nac yn ychwanegu PATCH 01.

## Cadarnhad Cam 2 — v005

Ar 11 Hydref 2026, cafodd y pum ffeil craidd ar gyfer y profion a'r
`Stage01FixtureGenerator.kt` eu hailadeiladu mewn coeden waith ar wahân o
ffynonellau â Git blob SHA union y gangen `Kotlin+Cymraeg`. Defnyddiwyd metadata
Git lleol newydd ar gyfer gwiriad enw'r gangen; **nid clon o holl hanes Git
yw hwn**. Nid oedd angen unrhyw stub na mopheth rhannol.

Cafwyd cod ymadael `0` o `sh run-stage02-tests.sh`, pasiodd pob un o'r 66 prawf
Cam 1, a datgelodd Cam 2 yr union dri gwahaniaeth bwriadol. Cynhyrchodd
`generate-stage01-fixtures.sh` yr un blob yn union â fixture Cam 1 a gedwir
yn y gangen. Gwrthododd y gwarchodwr ffynhonnell gangen anghywir ac oracl
wedi'i newid. Felly mae Cam 2 wedi'i gwblhau, ond nid yw'r cam hwn wedi'i
lanlwytho na'i commitio i'r ystorfa bell.

Mae canfyddiad ar wahân ynghylch `ExactInt.toLongExact` ar `Long.MIN_VALUE`
yn dal ar agor; nid yw'n rhan o Patch 01 ac ni chafodd ei guddio.
Y cam nesaf yw Cam 3 — PATCH 01 yn unig.
