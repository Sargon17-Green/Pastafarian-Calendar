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


## Cam 5 — Patch 02: tag diwrnod y Sylfaen

Mae `DayTagPatchWrapper.kt` yn cywiro'r tag dydd **ar ôl** galw'r
hen `LegacyDayTagAdapter.oldDayTag` yn union unwaith drwy'r dosbarthwr.
Cedwir `oldDayTag` heb newid ac mae `DISCOVERY_02` yn dal i gofnodi
tri anghysondeb disgwyliedig. Mae'r llwybr `PATCH_02` yn cadw
`patch02Input`, `patch02LegacyOutput` a `patch02Output` ar bob cyd-destun.
Mae'r gard `day == foundationDay` yn ddiangen yn fathemategol ond yn
fwriadol bresennol yn y patch hanesyddol.

Ar gyfer `F−2,F−1,F,F+1,F+2`, mae'r llwybr newydd yn dychwelyd
`4,2,1,3,5`. Mae'r hen lwybr yn aros yn `4,2,0,2,4`.

Defnyddiwch `sh run-stage05-tests.sh` o wreiddyn y gangen i ailbrofi
Camau 1–4 ac yna Cam 5. Mae'r profion newydd yn cynnwys 331 diwrnod,
60 achos mawr a 418 achos annibynnol `BigInteger` hyd at 2,048 did.
Ni ddefnyddir `BigInteger` mewn cod cynhyrchu.

**Statws y pecyn hwn:** mae'r cod Kotlin wedi'i lunio a'r profion
Cam 5 wedi pasio gyda'r union `ExactInt.kt` gwreiddiol. Nid yw hyn yn
disodli rhedeg holl oracl Cam 1 a'r gadwyn Camau 1–5; cadwir
`LAST_COMPLETED_STAGE=4` nes bod `STAGE05_NATIVE_GREEN` yn pasio
ar y gangen lawn. Ni weithredwyd unrhyw beth o Gam 6.


### Cadarnhad brodorol terfynol Cam 5 — GitHub Actions

**Mae'r cofnod hwn yn disodli'r statws PENDING uchod.** Llwyddodd swydd
`native-stage05-kotlin-cymraeg` yn llif gwaith presennol
`canonical-names-lock.yml` ar y gangen `Kotlin+Cymraeg` gyda Kotlin 1.9.0
a JDK 21. Defnyddiwyd y pum ffeil ffynhonnell/oracl gwreiddiol heb
amnewidion, ac ail-redwyd `sh run-stage05-tests.sh` o wraidd yr ystorfa.

Cadarnhawyd cod ymadael 0 a'r marc `STAGE05_NATIVE_GREEN`, ynghyd â
`STAGE01_PASS_66`, `STAGE02_EXPECTED_RED_3`,
`STAGE03_EXTENDED_BIGINT_GREEN_921`, `STAGE04_EXPECTED_RED_3`,
`STAGE04_BIGINT_INDEPENDENT_PASS_409`, `STAGE05_PATCH_GREEN_0` a
`STAGE05_BIGINT_INDEPENDENT_PASS_418`. Mae'r ddau brawf strict yn methu
**yn fwriadol** ac mae eu methiannau disgwyliedig wedi'u dilysu.

Tystiolaeth: [GitHub Actions — rhediad 38173345431](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38173345431),
commit gwreiddiol `b832b6430fb6b2beea09234a97f06e3a07f09a18`.
**`LAST_COMPLETED_STAGE=5`; y cam nesaf yw Cam 6 / DISCOVERY 03.**
Ni newidiwyd cod y llwybr etifeddol na dechrau Cam 6.


## Cam 6 — DISCOVERY 03: pellter o wahaniaeth dau dag dydd

Mae `LegacyDistanceAdapter.oldDistance(c,t)` yn cyfrifo gwahaniaeth absoliwt y tagiau dydd o PATCH 02. Nid yw'n defnyddio pellter cronolegol cynhwysol. Mae'r nam hanesyddol yn dal yn weithredol: ymhlith wyth tyst canonaidd ceir 5 `EXPECTED_RED` a 3 `MATCH`.

Ceir 441 prawf matrics a 549 prawf `BigInteger` annibynnol, gwarchodion cyd-destun a methiant strict disgwyliedig. Dylid ail-redeg `sh run-stage06-tests.sh` gyda'r holl ffynonellau gwreiddiol. Ni weithredwyd PATCH 03. Arhosir am dystysgrif brodorol cyn newid `LAST_COMPLETED_STAGE=5`.

**Ardystiad Cam 6:** llwyddodd yr holl atchweliadau Camau 1–6 ar GitHub Actions gyda Kotlin 1.9.0/JDK 21 a'r oracl Cam 1 gwreiddiol. Cadarnhawyd pob un o'r 21 marc prawf, gan gynnwys pum gwahaniaeth disgwyliedig a thair cyfatebiaeth. Rhediad: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38178119854 . Mae `LAST_COMPLETED_STAGE=6`. PATCH 03 yw'r cam nesaf.


## Cam 7 — PATCH 03: pellter cronolegol cynhwysol

