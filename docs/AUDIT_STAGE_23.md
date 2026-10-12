# Cam 23 — PATCH 11: ailgyfrifo sum yr hen bowls ym mhob stir

## Sylfaen
Gangen `Kotlin+Cymraeg`. Sylfaen ardystiedig Cam 22:
`ad31244586675897eff7d04cac7739ac81fe0c59`. Cedwir `LAST_COMPLETED_STAGE=22` hyd
nes PASS brodorol. Ni ddechreuwyd Cam 24 ac ni adeiladwyd
diferion gweledig cynhyrchu.

## Y cywiriad
Cedwir `LegacyCachedStirAdapter.oldCachedPostStir12` heb
ei newid: mae'n ailddefnyddio `savedBowlSum` stir 1 ar
bob stir 2..12. Mae `FreshStirPatchWrapper.patch` yn galw
yr hen ddull yn wirioneddol **yn gyntaf** ar glôn ac yn
cadw'r 12 hen stir, y cached sum, a'r canlyniad anghywir.

Yna, ar bob stir s=1..12, mae'r wrapper yn crynhoi bowls
y snapshot diweddaraf 1..6 ac yn defnyddio
`save(sum(old[1..6]) + 149*s)`. Gan ddefnyddio'r
`PermutationPatchWrapper.patch` cywir, mae'n pennu'r
permutation ac yn cymysgu'r chwe bowls o'r **un snapshot**
gyda'r ffactorau normadol 3,5,7. Mae'r bowl canlyniadol
yn mynd i'r stir dilynol. Nid yw'r wrapper yn dibynnu
ar oracl `NormativeCore` o fewn cynhyrchu.

Mae `BOOT → PATCH_11` yn cadw'n atomig y 12 stir cywir,
y 12 stir etifeddol, 12 saved sums newydd, pob permutation,
a'r counters mewn context annibynnol, heb replay.

## Gofynion profi
`sh run-stage23-tests.sh` yn rhedeg Camau 1–22 gyda'r
strict RED hanesyddol ac yna:
- 720 achos: 720 canlyniad normadol GREEN,
  720 hen ganlyniad RED, stir 1 GREEN y ddau,
  a'r sum newydd yn cywiro stir 2;
- 8,640 cam stir wedi'u gwirio'n annibynnol
  gyda'r oracl ffynhonnell wreiddiol;
- 4,320 achos BigInteger annibynnol gyda 51,840
  stir wedi'u gwirio;
- rhifau positif a negatif enfawr, guards,
  BOOT/replay, perchnogaeth a'r scarau blaenorol.

Dim ond ar ôl `STAGE23_FULL_NATIVE_GREEN` a PASS
Kotlin 1.9.0/JDK 21 gellir gosod
`LAST_COMPLETED_STAGE=23`. Y cam nesaf yw
Cam 24 — DISCOVERY 12.
