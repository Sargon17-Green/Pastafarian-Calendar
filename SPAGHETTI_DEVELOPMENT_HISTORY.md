# Hanes datblygu'r anghenfil sbageti

## Cam 1 — Bootstrap

### Beth a adeiladwyd

Dechreuwyd llinell `Kotlin + Cymraeg` newydd o sero. Crëwyd rhifyddeg union, catalog iaith ffynhonnell wedi'i rewi, cyfeirnod normadol prawf-yn-unig, gosodiadau lleol, profion, a sgerbwd anghenfil niwtral.

### Beth a dybiwyd

Nid oes rhagdybiaeth legacy fwriadol eto. Nid yw'r hanes yn rhagweld unrhyw un o'r 26 diffyg.

### Beth a ddarganfuwyd

Dim divergence hanesyddol eto. Mae Cam 1 yn gyflwr gwyrdd sylfaenol.

### Haen anghenfil a ychwanegwyd

Ychwanegwyd cyd-destun galwad, dosbarthwr camau, dilysydd, lapiwr gwallau a chragen metrigau. Mae'r haenau hyn yn semantig anweithredol ar hyn o bryd: nid ydynt yn cyfrifo dyddiad ac nid ydynt yn darllen eu metrigau yn ôl i benderfyniad normadol.

## Cam 2 — Darganfod 01: gweddill etifeddol yn lle SAVE

### Beth oedd y mecanwaith yn ei gredu

Tybiwyd mai gweddill Ewclidaidd arferol modulo `M` oedd y gwerth cywir mewn pob achos. Felly ychwanegwyd `LegacyRemainderAdapter.oldRemainder(value)` yn fwriadol heb reol `SAVE`.

### Beth a ddatgelwyd

Cysylltwyd y gweddill etifeddol â llwybr cynhyrchu trwy `MonsterBootstrapManager.observeLegacyRemainder` a handler `DISCOVERY_01`. Cedwir y gwerth gwreiddiol a'r allbwn yng nghyd-destun pob galwad.

Rhagwelir tri gwahaniaeth yn erbyn y cyfeirnod prawf-yn-unig: mae `M`, `2M` a `3M` yn rhoi sero yn y llwybr etifeddol, ond `M` yn ôl SAVE; mae `M+1` yn rhoi un yn y ddau lwybr.

### Beth na chywirwyd

Ni ychwanegwyd `savePatch` na llwybr Patch 01. Mae'r gwall yn aros yn weithredol, yn union fel y mae gofyn yn y cam darganfod.

### Canlyniad

Paratowyd prawf gwaelodlin Cam 1, archwiliad disgwyliedig-goch Cam 2 a phrawf normadol llym sy'n methu yn fwriadol. Mae'r prawf brodorol yn erbyn y goeden lawn yn dal heb ei redeg; nid yw Cam 2 wedi'i ardystio'n gyflawn.

### Dilysu dilynol

Profwyd y llwybr cynhyrchu etifeddol gyda'r union ffeil `ExactInt.kt` wreiddiol.
Estynnwyd profion yr un Cam 2 i saith achos ffin ychwanegol ac i berchnogaeth
cyd-destun. Ni ychwanegwyd unrhyw gywiriad. Mae archwiliad brodorol cyflawn
Cam 1 ac oracl llawn y calendr yn aros yn rhag-amod cwblhau.

### Archwiliad ychwanegol v003 (Cam 2 yn unig)

Ehangwyd y tystiolaeth o'r gweddill anghywir gyda 195 achos cyfnodol
ac achos pell o'r tu hwnt i 256 did. Nid oes cywiriad wedi'i gyflwyno.
Mae nam `ExactInt.toLongExact` ar `Long.MIN_VALUE` wedi'i gofnodi ar wahân;
ni chafodd y graith hanesyddol ei newid. Mae PASS brodorol llawn y goeden
yn dal heb ei gadarnhau.

