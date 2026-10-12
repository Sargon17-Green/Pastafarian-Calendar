# Cam 22 — DISCOVERY 11: cache savedBowlSum stir 1 am 12 stir

## Ffiniau
Gangen `Kotlin+Cymraeg`. Sylfaen wedi'i hardystio
`6a9859b44c21c77040c1dd306f307bd321426595`; `LAST_COMPLETED_STAGE=21` hyd nes CI llawn.
Ni ddechreuwyd PATCH 11 na'r adeiladwr diferion gweledig.

## Y nam hanesyddol
Ar ôl 46 arllwys cywir mae'r oracl yn gweithredu 12 stir.
Ar stir s mae'r contract normadol yn ailgyfrifo'r chwe bowl o'r
hen snapshot, yn eu crynhoi, ac yn gwneud
`savedBowlSum = save(sum(old[1..6]) + 149*s)`.
Mae'r saved sum newydd yn penderfynu'r permutation ac yn
mewnbynnu cymysgu 6 bowls gyda chymarebau 3/5/7.

Mae `LegacyCachedStirAdapter.oldCachedPostStir12` yn
cyfrifo'r saved sum **unwaith ar stir 1 yn unig**, yna'n
ei ddefnyddio ar stir 2..12 heb ailgyfrifo. Mae'r
permutation yn dal yn PATCH 08 (cywir i'r saved sum a
gafodd), ac mae'r cymysgu yn darllen un hen snapshot ar
bob stir; felly'r unig graith yw'r cache hen sum.

Mae pob `LegacyCachedStirStep` yn cadw'r hen bowls,
saved sum anghywir, stir a darddodd y cache,
permutation, bowls newydd a chyfrif y galwadau.
Mae `BOOT → DISCOVERY_11` yn gwneud pob un o'r 12 stir
ac yn ymrwymo'n atomig ar ôl pob gwiriad.

## Tystiolaeth brodorol
`sh run-stage22-tests.sh` yn ail-redeg Camau 1–21 ac yna:
- 720 achos: stir 1 yn GREEN, stir 2 a'r 12 stir terfynol
  yn EXPECTED_RED, dim MATCH, 8,640 cymysgiad wedi'u
  gwirio â fformiwla gyfeirio ar ochr prawf yn unig;
- rhifau anferth positif/negatif a guards mewnbwn;
- 4,320 tyst BigInteger annibynnol gyda 51,840
  cam stir wedi'u gwirio (6 cylch o 720);
- strict RED bwriadol ar stir 2;
- BOOT/replay, perchnogaeth, metrigau, adfer holl
  lwybrau'r hen gamau.

Rhaid cael PASS brodorol `STAGE22_FULL_NATIVE_EXPECTED_RED_COMPLETE`
ar Kotlin 1.9.0/JDK 21 cyn llofnodi.
Y cam nesaf fydd Cam 23 — PATCH 11.