Cadwyd `LegacyDistanceAdapter.oldDistance` o Gam 6 heb ei newid. Mae'r llwybr `BOOT → PATCH_03` yn galw'r hen gyfrifiad yn gyntaf, yna'n cyfrifo `abs(target-calculation)` ac yn disodli'r hen sail **dim ond os yw'n wahanol**. Ychwanegir `+1` yn derfynol bob tro, hyd yn oed pan na chafwyd disodli. Cedwir y ddwy sail, y faner disodli a'r canlyniad mewn cyd-destun sy'n eiddo i'r galwad.

Mae wyth tyst, 441 achos matrics, 549 prawf `BigInteger` annibynnol, ac amddiffyniadau ail-alw/BOOT wedi pasio mewn prawf JVM wedi'i ynysu. **Rhaid** i `sh run-stage07-tests.sh` basio ar y gangen wreiddiol cyn datgan Cam 7 wedi'i gwblhau. `LAST_COMPLETED_STAGE=6` hyd nes hynny. Ni ddechreuwyd Cam 8.

**Ardystiad terfynol Cam 7:** llwyddodd `run-stage07-tests.sh` yn gyfan gwbl o fewn GitHub Actions gyda'r ffynonellau gwreiddiol, yr oracl normadol gwreiddiol, Kotlin 1.9.0 a JDK 21. Cadarnhawyd `STAGE07_NATIVE_GREEN`, wyth tyst gwyrdd, 441 achos matrics a 549 prawf BigInteger annibynnol. Mae'r hen bump anghysondeb Cam 6 wedi'u cadw; cafwyd sero anghysondeb PATCH 03. Mae **`LAST_COMPLETED_STAGE=7`** ac mae Cam 8 / DISCOVERY 04 yn nesaf. Tystiolaeth: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38180495340


## Cam 8 — DISCOVERY 04: cerrig wedi'u diwygio fesul maes

Y graith fwriadol yw `LegacyStoneBuilder.mutateStonesWrong`: diweddarir gwenith, barlys, halen, chwerw a choch **yn yr un gwrthrych byw**, a bydd y fformiwlâu olaf yn gweld gwerthoedd newydd yn lle ciplun o'r hen res. Mae rhes 1 yn gywir (`17,29,43,71,101`), ond mae 224 o 225 cydran rhesi 2–46 yn anghydweddu â'r oracl.

Mae `BOOT → DISCOVERY_04` yn ymrwymo 46 rhes i gyd-destun pob galwad ar wahân. Mae `run-stage08-tests.sh` yn cynnwys prawf strict sy'n methu yn fwriadol a 230 cydran wedi'u gwirio'n annibynnol gan `BigInteger`. Mae'r prawf llawn GitHub Actions yn aros; nid yw Cam 9 / PATCH 04 wedi'i weithredu, ac mae `LAST_COMPLETED_STAGE=7` hyd nes ardystiad llawn.

**Ardystiad Cam 8:** ar commit `051a928af4cc5166fc5884f80db48c530b5c5931` llwyddodd holl brofion Camau 1–8 gyda'r oracl gwreiddiol, Kotlin 1.9.0 a JDK 21. Cadarnhawyd 30 marc log: `STAGE08_EXPECTED_RED_224`, `STAGE08_MATCH_1`, `STAGE08_BIGINT_INDEPENDENT_PASS_230`, `STAGE08_STRICT_RED_CONFIRMED` a `STAGE08_NATIVE_EXPECTED_RED_COMPLETE`, ynghyd â phob atchweliad blaenorol. **`LAST_COMPLETED_STAGE=8`**. Nid yw Cam 9 wedi'i ddechrau. Tystiolaeth: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38183229336


## Cam 9 — PATCH 04: ciplun y pum carreg

Mae `StonePatchWrapper.stonePatch` yn cadw ciplun o'r hen res, yn galw'n wirioneddol y mutator hanesyddol `mutateStonesWrong` ar glôn annibynnol, ac yn cadw'r `legacyGarbage`. Mae'n ailgyfrifo'r pum carreg yn llwyr o'r ciplun, heb ddarllen canlyniadau canolradd y mutator. Mae `BOOT → PATCH_04` yn ymrwymo'r ddau dabl i'r cyd-destun, gyda 45 galwad etifeddol a 46 rhes.

Mae `run-stage09-tests.sh` yn cynnwys atchweliadau Camau 1–8, pob un o'r 230 cydran gywir, cadw 224 anghysondeb DISCOVERY 04, prawf BigInteger annibynnol a gwarchodion perchnogaeth. Arhosir am PASS brodorol ar Kotlin 1.9.0/JDK 21 cyn newid `LAST_COMPLETED_STAGE=8`. Ni ddechreuwyd Cam 10.

**Ardystiad Cam 9:** llwyddodd `sh run-stage09-tests.sh` ar gangen `Kotlin+Cymraeg` gyda Kotlin 1.9.0, JDK 21 a'r oracl normadol gwreiddiol. Cafwyd `STAGE09_PATCH_GREEN_0`, `STAGE09_WHOLE_TABLE_GREEN_230`, `STAGE09_BIGINT_INDEPENDENT_GREEN_230`, `STAGE09_PRESERVED_DISCOVERY04_RED_224` a `STAGE09_NATIVE_GREEN`, gyda holl atchweliadau Camau 1–8 yn PASS. **`LAST_COMPLETED_STAGE=9`**. Cam 10 (`DISCOVERY 05`) sydd nesaf; nid yw wedi dechrau. Tystiolaeth: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38186462459


