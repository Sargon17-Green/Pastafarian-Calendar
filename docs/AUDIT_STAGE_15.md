# Cam 15 — PATCH 07: cyfieithydd sentinel ar gyfer rhesi malu

## Cwmpas
Gangen `Kotlin+Cymraeg`, HEAD ardystiedig Cam 14: `61a0f227e9177b9864dda9a059fc7d1ddd76f09a`.
Mae `LAST_COMPLETED_STAGE=14` tan fod y rhediad CI brodorol yn wyrdd.
Ni ddechreuwyd Cam 16 ac ni chyfrifir diferion gweledig yn y cam hwn.

## Gweithredu
Mae `LegacyGrindTableAdapter.legacyGrindRow` yn aros yn anghywir ac yn alwadwy:
ordinal 1 → rhes 2, ordinal 10 → rhes 11, ordinal 11 → `undefined`.
Mae `GrindPatchWrapper.patch` yn galw'r helper hwnnw'n gyntaf, yn gwirio
ei leoliad a'i allbwn, yna'n ychwanegu `null` at ddechrau **copi lleol**
o'r unarddeg rhes ffisegol. Mae `sentinelRows[grind]` felly'n gywir
am bob ordinal 1..11. Nid yw'r adapter na'r tabl gwreiddiol yn newid.

Mae `MonsterBootstrapManager.applyGrindPatch` yn gweithredu
`BOOT → PATCH_07`, yn cadw'r rhes anghywir, y faner undefined,
yr unarddeg rhes wreiddiol a'r tabl wedi'i gyfieithu, ac yn ymrwymo
i gyd ar ôl llwyddiant. Mae gan bob cyd-destun ei storfa ei hun.

## Prawf
Mae `sh run-stage15-tests.sh` yn ail-redeg Camau 1–14 ac yna'n profi:
- 11/11 rhes gywir, 11/11 gwall etifeddol wedi'u cadw, un sentinel;
- adfer y rhes 11, gwrthod ordinalau annilys;
- llwybr cynhyrchu, metrigau, gwarchod BOOT/replay a pherchnogaeth;
- 66 gwiriad `BigInteger` cywiro a 66 tyst etifeddol (60 gwall rhifol,
  6 undefined), heb gyfrifo diferion cynhyrchu;
- atchweliad `DISCOVERY_07`, `PATCH_05`, `PATCH_06`, a cherrig.

Dim ond ar ôl gweld `STAGE15_FULL_NATIVE_GREEN` ynghyd â
statws llwyddiant GitHub Actions ar Kotlin 1.9.0/JDK 21
y gellir gosod `LAST_COMPLETED_STAGE=15`.


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
