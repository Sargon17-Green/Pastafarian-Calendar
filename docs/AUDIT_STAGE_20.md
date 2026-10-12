# Cam 20 — DISCOVERY 10: rhestr bowls fyw a diweddariad in-place

## Ffiniau
Gangen `Kotlin+Cymraeg`, sylfaen ardystiedig Cam 19:
`fc6f4e7a88eb6d1d2ef31d26bfa4d40d978a4dc3`. Mae `LAST_COMPLETED_STAGE=19` tan i CI brodorol
lwyddo. Dim PATCH 10, adeiladwr diferion gweledig, na newid
i'r oracl. Mae'r arllwysiadau a'r permutation yn parhau'n gywir.

## Y graith hanesyddol
Ar gyfer pob diferyn i, mae `LegacyInPlaceBowlAdapter.mutateBowlsWrong`
yn galw'r `PourPatchWrapper.patch` go iawn, sy'n cofnodi'r
hen fixed-pour a dychwelyd y tri arllwys cywir.

Mae'r dull anghywir yn creu `live = snapshot.toMutableList()`,
ac yna am bob safle p=1..6 yn defnyddio'r gwerthoedd CYFREDOL
`live[id]`, `live[previousId]`, `live[nextId]` wrth
gyfrifo'r gwerth newydd, ac yn gwneud `live[id] = result`
**cyn** y safle nesaf. Yn y contract normadol, rhaid i bob
un o'r chwe gwerth ddarllen yr un hen snapshot ac yna
ysgrifennu i restr newydd.

Mae'r safle 1 yn dal yn gywir: nid oes bowl wedi'i newid
cyn y darlleniad cyntaf. Yn safle 2 mae `previousId`
bellach wedi newid, ac yn safle 6 mae `nextId` (y safle
cyntaf) hefyd wedi newid. Cedwir pob ID, pob darlleniad
byw a phob gwerth newydd mewn `LegacyInPlaceWrite`.
Mae `runWrongInPlace` yn ailadrodd 46 gwaith gyda'r input
diferion a roddwyd gan y galwr; 276 ysgrifen in-place.

Mae `BOOT → DISCOVERY_10` yn cyflawni'r 46 cam ac yn cadw
cofnodion, allbwn, permutation derfynol, metrigau,
a pherchnogaeth mewn cyd-destun annibynnol. Nid yw'n defnyddio
`NormativeCore` o fewn cynhyrchu.

## Profion
`sh run-stage20-tests.sh` yn ail-redeg Camau 1–19,
gan gynnwys y strict RED hanesyddol, ac wedyn:
- 720 permutation: 720 EXPECTED_RED, 0 MATCH, 720
  ysgrifen gyntaf GREEN, 3600 ysgrifen fyw anghywir;
- tystion go iawn o ddarlleniadau previous/next mewn
  chwe phosisiwn, heb lygredd yr mewnbynnau na'r snapshots;
- 46 diferyn identity a reverse gyda pours PATCH 09 cywir:
  hen live bowls RED, canlyniad PATCH 09 GREEN;
- 46 diferyn naturiol o'r oracl **ar ochr prawf yn unig**;
- 4320 achos BigInteger annibynnol ar chwe chylch,
  21600 ysgrifen fyw anghywir;
- strict RED gwirioneddol ar safle 2, guardiau, replay,
  BOOT, perchnogaeth a holl lwybrau cynharach.

`LAST_COMPLETED_STAGE=20` dim ond ar ôl
`STAGE20_FULL_NATIVE_EXPECTED_RED_COMPLETE` a
`SUCCESS` ar Kotlin 1.9.0/JDK 21. Cam 21 fydd PATCH 10.


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