## Cam 10 — DISCOVERY 05: storio diferion cudd yn ôl

Mae `LegacyHiddenDropAdapter` yn cyfrifo'r saith diferyn cudd drwy'r cyfrifon diwrnod a'r cerrig a gywirwyd eisoes. Mae'r tabl cyfernodau corfforol yn y drefn wrthdro, ond defnyddir cyfernod cywir y diferyn wrth ei gyfrifo. Cedwir y canlyniadau'n gorfforol fel `hidden7,hidden6,hidden5,hidden4,hidden3,hidden2,hidden1`. Mae'r hen ddarllenydd `legacyHiddenDirectByAssumedNearness` yn dychwelyd slot `k` fel petai'r storfa'n rhedeg ymlaen: ceir pedwar anghysondeb ar `k=1,2,6,7` ac un cyfatebiaeth ar `k=4`.

Mae `BOOT → DISCOVERY_05` yn rhedeg PATCH 02/03/04 cyn y cam storio, yn cadw'r rhesi cerrig, y storfa gudd a'r darlleniad anghywir mewn cyd-destun ar wahân. Ceir prawf annibynnol BigInteger dros bum pâr o ddiwrnodau (35 gwerth cudd, 175 cydran carreg), gwarchodion a methiant strict bwriadol. Mae'r prawf brodorol llawn yn aros am GitHub Actions; **`LAST_COMPLETED_STAGE=9`** nes hynny. Ni weithredwyd PATCH 05.

**Ardystiad Cam 10:** llwyddodd `sh run-stage10-tests.sh` ar commit `b2c0a978ca452545c98ff9a7349c6cddd5db345b`, gyda'r oracl a'r ffynonellau gwreiddiol, Kotlin 1.9.0 a JDK 21. Mae pob un o 24 marc wedi'i gadarnhau yn y log, gan gynnwys pedwar `EXPECTED_RED`, un `MATCH`, 35 cyfrifiad BigInteger annibynnol a 175 cydran carreg. Mae holl atchweliadau Camau 1–9 wedi pasio. **`LAST_COMPLETED_STAGE=10`**; Cam 11 (`PATCH 05`) yw'r nesaf, heb ei ddechrau. Tystiolaeth: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38214703144


## Cam 11 — PATCH 05: trosi trefn agosrwydd y diferion cudd

Cedwir y storfa ffisegol wrthdro o Gam 10 yn union, a cedwir y darllenydd anghywir `storage[k]` yn weithredol. Mae `HiddenNearnessPatchWrapper.patch` yn **galw'r hen ddarllenydd yn gyntaf** a chofnodi ei werth, ac yn defnyddio'r trosiad `8-k` ar ôl hynny i ddychwelyd y diferyn cywir. Mae `BOOT → PATCH_05` yn cadw'r storfa, y safle ffisegol, yr hen werth, y gwerth cywir, y statws a nifer galwadau mewn cyd-destun pob galwad.

Rhaid i bob un o saith safle k=1..7 fod yn GREEN, tra bo'r pedwar anghysondeb etifeddol k=1,2,6,7 yn aros yn alwadadwy a'r canolbwynt k=4 yn dal yn gyfatebiaeth. Mae 35 prawf BigInteger annibynnol ac 175 cydran carreg yn cael eu gwirio ar bum pâr diwrnod. **`LAST_COMPLETED_STAGE=10` hyd nes bod `run-stage11-tests.sh` yn llwyddo ar GitHub Actions.** Ni ddechreuwyd Cam 12.

**Ardystiad Cam 11:** pasiodd `sh run-stage11-tests.sh` gyda'r cod a'r oracl gwreiddiol ar Kotlin 1.9.0/JDK 21, commit ffynhonnell `326c843d2fb8a7f5c070362113a3284c4cbe6aac`. Gwiriwyd 30 marc yn log GitHub Actions: `STAGE11_PATCH_GREEN_7`, `STAGE11_PRESERVED_DISCOVERY05_RED_4`, `STAGE11_FIXED_MIDPOINT_K4_GREEN`, `STAGE11_BIGINT_INDEPENDENT_GREEN_35`, `STAGE11_BIGINT_PATCH04_STONES_GREEN_175` a `STAGE11_NATIVE_GREEN`, ynghyd â holl atchweliadau Camau 1–10. **`LAST_COMPLETED_STAGE=11`**. Cam 12 (`DISCOVERY 06`) yw'r cam nesaf, heb ei ddechrau. Tystiolaeth: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38222120118


## Cam 12 — DISCOVERY 06: legacyPrior yn gweld hanes gweledig yn unig

Mae `LegacyPriorAdapter.legacyPrior(visibleStore,i,back)` yn cyfrifo `i-back`, ond nid yw'n gallu darllen slotiau hanes cudd. Yn ôl yr oracl, slot 0 yw hidden1, slot -2 yw hidden3, a slot -6 yw hidden7; mae'r hen ddarllenydd yn dychwelyd `null` yn y tri achos, felly ceir **tri `EXPECTED_RED`, sero `MATCH`**. Cedwir prawf positif `i=2,back=1` ar slot gweledig 1 yn y llwybr cynhyrchu, gan ddefnyddio hidden1 a gywirwyd gan PATCH 05 fel gwerth profi yn unig (nid oes adeiladwr diferion gweledig eto).