### Diogelu profion y cam darganfod

Cryfhawyd y sgript profi i ddatgelu ffynhonnell sylfaen wedi'i
newid cyn rhedeg. Nid yw'r craith `oldRemainder` na'r tri
gwahaniaeth normadol wedi newid. Nid yw'r cam hwn wedi'i
farcio'n gyflawn heb rediad y goeden wirioneddol.

### Cadarnhad brodorol terfynol Cam 2 — 11 Hydref 2026

Ailadeiladwyd y goeden brofi leol gan ddefnyddio'r chwe blob cod
gwreiddiol o'r gangen ac ychwanegu'r delta DISCOVERY 01 yn unig.
Dychwelodd `run-stage02-tests.sh` cod `0` gyda
`STAGE01_PASS_66`, `STAGE02_PERIODICITY_PASS_195`,
`STAGE02_EXPECTED_RED_3` a `STAGE02_STRICT_RED_CONFIRMED`.
Ailgynhyrchwyd fixture Cam 1 yn union, gyda'r un blob SHA.
Gwrthododd y gwarchodwr gangen anghywir a mopheth wedi'i newid.

Mae'r tri gwahaniaeth yn parhau yn weithredol. Nid oes
`savePatch`, nid oes trosiad `0` i `M`, ac nid oes cod Cam 3.
Mae Cam 2 wedi'i ardystio'n **COMPLETE / EXPECTED_RED** gan y profion
brodorol; mae'r cam nesaf yn Cam 3 / PATCH 01, ar wahân.


## Cam 3 — Patch 01: SAVE drwy lapio'r graith etifeddol

### Pam y mae angen y darn hwn

Cadwyd tystiolaeth Cam 2: mae'r hen wreiddiad `oldRemainder`
yn dal i ddychwelyd `0` ar `M`, `2M` a `3M`.
Nid yw diffinio'r swyddogaeth hanesyddol o'r newydd yn ganiataol.

### Newid mewn cynhyrchu

Ychwanegwyd `SavePatchWrapper.savePatch` a handler `PATCH_01`.
Mae'r handler yn galw `oldRemainder` unwaith, yn cadw'r gweddill
a gafwyd, yna'n mapio `0` i `M`, gan adael gweddillion eraill heb eu newid.
Dim ond ar ôl cwblhau'r ddau gyfrifiad y caiff y gwerthoedd eu cofnodi
yn y cyd-destun. Mae'r dosbarthwr yn gwrthod galwad cyn BOOT ac yn
gwrthod galwad heb fewnbwn.

### Cadw'r llwybr coch

Nid yw `LegacyRemainderAdapter.kt` wedi'i newid. Mae `DISCOVERY_01`
yn dal yn hygyrch drwy `observeLegacyRemainder`. Disgwylir tri
gwahaniaeth yn y llwybr hwn, ond dim un yn `applySavePatch`.

### Dilysu a'r terfyn presennol

Cafwyd preflight PASS yn Kotlin ar 11 Hydref 2026 gyda dau amnewidyn
prawf dros dro (rhifyddeg BigInteger a SAVE); ni chânt eu lanlwytho.
Llwyddodd profion cwmpas Cam 2/3, gan gynnwys 195 achos cyfnodol,
129 prawf llydan, perchnogaeth cyflwr a gwarchod llwybr BOOT.
Mae'r rhediad gyda'r pum blob Cam 1 gwreiddiol a'r mopheth normadol llawn
**heb ei gynnal eto**. Nid oes hawl marcio Cam 3 COMPLETE cyn hynny.
Mae canfyddiad annibynnol Long.MIN_VALUE yn aros heb newid.


### Cam 3 — archwiliad dilynol (v002; heb gau'r cam eto)

