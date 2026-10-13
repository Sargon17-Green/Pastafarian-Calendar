# Cam 26 — DISCOVERY 13: rank0 yn lle unrank1 ym mwlch giât

## Sylfaen
Gangen `Kotlin+Cymraeg`, commit wedi'i ardystio
`bf5079e2753c0fa65c7a715e6b6491a23182c036`. Mae `LAST_COMPLETED_STAGE=25`
tan PASS brodorol. Mae Cam 27 PATCH 13 heb ddechrau.

## Y contract a'r graith
Ar gyfer giât n (positif neu negatif), mae'r oracl yn
cymryd y stream o `askBowl(sauce(FOUNDATION_DAY,
FOUNDATION_DAY ± n), bowl=1, seal=1)`. Mae'n
defnyddio `chooseRankInt(stream,922)` drwy unrank1
gyda gwrthod detholwyr sydd uwch na
`floor(M/922)*922`; mae'r gap cywir yn
`41+rank1` yn yr ystod 42..963.

Yn y caller hanesyddol
`LegacyGateGapRankAdapter.oldGateGapWithoutRank1`,
mae'r stream cyntaf cywir yn fewnbwn, ond cyfrifir
`rank0=(first-1) mod 922` a `gap=41+rank0`,
heb `+1` ac heb wrthod. Mae'r gap etifeddol felly
yn 41..962 ac yn anghywir fel arfer. Caiff
`streamDirectionStep`, gate n, `oneShotReads=1`
a `rejectedCandidatesProcessed=0` eu cadw'n dystion.

Mae gwrthod yn gallu creu **cydweddiad damweiniol**.
Yn union ar 8 prawf ymyl (4 values × 2 directions),
disgwylir 7 RED ac 1 MATCH; nid oes honiad ffug
bod pob ymyl yn RED. Nid yw hyn yn PATCH 13.

Mae `BOOT → DISCOVERY_13` yn cadw'n atomig
`LegacyGateGapRankRead`, y gap anghywir,
metriau a trace; gwrthodir replay. Mae'r
stream answer yn fewnbwn allanol ar hyn o bryd;
ni ddefnyddir `NormativeCore` o fewn cynhyrchu.

## Profion
`sh run-stage26-tests.sh` yn ailredeg pob cam
1–25, gan gynnwys yr holl strict RED blaenorol.
Ar ôl hynny:
- 922 positive + 922 negative: 1,844 EXPECTED_RED
  o'r gwall rank0; pen isaf legacy 41 a phen uchaf
  normadol 963;
- 8 prawf rejection ymyl: 7 RED, 1 MATCH;
- 11,064 achos BigInteger annibynnol o'r ystod
  dderbyniol, gyda phob RED yn fwriadol;
- dau stream naturiol positif a negatif o'r
  sauce oracl ar ochr prawf yn unig;
- strict RED gwirioneddol, guards, BOOT/replay,
  ownership a holl lwybrau Camau 1–25.

Ni chaniateir rhoi `LAST_COMPLETED_STAGE=26`
nes PASS Kotlin 1.9.0/JDK 21, a'r marc
`STAGE26_FULL_NATIVE_EXPECTED_RED_COMPLETE`.
Cam 27 fydd PATCH 13, gan gadw'r nam hwn.


## Ardystiad brodorol Cam 26 — COMPLETE

Ar commit `86673c940e9c003bc42fb5ae00d87c2ca9da4d84` llwyddodd GitHub Actions
[`38376236629`](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38376236629),
swydd Kotlin `115225200264`, ar Kotlin 1.9.0/JDK 21.
Gwiriwyd **48 marc** yn uniongyrchol yn y log:
pob cam 1–25 yn PASS; 922 achos positive
EXPECTED_RED, 922 achos negative EXPECTED_RED,
8 achos rejection ymyl (7 RED, 1 MATCH damweiniol),
11,064 BigInteger EXPECTED_RED, dau stream sauce naturiol
positive a negative, strict RED gwirioneddol,
BOOT/replay, perchnogaeth a holl lwybrau blaenorol.
Gwelwyd `STAGE26_FULL_NATIVE_EXPECTED_RED_COMPLETE`,
ac roedd y swydd Kotlin a'r swydd cloi enwau yn SUCCESS.

**`LAST_COMPLETED_STAGE=26`**. Cam 27
(`PATCH 13`) yw'r nesaf, heb ei ddechrau.
Cedwir `oldGateGapWithoutRank1` yn fyw ac
yn anghywir; mae'r stream sauce yn fewnbwn allanol
tan adeiladwr y diferion gweledig diweddarach.
