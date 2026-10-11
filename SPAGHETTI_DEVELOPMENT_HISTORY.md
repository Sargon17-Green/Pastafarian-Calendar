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
