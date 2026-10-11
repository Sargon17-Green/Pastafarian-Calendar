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
