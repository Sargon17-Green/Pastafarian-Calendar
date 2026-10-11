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