Cafodd holl ffeiliau PATCH 01 y llwythiad `98e65d7` eu cymharu yn ôl eu
hashiau Git, a gwiriwyd `ExactInt.kt` gwreiddiol yn union. Roedd y tri
gwahaniaeth hanesyddol yn Cam 2 yn dal yn bresennol, a phasiodd Cam 3
gydag 0 gwahaniaeth a 921 prawf BigInteger annibynnol ychwanegol, hyd at
2048 did. Cedwir y profion JVM ychwanegol dan `src/test/` yn unig.
Ni newidiodd y cod cynhyrchu. Ni ddylid dechrau Cam 4 cyn PASS llawn gyda'r
oracl a'r 66 prawf Cam 1 gwreiddiol.


### Cam 3 — cadarnhad brodorol llawn ar ôl trwsio'r integreiddio (11 Hydref 2026)

Wedi i delta v002 gael ei lwytho i'r gangen, archwiliwyd y
ffynonellau union a'u hashiau Git. Methodd y rhediad brodorol cyntaf
wrth gydosod Cam 1 am nad oedd `run-stage01-tests.sh` na
`run-stage02-tests.sh` yn cynnwys y ffynhonnell newydd
`SavePatchWrapper.kt` er bod `MonsterBootstrap.kt` yn ei defnyddio.
Darganfyddiad integreiddio oedd hwn, nid camgymeriad y fformiwla SAVE.

Cywirwyd rhestrau'r ddwy sgript yn unig. Ail-redwyd
`sh run-stage03-tests.sh` gyda'r pum ffeil brofi sylfaenol union,
`ExactInt` gwirioneddol a'r oracl calendr llawn. Cafwyd cod
ymadael **0**, `STAGE01_PASS_66`,
`STAGE02_EXPECTED_RED_3`, `STAGE02_STRICT_RED_CONFIRMED`,
`STAGE03_PATCH_GREEN_0`, `STAGE03_EXTENDED_BIGINT_GREEN_921`
a `STAGE03_NATIVE_GREEN`. Cedwir y graith a'r tri gwahaniaeth
etifeddol. Mae **Cam 3 wedi'i gwblhau ac wedi'i ddilysu'n frodorol**.
Ni ddechreuwyd Cam 4. Mae diffyg `Long.MIN_VALUE` yn parhau'n
ganfyddiad ar wahân.


## Cam 4 — Darganfod 02: tag dydd heb +1 wedi'r Sylfaen

Cyflwynwyd `LegacyDayTagAdapter.oldDayTag`, gyda chysonyn
`F = -15055671` annibynnol ar y cyfeirnod prawf. Mae'r hen gyfrifiad
`2*abs(day-F)` yn cofnodi'r camgymeriad bwriadol: ar ochr negatif y
Sylfaen mae'r gwerthoedd yn gywir, ond o'r Sylfaen ymlaen maent yn un
yn rhy fach. Mae `MonsterBootstrapManager.observeLegacyDayTag` yn gyrru'r
llwybr cynhyrchu `BOOT -> DISCOVERY_02`; mae'r handler yn cofnodi'r
allbwn anghywir a'r olrhain mewn cyd-destun ar wahân fesul galwad.

Cymharwyd y pum tyst `F-2,F-1,F,F+1,F+2` â `NormativeCore.dayCount`
(test-only). Gwelwyd union dri gwahaniaeth bwriadol a dau gyfatebiad.
Gwirir hefyd ystod 331 o ddiwrnodau, arwyddion positif/negyddol,
cyfanrifau pell, perchnogaeth cyd-destun, gwarchod y cyfnod BOOT a
chysondeb holl lwybrau Cam 2 a Cam 3. Mae'r prawf strict yn methu yn
fwriadol dim ond wrth ganfod y tri gwahaniaeth dynodedig.

Ni weithredwyd PATCH 02; ni newidiwyd `oldRemainder` na `savePatch`.
Disgwylir i Cam 4 orffen yn `EXPECTED_RED`; dim ond Cam 5 — PATCH 02 —
all lapio'r graith hwn yn nes ymlaen. Mae diffyg annibynnol
`ExactInt.toLongExact(Long.MIN_VALUE)` yn aros heb ei drwsio.


