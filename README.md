# Calendr Pastaffaraidd — Kotlin + Cymraeg

Mae'r goeden hon yn cynnwys Camau 1–4 sydd wedi'u dilysu'n frodorol: mae Cam 4 (`DISCOVERY 02`) yn cadw tri anghysondeb disgwyliedig, ac mae llwybrau Camau 1–3 yn aros yn weithredol. Daw'r llinell weithredu annibynnol o `Kotlin + Cymraeg`.

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


## Cam 3 — Patch 01: lapio'r weddill etifeddol

Mae'r handler newydd `PATCH_01` yn galw `LegacyRemainderAdapter.oldRemainder`
**yn gyntaf**, ac yna'n pasio'r gweddill hwnnw i
`SavePatchWrapper.savePatch`: os yw'r gweddill yn `0`, dychwelir `M`;
fel arall caiff y gwerth ei gadw. Mae hyn yn gweithredu SAVE ar gyfer
unrhyw fewnbwn cyfanrif, gan gynnwys rhifau negatif a gwerthoedd pell.
Nid yw'r gweithrediad etifeddol na'r llwybr `DISCOVERY_01` wedi'u
newid. Cedwir mewnbwn, gwerth etifeddol a gwerth cywir mewn cyd-destun
galwad newydd ar wahân.

```text
sh run-stage03-tests.sh
```

Mae'r sgript yn rhedeg Cam 1 a Cham 2 yn gyntaf, gan fynnu'r tri
gwahaniaeth etifeddol, ac yna brofion gwyrdd Patch 01. Cyn yr archwiliad
brodorol terfynol, llwyddodd preflight Kotlin yn erbyn amnewidion prawf
ar wahân i'r ystorfa. **Nid yw'r preflight hwn yn ardystio Cam 3**.
Mae `LAST_COMPLETED_STAGE=2` hyd nes bod y rhediad llawn yn PASS.


## Cadarnhad brodorol Cam 3 (11 Hydref 2026)

**Diweddariad sy'n disodli'r statws PENDING uchod:** Wedi llwytho
delta v002, cafwyd gwall integreiddio: roedd sgriptiau Cam 1 a Cham 2
yn hepgor `SavePatchWrapper.kt` wrth gydosod. Mae'r delta terfynol yn
cywiro'r ddwy sgript, heb newid y cod cynhyrchu.

Llwyddodd y rhediad llawn `sh run-stage03-tests.sh` gyda'r pum blob
ffynhonnell gwreiddiol ac oracl calendr llawn. Cod ymadael: **0**.
Pasiodd 66 prawf Cam 1, cadwyd tri gwahaniaeth disgwyliedig Cam 2,
ac ni chafwyd gwahaniaethau yn PATCH 01; pasiodd 921 achos annibynnol.
`LAST_COMPLETED_STAGE=3`. Y cam nesaf yw Cam 4 — `DISCOVERY 02`.

Mae'r cam diweddaru hwn yn cynnwys **y ddwy sgript brofi, a dogfennaeth
a metadata yn unig**. Peidiwch â llwytho'r logiau HANDOFF_ONLY i'r gangen.

## Cam 4 — Darganfod 02: craith tag dydd y Sylfaen

Mae `LegacyDayTagAdapter.oldDayTag(day)` yn cyfrifo `2 × abs(day − F)`,
lle `F = −15055671`. Nid yw'r hen lwybr hwn yn galw'r oracl normadol,
ac nid oes cywiriad PATCH 02 ynddo. Mae'r handler `DISCOVERY_02` yn
pasio drwy `BOOT`, yn storio'r mewnbwn a'r allbwn anghywir yng nghyd-destun
y galwad, ac yn gadael llwybrau Cam 2 a Cham 3 yn hygyrch ac yn ddigyfnewid.

Y canlyniadau gorfodol wrth gymharu â'r oracl prawf yn unig yw:

| Diwrnod | Hen dag | Tag normadol | Dosbarthiad |
|---|---:|---:|---|
| F−2 | 4 | 4 | CYFATEB |
| F−1 | 2 | 2 | CYFATEB |
| F | 0 | 1 | EXPECTED_RED |
| F+1 | 2 | 3 | EXPECTED_RED |
| F+2 | 4 | 5 | EXPECTED_RED |

Defnyddiwch `sh run-stage04-tests.sh` o gangen `Kotlin+Cymraeg` yn unig.
Mae'r sgript yn mynnu bod y 66 prawf Cam 1, prawf coch Cam 2, prawf
gwyrdd Cam 3 a'r 921 prawf estynedig oll yn pasio **cyn** gwirio Cam 4.
Mae'r gwiriad strict ar gyfer Cam 4 i fod i fethu, a gwneir hynny'n
amod cadarnhaol yn y sgript. Dim ond **un cam** sy'n cael ei ychwanegu:
ni chynhwysir unrhyw gywiriad y diwrnod na chyfrifiad pellter newydd.

**Statws ar ôl dilysiad brodorol:** Cam 4 wedi'i gwblhau fel
`EXPECTED_RED`; mae pob prawf Cam 1–3 yn parhau i basio, ac mae'r hen
tag dydd yn parhau'n anghywir yn fwriadol. Cam 5 / PATCH 02 yw'r cam
nesaf.


### Atgyfnerthu profion Cam 4 (v002)

Ychwanegwyd 60 prawf metamorffig ar gyfer diwrnodau cyn ac ar ôl y
Sylfaen gyda meintiau mawr hyd at 289 digid, ynghyd â gwerthoedd ger
`M` a'i lluosrifau. Gwiriwyd bod y tag a ddewiswyd yn dod o'r ddadl
`day`, nid o `calculationDay` na `targetDay`. Mae prawf ail-ddosbarthu'r
un cyd-destun yn mynnu ei wrthod heb newid allbwn, diagnosteg,
olrhain na metrigau. **Nid oes PATCH 02 yn y pecyn hwn.**


### Prawf annibynnol ychwanegol Cam 4 — v003

Mae `Stage04BigIntegerTests.kt` yn defnyddio `java.math.BigInteger` **yn y
profion yn unig** i wirio'r hen dag dydd, y cyfrif normadol a'r llwybr
cynhyrchu trwy'r dosbarthwr. Mae'r set benodol yn cynnwys 409 achos:
204 cyn y Sylfaen, 204 ar ei hôl, ac un achos ar y Sylfaen ei hun.
Mae'n defnyddio had sefydlog, meintiau hyd at 2,048 bit, a'r ffiniau
`M−1`, `M`, `M+1` a lluosrifau o `M`. Y disgwyl yw 204 cydweddiad
cyn y Sylfaen a 205 anghysondeb bwriadol ar ei hôl ac arni.

Nid yw'r estyniad hwn yn newid y pum tyst canonaidd na'r hen graith.
Mae `run-stage04-tests.sh` bellach yn mynnu
`STAGE04_BIGINT_INDEPENDENT_PASS_409` a
`STAGE04_BIGINT_RED_205_MATCH_204` cyn cadarnhau'r methiant strict
bwriadol. **Dim PATCH 02.**

**Ail-redeg v003:** llwyddodd `sh run-stage04-tests.sh` ar y
ffeiliau gwreiddiol â chod ymadael `0`, gan gynnwys yr holl farciau
Camau 1–3 a'r 409 prawf BigInteger annibynnol. Y cam nesaf yw
Cam 5 yn unig ar ôl lanlwytho Cam 4.