Mae'r profion yn gwirio camau 1–11, 15 diffyg hanes cudd dros bum pâr diwrnod, 35 gwerth BigInteger annibynnol, 175 cydran carreg, guardiau a methiant strict bwriadol. Mae `LAST_COMPLETED_STAGE=11` tan ardystiad brodorol. Ni ddechreuwyd `priorPatch` na Cham 13.

**Ardystiad Cam 12:** llwyddodd `run-stage12-tests.sh` gyda'r cod a'r oracl gwreiddiol ar Kotlin 1.9.0/JDK 21, commit `7fac959fc06edb8c59d0b7f0105fbf91151da87b`. Gwiriwyd 30 marc yn uniongyrchol yn y log, gan gynnwys tri `EXPECTED_RED`, 15 tyst BigInteger coll, 35 cyfrifiad cudd, 175 cydran carreg, methiant strict bwriadol a holl atchweliadau Camau 1–11. **`LAST_COMPLETED_STAGE=12`**, y cam nesaf yw Cam 13 (`PATCH 06`). Ni weithredwyd `priorPatch`. Tystiolaeth: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38224902493


## Cam 13 — PATCH 06: hanes gweledig a hanes cudd

Cyfrifir `slot=i-back` gan `PriorPatchWrapper.priorPatch`. Pan fo'r slot yn bositif, **galwir yr hen `LegacyPriorAdapter.legacyPrior`**, heb ddibyniaeth ar storfa gudd. Pan fo `slot<=0`, cyfrifir `hiddenK=1-slot` a darllenir y diferyn cywir drwy `HiddenNearnessPatchWrapper.hiddenByNearness`. Nid yw'r gangen gudd yn galw'r helper raw; cedwir diffygion Cam 12 yn weladwy. Mae'r llwybr cynhyrchu `BOOT → PATCH_06` yn cofnodi'r slot, y gangen, y gwerth wedi'i gywiro a'i ddata mewn cyd-destun unigol.

Bydd `run-stage13-tests.sh` yn ail-redeg Camau 1–12 a gwirio pob un o saith `hiddenK`, y gangen bositif, 35 cyfrifiad BigInteger annibynnol a phum darlleniad positif, gan gadw'r 15 `EXPECTED_RED` hen. Mae `LAST_COMPLETED_STAGE=12` tan PASS y CI brodorol. Ni ddechreuwyd Cam 14.

**Ardystiad Cam 13:** llwyddodd `sh run-stage13-tests.sh` ar commit `d043e234822f57250bf5f178a32aee16e5ceb875`, gyda Kotlin 1.9.0, JDK 21, y ffynonellau gwreiddiol a'r oracl normadol gwreiddiol. Gwiriwyd 35 marc log: pob atchweliad Camau 1–12, 7 darlleniad cudd yn GREEN, galwad wirioneddol i `legacyPrior` ar slot positif, 3 `EXPECTED_RED` wedi'u cadw, 35 prawf BigInteger cudd, 5 darlleniad positif a 175 cydran carreg. **`LAST_COMPLETED_STAGE=13`**. Cam 14 (`DISCOVERY 07`) yw'r nesaf; ni ddechreuwyd. Tystiolaeth: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38227553115


## Cam 14 — DISCOVERY 07: mynegai zero-based yr unarddeg malu

Mae `LegacyGrindTableAdapter` yn storio 11 rhes grŵp malu gwirioneddol, heb sentinel, mewn trefn zero-based. Mae'r hen helper `legacyGrindRow(grind)` yn defnyddio ordinal 1-based yn union fel index ffisegol: grind 1 yn darllen rhes normadol 2, grind 10 yn darllen rhes 11, a grind 11 yn dychwelyd `undefined`. Mae **11 `EXPECTED_RED` ac 0 `MATCH`**. Mae `BOOT → DISCOVERY_07` yn galw'r hen helper yn wirioneddol, yn cadw'r index uniongyrchol a'r rhes anghywir neu `null`, ac yn gwahanu'r cyflwr rhwng galwadau.

Mae `run-stage14-tests.sh` yn rhedeg Camau 1–13 ac yn gwirio'r 11 rhes, 66 tyst `BigInteger` annibynnol, gwarchodion a methiant strict bwriadol. **`LAST_COMPLETED_STAGE=13` nes bod y CI brodorol wedi pasio.** Nid oes sentinel, PATCH 07 na chyfrifiad diferion gweledig yng Ngham 14.

**Ardystiad Cam 14:** llwyddodd `sh run-stage14-tests.sh` ar commit `634b30b4ccdf2830b0cb16a98d19e689462ea8e4`, Kotlin 1.9.0 a JDK 21 gyda'r ffynonellau ac oracl gwreiddiol. Gwiriwyd 43 marc yn y log GitHub Actions: 11 `EXPECTED_RED` ac 0 `MATCH`, grind 1→rhes 2, grind 10→rhes 11, grind 11→`undefined`, 66 tyst BigInteger annibynnol, prawf strict disgwyliedig a holl atchweliadau Camau 1–13. **`LAST_COMPLETED_STAGE=14`**. Cam 15 (`PATCH 07`) yw'r nesaf; nid yw wedi'i ddechrau. Tystiolaeth: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38233182742


