# Cam 21 — PATCH 10: chwe bowl yn darllen yr un hen snapshot

## Ffiniau
Gangen `Kotlin+Cymraeg`; sylfaen ardystiedig Cam 20:
`df245124ad5447ae7d76535b59e93e88d078f05a`. Mae `LAST_COMPLETED_STAGE=20` tan PASS brodorol.
Ni ddechreuwyd Cam 22 na'r adeiladwr diferion gweledig.

## Y graith a'r cywiriad
Cedwir `LegacyInPlaceBowlAdapter.mutateBowlsWrong` heb newid:
mae'n ysgrifennu'r bowl newydd yn syth i'r rhestr fyw,
ac mae'r safleoedd nesaf yn darllen y bowl wedi'i newid.

Mae `BowlSnapshotPatchWrapper.patch` yn galw'r hen mutator
go iawn **yn gyntaf**, ar glôn yr hen chwe bowl. Cadwir
y chwe darlleniad byw, y chwe ysgrifen, y tri arllwys PATCH 09
cywir a'r canlyniad anghywir mewn `legacyStep`.

Dim ond wedyn y mae'r wrapper yn cyfrifo'r gwerthoedd newydd.
Ar gyfer pob safle 1..6, mae'n darllen `original[id]`,
`original[prevId]`, `original[nextId]` o'r **un snapshot
wedi'i rewi** ac yn ysgrifennu i restr `next` ar wahân.
Nid yw'n cyfrifo'r pours yr eildro: cedwir gwerthoedd PATCH 09
a ddaeth drwy'r graith go iawn. Ni chaiff yr un darlleniad
gwneud defnydd o `next` cyn diwedd y chwe chyfrifiad.

Mae `runPatchedSnapshots` yn prosesu 46 diferion allanol.
Mae pob cam yn cynhyrchu un hen graith a chwe gwerth cywir.
Mae `BOOT → PATCH_10` yn cadw'r 46 tyst a'r canlyniad cywir,
a'r naw cownter, yn atomig mewn cyd-destun unigryw.

## Gwirio brodorol
`sh run-stage21-tests.sh` yn rhedeg pob cam 1–20 ac yna:
- 720 permutation: 720 canlyniad cywir, 720 RED etifeddol;
  4,320 ysgrifen snapshot GREEN, 3,600 hen ysgrifen anghywir;
- 46 diferion identity, reverse a naturiol: canlyniad cywir
  yn cyfateb yn union i `NormativeCore` ar ochr prawf;
- 4,320 tyst annibynnol `BigInteger` (chwe chylch):
  4,320 GREEN cywir, 4,320 RED etifeddol, 21,600
  ysgrifen etifeddol anghywir;
- gwarchod ymyl, clôn, BOOT, replay, perchnogaeth a
  holl lwybrau a scarau Camau 1–20.

Ni chaniateir gosod `LAST_COMPLETED_STAGE=21` nes
`STAGE21_FULL_NATIVE_GREEN` a PASS GitHub Actions gyda
Kotlin 1.9.0/JDK 21. Y cam nesaf wedyn yw 22 DISCOVERY 11.