### Cadarnhad Cam 4: PASS brodorol, EXPECTED_RED

Ail-redwyd yr holl gadwyn regressions ar y fersiwn derfynol, gyda'r pum
blob prawf union a `ExactInt` gwreiddiol. Cod ymadael `0`:
`STAGE01_PASS_66`, `STAGE02_EXPECTED_RED_3`,
`STAGE03_EXTENDED_BIGINT_GREEN_921` a `STAGE04_EXPECTED_RED_3`.
Mae'r tri thyst coch yn fwriadol; mae'r prawf strict yn methu yn ôl y
contract ac mae'r sgript gyffredinol yn ei dderbyn yn briodol.
`LAST_COMPLETED_STAGE=4`. Dim PATCH 02 eto.


### Cam 4 / gwarchodaeth atchwanegol v002

Cyn lanlwytho'r cam, estynnwyd yr oracl profion gyda 60 achos mawr,
cydbwysedd dwy ochr y Sylfaen, a gwrthod ail-anfon yr un cyd-destun.
Ni newidiwyd hen `oldDayTag`, na'r llwybr cynhyrchu, na'r wybodaeth
normadol, ac ni ddechreuwyd Cam 5. Mae'r hen dri gwahaniaeth
bwriadol yn parhau'n dystiolaeth hanesyddol.


### Cam 4 / prawf BigInteger annibynnol v003

Ychwanegwyd oracl cyfrifiadol Java **yn y profion Kotlin yn unig**.
Mae 409 galwad drwy'r handler cynhyrchu `DISCOVERY_02` yn cadarnhau'r
cyfrifiad hanesyddol `2*abs(day-F)` yn annibynnol ar `ExactInt`:
204 MATCH cyn y Sylfaen, 205 EXPECTED_RED ar y Sylfaen ac ar ei hôl.
Cadwyd y pum tyst gwreiddiol, y llwybr PATCH 01 a'r ffin gamau.


### Cam 4 / cadarnhad v003

Ail-redwyd y cod terfynol gyda'r oracl gwreiddiol a 409 prawf
BigInteger annibynnol. Cod ymadael `0`, ac mae'r graith
`oldDayTag` yn parhau'n alwadadwy ac yn fwriadol wallus.


## Cam 5 — PATCH 02: gwarchod graith tag y Sylfaen

Cafodd `LegacyDayTagAdapter.oldDayTag` ei gadw fel yr oedd. Mae llwybr
cynhyrchu `BOOT → PATCH_02` yn cyfrifo'r hen dag yn gyntaf ac yn
cofnodi ei werth ar gyd-destun y galwad. Dim ond wedyn y mae'r
`DayTagPatchWrapper` yn ychwanegu un ar ddiwrnod y Sylfaen ac ar bob
diwrnod diweddarach. Cedwir prawf penodol `day == foundationDay`
sy'n ddiangen oherwydd `day >= foundationDay`: craith fwriadol y patch.

Roedd y pum tyst `F−2,F−1,F,F+1,F+2` yn `4,2,0,2,4` ar y llwybr
etifeddol a `4,2,1,3,5` ar y llwybr wedi'i drwsio. Llwyddodd
profion mewn Kotlin go iawn gyda'r union `ExactInt.kt` gwreiddiol:
5 tyst, 331 diwrnod, 60 achos mawr, 418 prawf `BigInteger` annibynnol,
perchnogaeth cyd-destun, ail-anfon, gwarchodaeth ac ailwirio'r hen
lwybrau. **Nid yw'r prawf hwn yn dystysgrif regressions Cam 1–5 eto.**

Rhaid rhedeg `run-stage05-tests.sh` yn erbyn y gangen lawn cyn newid
`LAST_COMPLETED_STAGE=5`. Nid oes PATCH 03 na DISCOVERY 03 yn y pecyn.