## Cam 15 — PATCH 07: cyfieithydd sentinel y rhesi malu

Mae'r adapter DISCOVERY 07 yn parhau'n union fel yr oedd. Mae
`GrindPatchWrapper.patch` yn galw'r darllenydd hen yn gyntaf ac yna'n
creu golwg gyda sentinel `null` yn safle 0; mae ordinal 1..11 yn darllen
rhes 1..11 yn gywir heb drosysgrifo'r tabl ffisegol. Mae
`MonsterBootstrapManager.applyGrindPatch` yn cadw'r hen wahaniaeth,
yr allbwn cywir a pherchnogaeth pob galwad. Nid yw Cam 15 yn adeiladu
diferion gweledig. Mae'r ardystiad Kotlin/JVM brodorol yn aros am CI;
cedwir `LAST_COMPLETED_STAGE=14` hyd at hynny.


## Ardystiad brodorol Cam 15 — COMPLETE

Ar commit `40bf4f7c9e3b4395a03a055f8ae5d5a5a4850714` llwyddodd rhediad GitHub Actions
[`38244045455`](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38244045455),
swydd Kotlin `114793412444`, gyda Kotlin 1.9.0 a JDK 21.
Gwiriwyd 23 marc allweddol yn uniongyrchol o'r log (a phob un o'r
11 marc grind unigol): Camau 1–14, 11 cyfieithiad cywir,
11 graith etifeddol RED, 66 prawf BigInteger cywir, 60 hen wall rhifol
a 6 hen achos undefined, gwarchodion BOOT/replay, perchnogaeth,
a holl lwybrau blaenorol. Gwelwyd `STAGE15_FULL_NATIVE_GREEN`;
gorffennodd y swydd frodorol a swydd cloi enwau gyda `SUCCESS`.
**`LAST_COMPLETED_STAGE=15`**. Cam 16 (`DISCOVERY 08`) yw'r nesaf,
heb ei ddechrau. Nid yw'r adeiladwr diferion gweledig wedi'i weithredu.


## Cam 16 — DISCOVERY 08: derbyn ordinal one-based gan unrank zero-based

Mae `oldPermutationUnrank0` yn gywir ar 0..719 ond mae'r caller
hanesyddol yn pasio `mod(drop-1,720)+1` yn uniongyrchol iddo.
Canlyniad: 719 cyfnewidiad anghywir, un `undefined` ar 720,
720/720 `EXPECTED_RED` a 0 `MATCH`. Mae
`MonsterBootstrapManager.observeLegacyPermutation` yn cofnodi'r
graith heb PATCH 08 na gwerth cywir cynhyrchu. Ni ddechreuwyd
adeiladwr diferion gweledig na pours. `LAST_COMPLETED_STAGE=15`
nes bo'r CI brodorol wedi pasio.


## Ardystiad brodorol Cam 16 — COMPLETE

Ar commit `3cf687cc17a799e01528b0e3e9ff04740190d97e` pasiodd GitHub Actions
[`38246266578`](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38246266578),
swydd `114800790604`, gyda Kotlin 1.9.0/JDK 21.
Gwelwyd pob un o 33 marc gwiriad allweddol yn log y swydd:
Camau 1–15 yn PASS; helper zero-based 720/720 GREEN;
caller anghywir 720/720 EXPECTED_RED, sero MATCH,
719 canlyniad anghywir ac un undefined; 4,320 tyst BigInteger,
strict red bwriadol, BOOT/replay a pherchnogaeth.
Gwelwyd `STAGE16_FULL_NATIVE_EXPECTED_RED_COMPLETE`;
gorffennodd y swydd Kotlin a'r swydd cloi enwau ill dwy â SUCCESS.

**`LAST_COMPLETED_STAGE=16`**. Mae Cam 17 (`PATCH 08`) yn
nesaf, heb ei ddechrau. Cedwir y nam cynhyrchu byw, heb adeiladwr
diferion gweledig na chywiriad cynnar.


## Cam 17 — PATCH 08: addasu rheng y permutation

Mae `PermutationPatchWrapper.patch` yn galw'r caller hanesyddol
anghywir yn wirioneddol ac yn cadw 719 canlyniad anghywir a'r
achos `undefined` ar ordinal 720. Wedyn mae'n trosi
`rank0 = oneBased - 1` a galw'r helper zero-based cywir.
Mae `MonsterBootstrapManager.applyPermutationPatch` yn
cadw'r graith a'r canlyniad cywir mewn cyd-destun unigryw.
Rhaid profi 720/720 GREEN, 720 RED etifeddol, 4,320 tyst
BigInteger a phob atchweliad Camau 1–16 cyn ardystio Cam 17.
Nid oes adeiladwr diferion gweledig na pours yng Ngham 17.
Mae `LAST_COMPLETED_STAGE=16` nes cwblhau'r CI brodorol.


## Ardystiad brodorol Cam 17 — COMPLETE

