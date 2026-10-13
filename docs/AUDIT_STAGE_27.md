# Cam 27 — PATCH 13: unrank1 a rejection ym mwlch y giât

## Llinach
Gangen `Kotlin+Cymraeg`, sylfaen ardystiedig Cam 26:
`e445002615208fcbee42db35b61c14c88b5ab655`. Mae `LAST_COMPLETED_STAGE=26` tan
lwyddo Kotlin brodorol. Nid yw Cam 28 wedi dechrau.

## Gwir nam hanesyddol, heb ei guddio
Mae `LegacyGateGapRankAdapter.oldGateGapWithoutRank1`
yn dal yn fyw, heb newid: mae'n defnyddio ordinal
`(first-1) mod 922` o'r *ateb cyntaf yn unig*, gan
anghofio rank1 a'r camau rejection. Mae'n rhoi gap
anghywir yn 41..962 yn lle 42..963.

Mae `GateGapRankPatchWrapper.patch` yn galw'r hen
ddull **yn gyntaf** ac yn cadw'r graith lawn. Yna
mae'n cyfrifo `upper = floor(M/922)*922` ac yn
cyfrifo `answerAt(k)` trwy symud un cam yn y
cyfeiriad `directionStep`, â wrap mod M, nes
bod yr ateb yn yr ystod 1..upper. Caiff pob ateb
a wrthodwyd ei gadw. Mae'r cywiriad wedyn yn
`rank1=1+((acceptedAnswer-1) mod 922)` ac
`gap=41+rank1`. Does dim un galwad oracle
`NormativeCore` yn y llwybr cynhyrchu.

Mae `BOOT → PATCH_13` yn cyflwyno'r
`GateGapPatchOutcome` a'r rank1, gap,
accepted answer, rhestr rejection a'r metriau
fel newid atomig mewn cyd-destun ar wahân.
Ni all replay ddyblygu'r cyfrifiad.

## Dilysu
`sh run-stage27-tests.sh` yn ail-redeg holl Gamau
1–26 a'r holl strict RED hanesyddol, wedyn:
- 922 positive + 922 negative: 1,844 GREEN cywir
  gyda 1,844 hen RED wedi'u cadw;
- 8 ffin rejection: 8 GREEN, 7 hen RED a
  1 MATCH damweiniol, gyda'r holl rejection traces;
- 11,064 achos BigInteger GREEN a 11,064
  hen RED; 442 profion rejected BigInteger ar gyfer
  pob un o'r 221 gwerth anghymwys yn y ddau gyfeiriad;
- gwirioneddau sauce positif a negatif yr oracl,
  guards, BOOT/replay, isolation a'r llwybrau blaenorol.

Ni chaniateir gosod `LAST_COMPLETED_STAGE=27`
hyd nes PASS brodorol Kotlin 1.9.0/JDK 21 gyda'r
marc `STAGE27_FULL_NATIVE_GREEN`. Mae'r
stream sauce yn fewnbwn allanol ar hyn o bryd.


## Ardystiad brodorol Cam 27 — COMPLETE

Ar commit `b7f514d7c3c2526ae11472454a946d7b9ba5e6f6` llwyddodd GitHub Actions
[`38430144336`](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38430144336),
swydd Kotlin `115409873362`, gyda Kotlin 1.9.0/JDK 21.
Gwiriwyd **51 marc** yn uniongyrchol yn log y swydd:
pob cam 1–26 yn PASS; 1,844 gap cywir GREEN a
1,844 hen gap RED wedi'u cadw; 8 ffin rejection
(8 GREEN, 7 legacy RED, 1 MATCH damweiniol);
11,064 BigInteger GREEN, 11,064 hen RED, 442
BigInteger rejection GREEN gyda'r trace gyfan;
gwerthoedd naturiol positif/negatif, BOOT/replay,
perchnogaeth a'r holl lwybrau blaenorol yn PASS.
Gwelwyd `STAGE27_FULL_NATIVE_GREEN`; gorffennodd
Kotlin a swydd cloi enwau yn SUCCESS.

**`LAST_COMPLETED_STAGE=27`**. Cam 28
(`DISCOVERY 14`) yw'r nesaf, heb ei ddechrau.
Cedwir `LegacyGateGapRankAdapter.oldGateGapWithoutRank1`
yn fyw ac anghywir; mae'r stream sauce yn parhau'n
fewnbwn allanol tan adeiladwr diferion gweledig.