### Cam 5 — ardystiad JVM llawn ar GitHub Actions

Yn dilyn y prawf lleol yn erbyn `ExactInt.kt` gwreiddiol, gweithredwyd
y gadwyn Camau 1–5 **gyfan** mewn swydd CI frodorol ar y gangen, gyda
Kotlin 1.9.0 a JDK 21. Cadarnhawyd PASS y 66 prawf Cam 1 a phob marc
cywir o Gamau 2–5, gan gynnwys y tri gwahaniaeth disgwyliedig yn y
ddau lwybr DISCOVERY a sero gwahaniaethau yn `PATCH_02`.

Mae rhediad GitHub Actions `38173345431` yn SUCCESS a
`STAGE05_NATIVE_GREEN` yn bresennol yn log y swydd. Felly **Cam 5
wedi'i gwblhau** (`LAST_COMPLETED_STAGE=5`). Nid oes unrhyw waith
Cam 6 wedi dechrau, ac nid yw'r dystiolaeth hon yn newid y craith
hanesyddol.


## Cam 6 — DISCOVERY 03: gwall pellter o dagiau dydd

Cadwyd PATCH 02 ac oldDayTag heb eu newid. Mae `oldDistance` yn cyfrifo `abs(patchedTag(c)-patchedTag(t))` gan alw'r addasydd a'r deunydd lapio cynhyrchu go iawn. Mae `BOOT → DISCOVERY_03` yn cadw'r mewnbynnau a'r canlyniad mewn cyd-destun preifat. O wyth tyst, mae 5 yn `EXPECTED_RED` a 3 yn `MATCH`. Ni chyflwynwyd PATCH 03. Mae'r prawf JVM brodorol llawn yn aros am CI.


### Ardystiad brodorol Cam 6 — PASS

Ar commit `fd32a7f795943683275dc19838bfa2b3287c2661`, llwyddodd GitHub Actions (`38178119854`, swydd `114584731224`) i redeg `run-stage06-tests.sh` yn llawn gyda Kotlin 1.9.0 a JDK 21. Cafwyd `STAGE01_PASS_66`, holl lwybrau Camau 2–5, `STAGE06_EXPECTED_RED_5`, `STAGE06_MATCH_3`, `STAGE06_MATRIX_PASS_441`, `STAGE06_BIGINT_INDEPENDENT_PASS_549`, `STAGE06_STRICT_RED_CONFIRMED` a `STAGE06_NATIVE_EXPECTED_RED_COMPLETE`. Mae Cam 6 wedi'i gwblhau; nid yw PATCH 03 wedi'i ddechrau.


## Cam 7 — PATCH 03: ail-basio'r pellter drwy'r graith

Mae `oldDistance` yn aros yn alwadadwy ac yn cynhyrchu'r un pum anghysondeb Cam 6. Mae'r handler `PATCH_03` yn ei alw'n wirioneddol, yn cofnodi ei sail, ac yn defnyddio `DistancePatchWrapper` i gymharu â `abs(t-c)`. Dim ond os yw'r sail yn wahanol y caiff ei newid, ac ychwanegir `+1` cynhwysol ym mhob achos. Mae wyth tyst wedi troi'n sero anghysondeb PATCH; 441 prawf matrics a 549 prawf BigInteger annibynnol wedi pasio yn y cam cyntaf. Mae'r prawf brodorol llawn gan GitHub Actions eto i'w gwblhau.


### Cam 7 — ardystiad brodorol cyflawn

Ar commit `3daa6b0e5e3fac8a6c2868e8bae19d7220ffa38d` llwyddodd swydd CI Kotlin (`114591831816`, rhediad `38180495340`) ar Kotlin 1.9.0/JDK 21. Cadarnhawyd 28 marc log: holl atchweliadau Camau 1–6, 8 tyst PATCH 03 gwyrdd, 441 prawf matrics a 549 prawf BigInteger annibynnol. Mae'r graith oldDistance yn dal yn alwadadwy gyda 5 EXPECTED_RED, tra bo PATCH 03 â 0 anghysondeb. `LAST_COMPLETED_STAGE=7`; ni ddechreuwyd Cam 8.