Ar commit `d6aa1486c36c3b410c7a9b459927496ec54a428d` llwyddodd rhediad GitHub Actions
[`38252648589`](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38252648589),
swydd Kotlin `114822613414`, gyda Kotlin 1.9.0/JDK 21 a'r
oracl ffynhonnell gwreiddiol. Gwiriwyd **32 marc** yn uniongyrchol
yn log y swydd. Pasiodd pob atchweliad Camau 1–16;
720 permutation gywir ac unigryw, 720 graith etifeddol RED wedi'u
cadw, 719 hen allbwn anghywir ac un undefined; 4,320 tyst
BigInteger cywir gyda 4,314 hen wall rhifol a 6 undefined;
ffiniau, cyfnodedd ±720, BOOT/replay, perchnogaeth a'r llwybrau
blaenorol. Gwelwyd `STAGE17_FULL_NATIVE_GREEN`, a gorffennodd
y swydd Kotlin a swydd cloi enwau â `SUCCESS`.

**`LAST_COMPLETED_STAGE=17`**. Cam 18 (`DISCOVERY 09`) yw'r
nesaf; ni ddechreuwyd. Nid oes adeiladwr diferion gweledig na pours.


## Cam 18 — DISCOVERY 09: darlleniad arllwys sefydlog

Mae `LegacyFixedPourAdapter.oldFixedPour` yn galw'r
trefnydd cywir PATCH 08 ond yn tynnu'r tri mewnbwn arllwys o
`old[1], old[2], old[3]` yn hytrach na
`old[order[0]], old[order[1]], old[order[2]]`.
Mae `BOOT → DISCOVERY_09` yn cadw tystiolaeth 46 cymysgiad,
cipluniau a'r trefn olaf. Cedwir yr addasiad chwe bowlen
ar sail ciplun, heb ddechrau PATCH 09, PATCH 10, adeiladwr
diferion gweledig, na'r cymysgiadau terfynol.
Gwirir pob 720 trefn (714 RED, 6 MATCH damweiniol),
4,320 tyst BigInteger a holl Gamau 1–17.
**`LAST_COMPLETED_STAGE=17`** tan PASS native CI.


## Ardystiad brodorol Cam 18 — COMPLETE

Ar commit `3831f1aa90d8fbb422cd64b4c8041240ad3254c0`, llwyddodd GitHub Actions
[`38256135742`](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38256135742),
swydd `native-stage18-kotlin-cymraeg` `114834585726`, ar
Kotlin 1.9.0/JDK 21 gyda'r oracl git gwreiddiol.
Gwelwyd **38 marc** gwirio yng nghynnwys gwirioneddol y log:
PASS holl Gamau 1–17; 714/720 RED, 6 MATCH damweiniol a
1,800 arllwys anghywir; 46 cylch gwrthdroad RED, hunaniaeth
MATCH, a mewnbwn naturiol yr oracl RED; 4,320 tyst BigInteger
gyda 4,284 RED, 36 MATCH, 10,800 cell anghywir; strict
RED bwriadol, BOOT, replay, ownership, ac atchweliadau.
Gwelwyd `STAGE18_FULL_NATIVE_EXPECTED_RED_COMPLETE`; llwyddodd
y swydd Kotlin a'r clo enwau (SUCCESS). Yr unig rybudd gweithredu
oedd rhybudd Node.js 20 GitHub Actions digyswllt â'r mathemateg.

**`LAST_COMPLETED_STAGE=18`** a `EXPECTED_REPOSITORY_STATE=EXPECTED_RED`,
fel y dylai fod i gam DISCOVERY. Cam 19 (`PATCH 09`) yw'r nesaf,
heb ei ddechrau. Nid yw'r graith etifeddol wedi'i dileu.


## Cam 19 — PATCH 09: arllwys o safleoedd y permutation

Mae `PourPatchWrapper` yn galw'r hen arllwys sefydlog 1,2,3
cyn cywiro'r tri ID ffynhonnell yn ôl `order[0..2]`.
Cedwir y canlyniadau etifeddol ac mae `BOOT → PATCH_09`
yn cwblhau'r 46 cymysgiad ar giplunau heb alias in-place.
Bwriedir profi 720 arllwys GREEN, 714 legacy RED,
4,320 prawf BigInteger a'r holl atchweliadau Camau 1–18.
Nid oes adeiladwr diferion gweledig yn y cam hwn.
`LAST_COMPLETED_STAGE=18` nes cwblhau CI brodorol.


## Ardystiad brodorol Cam 19 — COMPLETE

Ar commit `5e7f405f6f3f9750268c20f1ef2bdb3b43aa38ec` llwyddodd GitHub Actions
[`38261542258`](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38261542258),
swydd Kotlin `114853018881`, ar Kotlin 1.9.0/JDK 21.
Gwiriwyd **39 marc** yn uniongyrchol yn log gwirioneddol y swydd.
Pasiodd holl atchweliadau Camau 1–18; 720 o arllwysiadau
cywir, 714 nam legacy RED, 6 MATCH damweiniol a 1,800
cell legacy anghywir; 46 tro gwrthdro, union a naturiol yn
GREEN yn erbyn yr oracl; 4,320 tyst BigInteger GREEN gyda
4,284 legacy RED, 36 MATCH ac 10,800 cell anghywir.
Pasiodd BOOT, replay, metrigau, perchnogaeth a'r llwybrau blaenorol.
Gwelwyd `STAGE19_FULL_NATIVE_GREEN`, gyda swydd cloi enwau a
swydd Kotlin ill dwy yn `SUCCESS`.

**`LAST_COMPLETED_STAGE=19`**. Cam 20 (`DISCOVERY 10`)
yw'r nesaf, heb ei ddechrau. Cedwir y nodwedd mewnbynnau
diferion gweledig allanol a'r gwarchodaeth rhag alias in-place;
nid yw adeiladwr diferion gweledig yn rhan o'r cam hwn.


## Cam 20 — DISCOVERY 10: bowls byw yn lle hen snapshot

Mae `LegacyInPlaceBowlAdapter.mutateBowlsWrong` yn galw
`PourPatchWrapper.patch` yn gyntaf, gan gadw'r arllwys
etifeddol a'i gywiriad Cam 19. Yna mae'n diweddaru chwe bowl
**yn eu lle** yn nhrefn y permutation: mae safleoedd 2..6 yn
darllen bowls a newidiodd eisoes, er bod y contract normadol
yn gofyn am hen snapshot ar gyfer pob un o'r chwe darlleniad.
Caiff pob darlleniad byw a phob ysgrifen ei gadw fel tyst.

Mae'r profion Cam 20 yn mynnu 720 `EXPECTED_RED`,
720 ysgrifen gyntaf GREEN, 3600 ysgrifen anghywir,
4320 prawf BigInteger, 46 diferyn a holl atchweliadau Camau
1–19. Nid yw'r oracl yn rhan o gynhyrchu; mae'r diferion
gweledig yn parhau'n fewnbynnau allanol. Nid oes PATCH 10.

`LAST_COMPLETED_STAGE=19` nes llwyddiant CI brodorol.


## Ardystiad brodorol Cam 20 — COMPLETE

Ar commit `06eee4647f56f665db8e7b9fcb3f580a7273a07a` pasiodd GitHub Actions
[`38264758391`](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38264758391),
swydd Kotlin `114863999405` ar Kotlin 1.9.0/JDK 21.
Gwiriwyd **41 marc** uniongyrchol yn log y swydd:
holl gamau 1–19 yn PASS; 720 `EXPECTED_RED`,
0 `MATCH`, 720 ysgrifen gyntaf GREEN, 3,600 o
ysgrifeniadau byw anghywir; 4,320 tyst BigInteger
annibynnol, 21,600 ysgrifen byw anghywir; 46 diferion
identity, reverse a naturiol yn `EXPECTED_RED`,
guardiau BOOT/replay, perchnogaeth a methiant strict
bwriadol. Gwelwyd `STAGE20_FULL_NATIVE_EXPECTED_RED_COMPLETE`,
a llwyddodd y swydd Kotlin a swydd cloi enwau.

**`LAST_COMPLETED_STAGE=20`**. Cam 21 (`PATCH 10`)
yw'r nesaf, heb ei ddechrau; rhaid cadw'r mutator
etifeddol anghywir yn fyw. Ni adeiladwyd diferion
gweledig cynhyrchu o fewn Cam 20.


## Cam 21 — PATCH 10: clôn legacy a chwe darlleniad snapshot

Mae `BowlSnapshotPatchWrapper.patch` yn galw'r hen
`mutateBowlsWrong` yn wirioneddol ar glôn, gan gadw
chwe ysgrifen a'r graith darlleniadau byw. Wedyn mae'n
ailddefnyddio'r pours PATCH 09 cywir o'r un graith ac yn
cyfrifo pob un o'r chwe bowl o'r **un hen snapshot**,
gan ysgrifennu i restr newydd ar wahân.

Mae `BOOT → PATCH_10` yn prosesu 46 diferion, gyda 46
galwad legacy a 276 ysgrifen gywir. Mae'r profion yn
mynnu 720/720 GREEN, 720/720 RED legacy wedi'u cadw,
4,320 BigInteger GREEN, 21,600 hen ysgrifen anghywir
a holl atchweliadau Camau 1–20. Nid oes adeiladwr
diferion gweledig cynhyrchu o hyd.

`LAST_COMPLETED_STAGE=20` nes PASS Kotlin brodorol.


## Ardystiad brodorol Cam 21 — COMPLETE

Ar commit `a8d5beef2665123e543dde9cf3340359a484dda4` llwyddodd GitHub Actions
[`38268225516`](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38268225516),
swydd Kotlin `114875745625`, ar Kotlin 1.9.0/JDK 21.
Gwiriwyd **39 marc** yn uniongyrchol yn log y swydd:
holl gamau 1–20 yn PASS; 720 permutation gywir,
4,320 ysgrifen o'r snapshot cywir, 720 o hen ganlyniadau
RED wedi'u cadw, 3,600 hen ysgrifen anghywir;
4,320 tyst BigInteger GREEN gyda 21,600 ysgrifen etifeddol
anghywir; 46 diferyn identity, reverse a naturiol yn GREEN
yn erbyn yr oracl. Pasiodd y guardiau, BOOT/replay,
perchnogaeth a holl lwybrau blaenorol.
Gwelwyd `STAGE21_FULL_NATIVE_GREEN`, a llwyddodd y swydd
Kotlin a swydd cloi enwau ill dwy.