## Cam 8 — DISCOVERY 04: nam dilyniannol y pum carreg

Mae'r adeiladwr hen ffasiwn yn newid yr un cofnod mewn trefn benodol: gwenith, barlys, halen, chwerw, coch. Mae pob fformiwla ddilynol yn darllen y gwerthoedd sydd eisoes wedi newid, er y dylai ddefnyddio ciplun cyfan o'r hen res. Cedwir rhes 1 fel oedd; mae rhesi 2–46 yn dangos 224 gwahaniaeth mewn 225 cydran. Mae'r llwybr cynhyrchu ar wahân yn cofnodi'r tabl fesul galwad. Nid yw cam atgyweirio'r cerrig wedi'i ddechrau. Disgwylir prawf llawn CI cyn newid marc cwblhau'r cam.


### Cam 8 — ardystiad JVM brodorol llawn

Ar commit `051a928af4cc5166fc5884f80db48c530b5c5931` llwyddodd swydd GitHub Actions `114600034894` (rhediad `38183229336`) gyda Kotlin 1.9.0/JDK 21 a'r oracl gwreiddiol. Cadarnhawyd 30 marc, gan gynnwys atchweliadau Camau 1–7, 224 `EXPECTED_RED` mewn 225 cydran, 230 gwirio BigInteger annibynnol, cadw rhes 1, perchnogaeth a gwarchod ail-anfon, a'r methiant strict disgwyliedig. Mae Cam 8 yn gyflawn; ni ddechreuwyd PATCH 04.


## Cam 9 — PATCH 04: ciplun a gwastraff yr hen mutator

Ni newidiwyd `mutateStonesWrong`. Cyn pob rhes newydd, cedwir ciplun o'r pum carreg hen. Galwir yr un mutator ar glôn, cofnodir y `legacyGarbage` ac wedyn cyfrifir pob maes cywir o'r ciplun gwreiddiol. Mae rhesi 2–46 yn defnyddio 45 galwad, ac mae'r tabl 230 cydran yn gorfod cyfateb yn union i'r oracl. Mae'r 224 gwahaniaeth Cam 8 yn parhau'n weladwy trwy'r llwybr etifeddol ar wahân. Bydd ardystiad CI llawn yn penderfynu cwblhau'r cam.


### Cam 9 — ardystiad brodorol PASS

Llwyddodd y swydd `native-stage09-kotlin-cymraeg` (rhediad GitHub Actions `38186462459`, swydd `114609724515`) gyda'r oracl gwreiddiol ar Kotlin 1.9.0/JDK 21. Cadarnhawyd pob un o 19 marc a ddewiswyd o'r log swydd, gan gynnwys pob atchweliad Camau 1–8, 230 cydran wedi'u trwsio heb anghysondeb, 230 prawf BigInteger annibynnol, 45 galwad i'r mutator hanesyddol, a'r 224 anghysondeb DISCOVERY_04 a gadwyd. Mae Cam 9 wedi'i gwblhau; ni ddechreuwyd Cam 10.


## Cam 10 — DISCOVERY 05: darllen cudd wedi'i wrthdroi

Defnyddir y cerrig PATCH 04 cywir a'r cyfrifon PATCH 02/03 i greu saith gwerth cudd heb ymgynghori â'r oracl prawf. Yn fwriadol, mae'r storfa gorfforol yn trefnu hidden7 ... hidden1. Mae `legacyHiddenDirectByAssumedNearness` yn dychwelyd y slot k yn union, er mai hidden(8-k) sydd yno. Mae'r canolbwynt k=4 yn gywir trwy gyd-ddigwyddiad, a disgwylir pedwar gwahaniaeth ar k=1,2,6,7. Cedwir y cyflwr fesul galwad; nid yw cyfieithydd na chywiriad PATCH 05 yn bodoli. Bydd CI yn gwirio pob cam cyn ardystio Cam 10.