**`LAST_COMPLETED_STAGE=21`**. Cam 22 (`DISCOVERY 11`)
yw'r nesaf, heb ei ddechrau. Mae'r hen mutator
`mutateBowlsWrong` yn parhau'n fyw, ac nid yw
adeiladwr diferion gweledig wedi'i weithredu.


## Cam 22 — DISCOVERY 11: cache hen sum yn y 12 stir

Ar ôl 46 diferion, mae `LegacyCachedStirAdapter.oldCachedPostStir12`
yn ailadrodd 12 cymysgiad ond yn ail-ddefnyddio
`savedBowlSum` o stir 1 am stir 2..12. Mae stir 1
yn gywir; mae'r order PATCH 08 a'r chwe chyfrifiad
snapshot yn gywir ar gyfer y sum a roddir. **Y cache**
yw'r unig nam newydd, ac ni chaniateir cywiro'r cache
tan Gam 23 — PATCH 11.

Mae `BOOT → DISCOVERY_11` yn cadw pob hen snapshot,
saved sum, order a bowls ar bob stir. Mae'r profion
yn mynnu 720 RED ar stir 2 a chanlyniad 12 stir,
4,320 tyst BigInteger â 51,840 cam, strict RED,
a holl atchweliadau Camau 1–21. Mae'r bowls ôl-46
yn fewnbwn allanol; dim adeiladwr diferion gweledig.

`LAST_COMPLETED_STAGE=21` hyd nes PASS Kotlin brodorol.


## Ardystiad brodorol Cam 22 — COMPLETE

Ar commit `27f5969992a96b49dcea9c0f78e508556ae99be5` llwyddodd GitHub Actions
[`38274017335`](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38274017335),
swydd Kotlin `114894971609`, ar Kotlin 1.9.0/JDK 21.
Gwiriwyd **41 marc** yn uniongyrchol yn log gwirioneddol y swydd:
Camau 1–21 i gyd yn PASS; stir 1 yn GREEN i 720/720,
stir 2 yn EXPECTED_RED i 720/720 a stir 12 terfynol
yn EXPECTED_RED i 720/720, sero MATCH. Llwyddodd
4,320 tyst BigInteger annibynnol gyda 51,840 stir wedi'u
gwirio, achosion positif a negatif enfawr, guardiau,
strict RED bwriadol, BOOT/replay a pherchnogaeth.
Gwelwyd `STAGE22_FULL_NATIVE_EXPECTED_RED_COMPLETE`,
a gorffennodd y swydd Kotlin a'r swydd cloi enwau yn SUCCESS.

**`LAST_COMPLETED_STAGE=22`**. Cam 23 (`PATCH 11`)
yw'r nesaf, heb ei ddechrau. Rhaid cadw'r
`LegacyCachedStirAdapter.oldCachedPostStir12` byw ac
anghywir ar gyfer y patch nesaf. Dim adeiladwr diferion
gweledig cynhyrchu yma.


## Cam 23 — PATCH 11: savedBowlSum newydd ym mhob stir

Mae `FreshStirPatchWrapper.patch` yn galw'r hen
`oldCachedPostStir12` ar glôn ac yn cadw'r graith
cache stir 1 yn llawn. Ar ôl hynny, mae'n ailgyfrifo
`save(sum(old[1..6]) + 149*s)` ar bob stir 1..12,
yn defnyddio PATCH 08 ar gyfer y permutation, ac yn
ysgrifennu chwe bowls newydd o'r un hen snapshot.

Mae'r profion yn mynnu 720 GREEN cywir a 720 RED
etifeddol, 8,640 stir unigol wedi'u gwirio gyda'r
oracl gwreiddiol, 4,320 prawf BigInteger gyda 51,840
stir, a phob atchweliad Camau 1–22. Ni ddefnyddir
oracl prawf yng nghynhyrchu. Nid oes adeiladwr
diferion gweledig cynhyrchu o hyd.

`LAST_COMPLETED_STAGE=22` nes cwblhau CI brodorol.


## Ardystiad brodorol Cam 23 — COMPLETE

Ar commit `d9623a9eeb5b39c41bbfc07b055099e29903e0d5` pasiodd GitHub Actions
[`38278498810`](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38278498810),
swydd Kotlin `114909725837`, gyda Kotlin 1.9.0/JDK 21.
Gwiriwyd **40 marc** yn uniongyrchol yn log gwirioneddol y swydd:
holl Gamau 1–22 yn PASS; 720/720 canlyniad PATCH 11
GREEN, 720/720 RED etifeddol wedi'u cadw, 8,640
stir wedi'u gwirio â'r oracl ffynhonnell gwreiddiol;
4,320 achos BigInteger GREEN, 4,320 hen RED, 51,840
stir annibynnol; rhifau anferth, guards, BOOT/replay,
perchnogaeth a'r holl lwybrau blaenorol yn PASS.
Gwelwyd `STAGE23_FULL_NATIVE_GREEN`, a gorffennodd
y swydd Kotlin a'r swydd cloi enwau yn SUCCESS.

**`LAST_COMPLETED_STAGE=23`**. Cam 24
(`DISCOVERY 12`) yw'r nesaf, heb ei ddechrau.
Mae `oldCachedPostStir12` yn aros yn fyw ac yn
anghywir. Mae mewnbynnau bowls ôl-46 yn dal yn
allanol; nid oes adeiladwr diferion gweledig cynhyrchu.