### Cam 10 — ardystiad CI brodorol

Ar commit `b2c0a978ca452545c98ff9a7349c6cddd5db345b` llwyddodd swydd `native-stage10-kotlin-cymraeg` (`114696619440`, rhediad `38214703144`) gyda Kotlin 1.9.0/JDK 21 a'r oracl gwreiddiol. Cafwyd `STAGE10_BACKWARD_STORAGE_PASS_7`, `STAGE10_EXPECTED_RED_4`, `STAGE10_MATCH_1`, `STAGE10_BIGINT_INDEPENDENT_PASS_35`, `STAGE10_BIGINT_PATCH04_STONES_GREEN_175`, `STAGE10_STRICT_RED_CONFIRMED` a `STAGE10_NATIVE_EXPECTED_RED_COMPLETE`. Cadwyd holl atchweliadau Camau 1–9. Mae Cam 10 yn gyflawn; ni ddechreuwyd PATCH 05.


## Cam 11 — PATCH 05: hiddenByNearness yn defnyddio 8-k

Mae'r lapio cywiro'n galw'r hen `legacyHiddenDirectByAssumedNearness` yn union ac yn cofnodi'r gwerth anghywir, cyn galw'r cyfieithydd newydd `hiddenByNearness` sy'n dychwelyd y slot ffisegol `8-k`. Ni newidir y storfa backward na'r hen graith. Mae'r llwybr cynhyrchu ar wahân yn cadw'r k, y slot, y graith, yr allbwn cywir a'r cyfrif galwadau yng nghyd-destun y galwad. Disgwylir 7 GREEN newydd, y 4 anghysondeb etifeddol a 35 prawf BigInteger annibynnol, gyda 175 cydran carreg. Mae'r cam yn aros am ardystiad CI brodorol llawn; ni ddechreuwyd Cam 12.


### Cam 11 — ardystiad brodorol PASS

Ar commit `326c843d2fb8a7f5c070362113a3284c4cbe6aac` llwyddodd swydd `native-stage11-kotlin-cymraeg` (rhediad `38222120118`, swydd `114720632237`) gyda Kotlin 1.9.0/JDK 21 a'r oracl gwreiddiol. Gwiriwyd 30 marc: saith `k` yn GREEN, cadw pedwar anghysondeb DISCOVERY 05, cadw'r canolbwynt k=4, 35 prawf BigInteger annibynnol, 175 cydran carreg, gwarchodion a phob atchweliad Camau 1–10. Cedwir y storfa wrthdro a'r hen ddarllenydd heb newid. Mae Cam 11 wedi'i gwblhau; ni ddechreuwyd Cam 12.


## Cam 12 — DISCOVERY 06: graith legacyPrior weledig

Mae'r helper hanesyddol yn darllen `dropStore[i-back]` o storfa weledig yn unig. Nid oes ganddo drosiad o slotiau annhebyg i bositif i hidden1..hidden7. Yn y profion `i=1,back=1,3,7` ceir y slotiau 0,-2,-6 a thair anghysondeb. Nid yw'r algorithm diferion gweledig na `priorPatch` wedi'i weithredu. Yn y llwybr cynhyrchu, mae probe positif i=2/back=1 yn profi galwad wirioneddol i'r helper. Ceir profion perchnogaeth, BigInteger ac atchweliadau gan gynnwys PATCH 05. Bydd ardystiad CI cyn symud `LAST_COMPLETED_STAGE`.


### Cam 12 — ardystiad JVM brodorol llawn

Ar commit `7fac959fc06edb8c59d0b7f0105fbf91151da87b` llwyddodd swydd GitHub Actions `114729897099` (rhediad `38224902493`) gyda Kotlin 1.9.0 a JDK 21. Gwiriwyd 30 marc o log y swydd: yr holl atchweliadau Camau 1–11, tri slot hanes cudd anghywir `0,-2,-6`, profi positif slot 1, 35 cyfrifiad BigInteger annibynnol, 175 cydran carreg, 15 tyst coll ar bum pâr diwrnod a methiant strict disgwyliedig. `LAST_COMPLETED_STAGE=12`; ni ddechreuwyd Cam 13.


## Cam 13 — PATCH 06: priorPatch ar gyfer slotiau negyddol

Mae'r helper visible-only yn parhau'n alwadadwy heb ei newid. Mae'r lapio newydd yn gwahaniaethu yn union wrth `slot=i-back`: ar slot positif mae'n galw'r hen prior go iawn; ar slot di-bositif mae'n defnyddio `hiddenK=1-slot` drwy gyfieithydd hiddenByNearness PATCH 05, heb alw'r hen prior. Mae'r llwybr PATCH 06 newydd yn cadw tystiolaeth y gangen a'r allbwn yn annibynnol ar bob galwad. Mae'r hen dri achos EXPECTED_RED o Gam 12 i aros yn RED ar y llwybr DISCOVERY 06, tra bo pob un o'r saith safle cudd yn GREEN ar y llwybr cywiriedig. Arhosir am dystysgrif JVM brodorol cyn cau Cam 13.


### Cam 13 — ardystiad brodorol llawn

Ar commit `d043e234822f57250bf5f178a32aee16e5ceb875` llwyddodd swydd Kotlin `114738687143` (rhediad `38227553115`) ar Kotlin 1.9.0/JDK 21. Gwiriwyd 35 marc yn uniongyrchol o log y swydd: atchweliadau Camau 1–12, 7 darlleniad hidden GREEN, galw'r helper raw ar y gangen bositif yn unig, profi'r gangen bositif heb storfa gudd, 35 prawf BigInteger annibynnol, 175 cydran carreg a chadw 15 tyst o'r tri diffyg hanesyddol. Mae `LAST_COMPLETED_STAGE=13`; ni ddechreuwyd Cam 14.


## Cam 14 — DISCOVERY 07: gwall mynegeio tabl malu

Mae'r hen adalydd yn storio union 11 rhes ffisegol zero-based ar gyfer yr unarddeg malu a ddiffinnir gan yr oracl. Nid oes rhes sentinel. Galwir `legacyGrindRow(grind)` gan lwybr cynhyrchu `DISCOVERY_07` ac mae'n defnyddio'r ordinal un-based yn uniongyrchol fel index, felly grind 1 → row 2, grind 10 → row 11, grind 11 → undefined. Mae'r holl 11 cais yn `EXPECTED_RED`; ni chaiff unrhyw un fod yn `MATCH`. Cedwir perchnogaeth y cyd-destun a'r pob un o'r hen lwybrau, heb roi'r cywiriad PATCH 07 na'r adeiladwr diferion gweledig ar waith. Mae'r cam yn aros am ardystiad JVM brodorol.


### Cam 14 — ardystiad JVM brodorol llawn

Ar commit `634b30b4ccdf2830b0cb16a98d19e689462ea8e4` llwyddodd swydd `native-stage14-kotlin-cymraeg` (`114757365134`, rhediad `38233182742`) gyda Kotlin 1.9.0/JDK 21, ffynonellau gwreiddiol a'r oracl. Gwiriwyd 43 marc o log y swydd: yr holl atchweliadau Camau 1–13, 11 rhes grind zero-based heb sentinel, 11 `EXPECTED_RED`, 0 `MATCH`, 66 prawf BigInteger annibynnol, drysau a methiant strict bwriadol. Mae Cam 14 yn gyflawn; ni ddechreuwyd PATCH 07/Cam 15.


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
